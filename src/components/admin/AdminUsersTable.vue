<script setup>
import {
  Eye,
  Flame,
  GraduationCap,
  LoaderCircle,
  ShieldAlert,
  ShieldCheck,
  ShieldPlus,
  UserCheck,
  UserX,
  Users,
} from "lucide-vue-next";

defineProps({
  users: { type: Array, required: true },
  currentUserId: { type: String, default: "" },
  updatingUserId: { type: String, default: "" },
  loginSummary: { type: Function, required: true },
  getApplication: { type: Function, required: true },
});

const emit = defineEmits([
  "verify-app",
  "verify-student",
  "demote-instructor",
  "promote-admin",
  "revoke-admin",
]);
</script>

<template>
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
        <tr v-for="person in users" :key="person.user_id" class="transition-colors hover:bg-secondary/20">
          <td class="px-5 py-4">
            <div class="flex items-center gap-3">
              <span class="grid size-9 shrink-0 place-items-center rounded-full bg-secondary font-bold text-primary">
                {{ (person.full_name || person.email || 'U')[0].toUpperCase() }}
              </span>
              <div>
                <span class="block font-bold text-foreground">{{ person.full_name || 'Unnamed Learner' }}</span>
                <span class="block text-xs text-muted-foreground">{{ person.email }}</span>
                <span v-if="person.phone" class="block text-[11px] text-muted-foreground">{{ person.phone }}</span>
              </div>
            </div>
          </td>

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

          <td class="px-5 py-4 text-xs text-muted-foreground">
            {{ loginSummary(person.user_id).lastLogin || 'No activity recorded' }}
          </td>

          <td class="px-5 py-4">
            <span class="inline-flex items-center gap-1 text-xs font-bold text-foreground">
              <Flame :size="14" class="text-amber-500" />
              {{ loginSummary(person.user_id).streak }} {{ loginSummary(person.user_id).streak === 1 ? 'day' : 'days' }}
            </span>
          </td>

          <td class="px-5 py-4 text-xs text-muted-foreground">
            {{ person.created_at ? new Date(person.created_at).toLocaleDateString() : '—' }}
          </td>

          <td class="px-5 py-4 text-right">
            <div class="inline-flex items-center justify-end gap-1.5">
              <button
                v-if="getApplication(person.user_id)"
                type="button"
                class="inline-flex items-center gap-1 rounded border border-primary/30 bg-primary/5 px-2 py-1 text-xs font-bold text-primary hover:bg-primary/10"
                @click="emit('verify-app', getApplication(person.user_id))"
                title="View Dossier"
              >
                <Eye :size="12" /> Dossier
              </button>
              <button
                v-else-if="person.role === 'student'"
                type="button"
                class="inline-flex items-center gap-1 rounded border border-emerald-600/30 bg-emerald-50 px-2 py-1 text-xs font-bold text-emerald-800 hover:bg-emerald-100"
                @click="emit('verify-student', person)"
                title="Verify as Instructor"
              >
                <UserCheck :size="12" /> Verify
              </button>

              <div v-if="person.role === 'instructor'">
                <button
                  type="button"
                  :disabled="updatingUserId === person.user_id"
                  class="inline-flex items-center gap-1 rounded border border-border px-2 py-1 text-xs font-bold text-red-700 hover:bg-red-50 disabled:opacity-50"
                  @click="emit('demote-instructor', person)"
                  title="Demote to Learner"
                >
                  <LoaderCircle v-if="updatingUserId === person.user_id" :size="12" class="animate-spin" />
                  <UserX v-else :size="12" /> Demote
                </button>
              </div>

              <div v-if="person.role !== 'super_admin'">
                <button
                  type="button"
                  :disabled="updatingUserId === person.user_id"
                  class="inline-flex items-center gap-1 rounded border border-emerald-600/30 bg-emerald-700 px-2 py-1 text-xs font-bold text-white hover:bg-emerald-600 disabled:opacity-50"
                  @click="emit('promote-admin', person)"
                  title="Grant Super Admin Clearance"
                >
                  <LoaderCircle v-if="updatingUserId === person.user_id" :size="12" class="animate-spin" />
                  <ShieldPlus v-else :size="12" /> Make Admin
                </button>
              </div>
              <div v-else-if="person.user_id !== currentUserId">
                <button
                  type="button"
                  :disabled="updatingUserId === person.user_id"
                  class="inline-flex items-center gap-1 rounded border border-red-200 bg-red-50 px-2 py-1 text-xs font-bold text-red-700 hover:bg-red-100 disabled:opacity-50"
                  @click="emit('revoke-admin', person)"
                  title="Revoke Admin Clearance"
                >
                  <LoaderCircle v-if="updatingUserId === person.user_id" :size="12" class="animate-spin" />
                  <ShieldAlert v-else :size="12" /> Revoke
                </button>
              </div>
              <span v-else class="text-xs font-semibold text-emerald-700">You (Owner)</span>
            </div>
          </td>
        </tr>

        <tr v-if="!users.length">
          <td colspan="6" class="px-5 py-12 text-center text-sm text-muted-foreground">
            No users found matching your search criteria.
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>
