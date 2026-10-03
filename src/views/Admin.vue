<script setup>
import { onMounted, reactive, ref } from "vue";
import { Check, LoaderCircle, Plus, ShieldCheck } from "lucide-vue-next";
import { getAuthenticatedProfile } from "@/lib/auth";
import { supabase } from "@/lib/supabase";

const currentProfile = ref(null);
const courses = ref([]);
const people = ref([]);
const applications = ref([]);
const loginActivity = ref([]);
const reviewingUser = ref("");
const loading = ref(true);
const saving = ref(false);
const errorMessage = ref("");
const notice = ref("");
const activeTab = ref("courses");
const draft = reactive({ title: "", description: "", category: "", level: "beginner" });

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
  const [courseResult, peopleResult, applicationResult, activityResult] = await Promise.all([
    supabase.from("courses").select("id, title, category, level, published, created_at").order("created_at", { ascending: false }),
    supabase.from("profiles").select("user_id, email, full_name, role, created_at").order("created_at", { ascending: false }),
    supabase.from("instructor_applications").select("user_id, organization, professional_title, expertise, experience_years, qualification, verification_url, teaching_statement, status, review_notes, created_at, reviewed_at").order("created_at", { ascending: false }),
    supabase.from("login_activity").select("user_id, activity_date").order("activity_date", { ascending: false }).limit(10000),
  ]);
  if (courseResult.error || peopleResult.error || applicationResult.error || activityResult.error) {
    errorMessage.value = courseResult.error?.message || peopleResult.error?.message || applicationResult.error?.message || activityResult.error?.message || "Unable to load admin data.";
  } else {
    courses.value = courseResult.data ?? [];
    people.value = peopleResult.data ?? [];
    loginActivity.value = activityResult.data ?? [];
    applications.value = (applicationResult.data ?? []).map((application) => ({
      ...application,
      profile: people.value.find((person) => person.user_id === application.user_id),
    }));
  }
  loading.value = false;
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
    instructor_id: currentProfile.value.user_id,
    published: false,
  });
  if (error) {
    errorMessage.value = error.message;
  } else {
    Object.assign(draft, { title: "", description: "", category: "", level: "beginner" });
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
        <label class="space-y-1.5 text-sm font-semibold md:row-span-2">Description
          <textarea v-model="draft.description" rows="3" maxlength="2000" class="w-full resize-y border border-border px-3 py-2 font-normal outline-none focus:border-primary focus:ring-2 focus:ring-primary/20" placeholder="What will students learn?" />
        </label>
        <button type="submit" :disabled="saving || !draft.title.trim()" class="inline-flex min-h-11 items-center justify-center gap-2 bg-primary px-4 text-sm font-bold text-white outline-none hover:bg-primary/90 focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2 disabled:opacity-60">
          <LoaderCircle v-if="saving" :size="16" class="animate-spin" /><Plus v-else :size="16" /> {{ saving ? 'Creating...' : 'Create draft' }}
        </button>
      </form>
    </section>

    <div class="flex border-b border-border" role="tablist" aria-label="Administration sections">
      <button v-for="tab in [{ id: 'courses', label: 'Courses' }, { id: 'people', label: 'People' }, { id: 'applications', label: 'Instructor applications' }]" :key="tab.id" type="button" role="tab" :aria-selected="activeTab === tab.id" class="min-h-11 border-b-2 px-4 text-sm font-bold outline-none focus-visible:ring-2 focus-visible:ring-primary" :class="activeTab === tab.id ? 'border-primary text-primary' : 'border-transparent text-muted-foreground hover:text-foreground'" @click="activeTab = tab.id">{{ tab.label }} <span class="ml-1 text-xs">{{ tab.id === 'courses' ? courses.length : tab.id === 'people' ? people.length : applications.filter((application) => application.status === 'pending').length }}</span></button>
    </div>

    <div v-if="loading" class="flex items-center gap-2 py-12 text-sm text-muted-foreground"><LoaderCircle :size="18" class="animate-spin" /> Loading administration data...</div>
    <div v-else-if="activeTab === 'courses'" class="overflow-x-auto border border-border bg-white">
      <table class="w-full min-w-[600px] text-left text-sm">
        <thead class="border-b border-border bg-secondary/70 text-xs uppercase text-muted-foreground"><tr><th class="px-4 py-3 font-bold">Course</th><th class="px-4 py-3 font-bold">Level</th><th class="px-4 py-3 font-bold">Status</th><th class="px-4 py-3 font-bold">Action</th></tr></thead>
        <tbody>
          <tr v-for="course in courses" :key="course.id" class="border-b border-border last:border-0">
            <td class="px-4 py-4"><span class="block font-bold">{{ course.title }}</span><span class="text-xs text-muted-foreground">{{ course.category || 'General' }}</span></td>
            <td class="px-4 py-4 capitalize text-muted-foreground">{{ course.level }}</td>
            <td class="px-4 py-4"><span class="rounded-full px-2.5 py-1 text-xs font-bold" :class="course.published ? 'bg-emerald-50 text-emerald-800' : 'bg-secondary text-muted-foreground'">{{ course.published ? 'Published' : 'Draft' }}</span></td>
            <td class="px-4 py-4"><button type="button" class="inline-flex min-h-9 items-center gap-1.5 border border-border px-3 text-xs font-bold hover:border-primary hover:text-primary" @click="togglePublished(course)"><Check :size="14" /> {{ course.published ? 'Unpublish' : 'Publish' }}</button></td>
          </tr>
          <tr v-if="!courses.length"><td colspan="4" class="px-4 py-12 text-center text-muted-foreground">No courses yet. Create a draft above.</td></tr>
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
    <div v-else class="space-y-4">
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
  </section>
</template>
