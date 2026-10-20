<script setup>
import { onMounted, ref } from "vue";
import { useRouter } from "vue-router";
import { defineRule, useForm, useField } from "vee-validate";
import { required, email, min } from "@vee-validate/rules";
import {
  ArrowLeft,
  Eye,
  EyeOff,
  LoaderCircle,
  Lock,
  ShieldAlert,
  ShieldCheck,
} from "lucide-vue-next";
import { supabase } from "@/lib/supabase";
import { getAuthenticatedProfile } from "@/lib/auth";
import northstarMark from "@/assets/northstar-mark.png";

defineRule("required", required);
defineRule("email", email);
defineRule("min", min);

const router = useRouter();
const { validate } = useForm();
const isSubmitting = ref(false);
const showPassword = ref(false);
const serverError = ref("");
const successMessage = ref("");

const { value: emailValue, errorMessage: emailError } = useField(
  "email",
  "required|email"
);

const { value: password, errorMessage: passwordError } = useField(
  "password",
  "required|min:8"
);

onMounted(async () => {
  const { user, profile } = await getAuthenticatedProfile();
  if (user && profile?.role === "super_admin") {
    await router.replace("/admin");
  }
});

const handleAdminLogin = async () => {
  if (isSubmitting.value) return;
  serverError.value = "";
  successMessage.value = "";

  const result = await validate();
  if (!result.valid) return;

  if (!supabase) {
    serverError.value = "Supabase client is not configured. Check environment variables.";
    return;
  }

  isSubmitting.value = true;
  try {
    const { error: authError } = await supabase.auth.signInWithPassword({
      email: emailValue.value.trim().toLowerCase(),
      password: password.value,
    });
    if (authError) throw authError;

    const { user, profile, error: profileError } = await getAuthenticatedProfile();
    if (profileError || !user || !profile) {
      await supabase.auth.signOut();
      throw new Error(
        profileError?.message ||
        "Authenticated, but profile record was not found."
      );
    }

    if (profile.role !== "super_admin") {
      await supabase.auth.signOut();
      throw new Error(
        `Access denied. This account has the role "${profile.role}". Only accounts with "super_admin" clearance can enter this console.`
      );
    }

    // Log login activity
    await supabase.from("login_activity").insert({ user_id: user.id });

    successMessage.value = "Security clearance verified. Opening Super Admin Console...";
    setTimeout(async () => {
      await router.replace("/admin");
    }, 400);
  } catch (err) {
    serverError.value = err.message || "Failed to sign in. Verify your credentials.";
  } finally {
    isSubmitting.value = false;
  }
};
</script>

