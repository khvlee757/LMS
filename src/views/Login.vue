<script setup>
import { onMounted, ref } from "vue";
import { useRouter, useRoute } from "vue-router";
import { defineRule, useForm, useField } from "vee-validate";
import { required, email, min } from "@vee-validate/rules";
import {
  AlertCircle,
  GraduationCap,
  LoaderCircle,
  ShieldCheck,
  SquarePen,
} from "lucide-vue-next";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import animation from "@/assets/Login.lottie";
import { supabase } from "@/lib/supabase";
import { getAuthenticatedProfile } from "@/lib/auth";
import AuthPageLayout from "@/components/auth/AuthPageLayout.vue";
import PasswordField from "@/components/auth/PasswordField.vue";
import FeedbackMessage from "@/components/FeedbackMessage.vue";
import ForgotPasswordModal from "@/components/auth/ForgotPasswordModal.vue";
import SocialLoginButtons from "@/components/auth/SocialLoginButtons.vue";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";

defineRule("required", required);
defineRule("email", email);
defineRule("min", min);

const router = useRouter();
const route = useRoute();
const { validate } = useForm();
const loginType = ref(["student", "instructor"].includes(route.query.type) ? route.query.type : "student");
const isSubmitting = ref(false);
const rememberMe = ref(true);
const showForgotPassword = ref(false);
const serverError = ref("");
const successMessage = ref("");

const { value: emailValue, errorMessage: emailError } = useField("email", "required|email");
const { value: password, errorMessage: passwordError } = useField("password", "required|min:8");

onMounted(() => {
  const savedEmail = localStorage.getItem("northstar_remembered_email");
  if (savedEmail) {
    emailValue.value = savedEmail;
  }
});

const handleSubmit = async () => {
  if (isSubmitting.value) return;
  serverError.value = "";
  successMessage.value = "";
  const result = await validate();

  if (!result.valid) return;

  if (!supabase) {
    serverError.value = "Sign-in is not configured yet. Add your Supabase URL and publishable key.";
    return;
  }

  isSubmitting.value = true;
  try {
    const { error } = await supabase.auth.signInWithPassword({
      email: emailValue.value.trim().toLowerCase(),
      password: password.value,
    });
    if (error) throw error;

    const { user, profile, error: profileError } = await getAuthenticatedProfile();
    if (profileError) {
      await supabase.auth.signOut();
      throw new Error(`Signed in, but the profile could not be loaded: ${profileError.message}`);
    }
    if (!user || !profile) {
      await supabase.auth.signOut();
      throw new Error("Your account has no LMS profile record.");
    }

    const permittedRoles = loginType.value === "student"
      ? ["student", "super_admin"]
      : ["instructor", "super_admin"];

    if (!permittedRoles.includes(profile.role)) {
      let accessMessage = `This account has the role "${profile.role}" and is not enabled for ${loginType.value.replace("_", " ")} sign-in.`;
      if (loginType.value === "instructor" && profile?.role === "student") {
        const { data: application } = await supabase
          .from("instructor_applications")
          .select("status")
          .eq("user_id", user.id)
          .maybeSingle();

        if (!application && user.user_metadata?.instructor_application) {
          const m = user.user_metadata.instructor_application;
          await supabase.from("instructor_applications").upsert({
            user_id: user.id,
            organization: m.organization || "Independent",
            professional_title: m.professional_title || "Instructor",
            expertise: m.expertise || "General",
            experience_years: Number(m.experience_years) || 0,
            qualification: m.qualification || "Self-certified",
            verification_url: m.verification_url || "",
            teaching_statement: m.teaching_statement || "",
            status: "pending",
          }, { onConflict: "user_id" }).catch(() => {});
        }

        if (application?.status === "pending" || user.user_metadata?.instructor_application) {
          accessMessage = "Your instructor application is still under review. Sign in as a learner until it is approved.";
        }
      }
      await supabase.auth.signOut();
      throw new Error(accessMessage);
    }

    // Persist session email preference if Remember Me is checked
    if (rememberMe.value) {
      localStorage.setItem("northstar_remembered_email", emailValue.value.trim());
    } else {
      localStorage.removeItem("northstar_remembered_email");
    }

    const { error: activityError } = await supabase
      .from("login_activity")
      .insert({ user_id: user.id });

    successMessage.value = profile.role === "super_admin"
      ? "Signed in. Opening executive admin console..."
      : activityError && activityError.code !== "23505"
        ? "Signed in. Daily activity tracking is not available yet."
        : "Signed in. Opening your learning space...";

    const qRedirect = router.currentRoute.value.query.redirect;
    const defaultRoute = profile.role === "super_admin" ? "/admin" : profile.role === "instructor" ? "/instructor" : "/dashboard";
    const safeRedirect = typeof qRedirect === "string" && qRedirect.startsWith("/") && !qRedirect.startsWith("//") ? qRedirect : defaultRoute;
    await router.replace(safeRedirect);
  } catch (error) {
    serverError.value = error.message || "We couldn't sign you in. Check your details and try again.";
  } finally {
    isSubmitting.value = false;
  }
};
</script>

