<script setup>
import { computed, onMounted, ref } from "vue";
import { Search, ShieldPlus } from "lucide-vue-next";
import { useAdminData } from "@/lib/useAdminData";
import InstructorVerificationModal from "@/components/admin/InstructorVerificationModal.vue";
import AddAdminModal from "@/components/admin/AddAdminModal.vue";
import AdminUsersTable from "@/components/admin/AdminUsersTable.vue";

const {
  currentProfile,
  people,
  applications,
  loading,
  error,
  notice,
  loginSummary,
  reviewApplication,
  demoteInstructorToStudent,
  grantSuperAdmin,
  revokeSuperAdmin,
  fetchAdminData,
} = useAdminData();

onMounted(async () => {
  await fetchAdminData();
});

const searchQuery = ref("");
const roleFilter = ref("all");
const updatingUserId = ref("");
const activeModalApp = ref(null);
const showAddAdminModal = ref(false);

function getApplication(userId) {
  return applications.value.find((app) => app.user_id === userId);
}

function openVerifyForStudent(person) {
  activeModalApp.value = {
    user_id: person.user_id,
    organization: "Independent Educator",
    professional_title: "Instructor",
    expertise: "General Curriculum",
    experience_years: 1,
    qualification: "Directly Verified by Super Admin",
    verification_url: "",
    teaching_statement: "Verified account granted instructor privileges.",
    status: "pending",
    created_at: new Date().toISOString(),
    profile: person,
  };
}

async function handleModalReview({ application, status, notes }) {
  updatingUserId.value = application.user_id;
  await reviewApplication(application, status, notes);
  updatingUserId.value = "";
  activeModalApp.value = null;
}

const filteredPeople = computed(() => {
  let list = people.value;
  if (roleFilter.value !== "all") list = list.filter((p) => p.role === roleFilter.value);
  const q = searchQuery.value.trim().toLowerCase();
  if (q) {
    list = list.filter((p) =>
      (p.full_name || "").toLowerCase().includes(q) ||
      (p.email || "").toLowerCase().includes(q) ||
      (p.phone || "").toLowerCase().includes(q)
    );
  }
  return list;
});

async function handleDemote(user) {
  if (confirm(`Demote ${user.full_name || user.email} to learner?`)) {
    updatingUserId.value = user.user_id;
    await demoteInstructorToStudent(user.user_id);
    updatingUserId.value = "";
  }
}

async function handleRevokeAdmin(user) {
  if (confirm(`Revoke admin clearance from ${user.full_name || user.email}?`)) {
    updatingUserId.value = user.user_id;
    await revokeSuperAdmin(user.user_id);
    updatingUserId.value = "";
  }
}

async function handlePromoteUser(user) {
  if (confirm(`Grant super admin clearance to ${user.full_name || user.email}?`)) {
    updatingUserId.value = user.user_id;
    await grantSuperAdmin(user.user_id);
    updatingUserId.value = "";
  }
}

async function onGrantAdmin({ identifier }) {
  await grantSuperAdmin(identifier);
  showAddAdminModal.value = false;
}
</script>

<template>
  <div class="space-y-6">
    <header class="flex flex-wrap items-center justify-between gap-4">
      <div>
        <h1 class="text-3xl font-extrabold text-foreground sm:text-4xl">User & Learner Directory</h1>
        <p class="mt-1 text-sm text-muted-foreground">
          Manage user profiles, inspect login activity streaks, and manage role permissions.
        </p>
      </div>
      <div class="flex items-center gap-3">
        <span class="text-xs font-semibold text-muted-foreground">Total: {{ people.length }}</span>
        <button
          type="button"
          class="inline-flex min-h-9 items-center gap-1.5 rounded-lg bg-emerald-700 px-3.5 text-xs font-bold text-white hover:bg-emerald-600 shadow-xs"
          @click="showAddAdminModal = true"
        >
          <ShieldPlus :size="14" /> Add Admin
        </button>
      </div>
    </header>

    <div v-if="error" role="alert" class="rounded-md border border-red-200 bg-red-50 p-4 text-sm text-red-800">
      {{ error }}
    </div>
    <div v-if="notice" role="status" class="rounded-md border border-emerald-200 bg-emerald-50 p-4 text-sm text-emerald-800">
      {{ notice }}
    </div>

    <!-- Filters & Search Bar -->
    <div class="flex flex-col gap-4 rounded-xl border border-border bg-white p-4 shadow-xs sm:flex-row sm:items-center sm:justify-between">
      <div class="relative flex-1 max-w-md">
        <Search :size="16" class="absolute left-3.5 top-1/2 -translate-y-1/2 text-muted-foreground" />
        <input
          v-model="searchQuery"
          type="search"
          placeholder="Search by name, email, or phone..."
          class="h-10 w-full rounded-md border border-border bg-white pl-9 pr-3 text-sm outline-none focus:border-primary focus:ring-2 focus:ring-primary/20"
        />
      </div>

      <div class="flex flex-wrap items-center gap-2">
        <span class="text-xs font-bold text-muted-foreground">Role:</span>
        <div class="flex rounded-md border border-border bg-secondary/50 p-0.5 text-xs font-semibold">
          <button
            v-for="r in [
              { id: 'all', label: `All (${people.length})` },
              { id: 'student', label: `Learners (${people.filter(p => p.role === 'student').length})` },
              { id: 'instructor', label: `Instructors (${people.filter(p => p.role === 'instructor').length})` },
              { id: 'super_admin', label: `Admins (${people.filter(p => p.role === 'super_admin').length})` },
            ]"
            :key="r.id"
            type="button"
            class="rounded px-2.5 py-1 transition-colors"
            :class="roleFilter === r.id ? 'bg-primary text-white font-bold' : 'text-muted-foreground hover:text-foreground'"
            @click="roleFilter = r.id"
          >
            {{ r.label }}
          </button>
        </div>
      </div>
    </div>

    <!-- Users Table Component -->
    <AdminUsersTable
      :users="filteredPeople"
      :current-user-id="currentProfile?.user_id"
      :updating-user-id="updatingUserId"
      :login-summary="loginSummary"
      :get-application="getApplication"
      @verify-app="activeModalApp = $event"
      @verify-student="openVerifyForStudent($event)"
      @demote-instructor="handleDemote($event)"
      @promote-admin="handlePromoteUser($event)"
      @revoke-admin="handleRevokeAdmin($event)"
    />

    <!-- Instructor Verification Modal -->
    <InstructorVerificationModal
      v-if="activeModalApp"
      :application="activeModalApp"
      :reviewing="updatingUserId === activeModalApp?.user_id"
      @approve="handleModalReview({ application: $event.application, status: 'approved', notes: $event.notes })"
      @reject="handleModalReview({ application: $event.application, status: 'rejected', notes: $event.notes })"
      @close="activeModalApp = null"
    />

    <!-- Add Admin Modal -->
    <AddAdminModal
      v-if="showAddAdminModal"
      :people="people"
      :current-user-id="currentProfile?.user_id"
      @grant="onGrantAdmin"
      @close="showAddAdminModal = false"
    />
  </div>
</template>
