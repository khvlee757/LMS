<script setup>
import { computed } from 'vue';

const props = defineProps({
  data: {
    type: Array,
    required: true,
  },
  height: {
    type: Number,
    default: 160,
  },
  stroke: {
    type: String,
    default: '#43419D',
  },
});

const values = computed(() => props.data.map((d) => Number(d.users ?? d.value ?? 0)));
const max = computed(() => Math.max(...values.value, 1));
const min = computed(() => Math.min(...values.value, 0));

const points = computed(() => {
  const len = props.data.length;
  if (!len) return '';
  const stepX = 100 / Math.max(len - 1, 1);

  return values.value
    .map((v, i) => {
      const x = (i * stepX).toFixed(2);
      const percent = (v - min.value) / (max.value - min.value || 1);
      const y = ((1 - percent) * 100).toFixed(2);
      return `${x},${y}`;
    })
    .join(' ');
});
</script>

<template>
  <svg viewBox="0 0 100 100" preserveAspectRatio="none" :style="{height: `${height}px`, width: '100%'}" class="rounded-lg bg-transparent">
    <defs>
      <linearGradient id="areaGrad" x1="0" x2="0" y1="0" y2="1">
        <stop offset="0%" :stop-color="stroke" stop-opacity="0.18" />
        <stop offset="100%" :stop-color="stroke" stop-opacity="0" />
      </linearGradient>
    </defs>

    <polyline :points="points" fill="none" :stroke="stroke" stroke-width="1.6" stroke-linejoin="round" stroke-linecap="round" />

    <polygon v-if="points" :points="points + ' 100,100 0,100'" fill="url(#areaGrad)" opacity="0.9" />

    <g v-for="(d, i) in data" :key="i">
      <circle :cx="(i * (100 / Math.max(data.length - 1, 1))).toFixed(2)" :cy="(() => { const v = Number(d.users ?? d.value ?? 0); const percent = (v - min) / (max - min || 1); return ((1 - percent) * 100).toFixed(2); })()" r="1.1" fill="white" stroke="" />
    </g>

    <g transform="translate(0, 92)" class="text-xs fill-current text-muted-foreground">
      <text v-for="(d, i) in data" :key="i" :x="(i * (100 / Math.max(data.length - 1, 1))).toFixed(2)" y="6" text-anchor="middle" font-size="3">
        {{ d.day || d.label }}
      </text>
    </g>
  </svg>
</template>
