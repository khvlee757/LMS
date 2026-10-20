<script setup>
import { computed, ref } from "vue";
import { LoaderCircle, Search, ShieldCheck, UserCheck, X } from "lucide-vue-next";

const props = defineProps({
  people: { type: Array, required: true },
  currentUserId: { type: String, default: "" },
});

const emit = defineEmits(["grant", "close"]);

const searchQuery = ref("");
const selectedUserId = ref("");
const manualEmail = ref("");
const isSubmitting = ref(false);
const errorMessage = ref("");

const nonAdminUsers = computed(() => {
  const query = searchQuery.value.trim().toLowerCase();
  return props.people
    .filter((p) => p.role !== "super_admin" && p.user_id !== props.currentUserId)
    .filter((p) => {
      if (!query) return true;
      return (
        (p.full_name || "").toLowerCase().includes(query) ||
        (p.email || "").toLowerCase().includes(query)
      );
    })
    .slice(0, 8);
});

const selectedUser = computed(() => {
  return props.people.find((p) => p.user_id === selectedUserId.value);
});

async function handleSubmit() {
  errorMessage.value = "";
  const target = selectedUserId.value || manualEmail.value.trim().toLowerCase();
  if (!target) {
    errorMessage.value = "Select a registered user or enter a valid email address.";
    return;
  }
  isSubmitting.value = true;
  try {
    emit("grant", { identifier: target, user: selectedUser.value });
  } finally {
    isSubmitting.value = false;
  }
}
</script>

<template>
  <div class="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4 backdrop-blur-xs">
    <div
      class="flex max-h-[92vh] w-full max-w-lg flex-col overflow-hidden rounded-2xl border border-border bg-white shadow-2xl"
      role="dialog"
      aria-modal="true"
    >
      <header class="flex items-start justify-between border-b border-border bg-[#112922] p-5 text-white sm:px-6">
        <div class="flex items-center gap-3">
          <div class="grid size-11 shrink-0 place-items-center rounded-xl bg-emerald-600 font-extrabold text-white shadow-xs">
            <ShieldCheck :size="22" />
          </div>
          <div>
            <h2 class="text-lg font-black text-white sm:text-xl">Add Platform Administrator</h2>
            <p class="text-xs text-emerald-300">Grant executive administrative clearance to another user</p>
          </div>
        </div>
        <button
          type="button"
          class="rounded-lg p-1.5 text-slate-300 hover:bg-white/10 hover:text-white"
          @click="emit('close')"
          aria-label="Close dialog"
        >
          <X :size="20" />
        </button>
      </header>

      <form @submit.prevent="handleSubmit" class="flex-1 space-y-4 overflow-y-auto p-5 sm:p-6 text-xs text-foreground">
        <div v-if="errorMessage" role="alert" class="rounded-lg border border-red-200 bg-red-50 p-3 text-red-800 font-medium">
          {{ errorMessage }}
        </div>

        <div class="rounded-xl border border-emerald-500/20 bg-emerald-50/50 p-3.5 text-emerald-950">
          <p class="font-bold">Security Clearance Notice:</p>
          <p class="mt-0.5 leading-relaxed text-emerald-900/80">
            Administrators receive full clearance to inspect transaction ledgers, publish courses, manage educator credentials, and configure system settings.
          </p>
        </div>

        <!-- Quick Pick from Registered Accounts -->
        <div class="space-y-2">
          <label class="block font-bold text-foreground">Choose Registered User</label>
          <div class="relative">
            <Search :size="14" class="absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground" />
            <input
              v-model="searchQuery"
              type="search"
              placeholder="Filter by name or email..."
              class="h-9 w-full rounded-md border border-border bg-white pl-8 pr-3 text-xs outline-none focus:border-primary focus:ring-2 focus:ring-primary/20"
            />
          </div>

          <div class="max-h-40 overflow-y-auto rounded-lg border border-border divide-y divide-border">
            <button
              v-for="person in nonAdminUsers"
              :key="person.user_id"
              type="button"
              class="w-full text-left p-2.5 transition-colors flex items-center justify-between hover:bg-secondary/40"
              :class="selectedUserId === person.user_id ? 'bg-primary/10 font-bold text-primary' : ''"
              @click="selectedUserId = person.user_id; manualEmail = person.email"
            >
              <div>
                <p class="font-bold text-foreground">{{ person.full_name || 'Unnamed User' }}</p>
                <p class="text-[11px] text-muted-foreground">{{ person.email }} · <span class="capitalize">{{ person.role }}</span></p>
              </div>
              <UserCheck v-if="selectedUserId === person.user_id" :size="16" class="text-primary" />
            </button>
            <p v-if="!nonAdminUsers.length" class="p-3 text-center text-muted-foreground text-[11px]">
              No eligible users found matching query.
            </p>
          </div>
        </div>

        <div class="relative flex items-center py-1">
          <div class="flex-grow border-t border-border" />
          <span class="mx-3 shrink text-[10px] font-bold uppercase text-muted-foreground">OR ENTER EMAIL</span>
          <div class="flex-grow border-t border-border" />
        </div>

        <!-- Manual Email Field -->
        <div class="space-y-1">
          <label for="admin-email-input" class="block font-bold text-foreground">Registered User Email</label>
          <input
            id="admin-email-input"
            v-model="manualEmail"
            type="email"
            placeholder="user@example.com"
            class="h-9 w-full rounded-md border border-border bg-white px-3 text-xs outline-none focus:border-primary focus:ring-2 focus:ring-primary/20"
          />
        </div>

        <footer class="pt-3 flex items-center justify-end gap-2 border-t border-border">
          <button
            type="button"
            class="rounded-lg border border-border px-4 py-2 font-bold text-muted-foreground hover:bg-secondary"
            @click="emit('close')"
          >
            Cancel
          </button>
          <button
            type="submit"
            :disabled="isSubmitting || (!selectedUserId && !manualEmail.trim())"
            class="inline-flex min-h-9 items-center gap-1.5 rounded-lg bg-emerald-700 px-4 font-bold text-white hover:bg-emerald-600 disabled:opacity-50"
          >
            <LoaderCircle v-if="isSubmitting" :size="13" class="animate-spin" />
            <ShieldCheck v-else :size="13" />
            Grant Admin Clearance
          </button>
        </footer>
      </form>
    </div>
  </div>
</template>