<template>
  <div class="min-h-screen bg-[#0d211b] flex flex-col justify-between p-4 sm:p-6 lg:p-8 text-white">
    <!-- Top Navigation -->
    <header class="flex items-center justify-between max-w-5xl mx-auto w-full">
      <div class="flex items-center gap-3">
        <img :src="northstarMark" alt="Northstar" class="size-9 drop-shadow" />
        <div>
          <span class="block text-base font-black tracking-tight text-white">Northstar Learning</span>
          <span class="block text-[11px] font-bold text-emerald-400">Executive Console</span>
        </div>
      </div>

      <router-link
        to="/login"
        class="inline-flex items-center gap-1.5 text-xs font-bold text-slate-300 hover:text-white transition-colors"
      >
        <ArrowLeft :size="14" /> Back to Learner Sign in
      </router-link>
    </header>

    <!-- Main Card Container -->
    <main class="w-full max-w-md mx-auto my-8">
      <div class="rounded-2xl border border-white/10 bg-[#122b23] p-7 sm:p-8 shadow-2xl backdrop-blur-md">
        <!-- Badge & Title -->
        <div class="text-center space-y-2">
          <div class="inline-flex items-center gap-1.5 rounded-full bg-emerald-500/20 px-3 py-1 text-xs font-black text-emerald-300 border border-emerald-500/30">
            <ShieldCheck :size="15" /> Super Admin Authentication
          </div>
          <h1 class="text-2xl sm:text-3xl font-black text-white">System Sign In</h1>
          <p class="text-xs text-slate-300">
            Enter administrative credentials to access platform controls.
          </p>
        </div>

        <!-- Feedback notices -->
        <div v-if="serverError" role="alert" class="mt-5 rounded-lg border border-red-500/30 bg-red-950/60 p-3.5 text-xs text-red-200">
          <div class="flex items-start gap-2">
            <ShieldAlert :size="16" class="shrink-0 mt-0.5 text-red-400" />
            <span>{{ serverError }}</span>
          </div>
        </div>

        <div v-if="successMessage" role="status" class="mt-5 rounded-lg border border-emerald-500/30 bg-emerald-950/60 p-3.5 text-xs text-emerald-200">
          <div class="flex items-center gap-2">
            <ShieldCheck :size="16" class="shrink-0 text-emerald-400" />
            <span>{{ successMessage }}</span>
          </div>
        </div>

        <!-- Form -->
        <form class="mt-6 space-y-4" @submit.prevent="handleAdminLogin" novalidate>
          <!-- Email field -->
          <div class="space-y-1.5">
            <label for="admin-email" class="block text-xs font-bold uppercase tracking-wider text-slate-300">
              Admin Email
            </label>
            <input
              id="admin-email"
              v-model="emailValue"
              type="email"
              autocomplete="email"
              placeholder="admin@northstar.org"
              class="h-11 w-full rounded-lg border border-white/20 bg-black/20 px-3.5 text-sm text-white placeholder-slate-500 outline-none transition-colors focus:border-emerald-400 focus:ring-2 focus:ring-emerald-400/20"
              :class="{ 'border-red-500': Boolean(emailError) }"
            />
            <p v-if="emailError" class="text-xs text-red-400">{{ emailError }}</p>
          </div>

          <!-- Password field -->
          <div class="space-y-1.5">
            <label for="admin-password" class="block text-xs font-bold uppercase tracking-wider text-slate-300">
              Password
            </label>
            <div class="relative">
              <input
                id="admin-password"
                v-model="password"
                :type="showPassword ? 'text' : 'password'"
                autocomplete="current-password"
                placeholder="••••••••••••"
                class="h-11 w-full rounded-lg border border-white/20 bg-black/20 pl-3.5 pr-10 text-sm text-white placeholder-slate-500 outline-none transition-colors focus:border-emerald-400 focus:ring-2 focus:ring-emerald-400/20"
                :class="{ 'border-red-500': Boolean(passwordError) }"
              />
              <button
                type="button"
                class="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-white"
                @click="showPassword = !showPassword"
                :aria-label="showPassword ? 'Hide password' : 'Show password'"
              >
                <EyeOff v-if="showPassword" :size="16" />
                <Eye v-else :size="16" />
              </button>
            </div>
            <p v-if="passwordError" class="text-xs text-red-400">{{ passwordError }}</p>
          </div>

          <!-- Submit button -->
          <button
            type="submit"
            :disabled="isSubmitting"
            class="mt-2 flex min-h-12 w-full items-center justify-center gap-2 rounded-lg bg-emerald-600 px-4 text-sm font-bold text-white transition-all hover:bg-emerald-500 focus-visible:ring-2 focus-visible:ring-emerald-400 disabled:opacity-50"
          >
            <LoaderCircle v-if="isSubmitting" :size="17" class="animate-spin" />
            <Lock v-else :size="15" />
            {{ isSubmitting ? "Authenticating Clearance..." : "Access Admin Console" }}
          </button>
        </form>

        <!-- Security Notice -->
        <div class="mt-6 rounded-lg border border-white/5 bg-black/30 p-3 text-[11px] text-slate-400 leading-relaxed text-center">
          Security policy: Only accounts assigned the <code class="font-mono text-emerald-300">super_admin</code> role can authenticate here.
        </div>
      </div>
    </main>

    <!-- Footer -->
    <footer class="text-center text-xs text-slate-500 py-2">
      Northstar Learning Management Platform · Secure Administrator Gateway
    </footer>
  </div>
</template>

