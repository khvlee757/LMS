<script setup lang="ts">
const props = defineProps<{
  totalUsers: number
  totalCourses: number
  completionRate: number
}>()
</script>

<template>
  <section class="grid gap-4 md:grid-cols-3">
    <div class="rounded-2xl border bg-white p-5 shadow-sm">
      <p class="text-sm text-muted-foreground">Registered users</p>
      <h2 class="mt-3 text-3xl font-bold text-primary">{{ props.totalUsers }}</h2>
    </div>

    <div class="rounded-2xl border bg-white p-5 shadow-sm">
      <p class="text-sm text-muted-foreground">Courses available</p>
      <h2 class="mt-3 text-3xl font-bold text-primary">{{ props.totalCourses }}</h2>
    </div>

    <div class="rounded-2xl border bg-white p-5 shadow-sm">
      <p class="text-sm text-muted-foreground">Course completion</p>
      <h2 class="mt-3 text-3xl font-bold text-primary">{{ props.completionRate }}%</h2>
    </div>
  </section>
</template>
