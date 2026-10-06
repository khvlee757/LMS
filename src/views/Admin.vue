<script setup>
import { computed, onMounted, reactive, ref } from "vue";
import { BookOpen, Check, CircleDollarSign, GraduationCap, LoaderCircle, Plus, ReceiptText, ShieldCheck, Users } from "lucide-vue-next";
import { getAuthenticatedProfile } from "@/lib/auth";
import { supabase } from "@/lib/supabase";

const currentProfile = ref(null);
const courses = ref([]);
const books = ref([]);
const paymentOrders = ref([]);
const people = ref([]);
const applications = ref([]);
const loginActivity = ref([]);
const reviewingUser = ref("");
const loading = ref(true);
const saving = ref(false);
const errorMessage = ref("");
const notice = ref("");
const activeTab = ref("overview");
const draft = reactive({ title: "", description: "", category: "", level: "beginner", is_free: true, price: "" });
const paymentSearch = ref("");
const paidTotals = computed(() => {
  const totals = new Map();
  for (const order of paymentOrders.value) {
    if (order.status !== "paid") continue;
    totals.set(order.currency, (totals.get(order.currency) ?? 0) + order.amount_minor);
  }
  return [...totals.entries()];
});
const filteredPayments = computed(() => {
  const query = paymentSearch.value.trim().toLowerCase();
  if (!query) return paymentOrders.value;
  return paymentOrders.value.filter((order) => {
    const buyer = people.value.find((person) => person.user_id === order.buyer_id);
    const product = order.product_type === "course"
      ? courses.value.find((course) => course.id === order.course_id)
      : books.value.find((book) => book.id === order.book_id);
    return [order.receipt_number, order.provider_reference, buyer?.email, buyer?.full_name, product?.title]
      .some((value) => String(value ?? "").toLowerCase().includes(query));
  });
});
const summaryCards = computed(() => [
  { label: "Learners", value: people.value.filter((person) => person.role === "student").length, icon: GraduationCap },
  { label: "Instructors", value: people.value.filter((person) => person.role === "instructor").length, icon: Users },
  { label: "Courses", value: courses.value.length, icon: BookOpen },
  { label: "Books", value: books.value.length, icon: BookOpen },
  { label: "Paid orders", value: paymentOrders.value.filter((order) => order.status === "paid").length, icon: CircleDollarSign },
  { label: "Pending instructor reviews", value: applications.value.filter((application) => application.status === "pending").length, icon: ShieldCheck },
]);

onMounted(async () => {
  const { user, profile, error } = await getAuthenticatedProfile();
  currentProfile.value = profile;
  if (!supabase || !user || error) {
    errorMessage.value = error?.message || "Supabase is not configured.";
    loading.value = false;
    return;
  }
  await loadData();
});

async function loadData() {
  if (!supabase) return;
  const [courseResult, peopleResult, applicationResult, activityResult, bookResult, paymentResult] = await Promise.all([
    supabase.from("courses").select("id, title, category, level, published, is_free, price_minor, currency, created_at").order("created_at", { ascending: false }),
    supabase.from("profiles").select("user_id, email, full_name, role, created_at").order("created_at", { ascending: false }),
    supabase.from("instructor_applications").select("user_id, organization, professional_title, expertise, experience_years, qualification, verification_url, teaching_statement, status, review_notes, created_at, reviewed_at").order("created_at", { ascending: false }),
    supabase.from("login_activity").select("user_id, activity_date").order("activity_date", { ascending: false }).limit(10000),
    supabase.from("books").select("id, instructor_id, title, category, is_free, price_minor, currency, file_path, published, created_at").order("created_at", { ascending: false }),
    supabase.from("payment_orders").select("id, receipt_number, buyer_id, instructor_id, product_type, course_id, book_id, amount_minor, platform_fee_minor, currency, provider, provider_reference, status, created_at, paid_at").order("created_at", { ascending: false }).limit(500),
  ]);
  if (courseResult.error || peopleResult.error || applicationResult.error || activityResult.error || bookResult.error || paymentResult.error) {
    errorMessage.value = courseResult.error?.message || peopleResult.error?.message || applicationResult.error?.message || activityResult.error?.message || bookResult.error?.message || paymentResult.error?.message || "Unable to load admin data.";
  } else {
    courses.value = courseResult.data ?? [];
    people.value = peopleResult.data ?? [];
    loginActivity.value = activityResult.data ?? [];
    books.value = bookResult.data ?? [];
    paymentOrders.value = paymentResult.data ?? [];
    applications.value = (applicationResult.data ?? []).map((application) => ({
      ...application,
      profile: people.value.find((person) => person.user_id === application.user_id),
    }));
  }
  loading.value = false;
}