<template>
  <AuthPageLayout :animation-src="animation">
    <Card class="w-full max-w-lg border-0 bg-transparent shadow-none">
      <CardHeader class="space-y-2">
        <CardTitle class="text-4xl font-extrabold text-primary sm:text-5xl">Sign in</CardTitle>
        <CardDescription class="text-base text-primary/70 sm:text-lg">Choose your workspace, then sign in with your account.</CardDescription>
      </CardHeader>

      <CardContent>
        <form @submit.prevent="handleSubmit" class="grid grid-cols-1 gap-5 text-primary" novalidate>
          <FeedbackMessage :message="serverError" toast />
          <FeedbackMessage :message="successMessage" variant="success" />

          <!-- Workspace Selection Toggle -->
          <div class="space-y-2">
            <fieldset class="grid grid-cols-2 border border-border rounded-full bg-white p-1">
              <legend class="sr-only">Sign-in workspace type</legend>
              <button
                v-for="option in [{ id: 'student', label: 'Learner' }, { id: 'instructor', label: 'Instructor' }]"
                :key="option.id"
                type="button"
                :aria-pressed="loginType === option.id"
                class="min-h-12 px-1 rounded-full text-sm font-bold outline-none transition-colors focus-visible:ring-2 focus-visible:ring-primary"
                :class="loginType === option.id ? 'bg-primary text-white shadow-xs' : 'text-muted-foreground hover:bg-secondary hover:text-foreground'"
                @click="loginType = option.id; serverError = ''; router.replace({ query: { ...route.query, type: option.id } })"
              >
                {{ option.label }}
              </button>
            </fieldset>

            <div v-if="loginType === 'student'" class="rounded-xl border border-primary/15 bg-primary/5 p-3 text-xs leading-relaxed text-primary">
              <span class="font-bold flex items-center gap-1.5"><GraduationCap :size="15" /> Learner Workspace:</span>
              <p class="mt-0.5 text-primary/80">Access course catalog, study materials, quizzes, and your personal progress.</p>
            </div>
            <div v-else class="rounded-xl border border-primary/15 bg-primary/5 p-3 text-xs leading-relaxed text-primary">
              <span class="font-bold flex items-center gap-1.5"><SquarePen :size="15" /> Instructor Studio:</span>
              <p class="mt-0.5 text-primary/80">Manage course curricula, upload digital books, track students, and grade lessons.</p>
            </div>
          </div>

          <!-- Email Field with Clear Inline Format Requirements -->
          <div class="space-y-1.5">
            <Label for="email" class="text-base font-semibold text-primary">Email</Label>
            <Input
              id="email"
              v-model="emailValue"
              type="email"
              autocomplete="email"
              placeholder="e.g. learner@example.com"
              class="h-12 border-primary/30 bg-white text-base"
              :class="{ 'border-red-500 focus-visible:ring-red-400': Boolean(emailError) }"
              :aria-invalid="Boolean(emailError)"
              :aria-describedby="emailError ? 'login-email-error' : 'email-hint'"
            />
            <p v-if="emailError" id="login-email-error" role="alert" class="flex items-center gap-1 text-xs text-red-500">
              <AlertCircle :size="13" /> {{ emailError }}
            </p>
            <p v-else id="email-hint" class="text-xs text-muted-foreground">
              Enter the email address registered with your Northstar account.
            </p>
          </div>

          <!-- Password Field with inline validation & visible Forgot Password -->
          <div class="space-y-1.5">
            <div class="flex items-center justify-between">
              <Label for="password" class="text-base font-semibold text-primary">Password</Label>
              <button
                type="button"
                class="text-xs font-bold text-primary underline underline-offset-4 hover:text-primary/80"
                @click="showForgotPassword = true"
              >
                Forgot password?
              </button>
            </div>
            <PasswordField
              id="password"
              v-model="password"
              autocomplete="current-password"
              placeholder="Enter your password (min. 8 characters)"
              :invalid="Boolean(passwordError)"
              :described-by="passwordError ? 'login-password-error' : 'password-hint'"
            />
            <p v-if="passwordError" id="login-password-error" role="alert" class="flex items-center gap-1 text-xs text-red-500">
              <AlertCircle :size="13" /> {{ passwordError }}
            </p>
            <p v-else id="password-hint" class="text-xs text-muted-foreground">
              Minimum 8 characters required.
            </p>
          </div>

          <!-- Persistent Session / Remember Me Option -->
          <div class="flex items-center justify-between pt-1">
            <label class="flex items-center gap-2 cursor-pointer select-none text-sm font-semibold text-primary">
              <input
                v-model="rememberMe"
                type="checkbox"
                class="size-4 rounded border-primary/30 accent-primary"
              />
              Remember me on this device
            </label>
          </div>

          <!-- Submit Button -->
          <div class="pt-1">
            <Button
              type="submit"
              :disabled="isSubmitting"
              class="w-full bg-primary p-5 text-lg font-bold text-white hover:bg-primary/90 disabled:cursor-not-allowed disabled:opacity-60"
            >
              <LoaderCircle v-if="isSubmitting" class="mr-2 inline animate-spin" :size="20" aria-hidden="true" />
              {{ isSubmitting ? 'Signing in...' : 'Sign in' }}
            </Button>
          </div>

          
          <!-- Register and Admin Links -->
          <div class="pt-2 text-center text-sm text-primary/80">
            New here?
            <RouterLink to="/register" class="ml-1 font-bold text-primary underline underline-offset-4">
              Create an account
            </RouterLink>
          </div>

          <div class="border-t border-border/80 pt-4 text-center">
            <RouterLink
              to="/admin/login"
              class="inline-flex items-center gap-1.5 text-xs font-bold text-muted-foreground transition-colors hover:text-primary"
            >
              <ShieldCheck :size="13" /> Platform Administrator? Sign in here
            </RouterLink>
          </div>
        </form>
      </CardContent>
    </Card>

    <!-- Forgot Password Recovery Modal -->
    <ForgotPasswordModal
      v-if="showForgotPassword"
      :default-email="emailValue"
      @close="showForgotPassword = false"
    />
  </AuthPageLayout>
</template>