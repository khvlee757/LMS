<script setup lang="ts">
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"

const props = defineProps<{
  users: Array<any>
}>()
</script>

<template>
  <Card class="rounded-2xl">
    <CardHeader>
      <CardTitle>Recent Enrollments</CardTitle>
    </CardHeader>

    <CardContent>
      <div v-if="props.users.length" class="space-y-4">
        <div
          v-for="user in props.users.slice(0, 5)"
          :key="user.id || user.email"
          class="flex items-center justify-between border-b pb-3 last:border-0"
        >
          <div>
            <p class="font-medium">{{ user.name || "Student" }}</p>
            <p class="text-sm text-muted-foreground">{{ user.email }}</p>
          </div>

          <span class="rounded-full bg-primary/10 px-3 py-1 text-xs font-medium text-primary">
            Enrolled
          </span>
        </div>
      </div>

      <div v-else class="py-10 text-center text-muted-foreground">No enrollments yet</div>
    </CardContent>
  </Card>
</template>
