<script setup>
import { computed, onMounted, ref } from "vue";
import { RouterLink, useRoute } from "vue-router";
import { ArrowLeft, Check, CirclePlay, LoaderCircle } from "lucide-vue-next";
import { getAuthenticatedProfile } from "@/lib/auth";
import { supabase } from "@/lib/supabase";
import CourseAssessments from "@/components/courses/CourseAssessments.vue";
import PrivateFileField from "@/components/courses/PrivateFileField.vue";

const route = useRoute();
const course = ref(null);
const lessons = ref([]);
const completedIds = ref(new Set());
const expandedLesson = ref(null);
const loading = ref(true);
const busy = ref(false);
const enrolled = ref(false);
const errorMessage = ref("");
const notice = ref("");
const completionPercent = computed(() => lessons.value.length
  ? Math.round((completedIds.value.size / lessons.value.length) * 100)
  : 0
);
const coursePrice = computed(() => {
  if (!course.value || course.value.is_free) return "Free";
  const currency = course.value.currency || "NGN";
  const digits = new Intl.NumberFormat(undefined, { style: "currency", currency }).resolvedOptions().maximumFractionDigits;
  return new Intl.NumberFormat(undefined, { style: "currency", currency }).format(course.value.price_minor / (10 ** digits));
});

onMounted(loadCourse);

async function loadCourse() {
  const { user } = await getAuthenticatedProfile();
  if (!supabase || !user) {
    errorMessage.value = "Connect this app to Supabase to open course content.";
    loading.value = false;
    return;
  }
  const [courseResult, lessonsResult, enrollmentResult, progressResult] = await Promise.all([
    supabase.from("courses").select("id, title, description, category, level, thumbnail_url, instructor_id, is_free, price_minor, currency").eq("id", route.params.id).single(),
    supabase.from("lessons").select("id, title, content_body, content_url, content_path, position, duration_minutes").eq("course_id", route.params.id).order("position"),
    supabase.from("enrollments").select("course_id").eq("course_id", route.params.id).eq("user_id", user.id).maybeSingle(),
    supabase.from("lesson_progress").select("lesson_id").eq("course_id", route.params.id).eq("user_id", user.id).eq("completed", true),
  ]);
  const failure = courseResult.error || lessonsResult.error || enrollmentResult.error || progressResult.error;
  if (failure) errorMessage.value = failure.message;
  course.value = courseResult.data;
  lessons.value = lessonsResult.data ?? [];
  enrolled.value = Boolean(enrollmentResult.data);
  completedIds.value = new Set((progressResult.data ?? []).map((row) => row.lesson_id));
  loading.value = false;
}

async function enroll() {
  if (!supabase || busy.value) return;
  busy.value = true;
  const { data: userData, error: userError } = await supabase.auth.getUser();
  if (userError || !userData.user) {
    errorMessage.value = userError?.message || "Please sign in again.";
  } else {
    if (!course.value.is_free) {
      const { data, error } = await supabase.functions.invoke("paystack-checkout", {
        body: { productType: "course", productId: course.value.id },
      });
      if (error) errorMessage.value = error.message;
      else if (data?.authorizationUrl) {
        window.location.assign(data.authorizationUrl);
        return;
      } else errorMessage.value = data?.error || "Paystack checkout could not be started.";
      busy.value = false;
      return;
    }
    const { error } = await supabase.from("enrollments").insert({ user_id: userData.user.id, course_id: course.value.id });
    if (error && error.code !== "23505") errorMessage.value = error.message;
    else {
      enrolled.value = true;
      notice.value = "You are enrolled. Your lessons are ready.";
      const { data: courseLessons, error: lessonError } = await supabase
        .from("lessons")
        .select("id, title, content_body, content_url, content_path, position, duration_minutes")
        .eq("course_id", course.value.id)
        .order("position");
      if (lessonError) errorMessage.value = lessonError.message;
      else lessons.value = courseLessons ?? [];
    }
  }
  busy.value = false;
}

async function toggleComplete(lesson) {
  if (!supabase || busy.value) return;
  busy.value = true;
  const { data: userData, error: userError } = await supabase.auth.getUser();
  if (userError || !userData.user) {
    errorMessage.value = userError?.message || "Please sign in again.";
    busy.value = false;
    return;
  }
  const isComplete = completedIds.value.has(lesson.id);
  const { error } = await supabase.from("lesson_progress").upsert({
    user_id: userData.user.id,
    course_id: course.value.id,
    lesson_id: lesson.id,
    completed: !isComplete,
  }, { onConflict: "user_id,lesson_id" });
  if (error) errorMessage.value = error.message;
  else {
    const next = new Set(completedIds.value);
    if (isComplete) next.delete(lesson.id);
    else next.add(lesson.id);
    completedIds.value = next;
  }
  busy.value = false;
}
</script>

