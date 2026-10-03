<script setup>
import { computed, onMounted, ref } from "vue";
import { RouterLink } from "vue-router";
import { ArrowRight, GraduationCap, LoaderCircle } from "lucide-vue-next";
import { getAuthenticatedProfile } from "@/lib/auth";
import { supabase } from "@/lib/supabase";

const courses = ref([]);
const loading = ref(true);
const errorMessage = ref("");
const empty = computed(() => !loading.value && !errorMessage.value && courses.value.length === 0);

onMounted(async () => {
  const { user } = await getAuthenticatedProfile();
  if (!supabase || !user) {
    errorMessage.value = "Connect this app to Supabase to load your enrollments.";
    loading.value = false;
    return;
  }

  const { data, error } = await supabase
    .from("enrollments")
    .select("enrolled_at, courses(id, title, description, category, level, thumbnail_url, lessons(id))")
    .eq("user_id", user.id)
    .order("enrolled_at", { ascending: false });

  if (error) {
    errorMessage.value = error.message;
  } else {
    courses.value = (data ?? []).map((row) => ({
      ...row.courses,
      enrolledAt: row.enrolled_at,
      lessonCount: row.courses?.lessons?.length ?? 0,
    })).filter((course) => course.id);
  }
  loading.value = false;
});
</script>

<template>
  <section class="space-y-7">
    <header>
      <p class="mb-2 text-sm font-semibold text-primary">YOUR COURSES</p>
      <h1 class="text-3xl font-extrabold text-foreground sm:text-4xl">My learning</h1>
      <p class="mt-2 text-muted-foreground">Your enrolled courses, all in one place.</p>
    </header>

    <p v-if="errorMessage" role="alert" class="border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-800">{{ errorMessage }}</p>
    <div v-if="loading" class="flex items-center gap-2 py-14 text-sm text-muted-foreground"><LoaderCircle :size="18" class="animate-spin" /> Loading your courses...</div>
    <div v-else-if="empty" class="border border-dashed border-border bg-white px-6 py-16 text-center">
      <GraduationCap :size="30" class="mx-auto text-primary" aria-hidden="true" />
      <h2 class="mt-4 text-lg font-bold">Your learning list is ready</h2>
      <p class="mt-2 text-sm text-muted-foreground">Enroll in a course to see it here.</p>
      <RouterLink to="/courses" class="mt-5 inline-flex min-h-10 items-center gap-2 bg-primary px-4 text-sm font-bold text-white hover:bg-primary/90">Browse courses <ArrowRight :size="15" /></RouterLink>
    </div>
    <div v-else class="grid gap-5 md:grid-cols-2">
      <article v-for="course in courses" :key="course.id" class="flex min-h-52 flex-col justify-between border border-border bg-white p-5 sm:p-6">
        <div>
          <div class="flex items-center justify-between gap-3 text-xs font-semibold text-primary">
            <span>{{ course.category || 'Course' }}</span>
            <span class="text-muted-foreground">{{ course.lessonCount }} {{ course.lessonCount === 1 ? 'lesson' : 'lessons' }}</span>
          </div>
          <h2 class="mt-3 text-xl font-extrabold">{{ course.title }}</h2>
          <p class="mt-2 line-clamp-2 text-sm leading-6 text-muted-foreground">{{ course.description || 'Continue learning at your own pace.' }}</p>
        </div>
        <RouterLink :to="`/courses/${course.id}`" class="mt-5 inline-flex min-h-10 items-center justify-between border-t border-border pt-3 text-sm font-bold text-primary hover:underline">
          Continue course <ArrowRight :size="16" />
        </RouterLink>
      </article>
    </div>
  </section>
</template>
