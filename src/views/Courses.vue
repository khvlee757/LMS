<script setup>
import { computed, onMounted, ref } from "vue";
import { RouterLink } from "vue-router";
import { ArrowRight, BookOpen, LoaderCircle, Search } from "lucide-vue-next";
import { getAuthenticatedProfile } from "@/lib/auth";
import { supabase } from "@/lib/supabase";
import CourseCard from "@/components/courses/CourseCard.vue";

const courses = ref([]);
const enrolledIds = ref(new Set());
const searchTerm = ref("");
const loading = ref(true);
const enrollingId = ref("");
const message = ref("");
const messageIsError = ref(false);
const images = [
  "https://images.unsplash.com/photo-1498050108023-c5249f4df085?auto=format&fit=crop&w=900&q=80",
  "https://images.unsplash.com/photo-1522202176988-66273c2fd55f?auto=format&fit=crop&w=900&q=80",
  "https://images.unsplash.com/photo-1552664730-d307ca884978?auto=format&fit=crop&w=900&q=80",
  "https://images.unsplash.com/photo-1516321318423-f06f85e504b3?auto=format&fit=crop&w=900&q=80",
];

const visibleCourses = computed(() => courses.value.filter((course) => {
  const search = searchTerm.value.trim().toLowerCase();
  return !search || `${course.title} ${course.description ?? ""} ${course.category ?? ""}`.toLowerCase().includes(search);
}));

onMounted(async () => {
  const { user } = await getAuthenticatedProfile();
  if (!supabase || !user) {
    message.value = "Connect this app to Supabase to load the course catalog.";
    messageIsError.value = true;
    loading.value = false;
    return;
  }

  const [courseResult, enrollmentResult] = await Promise.all([
    supabase.from("courses").select("id, title, description, category, level, thumbnail_url, instructor_id").eq("published", true).order("created_at", { ascending: false }),
    supabase.from("enrollments").select("course_id").eq("user_id", user.id),
  ]);

  const failure = courseResult.error || enrollmentResult.error;
  if (failure) {
    message.value = failure.message;
    messageIsError.value = true;
  } else {
    courses.value = courseResult.data ?? [];
    enrolledIds.value = new Set((enrollmentResult.data ?? []).map((item) => item.course_id));
  }
  loading.value = false;
});

async function enroll(course) {
  if (!supabase || enrollingId.value) return;
  enrollingId.value = course.id;
  message.value = "";
  const { data: userData, error: userError } = await supabase.auth.getUser();
  if (userError || !userData.user) {
    message.value = userError?.message || "Please sign in again.";
    messageIsError.value = true;
    enrollingId.value = "";
    return;
  }
  const { error } = await supabase.from("enrollments").insert({ user_id: userData.user.id, course_id: course.id });
  if (error && error.code !== "23505") {
    message.value = error.message;
    messageIsError.value = true;
  } else {
    enrolledIds.value = new Set([...enrolledIds.value, course.id]);
    message.value = error ? "You are already enrolled in this course." : `Enrolled in ${course.title}.`;
    messageIsError.value = false;
  }
  enrollingId.value = "";
}
</script>

<template>
  <section class="space-y-7">
    <header class="flex flex-wrap items-end justify-between gap-5">
      <div>
        <p class="mb-2 text-sm font-semibold text-primary">GROW YOUR SKILLS</p>
        <h1 class="text-3xl font-extrabold text-foreground sm:text-4xl">Course catalog</h1>
        <p class="mt-2 text-muted-foreground">Find a course and learn at your own pace.</p>
      </div>
      <label class="relative block w-full sm:max-w-xs">
        <span class="sr-only">Search courses</span>
        <Search :size="17" class="absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground" aria-hidden="true" />
        <input v-model="searchTerm" type="search" placeholder="Search courses" class="h-11 w-full border border-border bg-white pl-10 pr-3 text-sm outline-none focus:border-primary focus:ring-2 focus:ring-primary/20" />
      </label>
    </header>

    <p v-if="message" role="status" class="border px-4 py-3 text-sm" :class="messageIsError ? 'border-red-200 bg-red-50 text-red-800' : 'border-emerald-200 bg-emerald-50 text-emerald-800'">{{ message }}</p>

    <div v-if="loading" class="flex items-center gap-2 py-14 text-sm text-muted-foreground"><LoaderCircle :size="18" class="animate-spin" /> Loading courses...</div>
    <div v-else-if="!visibleCourses.length" class="border border-dashed border-border bg-white px-6 py-16 text-center">
      <BookOpen :size="28" class="mx-auto text-primary" aria-hidden="true" />
      <h2 class="mt-4 text-lg font-bold">{{ searchTerm ? 'No courses match your search' : 'No published courses yet' }}</h2>
      <p class="mt-2 text-sm text-muted-foreground">{{ searchTerm ? 'Try another title or topic.' : 'New courses will show up here when they are published.' }}</p>
    </div>
    <div v-else class="grid gap-5 sm:grid-cols-2 xl:grid-cols-3">
      <CourseCard v-for="(course, index) in visibleCourses" :key="course.id" :course="course" :image="images[index % images.length]" :index="index">
        <template #action>
          <button v-if="!enrolledIds.has(course.id)" type="button" class="inline-flex min-h-10 w-full items-center justify-center gap-2 bg-primary px-4 text-sm font-bold text-white outline-none hover:bg-primary/90 focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2 disabled:opacity-60" :disabled="enrollingId === course.id" @click="enroll(course)">
            <LoaderCircle v-if="enrollingId === course.id" :size="16" class="animate-spin" />
            {{ enrollingId === course.id ? 'Enrolling...' : 'Enroll now' }}
          </button>
          <RouterLink v-else to="/learning" class="inline-flex min-h-10 w-full items-center justify-center gap-2 border border-primary px-4 text-sm font-bold text-primary hover:bg-secondary">Go to my learning <ArrowRight :size="15" /></RouterLink>
        </template>
      </CourseCard>
    </div>
  </section>
</template>
