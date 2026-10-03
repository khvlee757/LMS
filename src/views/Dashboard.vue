<script setup>
import { computed, onMounted, ref } from "vue";
import { RouterLink } from "vue-router";
import { ArrowRight, BookOpen, CheckCircle2, Flame, GraduationCap, Sparkles } from "lucide-vue-next";
import { getAuthenticatedProfile } from "@/lib/auth";
import { supabase } from "@/lib/supabase";
import StatCard from "@/components/dashboard/StatCard.vue";

const profile = ref(null);
const loading = ref(true);
const errorMessage = ref("");
const stats = ref({ available: 0, enrolled: 0, completed: 0, streak: 0 });
const activityDates = ref([]);
const recentDays = computed(() => {
  const dates = new Set(activityDates.value);
  const today = new Date().toISOString().slice(0, 10);
  return Array.from({ length: 7 }, (_, index) => {
    const date = new Date(`${today}T00:00:00.000Z`);
    date.setUTCDate(date.getUTCDate() - (6 - index));
    const value = date.toISOString().slice(0, 10);
    return {
      value,
      label: date.toLocaleDateString(undefined, { weekday: "short", timeZone: "UTC" }),
      active: dates.has(value),
    };
  });
});
const greetingName = computed(
  () => profile.value?.full_name?.split(/\s+/)[0] || "there"
);

function previousDate(value) {
  const date = new Date(`${value}T00:00:00.000Z`);
  date.setUTCDate(date.getUTCDate() - 1);
  return date.toISOString().slice(0, 10);
}

function calculateStreak(dates) {
  const activeDates = new Set(dates);
  const today = new Date().toISOString().slice(0, 10);
  let cursor = activeDates.has(today) ? today : previousDate(today);
  if (!activeDates.has(cursor)) return 0;

  let streak = 0;
  while (activeDates.has(cursor)) {
    streak += 1;
    cursor = previousDate(cursor);
  }
  return streak;
}

onMounted(async () => {
  const { user, profile: currentProfile } = await getAuthenticatedProfile();
  profile.value = currentProfile;
  if (!supabase || !user) {
    loading.value = false;
    errorMessage.value = "Connect this app to Supabase to load your learning data.";
    return;
  }

  const [coursesResult, enrollmentResult, completedResult, activityResult] = await Promise.all([
    supabase.from("courses").select("id", { count: "exact", head: true }).eq("published", true),
    supabase.from("enrollments").select("course_id", { count: "exact", head: true }).eq("user_id", user.id),
    supabase.from("lesson_progress").select("id", { count: "exact", head: true }).eq("user_id", user.id).eq("completed", true),
    supabase.from("login_activity").select("activity_date").eq("user_id", user.id).order("activity_date", { ascending: false }).limit(400),
  ]);
  const failure = coursesResult.error || enrollmentResult.error || completedResult.error || activityResult.error;
  if (failure) errorMessage.value = failure.message;
  activityDates.value = (activityResult.data ?? []).map((row) => row.activity_date);
  stats.value = {
    available: coursesResult.count ?? 0,
    enrolled: enrollmentResult.count ?? 0,
    completed: completedResult.count ?? 0,
    streak: calculateStreak(activityDates.value),
  };
  loading.value = false;
});
</script>

<template>
  <section class="space-y-8">
    <header class="flex flex-wrap items-end justify-between gap-4">
      <div>
        <p class="mb-2 text-sm font-semibold text-primary">YOUR LEARNING SPACE</p>
        <h1 class="text-3xl font-extrabold text-foreground sm:text-4xl">Welcome back, {{ greetingName }}</h1>
        <p class="mt-2 text-muted-foreground">A little progress each day adds up.</p>
      </div>
      <RouterLink to="/courses" class="inline-flex min-h-11 items-center gap-2 rounded-md bg-primary px-4 text-sm font-bold text-white outline-none hover:bg-primary/90 focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2">
        Explore courses <ArrowRight :size="17" aria-hidden="true" />
      </RouterLink>
    </header>

    <p v-if="errorMessage" role="alert" class="rounded-md border border-accent bg-white px-4 py-3 text-sm text-accent-foreground">{{ errorMessage }}</p>

    <div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
      <StatCard label="Courses to explore" :value="loading ? '—' : stats.available" :icon="BookOpen">
        <RouterLink to="/courses" class="inline-flex items-center gap-1 font-bold text-primary hover:underline">Browse catalog <ArrowRight :size="13" /></RouterLink>
      </StatCard>
      <StatCard label="In progress" :value="loading ? '—' : stats.enrolled" :icon="GraduationCap">
        <RouterLink to="/learning" class="inline-flex items-center gap-1 font-bold text-primary hover:underline">Open my learning <ArrowRight :size="13" /></RouterLink>
      </StatCard>
      <StatCard label="Lessons completed" :value="loading ? '—' : stats.completed" :icon="CheckCircle2">
        Keep your momentum going
      </StatCard>
      <StatCard label="Login streak" :value="loading ? '—' : stats.streak" :icon="Flame">
        {{ stats.streak === 1 ? 'day in a row' : 'days in a row' }}
      </StatCard>
    </div>

    <section class="border border-border bg-white p-5" aria-label="Daily login activity for the past week">
      <div class="flex flex-wrap items-start justify-between gap-4">
        <div>
          <h2 class="text-base font-extrabold">Daily activity</h2>
          <p class="mt-1 text-sm text-muted-foreground">Sign in each day to keep your streak alive.</p>
        </div>
        <div class="flex gap-2 sm:gap-3">
          <div v-for="day in recentDays" :key="day.value" class="grid justify-items-center gap-2" :aria-label="`${day.label}: ${day.active ? 'signed in' : 'no sign-in'}`">
            <span class="text-xs font-medium text-muted-foreground">{{ day.label }}</span>
            <span class="size-4 rounded-full" :class="day.active ? 'bg-primary' : 'bg-secondary'" />
          </div>
        </div>
      </div>
    </section>

    <section class="grid gap-6 lg:grid-cols-[1.4fr_0.8fr]">
      <div class="border border-border bg-white p-6 sm:p-8">
        <div class="flex items-start justify-between gap-4">
          <div>
            <p class="text-sm font-semibold text-primary">PICK UP SOMETHING NEW</p>
            <h2 class="mt-2 text-2xl font-extrabold">Make space for a new skill</h2>
            <p class="mt-2 max-w-lg text-sm leading-6 text-muted-foreground">Find a course that fits your goals, enroll in a few clicks, and keep your progress together in one place.</p>
          </div>
          <span class="hidden size-12 shrink-0 place-items-center bg-secondary text-primary sm:grid"><Sparkles :size="22" aria-hidden="true" /></span>
        </div>
        <RouterLink to="/courses" class="mt-6 inline-flex items-center gap-2 text-sm font-bold text-primary hover:underline">View the catalog <ArrowRight :size="16" /></RouterLink>
      </div>
      <div class="flex flex-col justify-between bg-primary p-6 text-white sm:p-8">
        <div>
          <p class="text-xs font-bold uppercase text-white/75">Your next step</p>
          <h2 class="mt-3 text-2xl font-extrabold">Build a learning streak</h2>
          <p class="mt-2 text-sm leading-6 text-white/80">Set aside a short block of time and return to a lesson you started.</p>
        </div>
        <RouterLink to="/learning" class="mt-6 inline-flex min-h-10 w-fit items-center gap-2 border border-white/40 px-3 text-sm font-semibold hover:bg-white/10">Go to my learning <ArrowRight :size="15" /></RouterLink>
      </div>
    </section>
  </section>
</template>
