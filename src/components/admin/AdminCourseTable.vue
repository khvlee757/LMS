<script setup>
import { computed, ref } from "vue";
import { RouterLink } from "vue-router";
import { Check, ExternalLink, Search, Trash2 } from "lucide-vue-next";

const props = defineProps({
  courses: { type: Array, required: true },
  people: { type: Array, required: true },
  money: { type: Function, required: true },
  actionCourseId: { type: String, default: "" },
});

const emit = defineEmits(["toggle-publish", "delete"]);

const searchQuery = ref("");
const statusFilter = ref("all");
const levelFilter = ref("all");

const filteredCourses = computed(() => {
  let list = props.courses;
  if (statusFilter.value === "published") {
    list = list.filter((c) => c.published);
  } else if (statusFilter.value === "draft") {
    list = list.filter((c) => !c.published);
  }

  if (levelFilter.value !== "all") {
    list = list.filter((c) => c.level === levelFilter.value);
  }

  const q = searchQuery.value.trim().toLowerCase();
  if (q) {
    list = list.filter((c) => {
      const instructor = props.people.find((p) => p.user_id === c.instructor_id);
      return (
        c.title.toLowerCase().includes(q) ||
        (c.category || "").toLowerCase().includes(q) ||
        (instructor?.full_name || "").toLowerCase().includes(q) ||
        (instructor?.email || "").toLowerCase().includes(q)
      );
    });
  }

  return list;
});
</script>

<template>
  <div class="space-y-4">
    <!-- Filters & Search -->
    <div class="flex flex-col gap-4 rounded-xl border border-border bg-white p-4 shadow-xs sm:flex-row sm:items-center sm:justify-between">
      <div class="relative flex-1 max-w-md">
        <Search :size="16" class="absolute left-3.5 top-1/2 -translate-y-1/2 text-muted-foreground" />
        <input
          v-model="searchQuery"
          type="search"
          placeholder="Search by course title, category, or instructor..."
          class="h-10 w-full rounded-md border border-border bg-white pl-9 pr-3 text-sm outline-none focus:border-primary focus:ring-2 focus:ring-primary/20"
        />
      </div>

      <div class="flex flex-wrap items-center gap-2">
        <div class="flex rounded-md border border-border bg-secondary/50 p-0.5 text-xs font-semibold">
          <button
            type="button"
            class="rounded px-2.5 py-1"
            :class="statusFilter === 'all' ? 'bg-primary text-white font-bold' : 'text-muted-foreground hover:text-foreground'"
            @click="statusFilter = 'all'"
          >
            All ({{ courses.length }})
          </button>
          <button
            type="button"
            class="rounded px-2.5 py-1"
            :class="statusFilter === 'published' ? 'bg-primary text-white font-bold' : 'text-muted-foreground hover:text-foreground'"
            @click="statusFilter = 'published'"
          >
            Published ({{ courses.filter(c => c.published).length }})
          </button>
          <button
            type="button"
            class="rounded px-2.5 py-1"
            :class="statusFilter === 'draft' ? 'bg-primary text-white font-bold' : 'text-muted-foreground hover:text-foreground'"
            @click="statusFilter = 'draft'"
          >
            Drafts ({{ courses.filter(c => !c.published).length }})
          </button>
        </div>

        <select
          v-model="levelFilter"
          class="h-9 rounded-md border border-border bg-white px-2.5 text-xs font-semibold text-foreground outline-none focus:border-primary"
        >
          <option value="all">All Levels</option>
          <option value="beginner">Beginner</option>
          <option value="intermediate">Intermediate</option>
          <option value="advanced">Advanced</option>
        </select>
      </div>
    </div>

    <!-- Courses Table -->
    <div class="overflow-x-auto rounded-xl border border-border bg-white shadow-xs">
      <table class="w-full min-w-[800px] text-left text-sm">
        <thead class="border-b border-border bg-secondary/60 text-xs font-bold uppercase tracking-wider text-muted-foreground">
          <tr>
            <th class="px-5 py-3.5">Course</th>
            <th class="px-5 py-3.5">Instructor</th>
            <th class="px-5 py-3.5">Level</th>
            <th class="px-5 py-3.5">Pricing</th>
            <th class="px-5 py-3.5">Status</th>
            <th class="px-5 py-3.5 text-right">Actions</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-border">
          <tr v-for="course in filteredCourses" :key="course.id" class="transition-colors hover:bg-secondary/20">
            <!-- Title & Category -->
            <td class="px-5 py-4">
              <div>
                <span class="block font-bold text-foreground">{{ course.title }}</span>
                <span class="block text-xs text-muted-foreground">{{ course.category || 'General' }}</span>
              </div>
            </td>

            <!-- Instructor -->
            <td class="px-5 py-4 text-xs">
              <span class="font-semibold text-foreground">
                {{ people.find(p => p.user_id === course.instructor_id)?.full_name || 'Northstar Instructor' }}
              </span>
              <span class="block text-muted-foreground">
                {{ people.find(p => p.user_id === course.instructor_id)?.email || '' }}
              </span>
            </td>

            <!-- Level -->
            <td class="px-5 py-4">
              <span class="inline-block rounded-full bg-secondary px-2.5 py-0.5 text-xs font-semibold capitalize text-foreground">
                {{ course.level }}
              </span>
            </td>

            <!-- Price -->
            <td class="px-5 py-4 text-xs font-bold">
              <span v-if="course.is_free" class="rounded bg-emerald-50 px-2 py-0.5 text-emerald-800">Free</span>
              <span v-else class="text-foreground">{{ money(course.price_minor, course.currency) }}</span>
            </td>

            <!-- Status -->
            <td class="px-5 py-4">
              <span
                class="inline-block rounded-full px-2.5 py-0.5 text-xs font-bold"
                :class="course.published ? 'bg-emerald-100 text-emerald-800' : 'bg-gray-100 text-gray-700'"
              >
                {{ course.published ? 'Published' : 'Draft' }}
              </span>
            </td>

            <!-- Actions -->
            <td class="px-5 py-4 text-right">
              <div class="inline-flex items-center gap-2">
                <RouterLink
                  :to="`/courses/${course.id}`"
                  target="_blank"
                  class="inline-flex items-center gap-1 rounded border border-border px-2.5 py-1 text-xs font-bold text-muted-foreground hover:bg-secondary hover:text-foreground"
                >
                  <ExternalLink :size="12" /> Preview
                </RouterLink>

                <button
                  type="button"
                  :disabled="actionCourseId === course.id"
                  class="inline-flex items-center gap-1 rounded border border-border px-2.5 py-1 text-xs font-bold hover:bg-secondary disabled:opacity-50"
                  :class="course.published ? 'text-amber-800' : 'text-emerald-800'"
                  @click="emit('toggle-publish', course)"
                >
                  <Check :size="12" />
                  {{ course.published ? 'Unpublish' : 'Publish' }}
                </button>

                <button
                  type="button"
                  :disabled="actionCourseId === course.id"
                  class="inline-flex items-center gap-1 rounded border border-red-200 px-2 py-1 text-xs font-bold text-red-700 hover:bg-red-50 disabled:opacity-50"
                  @click="emit('delete', course)"
                >
                  <Trash2 :size="12" />
                </button>
              </div>
            </td>
          </tr>

          <tr v-if="!filteredCourses.length">
            <td colspan="6" class="px-5 py-12 text-center text-sm text-muted-foreground">
              No courses match your search or filter.
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
