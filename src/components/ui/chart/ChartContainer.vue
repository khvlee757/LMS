<script setup>
import { cn } from '@/lib/utils';

const props = defineProps({
  class: {
    type: [String, Object, Array],
    required: false,
    default: '',
  },
});
</script>

<template>
  <div :class="cn('h-full w-full', props.class)" data-slot="chart-container">
    <slot />
  </div>
</template>
