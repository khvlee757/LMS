<script setup lang="ts">
import { ref } from "vue"

const emit = defineEmits<{
  (event: "add-course", payload: {
    title: string
    category: string
    mentor: string
    lessons: number
  }): void
}>()

const form = ref({
  title: "",
  category: "",
  mentor: "",
  lessons: 8,
})

const submit = () => {
  if (!form.value.title || !form.value.category || !form.value.mentor) {
    return
  }

  emit("add-course", {
    title: form.value.title,
    category: form.value.category,
    mentor: form.value.mentor,
    lessons: Number(form.value.lessons) || 8,
  })

  form.value = {
    title: "",
    category: "",
    mentor: "",
    lessons: 8,
  }
}
</script>

<template>
  <div class="rounded-2xl border bg-white p-5 shadow-sm">
    <h3 class="mb-4 text-xl font-semibold text-primary">Add new course</h3>

    <form class="space-y-4" @submit.prevent="submit">
      <div>
        <label class="mb-1 block text-sm font-medium text-primary">Course name</label>
        <input v-model="form.title" type="text" class="w-full rounded-lg border px-3 py-2 outline-none focus:border-primary" placeholder="e.g. Product Design" />
      </div>

      <div>
        <label class="mb-1 block text-sm font-medium text-primary">Category</label>
        <input v-model="form.category" type="text" class="w-full rounded-lg border px-3 py-2 outline-none focus:border-primary" placeholder="e.g. Design" />
      </div>

      <div>
        <label class="mb-1 block text-sm font-medium text-primary">Mentor</label>
        <input v-model="form.mentor" type="text" class="w-full rounded-lg border px-3 py-2 outline-none focus:border-primary" placeholder="e.g. Sarah Lee" />
      </div>

      <div>
        <label class="mb-1 block text-sm font-medium text-primary">Lessons</label>
        <input v-model="form.lessons" type="number" min="1" class="w-full rounded-lg border px-3 py-2 outline-none focus:border-primary" placeholder="8" />
      </div>

      <button type="submit" class="w-full rounded-lg bg-primary px-4 py-3 font-semibold text-white hover:bg-primary/90">
        Save course
      </button>
    </form>
  </div>
</template>
