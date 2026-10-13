<script setup>
import { computed, onMounted, ref } from "vue";
import {
  Check,
  Clock,
  ExternalLink,
  Eye,
  LoaderCircle,
  Search,
  ShieldCheck,
  UserCheck,
  X,
} from "lucide-vue-next";
import { useAdminData } from "@/lib/useAdminData";
import InstructorVerificationModal from "@/components/admin/InstructorVerificationModal.vue";

const {
  applications,
  loading,
  error,
  notice,
  reviewApplication,
  fetchAdminData,
} = useAdminData();

onMounted(async () => {
  await fetchAdminData();
});

const searchQuery = ref("");
const statusFilter = ref("pending");
const reviewingId = ref("");
const activeModalApplication = ref(null);

const filteredApplications = computed(() => {
  let list = applications.value;
  if (statusFilter.value !== "all") {
    list = list.filter((app) => app.status === statusFilter.value);
  }
  const q = searchQuery.value.trim().toLowerCase();
  if (q) {
    list = list.filter((app) =>
      (app.profile?.full_name || "").toLowerCase().includes(q) ||
      (app.profile?.email || "").toLowerCase().includes(q) ||
      (app.organization || "").toLowerCase().includes(q) ||
      (app.expertise || "").toLowerCase().includes(q)
    );
  }
  return list;
});

async function handleReview(application, status, notes = "") {
  reviewingId.value = application.user_id;
  await reviewApplication(application, status, notes);
  reviewingId.value = "";
  if (activeModalApplication.value?.user_id === application.user_id) {
    activeModalApplication.value = null;
  }
}
</script>