function money(amountMinor, currency) {
  const fractionDigits = new Intl.NumberFormat(undefined, { style: "currency", currency }).resolvedOptions().maximumFractionDigits;
  return new Intl.NumberFormat(undefined, { style: "currency", currency }).format(amountMinor / (10 ** fractionDigits));
}

function escapeHtml(value) {
  return String(value ?? "").replace(/[&<>"']/g, (character) => ({
    "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;",
  })[character]);
}

function printReceipt(order) {
  if (order.status !== "paid") return;
  const buyer = people.value.find((person) => person.user_id === order.buyer_id);
  const instructor = people.value.find((person) => person.user_id === order.instructor_id);
  const product = order.product_type === "course"
    ? courses.value.find((course) => course.id === order.course_id)
    : books.value.find((book) => book.id === order.book_id);
  const receiptWindow = window.open("", "_blank", "width=760,height=900");
  if (!receiptWindow) {
    errorMessage.value = "Allow pop-ups to print this receipt.";
    return;
  }
  const receiptNumber = escapeHtml(order.receipt_number);
  const formattedDate = escapeHtml(new Date(order.paid_at || order.created_at).toLocaleString());
  const instructorNet = order.amount_minor - order.platform_fee_minor;
  const receiptHtml = `<!doctype html><html><head><meta charset="utf-8"><title>Receipt ${receiptNumber}</title><style>body{font:16px Arial,sans-serif;color:#172522;margin:48px auto;max-width:680px;padding:0 24px}header{border-bottom:3px solid #12615b;padding-bottom:20px}h1{margin:0;color:#12615b}small,dt{color:#65756c}.total{border-top:1px solid #dbe5df;margin-top:24px;padding-top:18px;font-size:20px;font-weight:700}dl{display:grid;grid-template-columns:180px 1fr;gap:14px}dt{font-weight:700}dd{margin:0;overflow-wrap:anywhere}.thanks{margin-top:48px;padding-top:18px;border-top:1px solid #dbe5df;color:#65756c}@media print{body{margin:0 auto}}</style></head><body><header><h1>Northstar Learning</h1><small>Payment receipt</small></header><dl><dt>Receipt</dt><dd>${receiptNumber}</dd><dt>Paid</dt><dd>${formattedDate}</dd><dt>Customer</dt><dd>${escapeHtml(buyer?.full_name || buyer?.email || "Learner")}</dd><dt>Item</dt><dd>${escapeHtml(product?.title || "Learning product")}</dd><dt>Instructor</dt><dd>${escapeHtml(instructor?.full_name || "Instructor")}</dd><dt>Transaction reference</dt><dd>${escapeHtml(order.provider_reference)}</dd></dl><p class="total">Total paid: ${escapeHtml(money(order.amount_minor, order.currency))}</p><p>Platform fee (10%): ${escapeHtml(money(order.platform_fee_minor, order.currency))}</p><p>Instructor share before payment-provider fees: ${escapeHtml(money(instructorNet, order.currency))}</p><p class="thanks">Thank you for learning with Northstar Learning.</p></body></html>`;
  receiptWindow.document.write(receiptHtml);
  receiptWindow.document.close();
  window.setTimeout(() => {
    receiptWindow.focus();
    receiptWindow.print();
  }, 250);
}

