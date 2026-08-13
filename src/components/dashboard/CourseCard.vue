<script setup>
import {
  Card,
  CardContent,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
} from '@/components/ui/card';
import { Button } from '@/components/ui/button';

const props = defineProps({
  course: {
    type: Object,
    required: true,
  },
});
</script>

<template>
  <Card class="overflow-hidden border-0 bg-white shadow-md">
    <div class="relative h-28 overflow-hidden">
      <img
        :src="props.course.image"
        :alt="props.course.title"
        class="h-full w-full object-cover"
      />
      <div class="absolute inset-0 bg-gradient-to-t from-black/50 to-transparent" />
      <div class="absolute inset-0 flex items-start justify-between p-4 text-white">
        <span class="rounded-full bg-white/15 px-2.5 py-1 text-xs font-medium backdrop-blur-sm">
          {{ props.course.category }}
        </span>
        <span class="text-sm font-semibold">{{ props.course.progress }}%</span>
      </div>
    </div>

    <CardHeader class="space-y-3 pb-3">
      <CardTitle class="text-xl">{{ props.course.title }}</CardTitle>
      <CardDescription>{{ props.course.mentor }} • {{ props.course.lessons }} lessons</CardDescription>
    </CardHeader>

    <CardContent class="pb-4">
      <div class="mb-2 flex items-center justify-between text-sm text-muted-foreground">
        <span>Progress</span>
        <span class="font-medium text-foreground">{{ props.course.progress }}%</span>
      </div>
      <div class="h-2.5 w-full overflow-hidden rounded-full bg-muted">
        <div
          class="h-full rounded-full bg-primary transition-all duration-300"
          :style="{ width: `${props.course.progress}%` }"
        />
      </div>
    </CardContent>

    <CardFooter class="pt-0">
      <Button class="w-full">Continue</Button>
    </CardFooter>
  </Card>
</template>
