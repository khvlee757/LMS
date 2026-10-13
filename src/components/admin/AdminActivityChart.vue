<script setup>
import { TrendingUp } from "lucide-vue-next";

defineProps({
  pastWeekLogins: { type: Array, required: true },
  maxDailyLogins: { type: Number, required: true },
  learnersCount: { type: Number, required: true },
  instructorsCount: { type: Number, required: true },
  adminsCount: { type: Number, required: true },
});
</script>

<template>
  <div class="rounded-xl border border-border bg-white p-5 sm:p-6 lg:col-span-2">
    <div class="flex items-center justify-between">
      <div>
        <h2 class="text-base font-extrabold text-foreground">Active Daily Learners</h2>
        <p class="text-xs text-muted-foreground">Sign-in volume across the last 7 days</p>
      </div>
      <span class="inline-flex items-center gap-1 rounded bg-secondary px-2.5 py-1 text-xs font-bold text-primary">
        <TrendingUp :size="14" /> Platform Traffic
      </span>
    </div>

    <div class="mt-8 flex h-40 items-end justify-between gap-3 border-b border-border pb-2 px-2">
      <div
        v-for="day in pastWeekLogins"
        :key="day.label"
        class="flex flex-1 flex-col items-center gap-2"
      >
        <span class="text-[11px] font-bold text-primary">{{ day.count }}</span>
        <div
          class="w-full max-w-10 rounded-t-md bg-primary transition-all duration-300 hover:bg-emerald-600"
          :style="{ height: `${Math.max(8, (day.count / maxDailyLogins) * 110)}px` }"
        />
        <span class="text-xs font-semibold text-muted-foreground">{{ day.label }}</span>
      </div>
    </div>

    <div class="mt-4 flex flex-wrap items-center justify-between text-xs text-muted-foreground">
      <span>Weekly sign-in total: {{ pastWeekLogins.reduce((acc, d) => acc + d.count, 0) }} logins</span>
      <span>Role distribution: {{ learnersCount }} Learners · {{ instructorsCount }} Instructors · {{ adminsCount }} Super Admins</span>
    </div>
  </div>
</template>