function loginSummary(userId) {
  const dates = new Set(loginActivity.value
    .filter((activity) => activity.user_id === userId)
    .map((activity) => activity.activity_date));
  const lastLogin = [...dates].sort((left, right) => right.localeCompare(left))[0] ?? null;
  const today = new Date().toISOString().slice(0, 10);
  const yesterday = new Date(`${today}T00:00:00.000Z`);
  yesterday.setUTCDate(yesterday.getUTCDate() - 1);
  let date = dates.has(today) ? today : yesterday.toISOString().slice(0, 10);
  let streak = 0;
  while (dates.has(date)) {
    streak += 1;
    const previous = new Date(`${date}T00:00:00.000Z`);
    previous.setUTCDate(previous.getUTCDate() - 1);
    date = previous.toISOString().slice(0, 10);
  }
  return { lastLogin, streak };
}

async function createCourse() {
  if (!supabase || saving.value || !draft.title.trim()) return;
  saving.value = true;
  errorMessage.value = "";
  notice.value = "";
  const { error } = await supabase.from("courses").insert({
    title: draft.title.trim(),
    description: draft.description.trim(),
    category: draft.category.trim() || "General",
    level: draft.level,
    is_free: draft.is_free,
    price_minor: draft.is_free ? 0 : Math.round(Number(draft.price) * 100),
    currency: "NGN",
    instructor_id: currentProfile.value.user_id,
    published: false,
  });
  if (error) {
    errorMessage.value = error.message;
  } else {
    Object.assign(draft, { title: "", description: "", category: "", level: "beginner", is_free: true, price: "" });
    notice.value = "Course created as a draft.";
    await loadData();
  }
  saving.value = false;
}

async function togglePublished(course) {
  const { error } = await supabase.from("courses").update({ published: !course.published }).eq("id", course.id);
  if (error) errorMessage.value = error.message;
  else {
    course.published = !course.published;
    notice.value = course.published ? "Course published." : "Course moved to drafts.";
  }
}

async function reviewApplication(application, status) {
  if (!supabase || reviewingUser.value) return;
  reviewingUser.value = application.user_id;
  errorMessage.value = "";
  notice.value = "";

  if (application.status !== "approved" || status !== "approved") {
    const { error } = await supabase.from("instructor_applications").update({
      status,
      reviewed_by: currentProfile.value.user_id,
      reviewed_at: new Date().toISOString(),
    }).eq("user_id", application.user_id);
    if (error) {
      errorMessage.value = error.message;
      reviewingUser.value = "";
      return;
    }
    application.status = status;
  }

  if (status === "approved") {
    const { error } = await supabase.from("profiles").update({ role: "instructor" }).eq("user_id", application.user_id);
    if (error) errorMessage.value = `Application approved, but instructor access was not activated: ${error.message}`;
    else {
      const person = people.value.find((item) => item.user_id === application.user_id);
      if (person) person.role = "instructor";
      notice.value = `${application.profile?.full_name || application.profile?.email || "Applicant"} is now an instructor.`;
    }
  } else {
    notice.value = "Instructor application rejected. The account remains a learner.";
  }
  application.reviewed_at = new Date().toISOString();
  reviewingUser.value = "";
}
</script>

