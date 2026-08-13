<script setup>
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
} from '@/components/ui/card';

const props = defineProps({
  totalHours: {
    type: String,
    required: true,
    default: '0.0',
  },
  stats: {
    type: Array,
    required: true,
    default: () => [],
  },
});
</script>

<template>
  <Card class="border-0 bg-white shadow-md">
    <CardHeader class="pb-3">
      <p class="text-sm font-medium text-muted-foreground">Hours spent</p>
      <CardTitle class="text-xl">This week</CardTitle>
    </CardHeader>

    <CardContent class="space-y-5">
      <div class="text-4xl font-bold tracking-tight">{{ props.totalHours }}h</div>

      <div class="space-y-3 text-sm">
        <div
          v-for="item in props.stats"
          :key="item.label"
          :class="['flex items-center justify-between rounded-xl px-3 py-2', item.bg]"
        >
          <span class="text-muted-foreground">{{ item.label }}</span>
          <span class="font-semibold text-foreground">{{ item.value }}</span>
        </div>
      </div>
    </CardContent>
  </Card>
</template>
