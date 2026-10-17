<script setup>
import { ref } from "vue";
import { CheckCircle2, LoaderCircle, Mail, ShieldAlert, X } from "lucide-vue-next";
import { supabase } from "@/lib/supabase";

const props = defineProps({
  defaultEmail: { type: String, default: "" },
});

const emit = defineEmits(["close"]);

const email = ref(props.defaultEmail || "");
const loading = ref(false);
const error = ref("");
const success = ref(false);

async function handleReset() {
  if (!email.value.trim() || loading.value) return;
  error.value = "";
  success.value = false;

  if (!supabase) {
    error.value = "Authentication service is not configured.";
    return;
  }

  loading.value = true;
  try {
    const { error: resetError } = await supabase.auth.resetPasswordForEmail(
      email.value.trim().toLowerCase(),
      {
        redirectTo: `${window.location.origin}/login?reset=true`,
      }
    );
    if (resetError) throw resetError;
    success.value = true;
  } catch (err) {
    error.value = err.message || "Failed to send password reset email. Please try again.";
  } finally {
    loading.value = false;
  }
}
</script>

<template>
  <div class="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4 backdrop-blur-xs">
    <div
      class="w-full max-w-md overflow-hidden rounded-2xl border border-border bg-white p-6 shadow-2xl"
      role="dialog"
      aria-modal="true"
      aria-labelledby="forgot-title"
    >
      <div class="flex items-center justify-between pb-3 border-b border-border">
        <h2 id="forgot-title" class="text-xl font-black text-primary">Reset your password</h2>
        <button
          type="button"
          class="rounded-lg p-1.5 text-muted-foreground hover:bg-secondary hover:text-foreground"
          @click="emit('close')"
          aria-label="Close dialog"
        >
          <X :size="18" />
        </button>
      </div>

      <div v-if="success" class="my-6 space-y-4 text-center">
        <div class="mx-auto grid size-12 place-items-center rounded-full bg-emerald-100 text-emerald-800">
          <CheckCircle2 :size="24" />
        </div>
        <div class="space-y-1">
          <h3 class="text-lg font-bold text-foreground">Password reset email sent</h3>
          <p class="text-xs text-muted-foreground">
            We've sent password reset instructions to <strong class="text-foreground">{{ email }}</strong>. Please check your inbox and follow the link.
          </p>
        </div>
        <button
          type="button"
          class="mt-2 w-full rounded-lg bg-primary py-2.5 text-sm font-bold text-white hover:bg-primary/90"
          @click="emit('close')"
        >
          Return to Sign In
        </button>
      </div>

      <form v-else class="my-5 space-y-4" @submit.prevent="handleReset">
        <p class="text-xs text-muted-foreground leading-relaxed">
          Enter the email address associated with your Northstar Learning account, and we'll send you a recovery link to reset your password.
        </p>

        <div v-if="error" role="alert" class="rounded-lg border border-red-200 bg-red-50 p-3 text-xs text-red-800 flex items-start gap-2">
          <ShieldAlert :size="15" class="shrink-0 mt-0.5 text-red-600" />
          <span>{{ error }}</span>
        </div>

        <div class="space-y-1.5">
          <label for="recovery-email" class="block text-xs font-bold uppercase tracking-wider text-muted-foreground">
            Account Email Address
          </label>
          <div class="relative">
            <Mail :size="16" class="absolute left-3.5 top-1/2 -translate-y-1/2 text-muted-foreground" />
            <input
              id="recovery-email"
              v-model="email"
              type="email"
              required
              autocomplete="email"
              placeholder="e.g. learner@example.com"
              class="h-11 w-full rounded-lg border border-border bg-white pl-10 pr-3.5 text-sm outline-none focus:border-primary focus:ring-2 focus:ring-primary/20"
            />
          </div>
        </div>

        <div class="flex items-center justify-end gap-2 pt-2">
          <button
            type="button"
            class="rounded-lg border border-border px-4 py-2 text-xs font-bold text-muted-foreground hover:bg-secondary"
            @click="emit('close')"
          >
            Cancel
          </button>
          <button
            type="submit"
            :disabled="loading || !email.trim()"
            class="inline-flex min-h-10 items-center justify-center gap-2 rounded-lg bg-primary px-5 text-xs font-bold text-white hover:bg-primary/90 disabled:opacity-50"
          >
            <LoaderCircle v-if="loading" :size="14" class="animate-spin" />
            {{ loading ? "Sending Link..." : "Send Reset Link" }}
          </button>
        </div>
      </form>
    </div>
  </div>
</template>