<template>
  <section class="space-y-7">
    <header class="flex flex-wrap items-end justify-between gap-4">
      <div>
        <p class="mb-2 text-sm font-semibold text-primary">OWNER WORKSPACE</p>
        <h1 class="text-3xl font-extrabold text-foreground sm:text-4xl">Administration</h1>
        <p class="mt-2 text-muted-foreground">Manage course publishing and learner access.</p>
      </div>
      <span class="inline-flex items-center gap-2 border border-primary/20 bg-white px-3 py-2 text-xs font-bold text-primary"><ShieldCheck :size="16" /> Super admin</span>
    </header>

    <p v-if="errorMessage" role="alert" class="border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-800">{{ errorMessage }}</p>
    <p v-if="notice" role="status" class="border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-800">{{ notice }}</p>

    <section class="border border-border bg-white p-5 sm:p-6">
      <div class="mb-5 flex items-center gap-2"><Plus :size="18" class="text-primary" /><h2 class="text-lg font-extrabold">Create a course</h2></div>
      <form class="grid gap-4 md:grid-cols-2" @submit.prevent="createCourse">
        <label class="space-y-1.5 text-sm font-semibold">Course title
          <input v-model="draft.title" required maxlength="160" class="h-11 w-full border border-border px-3 font-normal outline-none focus:border-primary focus:ring-2 focus:ring-primary/20" placeholder="e.g. Foundations of Biology" />
        </label>
        <label class="space-y-1.5 text-sm font-semibold">Category
          <input v-model="draft.category" maxlength="80" class="h-11 w-full border border-border px-3 font-normal outline-none focus:border-primary focus:ring-2 focus:ring-primary/20" placeholder="Science, design, business..." />
        </label>
        <label class="space-y-1.5 text-sm font-semibold">Level
          <select v-model="draft.level" class="h-11 w-full border border-border bg-white px-3 font-normal outline-none focus:border-primary focus:ring-2 focus:ring-primary/20">
            <option value="beginner">Beginner</option><option value="intermediate">Intermediate</option><option value="advanced">Advanced</option>
          </select>
        </label>
        <label class="flex min-h-11 items-center gap-3 border border-border px-3 text-sm font-semibold">
          <input v-model="draft.is_free" type="checkbox" class="size-4 accent-primary" /> Free course
        </label>
        <label v-if="!draft.is_free" class="space-y-1.5 text-sm font-semibold">Price (NGN)
          <input v-model="draft.price" type="number" min="1" step="0.01" required class="h-11 w-full border border-border px-3 font-normal outline-none focus:border-primary focus:ring-2 focus:ring-primary/20" placeholder="e.g. 5000" />
        </label>
        <label class="space-y-1.5 text-sm font-semibold md:row-span-2">Description
          <textarea v-model="draft.description" rows="3" maxlength="2000" class="w-full resize-y border border-border px-3 py-2 font-normal outline-none focus:border-primary focus:ring-2 focus:ring-primary/20" placeholder="What will students learn?" />
        </label>
        <button type="submit" :disabled="saving || !draft.title.trim() || (!draft.is_free && !(Number(draft.price) > 0))" class="inline-flex min-h-11 items-center justify-center gap-2 bg-primary px-4 text-sm font-bold text-white outline-none hover:bg-primary/90 focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2 disabled:opacity-60">
          <LoaderCircle v-if="saving" :size="16" class="animate-spin" /><Plus v-else :size="16" /> {{ saving ? 'Creating...' : 'Create draft' }}
        </button>
      </form>
    </section>

    <div class="flex flex-wrap border-b border-border" role="tablist" aria-label="Administration sections">
      <button v-for="tab in [{ id: 'overview', label: 'Overview' }, { id: 'people', label: 'People' }, { id: 'applications', label: 'Instructor applications' }, { id: 'courses', label: 'Courses' }, { id: 'books', label: 'Books' }, { id: 'payments', label: 'Payments' }]" :key="tab.id" type="button" role="tab" :aria-selected="activeTab === tab.id" class="min-h-11 border-b-2 px-4 text-sm font-bold outline-none focus-visible:ring-2 focus-visible:ring-primary" :class="activeTab === tab.id ? 'border-primary text-primary' : 'border-transparent text-muted-foreground hover:text-foreground'" @click="activeTab = tab.id">{{ tab.label }} <span v-if="tab.id !== 'overview'" class="ml-1 text-xs">{{ tab.id === 'courses' ? courses.length : tab.id === 'books' ? books.length : tab.id === 'payments' ? paymentOrders.length : tab.id === 'people' ? people.length : applications.filter((application) => application.status === 'pending').length }}</span></button>
    </div>

    <div v-if="loading" class="flex items-center gap-2 py-12 text-sm text-muted-foreground"><LoaderCircle :size="18" class="animate-spin" /> Loading administration data...</div>
    <div v-else-if="activeTab === 'overview'" class="space-y-6">
      <div class="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
        <article v-for="card in summaryCards" :key="card.label" class="border border-border bg-white p-5">
          <div class="flex items-center justify-between"><span class="text-sm font-semibold text-muted-foreground">{{ card.label }}</span><component :is="card.icon" :size="19" class="text-primary" aria-hidden="true" /></div>
          <p class="mt-5 text-3xl font-extrabold">{{ card.value }}</p>
        </article>
      </div>
      <section class="border border-border bg-white p-5 sm:p-6">
        <div class="flex flex-wrap items-start justify-between gap-4">
          <div><h2 class="text-lg font-extrabold">Verified sales</h2><p class="mt-1 text-sm text-muted-foreground">Totals include only completed Paystack payments.</p></div>
          <button type="button" class="text-sm font-bold text-primary underline underline-offset-4" @click="activeTab = 'payments'">All payments</button>
        </div>
        <div v-if="paidTotals.length" class="mt-5 grid gap-3 sm:grid-cols-2 xl:grid-cols-3">
          <div v-for="[currency, amount] in paidTotals" :key="currency" class="border border-border bg-secondary/50 p-4"><p class="text-xs font-bold uppercase text-muted-foreground">{{ currency }} gross paid</p><p class="mt-2 text-2xl font-extrabold">{{ money(amount, currency) }}</p></div>
        </div>
        <p v-else class="mt-5 border border-dashed border-border px-4 py-8 text-center text-sm text-muted-foreground">No verified payments yet. Payment checkout must be configured before sales appear here.</p>
      </section>
      <section class="border border-border bg-white">
        <div class="flex items-center justify-between gap-4 border-b border-border px-4 py-4"><h2 class="font-extrabold">Recent payments</h2><button type="button" class="text-sm font-bold text-primary hover:underline" @click="activeTab = 'payments'">View all</button></div>
        <div v-if="!paymentOrders.length" class="px-4 py-9 text-center text-sm text-muted-foreground">No payment records are available yet.</div>
        <div v-else class="overflow-x-auto"><table class="w-full min-w-[720px] text-left text-sm"><thead class="bg-secondary/70 text-xs uppercase text-muted-foreground"><tr><th class="px-4 py-3">Receipt</th><th class="px-4 py-3">Item</th><th class="px-4 py-3">Amount</th><th class="px-4 py-3">Status</th><th class="px-4 py-3">Action</th></tr></thead><tbody><tr v-for="order in paymentOrders.slice(0, 5)" :key="order.id" class="border-t border-border"><td class="px-4 py-3 font-semibold">{{ order.receipt_number }}</td><td class="px-4 py-3">{{ order.product_type === 'course' ? courses.find((item) => item.id === order.course_id)?.title : books.find((item) => item.id === order.book_id)?.title }}</td><td class="px-4 py-3">{{ money(order.amount_minor, order.currency) }}</td><td class="px-4 py-3 capitalize">{{ order.status }}</td><td class="px-4 py-3"><button type="button" :disabled="order.status !== 'paid'" class="inline-flex items-center gap-1.5 text-xs font-bold text-primary hover:underline disabled:text-muted-foreground" @click="printReceipt(order)"><ReceiptText :size="14" />Receipt</button></td></tr></tbody></table></div>
      </section>
    </div>
    <div v-else-if="activeTab === 'courses'" class="overflow-x-auto border border-border bg-white">
      <table class="w-full min-w-[600px] text-left text-sm">
        <thead class="border-b border-border bg-secondary/70 text-xs uppercase text-muted-foreground"><tr><th class="px-4 py-3 font-bold">Course</th><th class="px-4 py-3 font-bold">Level</th><th class="px-4 py-3 font-bold">Price</th><th class="px-4 py-3 font-bold">Status</th><th class="px-4 py-3 font-bold">Action</th></tr></thead>
        <tbody>
          <tr v-for="course in courses" :key="course.id" class="border-b border-border last:border-0">
            <td class="px-4 py-4"><span class="block font-bold">{{ course.title }}</span><span class="text-xs text-muted-foreground">{{ course.category || 'General' }}</span></td>
            <td class="px-4 py-4 capitalize text-muted-foreground">{{ course.level }}</td>
            <td class="px-4 py-4">{{ course.is_free ? 'Free' : money(course.price_minor, course.currency) }}</td>
            <td class="px-4 py-4"><span class="rounded-full px-2.5 py-1 text-xs font-bold" :class="course.published ? 'bg-emerald-50 text-emerald-800' : 'bg-secondary text-muted-foreground'">{{ course.published ? 'Published' : 'Draft' }}</span></td>
            <td class="px-4 py-4"><button type="button" class="inline-flex min-h-9 items-center gap-1.5 border border-border px-3 text-xs font-bold hover:border-primary hover:text-primary" @click="togglePublished(course)"><Check :size="14" /> {{ course.published ? 'Unpublish' : 'Publish' }}</button></td>
          </tr>
          <tr v-if="!courses.length"><td colspan="5" class="px-4 py-12 text-center text-muted-foreground">No courses yet. Create a draft above.</td></tr>
        </tbody>
      </table>
    </div>
    <div v-else-if="activeTab === 'people'" class="overflow-x-auto border border-border bg-white">
      <table class="w-full min-w-[820px] text-left text-sm">
        <thead class="border-b border-border bg-secondary/70 text-xs uppercase text-muted-foreground"><tr><th class="px-4 py-3 font-bold">Account</th><th class="px-4 py-3 font-bold">Role</th><th class="px-4 py-3 font-bold">Last login</th><th class="px-4 py-3 font-bold">Streak</th><th class="px-4 py-3 font-bold">Access</th></tr></thead>
        <tbody>
          <tr v-for="person in people" :key="person.user_id" class="border-b border-border last:border-0">
            <td class="px-4 py-4"><span class="block font-semibold">{{ person.full_name || 'New learner' }}</span><span class="text-xs text-muted-foreground">{{ person.email }}</span></td>
            <td class="px-4 py-4"><span class="capitalize">{{ person.role.replace('_', ' ') }}</span><span v-if="person.role === 'super_admin'" class="ml-2 text-xs text-primary">Owner</span></td>
            <td class="px-4 py-4 text-muted-foreground">{{ loginSummary(person.user_id).lastLogin || 'No logins yet' }}</td>
            <td class="px-4 py-4 font-semibold">{{ loginSummary(person.user_id).streak }} {{ loginSummary(person.user_id).streak === 1 ? 'day' : 'days' }}</td>
            <td class="px-4 py-4 text-xs text-muted-foreground">{{ person.role === 'super_admin' ? 'Only owner' : person.role === 'instructor' ? 'Approved application' : 'Learner access' }}</td>
          </tr>
          <tr v-if="!people.length"><td colspan="5" class="px-4 py-12 text-center text-muted-foreground">No profiles found.</td></tr>
        </tbody>
      </table>
    </div>
    <div v-else-if="activeTab === 'applications'" class="space-y-4">
      <article v-for="application in applications" :key="application.user_id" class="space-y-5 border border-border bg-white p-5 sm:p-6">
        <header class="flex flex-wrap items-start justify-between gap-3">
          <div>
            <h2 class="text-lg font-extrabold">{{ application.profile?.full_name || application.profile?.email || 'Instructor applicant' }}</h2>
            <p class="mt-1 text-sm text-muted-foreground">{{ application.organization }} · {{ application.professional_title }} · {{ application.experience_years }} years experience</p>
            <p class="mt-1 text-xs text-muted-foreground">Submitted {{ new Date(application.created_at).toLocaleDateString() }}</p>
          </div>
          <span class="rounded-full px-2.5 py-1 text-xs font-bold capitalize" :class="application.status === 'approved' ? 'bg-emerald-50 text-emerald-800' : application.status === 'rejected' ? 'bg-red-50 text-red-800' : 'bg-accent text-accent-foreground'">{{ application.status }}<span v-if="application.status === 'approved' && application.profile?.role !== 'instructor'"> · access pending</span></span>
        </header>
        <div class="grid gap-4 text-sm sm:grid-cols-2">
          <div><p class="text-xs font-bold uppercase text-muted-foreground">Subject area</p><p class="mt-1">{{ application.expertise }}</p></div>
          <div><p class="text-xs font-bold uppercase text-muted-foreground">Qualifications</p><p class="mt-1 whitespace-pre-line">{{ application.qualification }}</p></div>
          <div class="sm:col-span-2"><p class="text-xs font-bold uppercase text-muted-foreground">Teaching statement</p><p class="mt-1 whitespace-pre-line">{{ application.teaching_statement }}</p></div>
          <div class="sm:col-span-2"><a :href="application.verification_url" target="_blank" rel="noopener noreferrer" class="font-semibold text-primary underline underline-offset-4">Review verification link</a></div>
        </div>
        <footer v-if="application.status === 'pending' || (application.status === 'approved' && application.profile?.role !== 'instructor')" class="flex flex-wrap justify-end gap-2 border-t border-border pt-4">
          <button v-if="application.status === 'pending'" type="button" :disabled="reviewingUser === application.user_id" class="min-h-10 border border-border px-4 text-sm font-bold text-foreground hover:bg-secondary disabled:opacity-50" @click="reviewApplication(application, 'rejected')">Reject</button>
          <button type="button" :disabled="reviewingUser === application.user_id" class="inline-flex min-h-10 items-center gap-2 bg-primary px-4 text-sm font-bold text-white hover:bg-primary/90 disabled:opacity-50" @click="reviewApplication(application, 'approved')"><LoaderCircle v-if="reviewingUser === application.user_id" :size="15" class="animate-spin" /><Check v-else :size="15" />{{ application.status === 'approved' ? 'Finish instructor access' : 'Approve instructor' }}</button>
        </footer>
      </article>
      <div v-if="!applications.length" class="border border-dashed border-border bg-white px-6 py-14 text-center text-sm text-muted-foreground">No instructor applications yet.</div>
    </div>
    <div v-else-if="activeTab === 'books'" class="overflow-x-auto border border-border bg-white">
      <table class="w-full min-w-[760px] text-left text-sm">
        <thead class="border-b border-border bg-secondary/70 text-xs uppercase text-muted-foreground"><tr><th class="px-4 py-3 font-bold">Book</th><th class="px-4 py-3 font-bold">Instructor</th><th class="px-4 py-3 font-bold">Price</th><th class="px-4 py-3 font-bold">File</th><th class="px-4 py-3 font-bold">Status</th></tr></thead>
        <tbody>
          <tr v-for="book in books" :key="book.id" class="border-b border-border last:border-0">
            <td class="px-4 py-4"><span class="block font-bold">{{ book.title }}</span><span class="text-xs text-muted-foreground">{{ book.category || 'General' }}</span></td>
            <td class="px-4 py-4">{{ people.find((person) => person.user_id === book.instructor_id)?.full_name || people.find((person) => person.user_id === book.instructor_id)?.email || 'Instructor' }}</td>
            <td class="px-4 py-4">{{ book.is_free ? 'Free' : money(book.price_minor, book.currency) }}</td>
            <td class="px-4 py-4 text-muted-foreground">{{ book.file_path ? 'Attached' : 'No file' }}</td>
            <td class="px-4 py-4"><span class="rounded-full px-2.5 py-1 text-xs font-bold" :class="book.published ? 'bg-emerald-50 text-emerald-800' : 'bg-secondary text-muted-foreground'">{{ book.published ? 'Published' : 'Draft' }}</span></td>
          </tr>
          <tr v-if="!books.length"><td colspan="5" class="px-4 py-12 text-center text-muted-foreground">No books have been added yet.</td></tr>
        </tbody>
      </table>
    </div>
    <div v-else-if="activeTab === 'payments'" class="space-y-4">
      <div class="flex flex-wrap items-end justify-between gap-4">
        <div><h2 class="text-lg font-extrabold">Payment records</h2><p class="mt-1 text-sm text-muted-foreground">Receipts can be printed only for Paystack payments verified as paid.</p></div>
        <label class="block w-full sm:max-w-xs"><span class="sr-only">Search payments</span><input v-model="paymentSearch" type="search" class="h-10 w-full border border-border bg-white px-3 text-sm outline-none focus:border-primary focus:ring-2 focus:ring-primary/20" placeholder="Search receipt, buyer, item" /></label>
      </div>
      <div class="overflow-x-auto border border-border bg-white">
        <table class="w-full min-w-[900px] text-left text-sm">
          <thead class="border-b border-border bg-secondary/70 text-xs uppercase text-muted-foreground"><tr><th class="px-4 py-3 font-bold">Receipt</th><th class="px-4 py-3 font-bold">Customer</th><th class="px-4 py-3 font-bold">Item</th><th class="px-4 py-3 font-bold">Total</th><th class="px-4 py-3 font-bold">Platform 10%</th><th class="px-4 py-3 font-bold">Status</th><th class="px-4 py-3 font-bold">Action</th></tr></thead>
          <tbody>
            <tr v-for="order in filteredPayments" :key="order.id" class="border-b border-border last:border-0">
              <td class="px-4 py-4 font-semibold">{{ order.receipt_number }}</td>
              <td class="px-4 py-4">{{ people.find((person) => person.user_id === order.buyer_id)?.email || 'Learner' }}</td>
              <td class="px-4 py-4">{{ order.product_type === 'course' ? courses.find((item) => item.id === order.course_id)?.title || 'Course' : books.find((item) => item.id === order.book_id)?.title || 'Book' }}</td>
              <td class="px-4 py-4">{{ money(order.amount_minor, order.currency) }}</td>
              <td class="px-4 py-4">{{ money(order.platform_fee_minor, order.currency) }}</td>
              <td class="px-4 py-4"><span class="rounded-full px-2.5 py-1 text-xs font-bold capitalize" :class="order.status === 'paid' ? 'bg-emerald-50 text-emerald-800' : 'bg-secondary text-muted-foreground'">{{ order.status }}</span></td>
              <td class="px-4 py-4"><button type="button" :disabled="order.status !== 'paid'" class="inline-flex min-h-9 items-center gap-1.5 border border-primary px-3 text-xs font-bold text-primary hover:bg-secondary disabled:cursor-not-allowed disabled:opacity-40" @click="printReceipt(order)"><ReceiptText :size="14" />Print receipt</button></td>
            </tr>
            <tr v-if="!filteredPayments.length"><td colspan="7" class="px-4 py-12 text-center text-muted-foreground">{{ paymentOrders.length ? 'No payments match your search.' : 'No payment records yet. Paystack checkout must be configured before purchases appear here.' }}</td></tr>
          </tbody>
        </table>
      </div>
    </div>
  </section>
</template>
