<script setup>
import { onMounted, ref } from "vue";
import { Plus } from "lucide-vue-next";
import { useAdminData } from "@/lib/useAdminData";
import AdminCourseCreateModal from "@/components/admin/AdminCourseCreateModal.vue";
import AdminCourseTable from "@/components/admin/AdminCourseTable.vue";

const {
  courses,
  people,
  loading,
  error,
  notice,
  money,
  toggleCoursePublished,
  deleteCourse,
  createCourse,
  fetchAdminData,
} = useAdminData();

onMounted(async () => {
  await fetchAdminData();
});

const showCreateModal = ref(false);
const savingCourse = ref(false);
const actionCourseId = ref("");

async function handleCreate(draft) {
  if (savingCourse.value) return;
  savingCourse.value = true;
  const success = await createCourse(draft);
  if (success) {
    showCreateModal.value = false;
  }
  savingCourse.value = false;
}

async function handleTogglePublish(course) {
  actionCourseId.value = course.id;
  await toggleCoursePublished(course);
  actionCourseId.value = "";
}

async function handleDelete(course) {
  if (confirm(`Are you sure you want to permanently delete course "${course.title}"? This cannot be undone.`)) {
    actionCourseId.value = course.id;
    await deleteCourse(course.id);
    actionCourseId.value = "";
  }
}
</script>

<template>
  <div class="space-y-6">
    <header class="flex flex-wrap items-center justify-between gap-4">
      <div>
        <h1 class="text-3xl font-extrabold text-foreground sm:text-4xl">Course Management</h1>
        <p class="mt-1 text-sm text-muted-foreground">
          Publish, moderate, inspect, and manage all courses across Northstar.
        </p>
      </div>

      <button
        type="button"
        class="inline-flex min-h-11 items-center gap-2 rounded-lg bg-primary px-4 text-sm font-bold text-white shadow-xs hover:bg-primary/90"
        @click="showCreateModal = !showCreateModal"
      >
        <Plus :size="16" /> {{ showCreateModal ? 'Close Form' : 'New Course' }}
      </button>
    </header>

    <div v-if="error" role="alert" class="rounded-md border border-red-200 bg-red-50 p-4 text-sm text-red-800">
      {{ error }}
    </div>
    <div v-if="notice" role="status" class="rounded-md border border-emerald-200 bg-emerald-50 p-4 text-sm text-emerald-800">
      {{ notice }}
    </div>

    <!-- Create Course Modal/Accordion -->
    <AdminCourseCreateModal
      v-if="showCreateModal"
      :saving="savingCourse"
      @create="handleCreate"
      @close="showCreateModal = false"
    />

    <!-- Courses Table & Filters -->
    <AdminCourseTable
      :courses="courses"
      :people="people"
      :money="money"
      :action-course-id="actionCourseId"
      @toggle-publish="handleTogglePublish"
      @delete="handleDelete"
    />
  </div>
</template>
