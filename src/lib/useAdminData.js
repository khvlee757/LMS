import { computed, ref } from "vue";
import { supabase } from "@/lib/supabase";
import { getAuthenticatedProfile } from "@/lib/auth";
import { money, calculateLoginSummary } from "@/lib/adminFormatters";
import { printOrderReceipt } from "@/lib/adminReceipt";

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

      const err = coursesRes.error || peopleRes.error || applicationsRes.error || activityRes.error || booksRes.error || paymentsRes.error;
      if (err) throw new Error(err.message || "Failed to load administration data.");

      people.value = peopleRes.data ?? [];
      courses.value = coursesRes.data ?? [];
      books.value = booksRes.data ?? [];
      loginActivity.value = activityRes.data ?? [];
      paymentOrders.value = paymentRes.data ?? [];
      applications.value = (applicationsRes.data ?? []).map((app) => ({
        ...app,
        profile: people.value.find((p) => p.user_id === app.user_id),
      }));
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

  async function createCourse(draft) {
    if (!supabase || !currentProfile.value || !draft.title.trim()) return false;
    error.value = "";
    notice.value = "";
    const { data, error: insertError } = await supabase.from("courses").insert({
      title: draft.title.trim(),
      description: draft.description?.trim() || "",
      category: draft.category?.trim() || "General",
      level: draft.level || "beginner",
      is_free: draft.is_free,
      price_minor: draft.is_free ? 0 : Math.round(Number(draft.price) * 100),
      currency: "NGN",
      instructor_id: currentProfile.value.user_id,
      published: false,
    }).select().single();

    if (insertError) {
      error.value = insertError.message;
      return false;
    }
    courses.value = [data, ...courses.value];
    notice.value = "New course created as draft.";
    return true;
  }

  async function toggleCoursePublished(course) {
    if (!supabase) return;
    error.value = "";
    const targetStatus = !course.published;
    const { error: updateError } = await supabase.from("courses").update({ published: targetStatus }).eq("id", course.id);
    if (updateError) error.value = updateError.message;
    else {
      course.published = targetStatus;
      notice.value = targetStatus ? `Course "${course.title}" published.` : `Course "${course.title}" unpublished.`;
    }
  }

  async function deleteCourse(courseId) {
    if (!supabase) return false;
    error.value = "";
    const { error: delError } = await supabase.from("courses").delete().eq("id", courseId);
    if (delError) {
      error.value = delError.message;
      return false;
    }
    courses.value = courses.value.filter((c) => c.id !== courseId);
    notice.value = "Course deleted successfully.";
    return true;
  }

  async function toggleBookPublished(book) {
    if (!supabase) return;
    error.value = "";
    const targetStatus = !book.published;
    const { error: updateError } = await supabase.from("books").update({ published: targetStatus }).eq("id", book.id);
    if (updateError) error.value = updateError.message;
    else {
      book.published = targetStatus;
      notice.value = targetStatus ? `Book "${book.title}" published.` : `Book "${book.title}" unpublished.`;
    }
  }

  async function deleteBook(bookId) {
    if (!supabase) return false;
    error.value = "";
    const { error: delError } = await supabase.from("books").delete().eq("id", bookId);
    if (delError) {
      error.value = delError.message;
      return false;
    }
    books.value = books.value.filter((b) => b.id !== bookId);
    notice.value = "Book deleted successfully.";
    return true;
  }

  async function reviewApplication(application, status, reviewNotes = "") {
    if (!supabase || !currentProfile.value) return false;
    error.value = "";
    notice.value = "";

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
    const { error: roleError } = await supabase
      .from("profiles")
      .update({ role: targetRole })
      .eq("user_id", application.user_id);

    if (roleError) {
      error.value = `Status updated, but role update failed: ${roleError.message}`;
      return false;
    }

    const person = people.value.find((p) => p.user_id === application.user_id);
    if (person) person.role = targetRole;

    notice.value = status === "approved"
      ? `Instructor verified & approved for ${application.profile?.full_name || application.profile?.email || "Applicant"}.`
      : `Application rejected. Account remains learner.`;
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
    for (const order of verifiedPaidOrders.value) {
      map.set(order.currency, (map.get(order.currency) || 0) + order.amount_minor);
    }
    return [...map.entries()];
  });

  const platformFeesByCurrency = computed(() => {
    const map = new Map();
    for (const order of verifiedPaidOrders.value) {
      map.set(order.currency, (map.get(order.currency) || 0) + (order.platform_fee_minor || 0));
    }
    return [...map.entries()];
  });

  return {
    currentProfile,
    people,
    courses,
    books,
    applications,
    paymentOrders,
    loginActivity,
    loading,
    error,
    notice,
    pendingApplicationsCount,
    verifiedPaidOrders,
    grossSalesByCurrency,
    platformFeesByCurrency,
    fetchAdminData,
    money,
    loginSummary,
    printReceipt,
    createCourse,
    toggleCoursePublished,
    deleteCourse,
    toggleBookPublished,
    deleteBook,
    reviewApplication,
    demoteInstructorToStudent,
  };
}
