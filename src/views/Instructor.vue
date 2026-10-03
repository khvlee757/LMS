<script setup>
import { onMounted, reactive, ref } from "vue";
import { LoaderCircle, Plus, Save, Trash2 } from "lucide-vue-next";
import { getAuthenticatedProfile } from "@/lib/auth";
import { supabase } from "@/lib/supabase";

const profile = ref(null);
const courses = ref([]);
const selectedCourse = ref(null);
const lessons = ref([]);
const loading = ref(true);
const saving = ref(false);
const errorMessage = ref("");
const notice = ref("");
const courseDraft = reactive({ title: "", description: "", category: "", level: "beginner", thumbnail_url: "" });
const lessonDraft = reactive({ title: "", content_body: "", content_url: "", duration_minutes: "" });

onMounted(async () => {
  const { user, profile: currentProfile, error } = await getAuthenticatedProfile();
  profile.value = currentProfile;
  if (!user || !currentProfile || !["instructor", "super_admin"].includes(currentProfile.role)) {
    errorMessage.value = error?.message || "Your account does not have instructor access.";
    loading.value = false;
    return;
  }
  await loadCourses(user.id, currentProfile.role === "super_admin");
});

async function loadCourses(userId, isAdmin = false) {
  if (!supabase) return;
  let query = supabase.from("courses").select("id, title, description, category, level, thumbnail_url, published, created_at").order("created_at", { ascending: false });
  if (!isAdmin) query = query.eq("instructor_id", userId);
  const { data, error } = await query;
  if (error) errorMessage.value = error.message;
  else courses.value = data ?? [];
  loading.value = false;
}

async function createCourse() {
  if (!supabase || !profile.value || saving.value || !courseDraft.title.trim()) return;
  saving.value = true;
  errorMessage.value = "";
  notice.value = "";
  const { data, error } = await supabase.from("courses").insert({
    instructor_id: profile.value.user_id,
    title: courseDraft.title.trim(),
    description: courseDraft.description.trim(),
    category: courseDraft.category.trim() || "General",
    level: courseDraft.level,
    thumbnail_url: courseDraft.thumbnail_url.trim() || null,
    published: false,
  }).select("id, title, description, category, level, thumbnail_url, published, created_at").single();
  if (error) errorMessage.value = error.message;
  else {
    courses.value = [data, ...courses.value];
    Object.assign(courseDraft, { title: "", description: "", category: "", level: "beginner", thumbnail_url: "" });
    notice.value = "Course created as a draft.";
    await selectCourse(data);
  }
  saving.value = false;
}

async function selectCourse(course) {
  selectedCourse.value = course;
  lessons.value = [];
  const { data, error } = await supabase.from("lessons")
    .select("id, title, content_body, content_url, position, duration_minutes")
    .eq("course_id", course.id)
    .order("position");
  if (error) errorMessage.value = error.message;
  else lessons.value = data ?? [];
}

async function saveCourse() {
  if (!supabase || !selectedCourse.value || saving.value) return;
  saving.value = true;
  const { error } = await supabase.from("courses").update({
    title: selectedCourse.value.title.trim(),
    description: selectedCourse.value.description.trim(),
    category: selectedCourse.value.category.trim() || "General",
    level: selectedCourse.value.level,
    thumbnail_url: selectedCourse.value.thumbnail_url?.trim() || null,
  }).eq("id", selectedCourse.value.id);
  if (error) errorMessage.value = error.message;
  else notice.value = "Course details saved.";
  saving.value = false;
}

async function togglePublished(course) {
  if (!supabase || saving.value) return;
  saving.value = true;
  const { error } = await supabase.from("courses").update({ published: !course.published }).eq("id", course.id);
  if (error) errorMessage.value = error.message;
  else {
    course.published = !course.published;
    if (selectedCourse.value?.id === course.id) selectedCourse.value.published = course.published;
    notice.value = course.published ? "Course published to the catalog." : "Course moved back to drafts.";
  }
  saving.value = false;
}

async function createLesson() {
  if (!supabase || !selectedCourse.value || saving.value || !lessonDraft.title.trim()) return;
  saving.value = true;
  const { data, error } = await supabase.from("lessons").insert({
    course_id: selectedCourse.value.id,
    title: lessonDraft.title.trim(),
    content_body: lessonDraft.content_body.trim(),
    content_url: lessonDraft.content_url.trim() || null,
    duration_minutes: lessonDraft.duration_minutes ? Number(lessonDraft.duration_minutes) : null,
    position: Math.max(-1, ...lessons.value.map((lesson) => lesson.position)) + 1,
  }).select("id, title, content_body, content_url, position, duration_minutes").single();
  if (error) errorMessage.value = error.message;
  else {
    lessons.value.push(data);
    Object.assign(lessonDraft, { title: "", content_body: "", content_url: "", duration_minutes: "" });
    notice.value = "Lesson added.";
  }
  saving.value = false;
}

