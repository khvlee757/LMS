<script setup>
import { reactive } from "vue";
import { LoaderCircle, Plus, X } from "lucide-vue-next";

defineProps({
  saving: { type: Boolean, default: false },
});

const emit = defineEmits(["create", "close"]);

const draft = reactive({
  title: "",
  description: "",
  category: "",
  level: "beginner",
  is_free: true,
  price: "",
});

function handleSubmit() {
  if (!draft.title.trim()) return;
  emit("create", { ...draft });
}
</script>

<template>
  <section class="rounded-xl border border-primary/20 bg-white p-5 shadow-sm sm:p-6">
    <div class="mb-4 flex items-center justify-between">
      <h2 class="text-lg font-extrabold text-primary">Create New Platform Course</h2>
      <button type="button" class="text-muted-foreground hover:text-foreground" @click="emit('close')">
        <X :size="18" />
      </button>
    </div>

    <form class="grid gap-4 md:grid-cols-2" @submit.prevent="handleSubmit">
      <label class="space-y-1.5 text-xs font-bold uppercase text-muted-foreground">
        Course Title
        <input
          v-model="draft.title"
          required
          maxlength="160"
          class="h-11 w-full rounded-md border border-border px-3 text-sm font-normal text-foreground outline-none focus:border-primary focus:ring-2 focus:ring-primary/20"
          placeholder="e.g. Modern Web Development"
        />
      </label>

      <label class="space-y-1.5 text-xs font-bold uppercase text-muted-foreground">
        Category
        <input
          v-model="draft.category"
          maxlength="80"
          class="h-11 w-full rounded-md border border-border px-3 text-sm font-normal text-foreground outline-none focus:border-primary focus:ring-2 focus:ring-primary/20"
          placeholder="Computer Science, Design, Business..."
        />
      </label>

      <label class="space-y-1.5 text-xs font-bold uppercase text-muted-foreground">
        Skill Level
        <select
          v-model="draft.level"
          class="h-11 w-full rounded-md border border-border bg-white px-3 text-sm font-normal text-foreground outline-none focus:border-primary focus:ring-2 focus:ring-primary/20"
        >
          <option value="beginner">Beginner</option>
          <option value="intermediate">Intermediate</option>
          <option value="advanced">Advanced</option>
        </select>
      </label>

      <div class="flex items-center gap-4">
        <label class="flex min-h-11 flex-1 items-center gap-3 rounded-md border border-border px-3 text-sm font-semibold text-foreground">
          <input v-model="draft.is_free" type="checkbox" class="size-4 accent-primary" /> Free Course
        </label>
        <label v-if="!draft.is_free" class="flex-1 space-y-1 text-xs font-bold uppercase text-muted-foreground">
          Price (NGN)
          <input
            v-model="draft.price"
            type="number"
            min="1"
            step="0.01"
            required
            class="h-11 w-full rounded-md border border-border px-3 text-sm font-normal text-foreground outline-none focus:border-primary focus:ring-2 focus:ring-primary/20"
            placeholder="e.g. 5000"
          />
        </label>
      </div>

      <label class="space-y-1.5 text-xs font-bold uppercase text-muted-foreground md:col-span-2">
        Description
        <textarea
          v-model="draft.description"
          rows="3"
          maxlength="2000"
          class="w-full rounded-md border border-border px-3 py-2 text-sm font-normal text-foreground outline-none focus:border-primary focus:ring-2 focus:ring-primary/20"
          placeholder="Course overview and objectives..."
        />
      </label>

      <div class="md:col-span-2 flex justify-end gap-2">
        <button
          type="button"
          class="min-h-11 rounded-md border border-border px-4 text-xs font-bold hover:bg-secondary"
          @click="emit('close')"
        >
          Cancel
        </button>
        <button
          type="submit"
          :disabled="saving || !draft.title.trim() || (!draft.is_free && !(Number(draft.price) > 0))"
          class="inline-flex min-h-11 items-center gap-2 rounded-md bg-primary px-5 text-xs font-bold text-white hover:bg-primary/90 disabled:opacity-50"
        >
          <LoaderCircle v-if="saving" :size="15" class="animate-spin" />
          <Plus v-else :size="15" />
          {{ saving ? 'Saving Course...' : 'Save as Draft' }}
        </button>
      </div>
    </form>
  </section>
</template>
