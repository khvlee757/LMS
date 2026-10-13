<script setup>
import { ref } from "vue";
import {
  Briefcase,
  Building,
  Check,
  CheckCircle2,
  Clock,
  Copy,
  ExternalLink,
  GraduationCap,
  LoaderCircle,
  Mail,
  Phone,
  ShieldCheck,
  User,
  X,
} from "lucide-vue-next";

const props = defineProps({
  application: { type: Object, required: true },
  reviewing: { type: Boolean, default: false },
});

const emit = defineEmits(["approve", "reject", "close"]);

const reviewNotes = ref(props.application.review_notes || "");
const copiedUrl = ref(false);

function copyLink() {
  if (!props.application.verification_url) return;
  navigator.clipboard.writeText(props.application.verification_url);
  copiedUrl.value = true;
  setTimeout(() => {
    copiedUrl.value = false;
  }, 2000);
}

function handleApprove() {
  emit("approve", { application: props.application, notes: reviewNotes.value });
}

function handleReject() {
  emit("reject", { application: props.application, notes: reviewNotes.value });
}
</script>

<template>
  <div class="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4 backdrop-blur-xs">
    <div
      class="flex max-h-[92vh] w-full max-w-2xl flex-col overflow-hidden rounded-2xl border border-border bg-white shadow-2xl"
      role="dialog"
      aria-modal="true"
    >
      <!-- Modal Header -->
      <header class="flex items-start justify-between border-b border-border bg-[#112922] p-5 text-white sm:px-6">
        <div class="flex items-center gap-3">
          <div class="grid size-12 shrink-0 place-items-center rounded-xl bg-emerald-600 font-extrabold text-white text-lg shadow-sm">
            {{ (application.profile?.full_name || application.profile?.email || 'I')[0].toUpperCase() }}
          </div>
          <div>
            <div class="flex items-center gap-2">
              <h2 class="text-lg font-black text-white sm:text-xl">
                {{ application.profile?.full_name || 'Educator Applicant' }}
              </h2>
              <span
                class="rounded-full px-2.5 py-0.5 text-[11px] font-bold capitalize"
                :class="{
                  'bg-amber-400 text-black': application.status === 'pending',
                  'bg-emerald-400 text-black': application.status === 'approved',
                  'bg-red-400 text-white': application.status === 'rejected',
                }"
              >
                {{ application.status }}
              </span>
            </div>
            <p class="text-xs text-emerald-300">
              Instructor Registration Verification Dossier
            </p>
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

      <!-- Scrollable Dossier Content -->
      <div class="flex-1 space-y-5 overflow-y-auto p-5 sm:p-6 text-sm text-foreground">
        <!-- Contact & Identity Bar -->
        <div class="grid gap-3 rounded-xl border border-border bg-secondary/40 p-4 sm:grid-cols-3 text-xs">
          <div class="flex items-center gap-2">
            <Mail :size="15" class="text-primary shrink-0" />
            <span class="truncate font-semibold">{{ application.profile?.email || 'No email' }}</span>
          </div>
          <div class="flex items-center gap-2">
            <Phone :size="15" class="text-primary shrink-0" />
            <span class="truncate font-semibold">{{ application.profile?.phone || 'No phone provided' }}</span>
          </div>
          <div class="flex items-center gap-2">
            <Clock :size="15" class="text-primary shrink-0" />
            <span class="text-muted-foreground">Applied {{ new Date(application.created_at).toLocaleDateString() }}</span>
          </div>
        </div>

        <!-- Professional Background -->
        <div class="grid gap-4 sm:grid-cols-2">
          <div class="rounded-xl border border-border p-4 bg-white">
            <div class="flex items-center gap-2 text-xs font-bold uppercase tracking-wider text-muted-foreground">
              <Building :size="14" class="text-primary" /> Institution / School
            </div>
            <p class="mt-2 text-base font-extrabold text-foreground">{{ application.organization }}</p>
            <p class="text-xs text-muted-foreground font-semibold mt-0.5">{{ application.professional_title }}</p>
          </div>

          <div class="rounded-xl border border-border p-4 bg-white">
            <div class="flex items-center gap-2 text-xs font-bold uppercase tracking-wider text-muted-foreground">
              <Briefcase :size="14" class="text-primary" /> Teaching Experience
            </div>
            <p class="mt-2 text-base font-extrabold text-foreground">
              {{ application.experience_years }} {{ application.experience_years === 1 ? 'Year' : 'Years' }}
            </p>
            <p class="text-xs text-primary font-semibold mt-0.5">Field: {{ application.expertise }}</p>
          </div>
        </div>

        <!-- Verification Credentials URL -->
        <div class="rounded-xl border border-emerald-500/30 bg-emerald-50/50 p-4">
          <div class="flex items-center justify-between">
            <span class="flex items-center gap-1.5 text-xs font-bold uppercase tracking-wider text-emerald-900">
              <ShieldCheck :size="15" class="text-emerald-700" /> External Verification Link
            </span>
            <span class="text-[11px] text-emerald-800">Submitted by applicant</span>
          </div>
          <div class="mt-2.5 flex flex-wrap items-center gap-2">
            <a
              :href="application.verification_url"
              target="_blank"
              rel="noopener noreferrer"
              class="inline-flex items-center gap-1.5 rounded-lg bg-emerald-700 px-3.5 py-2 text-xs font-bold text-white hover:bg-emerald-800"
            >
              <ExternalLink :size="13" /> Open Credential / Portfolio Link
            </a>
            <button
              type="button"
              class="inline-flex items-center gap-1.5 rounded-lg border border-emerald-600/40 bg-white px-3 py-2 text-xs font-bold text-emerald-900 hover:bg-emerald-100"
              @click="copyLink"
            >
              <Check v-if="copiedUrl" :size="13" class="text-emerald-700" />
              <Copy v-else :size="13" />
              {{ copiedUrl ? 'Copied' : 'Copy URL' }}
            </button>
          </div>
          <p class="mt-2 truncate font-mono text-[11px] text-emerald-800/80">
            {{ application.verification_url }}
          </p>
        </div>

        <!-- Qualifications -->
        <div class="rounded-xl border border-border p-4 bg-white">
          <p class="text-xs font-bold uppercase tracking-wider text-muted-foreground">
            Academic & Professional Qualifications
          </p>
          <p class="mt-2 whitespace-pre-line text-sm leading-relaxed text-foreground">
            {{ application.qualification }}
          </p>
        </div>

        <!-- Teaching Philosophy -->
        <div class="rounded-xl border border-border p-4 bg-white">
          <p class="text-xs font-bold uppercase tracking-wider text-muted-foreground">
            Course Objectives & Teaching Statement
          </p>
          <p class="mt-2 whitespace-pre-line text-sm leading-relaxed text-foreground">
            {{ application.teaching_statement }}
          </p>
        </div>

        <!-- Reviewer Notes & Decision Area -->
        <div class="rounded-xl border border-border bg-secondary/30 p-4 space-y-2.5">
          <label for="review-notes-input" class="block text-xs font-bold uppercase tracking-wider text-muted-foreground">
            Super Admin Review Notes / Audit Trail
          </label>
          <textarea
            id="review-notes-input"
            v-model="reviewNotes"
            rows="2"
            placeholder="Add internal verification notes or reason for approval/rejection..."
            class="w-full rounded-lg border border-border bg-white px-3 py-2 text-xs outline-none focus:border-primary focus:ring-2 focus:ring-primary/20"
          />
          <p v-if="application.reviewed_at" class="text-[11px] text-muted-foreground">
            Last reviewed on {{ new Date(application.reviewed_at).toLocaleString() }}
          </p>
        </div>
      </div>

      <!-- Action Footer -->
      <footer class="flex flex-wrap items-center justify-between gap-3 border-t border-border bg-secondary/20 p-4 sm:px-6">
        <button
          type="button"
          class="rounded-lg border border-border px-4 py-2 text-xs font-bold text-muted-foreground hover:bg-white hover:text-foreground"
          @click="emit('close')"
        >
          Close
        </button>

        <div class="flex items-center gap-2">
          <button
            type="button"
            :disabled="reviewing"
            class="inline-flex min-h-10 items-center gap-1.5 rounded-lg border border-red-200 bg-white px-4 text-xs font-bold text-red-700 hover:bg-red-50 disabled:opacity-50"
            @click="handleReject"
          >
            <X :size="14" /> Reject Application
          </button>
          <button
            type="button"
            :disabled="reviewing"
            class="inline-flex min-h-10 items-center gap-1.5 rounded-lg bg-emerald-700 px-5 text-xs font-bold text-white hover:bg-emerald-600 disabled:opacity-50"
            @click="handleApprove"
          >
            <LoaderCircle v-if="reviewing" :size="14" class="animate-spin" />
            <CheckCircle2 v-else :size="14" />
            {{ application.status === 'approved' ? 'Update & Confirm Approval' : 'Verify & Approve Instructor' }}
          </button>
        </div>
      </footer>
    </div>
  </div>
</template>