async function saveLesson(lesson) {
  if (!supabase || saving.value) return;
  saving.value = true;
  const { error } = await supabase.from("lessons").update({
    title: lesson.title.trim(),
    content_body: lesson.content_body,
    content_url: lesson.content_url?.trim() || null,
    duration_minutes: lesson.duration_minutes || null,
  }).eq("id", lesson.id);
  if (error) errorMessage.value = error.message;
  else notice.value = "Lesson saved.";
  saving.value = false;
}

async function moveLesson(index, direction) {
  if (!supabase || saving.value) return;
  const nextIndex = index + direction;
  if (nextIndex < 0 || nextIndex >= lessons.value.length) return;
  saving.value = true;
  const first = lessons.value[index];
  const second = lessons.value[nextIndex];
  const firstPosition = first.position;
  const secondPosition = second.position;
  const temporaryPosition = Math.max(...lessons.value.map((lesson) => lesson.position)) + 1;
  const temporaryResult = await supabase.from("lessons").update({ position: temporaryPosition }).eq("id", first.id);
  if (temporaryResult.error) {
    errorMessage.value = temporaryResult.error.message;
  } else {
    const secondResult = await supabase.from("lessons").update({ position: firstPosition }).eq("id", second.id);
    if (secondResult.error) {
      await supabase.from("lessons").update({ position: firstPosition }).eq("id", first.id);
      errorMessage.value = secondResult.error.message;
    } else {
      const firstResult = await supabase.from("lessons").update({ position: secondPosition }).eq("id", first.id);
      if (firstResult.error) {
        await supabase.from("lessons").update({ position: secondPosition }).eq("id", second.id);
        await supabase.from("lessons").update({ position: firstPosition }).eq("id", first.id);
        errorMessage.value = firstResult.error.message;
      } else {
        first.position = secondPosition;
        second.position = firstPosition;
        lessons.value.sort((left, right) => left.position - right.position);
        notice.value = "Lesson order updated.";
      }
    }
  }
  saving.value = false;
}

async function deleteLesson(lesson) {
  if (!supabase || saving.value) return;
  saving.value = true;
  const { error } = await supabase.from("lessons").delete().eq("id", lesson.id);
  if (error) errorMessage.value = error.message;
  else {
    lessons.value = lessons.value.filter((item) => item.id !== lesson.id);
    notice.value = "Lesson deleted.";
  }
  saving.value = false;
}
</script>

