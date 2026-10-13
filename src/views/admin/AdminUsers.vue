<script setup>
import { computed, onMounted, ref } from "vue";
import {
  Check,
  Flame,
  GraduationCap,
  LoaderCircle,
  Search,
  ShieldCheck,
  UserCheck,
  UserX,
  Users,
} from "lucide-vue-next";
import { useAdminData } from "@/lib/useAdminData";

const {
  people,
  loading,
  error,
  notice,
  loginSummary,
  demoteInstructorToStudent,
  fetchAdminData,
} = useAdminData();

onMounted(async () => {
  await fetchAdminData();
});

const searchQuery = ref("");
const roleFilter = ref("all");
const updatingUserId = ref("");

const filteredPeople = computed(() => {
  let list = people.value;
  if (roleFilter.value !== "all") {
    list = list.filter((p) => p.role === roleFilter.value);
  }
  const q = searchQuery.value.trim().toLowerCase();
  if (q) {
    list = list.filter(
      (p) =>
        (p.full_name || "").toLowerCase().includes(q) ||
        (p.email || "").toLowerCase().includes(q) ||
        (p.phone || "").toLowerCase().includes(q)
    );
  }
  return list;
});

async function handleDemote(user) {
  if (confirm(`Are you sure you want to demote ${user.full_name || user.email} to learner? They will lose access to instructor creation features.`)) {
    updatingUserId.value = user.user_id;
    await demoteInstructorToStudent(user.user_id);
    updatingUserId.value = "";
  }
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
      <div class="flex items-center gap-2 text-xs font-semibold text-muted-foreground">
        <span>Total Accounts: {{ people.length }}</span>
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
            type="button"
            class="rounded px-2.5 py-1 transition-colors"
            :class="roleFilter === 'all' ? 'bg-primary text-white font-bold' : 'text-muted-foreground hover:text-foreground'"
            @click="roleFilter = 'all'"
          >
            All ({{ people.length }})
          </button>
          <button
            type="button"
            class="rounded px-2.5 py-1 transition-colors"
            :class="roleFilter === 'student' ? 'bg-primary text-white font-bold' : 'text-muted-foreground hover:text-foreground'"
            @click="roleFilter = 'student'"
          >
            Learners ({{ people.filter(p => p.role === 'student').length }})
          </button>
          <button
            type="button"
            class="rounded px-2.5 py-1 transition-colors"
            :class="roleFilter === 'instructor' ? 'bg-primary text-white font-bold' : 'text-muted-foreground hover:text-foreground'"
            @click="roleFilter = 'instructor'"
          >
            Instructors ({{ people.filter(p => p.role === 'instructor').length }})
          </button>
          <button
            type="button"
            class="rounded px-2.5 py-1 transition-colors"
            :class="roleFilter === 'super_admin' ? 'bg-primary text-white font-bold' : 'text-muted-foreground hover:text-foreground'"
            @click="roleFilter = 'super_admin'"
          >
            Admins ({{ people.filter(p => p.role === 'super_admin').length }})
          </button>
        </div>
      </div>
    </div>

    <!-- Users Table -->
    <div class="overflow-x-auto rounded-xl border border-border bg-white shadow-xs">
      <table class="w-full min-w-[760px] text-left text-sm">
        <thead class="border-b border-border bg-secondary/60 text-xs font-bold uppercase tracking-wider text-muted-foreground">
          <tr>
            <th class="px-5 py-3.5">User Profile</th>
            <th class="px-5 py-3.5">Role</th>
            <th class="px-5 py-3.5">Last Login</th>
            <th class="px-5 py-3.5">Streak</th>
            <th class="px-5 py-3.5">Joined</th>
            <th class="px-5 py-3.5 text-right">Actions</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-border">
          <tr v-for="person in filteredPeople" :key="person.user_id" class="transition-colors hover:bg-secondary/20">
            <!-- User info -->
            <td class="px-5 py-4">
              <div class="flex items-center gap-3">
                <span class="grid size-9 shrink-0 place-items-center rounded-full bg-secondary font-bold text-primary">
                  {{ (person.full_name || person.email || 'U')[0].toUpperCase() }}
                </span>
                <div>
                  <span class="block font-bold text-foreground">
                    {{ person.full_name || 'Unnamed Learner' }}
                  </span>
                  <span class="block text-xs text-muted-foreground">{{ person.email }}</span>
                  <span v-if="person.phone" class="block text-[11px] text-muted-foreground">{{ person.phone }}</span>
                </div>
              </div>
            </td>

            <!-- Role Badge -->
            <td class="px-5 py-4">
              <span
                class="inline-flex items-center gap-1 rounded-full px-2.5 py-0.5 text-xs font-bold capitalize"
                :class="{
                  'bg-emerald-100 text-emerald-800': person.role === 'super_admin',
                  'bg-blue-100 text-blue-800': person.role === 'instructor',
                  'bg-gray-100 text-gray-700': person.role === 'student',
                }"
              >
                <ShieldCheck v-if="person.role === 'super_admin'" :size="12" />
                <GraduationCap v-else-if="person.role === 'instructor'" :size="12" />
                <Users v-else :size="12" />
                {{ person.role.replace('_', ' ') }}
              </span>
            </td>

            <!-- Last login -->
            <td class="px-5 py-4 text-xs text-muted-foreground">
              {{ loginSummary(person.user_id).lastLogin || 'No activity recorded' }}
            </td>

            <!-- Streak -->
            <td class="px-5 py-4">
              <span class="inline-flex items-center gap-1 text-xs font-bold text-foreground">
                <Flame :size="14" class="text-amber-500" />
                {{ loginSummary(person.user_id).streak }} {{ loginSummary(person.user_id).streak === 1 ? 'day' : 'days' }}
              </span>
            </td>

            <!-- Joined Date -->
            <td class="px-5 py-4 text-xs text-muted-foreground">
              {{ person.created_at ? new Date(person.created_at).toLocaleDateString() : '—' }}
            </td>

            <!-- Actions -->
            <td class="px-5 py-4 text-right">
              <div v-if="person.role === 'instructor'" class="inline-flex items-center gap-2">
                <button
                  type="button"
                  :disabled="updatingUserId === person.user_id"
                  class="inline-flex items-center gap-1 rounded border border-border px-2.5 py-1 text-xs font-bold text-red-700 hover:bg-red-50 disabled:opacity-50"
                  @click="handleDemote(person)"
                >
                  <LoaderCircle v-if="updatingUserId === person.user_id" :size="12" class="animate-spin" />
                  <UserX v-else :size="12" /> Demote to Learner
                </button>
              </div>
              <span v-else-if="person.role === 'super_admin'" class="text-xs font-semibold text-emerald-700">
                System Owner
              </span>
              <span v-else class="text-xs text-muted-foreground">
                Standard access
              </span>
            </td>
          </tr>

          <tr v-if="!filteredPeople.length">
            <td colspan="6" class="px-5 py-12 text-center text-sm text-muted-foreground">
              No users found matching your search criteria.
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

