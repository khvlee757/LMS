<script setup>
defineProps({
  label: { type: String, required: true },
  value: { type: [Number, String], required: true },
  icon: { type: [Object, Function], required: true },
});
</script>

<template>
  <article class="border border-border bg-white p-5 reveal-on-enter">
    <div class="flex items-center justify-between">
      <span class="text-sm font-semibold text-muted-foreground">{{ label }}</span>
      <component :is="icon" :size="19" class="text-primary" aria-hidden="true" />
    </div>
    <p class="mt-5 text-3xl font-extrabold">{{ value }}</p>
    <div class="mt-2 min-h-4 text-xs text-muted-foreground"><slot /></div>
  </article>
</template>