<template>
  <section class="space-y-7">
    <header>
      <p class="mb-2 text-sm font-semibold text-primary">INSTRUCTOR WORKSPACE</p>
      <h1 class="text-3xl font-extrabold text-foreground sm:text-4xl">Teach your courses</h1>
      <p class="mt-2 text-muted-foreground">Build course content, arrange lessons, and publish when you're ready.</p>
    </header>

    <p v-if="errorMessage" role="alert" class="border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-800">{{ errorMessage }}</p>
    <p v-if="notice" role="status" class="border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-800">{{ notice }}</p>

    <div class="grid gap-6 xl:grid-cols-[0.8fr_1.2fr]">
      <section class="h-fit border border-border bg-white p-5 sm:p-6">
        <h2 class="text-lg font-extrabold">Create a course</h2>
        <form class="mt-4 space-y-4" @submit.prevent="createCourse">
          <label class="block space-y-1.5 text-sm font-semibold">Course title
            <input v-model="courseDraft.title" required maxlength="160" class="h-11 w-full border border-border px-3 font-normal outline-none focus:border-primary focus:ring-2 focus:ring-primary/20" placeholder="Course title" />
          </label>
          <label class="block space-y-1.5 text-sm font-semibold">Description
            <textarea v-model="courseDraft.description" rows="3" maxlength="2000" class="w-full resize-y border border-border px-3 py-2 font-normal outline-none focus:border-primary focus:ring-2 focus:ring-primary/20" placeholder="What will learners learn?" />
          </label>
          <div class="grid grid-cols-2 gap-3">
            <label class="block space-y-1.5 text-sm font-semibold">Category
              <input v-model="courseDraft.category" maxlength="80" class="h-11 w-full border border-border px-3 font-normal outline-none focus:border-primary focus:ring-2 focus:ring-primary/20" placeholder="General" />
            </label>
            <label class="block space-y-1.5 text-sm font-semibold">Level
              <select v-model="courseDraft.level" class="h-11 w-full border border-border bg-white px-3 font-normal outline-none focus:border-primary focus:ring-2 focus:ring-primary/20"><option value="beginner">Beginner</option><option value="intermediate">Intermediate</option><option value="advanced">Advanced</option></select>
            </label>
          </div>
          <label class="block space-y-1.5 text-sm font-semibold">Cover image URL
            <input v-model="courseDraft.thumbnail_url" type="url" class="h-11 w-full border border-border px-3 font-normal outline-none focus:border-primary focus:ring-2 focus:ring-primary/20" placeholder="https://..." />
          </label>
          <button type="submit" :disabled="saving || !courseDraft.title.trim()" class="inline-flex min-h-11 w-full items-center justify-center gap-2 bg-primary px-4 text-sm font-bold text-white outline-none hover:bg-primary/90 focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2 disabled:opacity-60"><LoaderCircle v-if="saving" :size="16" class="animate-spin" /><Plus v-else :size="16" />Create course draft</button>
        </form>
      </section>

      <section class="space-y-4">
        <div class="flex items-center justify-between"><h2 class="text-lg font-extrabold">Your courses</h2><span class="text-xs text-muted-foreground">{{ courses.length }} total</span></div>
        <div v-if="loading" class="flex items-center gap-2 border border-border bg-white p-6 text-sm text-muted-foreground"><LoaderCircle :size="18" class="animate-spin" /> Loading courses...</div>
        <div v-else-if="!courses.length" class="border border-dashed border-border bg-white px-5 py-10 text-center text-sm text-muted-foreground">Create your first course to get started.</div>
        <div v-else class="divide-y divide-border border border-border bg-white">
          <article v-for="course in courses" :key="course.id" class="p-4 sm:p-5">
            <div class="flex flex-wrap items-start justify-between gap-3">
              <button type="button" class="text-left outline-none focus-visible:ring-2 focus-visible:ring-primary" @click="selectCourse(course)"><span class="block font-bold">{{ course.title }}</span><span class="mt-1 block text-xs text-muted-foreground">{{ course.category }} · <span class="capitalize">{{ course.level }}</span></span></button>
              <div class="flex items-center gap-2"><span class="rounded-full px-2.5 py-1 text-xs font-bold" :class="course.published ? 'bg-emerald-50 text-emerald-800' : 'bg-secondary text-muted-foreground'">{{ course.published ? 'Published' : 'Draft' }}</span><button type="button" class="min-h-9 border border-primary px-3 text-xs font-bold text-primary hover:bg-secondary" @click="togglePublished(course)">{{ course.published ? 'Unpublish' : 'Publish' }}</button></div>
            </div>
          </article>
        </div>
      </section>
    </div>

    <section v-if="selectedCourse" class="space-y-5 border border-border bg-white p-5 sm:p-6">
      <div class="flex flex-wrap items-center justify-between gap-3"><div><p class="text-xs font-bold uppercase tracking-wide text-primary">COURSE EDITOR</p><h2 class="mt-1 text-xl font-extrabold">{{ selectedCourse.title }}</h2></div><button type="button" class="text-sm font-semibold text-muted-foreground underline underline-offset-4 hover:text-foreground" @click="selectedCourse = null">Close editor</button></div>
      <div class="grid gap-3 md:grid-cols-2">
        <label class="space-y-1 text-xs font-bold">Title<input v-model="selectedCourse.title" maxlength="160" class="h-10 w-full border border-border px-3 text-sm font-normal outline-none focus:border-primary focus:ring-2 focus:ring-primary/20" /></label>
        <label class="space-y-1 text-xs font-bold">Category<input v-model="selectedCourse.category" maxlength="80" class="h-10 w-full border border-border px-3 text-sm font-normal outline-none focus:border-primary focus:ring-2 focus:ring-primary/20" /></label>
        <label class="space-y-1 text-xs font-bold">Description<textarea v-model="selectedCourse.description" rows="3" class="w-full border border-border px-3 py-2 text-sm font-normal outline-none focus:border-primary focus:ring-2 focus:ring-primary/20" /></label>
        <div class="space-y-3"><label class="block space-y-1 text-xs font-bold">Cover image URL<input v-model="selectedCourse.thumbnail_url" type="url" class="h-10 w-full border border-border px-3 text-sm font-normal outline-none focus:border-primary focus:ring-2 focus:ring-primary/20" /></label><button type="button" :disabled="saving" class="inline-flex min-h-9 items-center gap-2 border border-primary px-3 text-xs font-bold text-primary hover:bg-secondary disabled:opacity-60" @click="saveCourse"><Save :size="14" />Save course details</button></div>
      </div>

      <div class="border-t border-border pt-5"><h3 class="text-base font-extrabold">Lessons <span class="ml-1 text-xs font-medium text-muted-foreground">{{ lessons.length }}</span></h3>
        <form class="mt-4 grid gap-3 lg:grid-cols-[1fr_1.4fr_1fr_0.7fr_auto]" @submit.prevent="createLesson">
          <input v-model="lessonDraft.title" required maxlength="160" aria-label="Lesson title" class="h-10 border border-border px-3 text-sm outline-none focus:border-primary focus:ring-2 focus:ring-primary/20" placeholder="Lesson title" />
          <input v-model="lessonDraft.content_body" aria-label="Lesson text" class="h-10 border border-border px-3 text-sm outline-none focus:border-primary focus:ring-2 focus:ring-primary/20" placeholder="Text or instructions" />
          <input v-model="lessonDraft.content_url" type="url" aria-label="Lesson resource URL" class="h-10 border border-border px-3 text-sm outline-none focus:border-primary focus:ring-2 focus:ring-primary/20" placeholder="Resource URL (optional)" />
          <input v-model="lessonDraft.duration_minutes" type="number" min="0" max="1440" step="1" aria-label="Lesson duration in minutes" class="h-10 border border-border px-3 text-sm outline-none focus:border-primary focus:ring-2 focus:ring-primary/20" placeholder="Minutes" />
          <button type="submit" :disabled="saving || !lessonDraft.title.trim()" class="inline-flex min-h-10 items-center justify-center gap-2 bg-primary px-3 text-sm font-bold text-white hover:bg-primary/90 disabled:opacity-60"><Plus :size="16" />Add lesson</button>
        </form>
      </div>
      <ol class="divide-y divide-border border-y border-border">
        <li v-for="(lesson, index) in lessons" :key="lesson.id" class="grid gap-3 py-4 lg:grid-cols-[2.5rem_1fr_1.5fr_1fr_auto] lg:items-center">
          <span class="grid size-8 place-items-center rounded-full bg-secondary text-xs font-bold text-primary">{{ index + 1 }}</span>
          <input v-model="lesson.title" :aria-label="`Lesson ${index + 1} title`" class="h-10 border border-border px-3 text-sm font-semibold outline-none focus:border-primary focus:ring-2 focus:ring-primary/20" />
          <input v-model="lesson.content_body" :aria-label="`Lesson ${index + 1} text`" class="h-10 border border-border px-3 text-sm outline-none focus:border-primary focus:ring-2 focus:ring-primary/20" placeholder="Lesson text" />
          <input v-model="lesson.content_url" type="url" :aria-label="`Lesson ${index + 1} resource URL`" class="h-10 border border-border px-3 text-sm outline-none focus:border-primary focus:ring-2 focus:ring-primary/20" placeholder="Resource URL" />
          <div class="flex items-center gap-1"><button type="button" :disabled="index === 0 || saving" class="grid size-9 place-items-center border border-border text-sm font-bold hover:bg-secondary disabled:opacity-40" :aria-label="`Move ${lesson.title} up`" @click="moveLesson(index, -1)">↑</button><button type="button" :disabled="index === lessons.length - 1 || saving" class="grid size-9 place-items-center border border-border text-sm font-bold hover:bg-secondary disabled:opacity-40" :aria-label="`Move ${lesson.title} down`" @click="moveLesson(index, 1)">↓</button><button type="button" class="grid size-9 place-items-center text-red-700 outline-none hover:bg-red-50 focus-visible:ring-2 focus-visible:ring-red-700" :aria-label="`Delete ${lesson.title}`" @click="deleteLesson(lesson)"><Trash2 :size="16" /></button><button type="button" class="grid size-9 place-items-center border border-primary text-primary outline-none hover:bg-secondary focus-visible:ring-2 focus-visible:ring-primary" :aria-label="`Save ${lesson.title}`" @click="saveLesson(lesson)"><Save :size="15" /></button></div>
        </li>
        <li v-if="!lessons.length" class="py-5 text-sm text-muted-foreground">No lessons in this course yet.</li>
      </ol>
    </section>
  </section>
</template>
