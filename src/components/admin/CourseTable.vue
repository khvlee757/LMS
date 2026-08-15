<script setup lang="ts">
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"

const props = defineProps<{
  courses: Array<any>
}>()

const emit = defineEmits<{
  (event: "remove-course", courseId: string): void
}>()
</script>

<template>
  <Card class="rounded-2xl">
    <CardHeader class="flex flex-row items-center justify-between">
      <CardTitle>Course List</CardTitle>
      <span class="text-sm text-muted-foreground">{{ props.courses.length }} Courses</span>
    </CardHeader>

    <CardContent>
      <div class="overflow-x-auto">
        <table class="w-full">
          <thead>
            <tr class="border-b text-left">
              <th class="pb-3">Course</th>
              <th class="pb-3">Category</th>
              <th class="pb-3">Mentor</th>
              <th class="pb-3">Lessons</th>
              <th class="pb-3"></th>
            </tr>
          </thead>

          <tbody>
            <tr v-for="course in props.courses" :key="course.id" class="border-b">
              <td class="py-4 font-medium">{{ course.title }}</td>
              <td class="py-4">{{ course.category }}</td>
              <td class="py-4">{{ course.mentor }}</td>
              <td class="py-4">{{ course.lessons }}</td>
              <td class="py-4 text-right">
                <button @click="emit('remove-course', course.id)" class="rounded-md bg-red-500 px-3 py-1 text-sm text-white">
                  Delete
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </CardContent>
  </Card>
</template>
