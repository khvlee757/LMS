import { computed, ref } from "vue";
import { supabase } from "@/lib/supabase";
import { getAuthenticatedProfile } from "@/lib/auth";
import { money, calculateLoginSummary } from "@/lib/adminFormatters";
import { printOrderReceipt } from "@/lib/adminReceipt";
import { createAdminCatalogActions } from "@/lib/useAdminCatalog";

const currentProfile = ref(null);
const people = ref([]);
const courses = ref([]);
const books = ref([]);
const applications = ref([]);
const paymentOrders = ref([]);
const loginActivity = ref([]);
const loading = ref(false);
const error = ref("");
const notice = ref("");
let hasLoadedOnce = false;

export function useAdminData() {
  async function fetchAdminData(force = false) {
    if (hasLoadedOnce && !force && people.value.length > 0) return;
    if (!supabase) {
      error.value = "Supabase client is not available.";
      return;
    }

    loading.value = true;
    error.value = "";

    try {
      const { user, profile, error: authErr } = await getAuthenticatedProfile();
      if (authErr || !user) throw new Error(authErr?.message || "Not authenticated.");
      currentProfile.value = profile;

      const [coursesRes, peopleRes, applicationsRes, activityRes, booksRes, paymentsRes] = await Promise.all([
        supabase.from("courses").select("id, instructor_id, title, description, category, level, thumbnail_url, published, is_free, price_minor, currency, created_at").order("created_at", { ascending: false }),
        supabase.from("profiles").select("user_id, email, full_name, phone, role, created_at").order("created_at", { ascending: false }),
        supabase.from("instructor_applications").select("user_id, organization, professional_title, expertise, experience_years, qualification, verification_url, teaching_statement, status, review_notes, reviewed_by, reviewed_at, created_at").order("created_at", { ascending: false }),
        supabase.from("login_activity").select("user_id, activity_date").order("activity_date", { ascending: false }).limit(10000),
        supabase.from("books").select("id, instructor_id, title, description, category, is_free, price_minor, currency, file_path, published, created_at").order("created_at", { ascending: false }),
        supabase.from("payment_orders").select("id, receipt_number, buyer_id, instructor_id, product_type, course_id, book_id, amount_minor, platform_fee_minor, currency, provider, provider_reference, status, created_at, paid_at").order("created_at", { ascending: false }).limit(1000),
      ]);

      if (peopleRes.error) {
        throw new Error(`Failed to load user profiles: ${peopleRes.error.message}`);
      }

      people.value = peopleRes.data ?? [];
      courses.value = coursesRes.data ?? [];
      books.value = booksRes.data ?? [];
      loginActivity.value = activityRes.data ?? [];
      paymentOrders.value = paymentsRes.data ?? [];

      const rawApps = applicationsRes.data ?? [];
      const appUserIds = new Set(rawApps.map((a) => a.user_id));

      const mappedApps = rawApps.map((app) => ({
        ...app,
        profile: people.value.find((p) => p.user_id === app.user_id),
      }));

      // Ensure every instructor in profiles has an inspectable dossier
      const fallbackInstructorApps = people.value
        .filter((p) => p.role === "instructor" && !appUserIds.has(p.user_id))
        .map((p) => ({
          user_id: p.user_id,
          organization: "Registered Educator",
          professional_title: "Instructor",
          expertise: "Curriculum Specialist",
          experience_years: 1,
          qualification: "Verified Account",
          verification_url: "",
          teaching_statement: "Instructor registered on platform.",
          status: "approved",
          created_at: p.created_at || new Date().toISOString(),
          profile: p,
        }));

      applications.value = [...mappedApps, ...fallbackInstructorApps];

      if (applicationsRes.error && applicationsRes.error.code === "42P01") {
        notice.value = "Table 'instructor_applications' not detected. Run setup.sql in Supabase to track custom verification forms.";
      }
      hasLoadedOnce = true;
    } catch (e) {
      error.value = e.message || "Error fetching admin data.";
    } finally {
      loading.value = false;
    }
  }

  function loginSummary(userId) {
    return calculateLoginSummary(loginActivity.value, userId);
  }

  function printReceipt(order) {
    try {
      printOrderReceipt(order, { people: people.value, courses: courses.value, books: books.value });
    } catch (e) {
      error.value = e.message;
    }
  }

  const {
    createCourse,
    toggleCoursePublished,
    deleteCourse,
    toggleBookPublished,
    deleteBook,
  } = createAdminCatalogActions({ currentProfile, courses, books, error, notice });

  async function reviewApplication(application, status, reviewNotes = "") {
    if (!supabase || !currentProfile.value) return false;
    error.value = "";
    notice.value = "";

    // 1. Try atomic database RPC first (bypasses RLS issues)
    const { error: rpcErr } = await supabase.rpc("admin_review_instructor_application", {
      target_user_id: application.user_id,
      new_status: status,
      notes: reviewNotes || null,
    });

    if (!rpcErr) {
      application.status = status;
      application.reviewed_at = new Date().toISOString();
      application.review_notes = reviewNotes;
      const targetRole = status === "approved" ? "instructor" : "student";
      const person = people.value.find((p) => p.user_id === application.user_id);
      if (person) person.role = targetRole;
      if (!applications.value.some((a) => a.user_id === application.user_id)) {
        applications.value = [application, ...applications.value];
      }
      notice.value = status === "approved"
        ? `Instructor verified & approved for ${application.profile?.full_name || application.profile?.email || "Applicant"}.`
        : `Application rejected. Account remains learner.`;
      return true;
    }

    // 2. Direct UPDATE fallback (uses update policy, avoids insert policy violation)
    const { error: appError } = await supabase
      .from("instructor_applications")
      .update({
        status,
        review_notes: reviewNotes || null,
        reviewed_by: currentProfile.value.user_id,
        reviewed_at: new Date().toISOString(),
      })
      .eq("user_id", application.user_id);

    if (appError) {
      error.value = appError.message;
      return false;
    }

    application.status = status;
    application.reviewed_at = new Date().toISOString();
    application.review_notes = reviewNotes;

    const targetRole = status === "approved" ? "instructor" : "student";
    const { error: roleError } = await supabase.from("profiles").update({ role: targetRole }).eq("user_id", application.user_id);
    if (roleError) {
      error.value = `Status updated, but role update failed: ${roleError.message}`;
      return false;
    }

    const person = people.value.find((p) => p.user_id === application.user_id);
    if (person) person.role = targetRole;
    if (!applications.value.some((a) => a.user_id === application.user_id)) {
      applications.value = [application, ...applications.value];
    }

    notice.value = status === "approved"
      ? `Instructor verified & approved for ${application.profile?.full_name || application.profile?.email || "Applicant"}.`
      : `Application rejected. Account remains learner.`;
    return true;
  }

  async function grantSuperAdmin(identifier) {
    if (!supabase || !currentProfile.value) return false;
    error.value = "";
    notice.value = "";
    const clean = String(identifier || "").trim().toLowerCase();

    const { data: rpcData, error: rpcErr } = await supabase.rpc("add_super_admin", { target_email: clean });
    if (!rpcErr && rpcData?.success) {
      const p = people.value.find((u) => u.email?.toLowerCase() === clean || u.user_id === rpcData.user_id);
      if (p) p.role = "super_admin";
      notice.value = `Super admin clearance granted to ${p?.full_name || clean}.`;
      return true;
    }

    const person = people.value.find((u) => u.email?.toLowerCase() === clean || u.user_id === clean);
    if (!person) {
      error.value = rpcErr?.message || `User "${clean}" not found. Ensure they are registered first.`;
      return false;
    }

    const { error: updErr } = await supabase.from("profiles").update({ role: "super_admin" }).eq("user_id", person.user_id);
    if (updErr) {
      error.value = updErr.message;
      return false;
    }
    person.role = "super_admin";
    notice.value = `Super admin clearance granted to ${person.full_name || person.email}.`;
    return true;
  }

  async function revokeSuperAdmin(userId) {
    if (!supabase || !currentProfile.value) return false;
    if (userId === currentProfile.value.user_id) {
      error.value = "You cannot remove admin clearance from your own account.";
      return false;
    }
    error.value = "";
    notice.value = "";

    const { data: rpcData, error: rpcErr } = await supabase.rpc("demote_super_admin", { target_user_id: userId });
    if (!rpcErr && rpcData?.success) {
      const p = people.value.find((u) => u.user_id === userId);
      if (p) p.role = "student";
      notice.value = `Admin clearance revoked. Account role changed to Learner.`;
      return true;
    }

    const { error: updErr } = await supabase.from("profiles").update({ role: "student" }).eq("user_id", userId);
    if (updErr) {
      error.value = updErr.message;
      return false;
    }
    const person = people.value.find((u) => u.user_id === userId);
    if (person) person.role = "student";
    notice.value = `Admin clearance revoked. Account role changed to Learner.`;
    return true;
  }

  async function demoteInstructorToStudent(userId) {
    if (!supabase) return false;
    error.value = "";
    const { error: roleError } = await supabase.from("profiles").update({ role: "student" }).eq("user_id", userId);
    if (roleError) {
      error.value = `Could not update user role: ${roleError.message}`;
      return false;
    }
    const person = people.value.find((p) => p.user_id === userId);
    if (person) person.role = "student";
    notice.value = `Account role changed to Learner.`;
    return true;
  }

  const pendingApplicationsCount = computed(() => applications.value.filter((app) => app.status === "pending").length);
  const verifiedPaidOrders = computed(() => paymentOrders.value.filter((o) => o.status === "paid"));

  const grossSalesByCurrency = computed(() => {
    const map = new Map();
    for (const o of verifiedPaidOrders.value) map.set(o.currency, (map.get(o.currency) || 0) + o.amount_minor);
    return [...map.entries()];
  });

  const platformFeesByCurrency = computed(() => {
    const map = new Map();
    for (const o of verifiedPaidOrders.value) map.set(o.currency, (map.get(o.currency) || 0) + (o.platform_fee_minor || 0));
    return [...map.entries()];
  });

  return {
    currentProfile, people, courses, books, applications, paymentOrders, loginActivity,
    loading, error, notice, pendingApplicationsCount, verifiedPaidOrders,
    grossSalesByCurrency, platformFeesByCurrency, fetchAdminData, money, loginSummary,
    printReceipt, createCourse, toggleCoursePublished, deleteCourse,
    toggleBookPublished, deleteBook, reviewApplication, demoteInstructorToStudent,
    grantSuperAdmin, revokeSuperAdmin,
  };
}
