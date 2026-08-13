<script setup>
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
} from '@/components/ui/card';

const props = defineProps({
  data: {
    type: Array,
    required: true,
    default: () => [],
  },
});
</script>

<template>
  <Card class="border-0 bg-white shadow-md">
    <CardHeader class="pb-4">
      <div class="flex items-center justify-between gap-4">
        <div>
          <p class="text-sm font-medium text-muted-foreground">Time spent</p>
          <CardTitle class="text-xl">Course Activity</CardTitle>
        </div>
        <span class="rounded-full bg-violet-100 px-2.5 py-1 text-xs font-semibold text-violet-700">
          +12.4%
        </span>
      </div>
    </CardHeader>

    <CardContent>
      <div class="flex h-52 items-end gap-3 rounded-2xl bg-gradient-to-b from-violet-50 to-white p-4">
        <div v-for="day in props.data" :key="day.label" class="flex flex-1 flex-col items-center justify-end gap-2">
          <span class="text-xs font-medium text-muted-foreground">{{ day.value }}h</span>
          <div
            class="w-full rounded-t-xl bg-gradient-to-t from-violet-600 to-violet-400 shadow-sm"
            :style="{ height: day.height }"
          />
          <span class="text-xs font-medium text-muted-foreground">{{ day.label }}</span>
        </div>
      </div>
    </CardContent>
  </Card>
</template>
