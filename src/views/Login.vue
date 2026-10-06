<script setup>
import { ref } from "vue";
import { useRouter } from "vue-router";
import { useRoute } from "vue-router";
import { defineRule, useForm, useField } from "vee-validate";
import { required, email, min } from "@vee-validate/rules";
import { LoaderCircle } from "lucide-vue-next";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import animation from "@/assets/Login.lottie";
import { supabase } from "@/lib/supabase";
import { getAuthenticatedProfile } from "@/lib/auth";
import AuthPageLayout from "@/components/auth/AuthPageLayout.vue";
import PasswordField from "@/components/auth/PasswordField.vue";
import FeedbackMessage from "@/components/FeedbackMessage.vue";

import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";

defineRule("required", required);
defineRule("email", email);
defineRule("min", min);

const router = useRouter();
const route = useRoute();
const { validate } = useForm();
const loginType = ref(["student", "instructor", "super_admin"].includes(route.query.type) ? route.query.type : "student");
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

const handleSubmit = async () => {
  if (isSubmitting.value) return;
  serverError.value = "";
  successMessage.value = "";
  const result = await validate();

  if (!result.valid) {
    return;
  }

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
      throw new Error(`Signed in, but the LMS profile could not be loaded: ${profileError.message}`);
    }
    if (!user || !profile) {
      await supabase.auth.signOut();
      throw new Error("Your account has no LMS profile. If it was registered before setup.sql was run, the profile needs to be created in Supabase first.");
    }

    const permittedRoles = loginType.value === "student"
      ? ["student", "super_admin"]
      : loginType.value === "instructor"
        ? ["instructor", "super_admin"]
        : ["super_admin"];
    if (!permittedRoles.includes(profile.role)) {
      let accessMessage = `This account has the role "${profile.role}" and is not enabled for ${loginType.value.replace("_", " ")} sign-in.`;
      if (loginType.value === "instructor" && profile?.role === "student") {
        const { data: application } = await supabase
          .from("instructor_applications")
          .select("status")
          .eq("user_id", user.id)
          .maybeSingle();
        if (application?.status === "pending") {
          accessMessage = "Your instructor application is still under review. Sign in as a learner until it is approved.";
        }
      }
      await supabase.auth.signOut();
      throw new Error(accessMessage);
    }

    const { error: activityError } = await supabase
      .from("login_activity")
      .insert({ user_id: user.id });
    successMessage.value = activityError && activityError.code !== "23505"
      ? "Signed in. Daily activity tracking is not available yet."
      : "Signed in. Opening your learning space...";
    const redirect = typeof router.currentRoute.value.query.redirect === "string"
      ? router.currentRoute.value.query.redirect
      : loginType.value === "super_admin"
        ? "/admin"
        : loginType.value === "instructor"
          ? "/instructor"
          : "/dashboard";
    const safeRedirect = redirect.startsWith("/") && !redirect.startsWith("//")
      ? redirect
      : "/dashboard";
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
          <CardTitle class="text-4xl font-extrabold text-primary sm:text-5xl">
            Sign in
          </CardTitle>

          <CardDescription class="text-base text-primary/70 sm:text-lg">
            Choose your workspace, then sign in with your account.
          </CardDescription>
        </CardHeader>

        <CardContent>
          <form
            @submit.prevent="handleSubmit"
            class="grid grid-cols-1 gap-5 text-primary"
            novalidate
          >
            <FeedbackMessage :message="serverError" toast />
            <FeedbackMessage :message="successMessage" variant="success" />
            <fieldset class="grid grid-cols-3 border border-border rounded-full bg-white p-1">
              <legend class="sr-only">Sign-in type</legend>
              <button
                v-for="option in [{ id: 'student', label: 'Learner' }, { id: 'instructor', label: 'Instructor' }, { id: 'super_admin', label: 'Super admin' }]"
                :key="option.id"
                type="button"
                :aria-pressed="loginType === option.id"
                class="min-h-12 px-1 rounded-full text-sm font-bold outline-none transition-colors focus-visible:ring-2 focus-visible:ring-primary"
                :class="loginType === option.id ? 'bg-primary text-white' : 'text-muted-foreground hover:bg-secondary hover:text-foreground'"
                @click="loginType = option.id; serverError = ''; router.replace({ query: { ...route.query, type: option.id } })"
              >
                {{ option.label }}
              </button>
            </fieldset>
            <div class="space-y-2">
              <Label
                for="email"
                class="text-xl text-primary"
              >
                Email
              </Label>

              <Input
                id="email"
                v-model="emailValue"
                type="email"
                autocomplete="email"
                placeholder="you@example.com"
                class="h-12 border-primary/30 bg-white text-base"
                :aria-invalid="Boolean(emailError)"
                :aria-describedby="emailError ? 'login-email-error' : undefined"
              />

              <p
                v-if="emailError"
                id="login-email-error"
                role="alert"
                class="text-sm text-red-500"
              >
                {{ emailError }}
              </p>
            </div>

            <div class="space-y-2">
              <Label
                for="password"
                class="text-xl text-primary"
              >
                Password
              </Label>

              <PasswordField
                id="password"
                v-model="password"
                autocomplete="current-password"
                placeholder="Enter your password"
                :invalid="Boolean(passwordError)"
                :described-by="passwordError ? 'login-password-error' : undefined"
              />

              <p
                v-if="passwordError"
                id="login-password-error"
                role="alert"
                class="text-sm text-red-500"
              >
                {{ passwordError }}
              </p>
            </div>

            <div class="pt-2">
              <Button
                type="submit"
                :disabled="isSubmitting"
                class="w-full bg-primary p-6 text-xl font-bold text-white hover:bg-primary/90 disabled:cursor-not-allowed disabled:opacity-60"
              >
                <LoaderCircle v-if="isSubmitting" class="mr-2 inline animate-spin" :size="20" aria-hidden="true" />
                {{ isSubmitting ? 'Signing in...' : 'Login' }}
              </Button>
            </div>

            <div class="pt-2 text-center text-base text-primary/80">
              New here?
              <RouterLink
                to="/register"
                class="ml-1 font-semibold text-primary underline underline-offset-4"
              >
                Register
              </RouterLink>
            </div>
          </form>
        </CardContent>
      </Card>
  </AuthPageLayout>
</template>