<script setup>
defineProps({
  course: { type: Object, required: true },
  image: { type: String, default: "" },
  index: { type: Number, default: 0 },
});
</script>

<template>
  <article class="overflow-hidden border border-border bg-white reveal-on-enter" :style="{ '--reveal-delay': `${Math.min(index, 8) * 45}ms` }">
    <img v-if="image || course.thumbnail_url" :src="course.thumbnail_url || image" :alt="`${course.title} course`" class="h-44 w-full object-cover" loading="lazy" />
    <div class="space-y-3 p-5">
      <div class="flex items-center justify-between gap-3 text-xs font-semibold text-muted-foreground">
        <span class="truncate">{{ course.category || 'General' }}</span>
        <span v-if="course.level" class="shrink-0 rounded-full bg-secondary px-2.5 py-1 capitalize">{{ course.level }}</span>
      </div>
      <h2 class="text-xl font-extrabold">{{ course.title }}</h2>
      <p class="min-h-12 text-sm leading-6 text-muted-foreground">{{ course.description || 'Course details coming soon.' }}</p>
      <slot name="action" />
    </div>
  </article>
</template>