<template>
  <div class="space-y-6">
    <header class="flex flex-wrap items-center justify-between gap-4">
      <div>
        <h1 class="text-3xl font-extrabold text-foreground sm:text-4xl">Instructor Application Reviews</h1>
        <p class="mt-1 text-sm text-muted-foreground">
          Inspect collected credentials, verify background URLs, and grant instructor publishing access.
        </p>
      </div>
      <div class="text-xs font-bold text-muted-foreground">
        {{ applications.length }} Total Applications on Record
      </div>
    </header>

    <div v-if="error" role="alert" class="rounded-md border border-red-200 bg-red-50 p-4 text-sm text-red-800">
      {{ error }}
    </div>
    <div v-if="notice" role="status" class="rounded-md border border-emerald-200 bg-emerald-50 p-4 text-sm text-emerald-800">
      {{ notice }}
    </div>

    <!-- Filter & Search Controls -->
    <div class="flex flex-col gap-4 rounded-xl border border-border bg-white p-4 shadow-xs sm:flex-row sm:items-center sm:justify-between">
      <!-- Tabs -->
      <div class="flex flex-wrap gap-1.5">
        <button
          v-for="tab in [
            { id: 'pending', label: 'Pending Review', count: applications.filter(a => a.status === 'pending').length },
            { id: 'approved', label: 'Approved', count: applications.filter(a => a.status === 'approved').length },
            { id: 'rejected', label: 'Rejected', count: applications.filter(a => a.status === 'rejected').length },
            { id: 'all', label: 'All', count: applications.length },
          ]"
          :key="tab.id"
          type="button"
          class="inline-flex items-center gap-1.5 rounded-lg px-3 py-1.5 text-xs font-bold transition-colors"
          :class="statusFilter === tab.id ? 'bg-primary text-white shadow-xs' : 'bg-secondary text-muted-foreground hover:text-foreground'"
          @click="statusFilter = tab.id"
        >
          <span>{{ tab.label }}</span>
          <span
            class="rounded-full px-1.5 py-0.2 text-[10px]"
            :class="statusFilter === tab.id ? 'bg-white/20 text-white font-black' : 'bg-white text-muted-foreground'"
          >
            {{ tab.count }}
          </span>
        </button>
      </div>

      <!-- Search input -->
      <div class="relative w-full sm:max-w-xs">
        <Search :size="15" class="absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground" />
        <input
          v-model="searchQuery"
          type="search"
          placeholder="Search by name, email, or school..."
          class="h-9 w-full rounded-md border border-border bg-white pl-8 pr-3 text-xs outline-none focus:border-primary focus:ring-2 focus:ring-primary/20"
        />
      </div>
    </div>

    <!-- Applications List -->
    <div v-if="!filteredApplications.length" class="rounded-xl border border-dashed border-border bg-white px-6 py-16 text-center text-sm text-muted-foreground">
      No applications found matching your criteria.
    </div>

    <div v-else class="space-y-4">
      <article
        v-for="app in filteredApplications"
        :key="app.user_id"
        class="rounded-xl border border-border bg-white p-5 shadow-xs transition-shadow hover:shadow-md sm:p-6"
      >
        <!-- Header -->
        <div class="flex flex-wrap items-start justify-between gap-4 border-b border-border/80 pb-4">
          <div class="flex items-center gap-3">
            <span class="grid size-11 place-items-center rounded-xl bg-secondary font-black text-primary text-base">
              {{ (app.profile?.full_name || app.profile?.email || 'A')[0].toUpperCase() }}
            </span>
            <div>
              <div class="flex items-center gap-2">
                <h2 class="text-lg font-extrabold text-foreground">
                  {{ app.profile?.full_name || 'Educator Applicant' }}
                </h2>
                <span class="text-xs text-muted-foreground">({{ app.profile?.email }})</span>
              </div>
              <p class="text-xs font-semibold text-primary">
                {{ app.professional_title }} at {{ app.organization }} · {{ app.experience_years }} years experience
              </p>
              <p class="text-[11px] text-muted-foreground mt-0.5">
                Submitted on {{ new Date(app.created_at).toLocaleDateString() }}
                <span v-if="app.profile?.phone"> · Phone: {{ app.profile.phone }}</span>
              </p>
            </div>
          </div>

          <div class="flex items-center gap-2">
            <span
              class="inline-flex items-center gap-1 rounded-full px-2.5 py-0.5 text-xs font-bold capitalize"
              :class="{
                'bg-amber-100 text-amber-800': app.status === 'pending',
                'bg-emerald-100 text-emerald-800': app.status === 'approved',
                'bg-red-100 text-red-800': app.status === 'rejected',
              }"
            >
              <Clock v-if="app.status === 'pending'" :size="12" />
              <Check v-else-if="app.status === 'approved'" :size="12" />
              <X v-else :size="12" />
              {{ app.status }}
            </span>
          </div>
        </div>

        <!-- Details Preview -->
        <div class="mt-4 grid gap-3 text-xs sm:grid-cols-2">
          <div class="rounded-lg bg-secondary/30 p-3">
            <span class="font-bold uppercase text-muted-foreground text-[10px]">Subject Expertise</span>
            <p class="mt-1 font-semibold text-foreground">{{ app.expertise }}</p>
          </div>

          <div class="rounded-lg bg-secondary/30 p-3">
            <span class="font-bold uppercase text-muted-foreground text-[10px]">Verification Link</span>
            <p class="mt-1 truncate">
              <a
                :href="app.verification_url"
                target="_blank"
                rel="noopener noreferrer"
                class="inline-flex items-center gap-1 font-bold text-primary hover:underline"
              >
                {{ app.verification_url }} <ExternalLink :size="11" />
              </a>
            </p>
          </div>
        </div>

        <!-- Action Bar -->
        <footer class="mt-4 flex flex-wrap items-center justify-between gap-3 border-t border-border pt-4">
          <button
            type="button"
            class="inline-flex items-center gap-1.5 rounded-lg border border-primary/30 bg-primary/5 px-3.5 py-2 text-xs font-bold text-primary hover:bg-primary/10"
            @click="activeModalApplication = app"
          >
            <Eye :size="14" /> Inspect & Verify Full Details
          </button>

          <div class="flex items-center gap-2">
            <button
              v-if="app.status === 'pending'"
              type="button"
              :disabled="reviewingId === app.user_id"
              class="inline-flex min-h-9 items-center gap-1 rounded-md border border-border px-3 text-xs font-bold text-foreground hover:bg-secondary disabled:opacity-50"
              @click="handleReview(app, 'rejected')"
            >
              Reject
            </button>
            <button
              type="button"
              :disabled="reviewingId === app.user_id"
              class="inline-flex min-h-9 items-center gap-1.5 rounded-md bg-primary px-4 text-xs font-bold text-white hover:bg-primary/90 disabled:opacity-50"
              @click="handleReview(app, 'approved')"
            >
              <LoaderCircle v-if="reviewingId === app.user_id" :size="13" class="animate-spin" />
              <Check v-else :size="13" />
              {{ app.status === 'approved' ? 'Approved' : 'Verify & Approve' }}
            </button>
          </div>
        </footer>
      </article>
    </div>

    <!-- Full Verification Dossier Modal -->
    <InstructorVerificationModal
      v-if="activeModalApplication"
      :application="activeModalApplication"
      :reviewing="reviewingId === activeModalApplication?.user_id"
      @approve="handleReview($event.application, 'approved', $event.notes)"
      @reject="handleReview($event.application, 'rejected', $event.notes)"
      @close="activeModalApplication = null"
    />
  </div>
</template>