<template>
  <section v-if="loading" class="flex items-center gap-2 py-16 text-sm text-muted-foreground"><LoaderCircle :size="18" class="animate-spin" /> Loading course...</section>
  <section v-else-if="course" class="mx-auto max-w-4xl space-y-7">
    <RouterLink to="/courses" class="inline-flex items-center gap-2 text-sm font-bold text-primary hover:underline"><ArrowLeft :size="16" /> Course catalog</RouterLink>
    <header class="overflow-hidden border border-border bg-white">
      <img v-if="course.thumbnail_url" :src="course.thumbnail_url" :alt="`${course.title} course`" class="h-56 w-full object-cover sm:h-72" />
      <div class="p-6 sm:p-8">
        <div class="flex flex-wrap items-center gap-2 text-xs font-bold text-primary"><span>{{ course.category || 'Course' }}</span><span v-if="course.level" class="rounded-full bg-secondary px-2.5 py-1 capitalize text-foreground">{{ course.level }}</span><span class="rounded-full bg-accent px-2.5 py-1 text-accent-foreground">{{ coursePrice }}</span></div>
        <h1 class="mt-3 text-3xl font-extrabold sm:text-4xl">{{ course.title }}</h1>
        <p class="mt-3 max-w-3xl text-sm leading-7 text-muted-foreground">{{ course.description || 'Course details coming soon.' }}</p>
        <button v-if="!enrolled" type="button" :disabled="busy" class="mt-6 inline-flex min-h-11 items-center gap-2 bg-primary px-5 text-sm font-bold text-white hover:bg-primary/90 disabled:opacity-60" @click="enroll"><LoaderCircle v-if="busy" :size="16" class="animate-spin" />{{ course.is_free ? 'Enroll free' : 'Continue to secure payment' }}</button>
        <div v-else class="mt-6 max-w-sm">
          <div class="flex items-center justify-between text-xs font-semibold"><span>Course progress</span><span>{{ completionPercent }}%</span></div>
          <div class="mt-2 h-2 overflow-hidden bg-secondary" role="progressbar" :aria-valuenow="completionPercent" aria-valuemin="0" aria-valuemax="100" :aria-label="`Course progress ${completionPercent}%`"><div class="h-full bg-primary transition-[width]" :style="{ width: `${completionPercent}%` }" /></div>
        </div>
      </div>
    </header>

    <p v-if="errorMessage" role="alert" class="border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-800">{{ errorMessage }}</p>
    <p v-if="notice" role="status" class="border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-800">{{ notice }}</p>

    <div class="flex items-center justify-between border-b border-border pb-3">
      <h2 class="text-xl font-extrabold">Course content</h2>
      <span class="text-sm text-muted-foreground">{{ lessons.length }} lessons</span>
    </div>
    <div v-if="!lessons.length" class="border border-dashed border-border bg-white px-5 py-10 text-center text-sm text-muted-foreground">{{ enrolled ? 'The instructor has not added lessons yet.' : 'Enroll in this course to access its lessons.' }}</div>
    <div v-else class="divide-y divide-border border border-border bg-white">
      <article v-for="(lesson, index) in lessons" :key="lesson.id" class="p-4 sm:p-5">
        <div class="flex items-center gap-3">
          <span class="grid size-9 shrink-0 place-items-center rounded-full" :class="completedIds.has(lesson.id) ? 'bg-primary text-white' : 'bg-secondary text-primary'">
            <Check v-if="completedIds.has(lesson.id)" :size="17" aria-label="Completed" /><span v-else class="text-xs font-bold">{{ index + 1 }}</span>
          </span>
          <button type="button" class="min-w-0 flex-1 text-left outline-none focus-visible:ring-2 focus-visible:ring-primary" :aria-expanded="expandedLesson === lesson.id" @click="expandedLesson = expandedLesson === lesson.id ? null : lesson.id">
            <span class="block font-bold">{{ lesson.title }}</span>
            <span class="mt-1 block text-xs text-muted-foreground">{{ lesson.duration_minutes ? `${lesson.duration_minutes} min` : 'Lesson' }}</span>
          </button>
          <CirclePlay :size="18" class="shrink-0 text-muted-foreground" aria-hidden="true" />
        </div>
        <div v-if="expandedLesson === lesson.id" class="ml-12 mt-4 space-y-4">
          <p v-if="lesson.content_body" class="whitespace-pre-line text-sm leading-7 text-foreground/85">{{ lesson.content_body }}</p>
          <a v-if="lesson.content_url" :href="lesson.content_url" target="_blank" rel="noopener noreferrer" class="inline-flex text-sm font-bold text-primary underline underline-offset-4">Open lesson resource</a>
          <PrivateFileField v-if="enrolled && lesson.content_path" :model-value="lesson.content_path" :course-id="course.id" kind="material" label="Course material" read-only />
          <button v-if="enrolled" type="button" class="inline-flex min-h-9 items-center gap-2 border border-primary px-3 text-xs font-bold text-primary hover:bg-secondary disabled:opacity-60" :disabled="busy" @click="toggleComplete(lesson)"><Check :size="14" />{{ completedIds.has(lesson.id) ? 'Mark incomplete' : 'Mark complete' }}</button>
          <p v-else class="text-xs text-muted-foreground">Enroll to track lesson completion.</p>
        </div>
      </article>
    </div>
    <p v-if="!enrolled" class="border border-dashed border-border bg-white px-5 py-4 text-sm text-muted-foreground">Enroll in this course to access its quizzes and assignments.</p>
    <CourseAssessments v-else :course-id="course.id" :enrolled="enrolled" />
  </section>
  <section v-else class="border border-border bg-white px-6 py-12 text-center">
    <h1 class="text-xl font-bold">Course unavailable</h1>
    <p class="mt-2 text-sm text-muted-foreground">This course may have been removed or is not published.</p>
    <RouterLink to="/courses" class="mt-4 inline-flex text-sm font-bold text-primary hover:underline">Return to catalog</RouterLink>
  </section>
</template>
