<script setup>
import { onBeforeUnmount, ref, watch } from "vue";
import { useRouter } from "vue-router";
import { defineRule, useForm, useField } from "vee-validate";
import { required } from "@vee-validate/rules";
import { LoaderCircle } from "lucide-vue-next";

import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import animation from "@/assets/school.lottie";
import { supabase } from "@/lib/supabase";
import AuthPageLayout from "@/components/auth/AuthPageLayout.vue";
import PasswordField from "@/components/auth/PasswordField.vue";
import PasswordStrength from "@/components/auth/PasswordStrength.vue";
import FeedbackMessage from "@/components/FeedbackMessage.vue";
import InstructorVerificationFields from "@/components/auth/InstructorVerificationFields.vue";
import RegisterAccountFields from "@/components/auth/RegisterAccountFields.vue";

defineRule("required", required);
defineRule("fullName", (v) => String(v ?? "").trim().split(/\s+/).filter(Boolean).length >= 2 || "Enter your first and last name.");
defineRule("emailFormat", (v) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(String(v ?? "").trim()) || "Enter a valid email address.");
defineRule("internationalPhone", (v) => /^\+[1-9]\d{7,14}$/.test(String(v ?? "").replace(/[\s().-]/g, "")) || "Enter an international number with country code, such as +1 202 555 0123.");
defineRule("strongPassword", (v) => {
  const c = String(v ?? "");
  return (c.length >= 8 && /[a-z]/.test(c) && /[A-Z]/.test(c) && /\d/.test(c) && /[^A-Za-z0-9\s]/.test(c)) ||
    "Use at least 8 characters with uppercase, lowercase, number, and symbol.";
});

const router = useRouter();
const { validate, validateField } = useForm();
const isSubmitting = ref(false);
const accountType = ref("student");
const serverError = ref("");
const successMessage = ref("");
let redirectTimer;

defineRule("instructorRequired", (value) =>
  accountType.value !== "instructor" || String(value ?? "").trim().length > 0 ||
  "Required for instructor review."
);
defineRule("instructorExperience", (value) =>
  accountType.value !== "instructor" ||
  (String(value ?? "").trim() !== "" && Number.isInteger(Number(value)) && Number(value) >= 0 && Number(value) <= 60) ||
  "Enter experience from 0 to 60 years."
);
defineRule("verificationUrl", (value) =>
  accountType.value !== "instructor" ||
  /^https?:\/\/[^\s]+\.[^\s]+$/i.test(String(value ?? "").trim()) ||
  "Enter a public http or https verification link."
);

const { value: name, errorMessage: nameError } = useField("name", "required|fullName");
const { value: emailValue, errorMessage: emailError } = useField("email", "required|emailFormat");
const { value: phone, errorMessage: phoneError } = useField("phone", "required|internationalPhone");

const { value: organization, errorMessage: organizationError } = useField("organization", "instructorRequired");
const { value: professionalTitle, errorMessage: professionalTitleError } = useField("professionalTitle", "instructorRequired");
const { value: expertise, errorMessage: expertiseError } = useField("expertise", "instructorRequired");
const { value: experienceYears, errorMessage: experienceYearsError } = useField("experienceYears", "instructorExperience");
const { value: qualification, errorMessage: qualificationError } = useField("qualification", "instructorRequired");
const { value: verificationUrl, errorMessage: verificationUrlError } = useField("verificationUrl", "verificationUrl");
const { value: teachingStatement, errorMessage: teachingStatementError } = useField("teachingStatement", "instructorRequired");

const { value: password, errorMessage: passwordError } = useField("password", "required|strongPassword");
const { value: confirmPassword, errorMessage: confirmPasswordError } = useField(
  "confirmPassword",
  (value) => {
    if (!value) return "Please confirm your password.";
    return value === password.value || "Passwords do not match.";
  }
);

watch(password, () => {
  if (confirmPassword.value) validateField("confirmPassword");
});

onBeforeUnmount(() => window.clearTimeout(redirectTimer));

function normalizePhone(value) {
  return value.replace(/[\s().-]/g, "");
}

const handleSubmit = async () => {
  if (isSubmitting.value) return;
  serverError.value = "";
  successMessage.value = "";
  const result = await validate();

  if (!result.valid) return;

  if (!supabase) {
    serverError.value = "Registration is not configured yet. Add your Supabase URL and publishable key.";
    return;
  }

  isSubmitting.value = true;
  try {
    const { data, error } = await supabase.auth.signUp({
      email: emailValue.value.trim().toLowerCase(),
      password: password.value,
      options: {
        emailRedirectTo: `${window.location.origin}/login`,
        data: {
          full_name: name.value.trim(),
          phone: normalizePhone(phone.value),
          account_type: accountType.value,
          ...(accountType.value === "instructor" && {
            instructor_application: {
              organization: organization.value.trim(),
              professional_title: professionalTitle.value.trim(),
              expertise: expertise.value.trim(),
              experience_years: Number(experienceYears.value),
              qualification: qualification.value.trim(),
              verification_url: verificationUrl.value.trim(),
              teaching_statement: teachingStatement.value.trim(),
            },
          }),
        },
      },
    });

    if (error) throw error;

    if (accountType.value === "instructor" && data?.user && data?.session) {
      await supabase.from("instructor_applications").upsert({
        user_id: data.user.id,
        organization: organization.value.trim(),
        professional_title: professionalTitle.value.trim(),
        expertise: expertise.value.trim(),
        experience_years: Number(experienceYears.value) || 0,
        qualification: qualification.value.trim(),
        verification_url: verificationUrl.value.trim(),
        teaching_statement: teachingStatement.value.trim(),
        status: "pending",
      }, { onConflict: "user_id" }).catch(() => {});
    }

    if (!data.session) {
      successMessage.value = accountType.value === "instructor"
        ? "Your instructor application is pending review. Confirm your email; your account will remain a learner until approved."
        : "Account created. Check your email to confirm your address before logging in.";
      return;
    }

    successMessage.value = "Account created. Redirecting to login...";
    redirectTimer = window.setTimeout(() => router.push("/login"), 1200);
  } catch (error) {
    serverError.value = error.message || "We couldn't create your account. Please try again.";
  } finally {
    isSubmitting.value = false;
  }
};
</script>

<template>
  <AuthPageLayout
    :animation-src="animation"
    form-at-top
    side-headline="Make learning yours."
    side-description="Join as a learner or apply to teach. One account opens the door to new skills and new ways to share what you know."
  >
    <section>
      <header class="mb-7">
        <p class="mb-3 text-xs font-bold uppercase text-primary lg:hidden">NORTHSTAR LEARNING</p>
        <p class="mb-2 text-sm font-bold text-primary">CREATE YOUR ACCOUNT</p>
        <h2 class="text-3xl font-extrabold text-foreground sm:text-4xl">Start learning here.</h2>
        <p class="mt-2 text-base leading-7 text-muted-foreground">Choose your path. You can always apply to teach later.</p>
      </header>

      <form
        @submit.prevent="handleSubmit"
        class="grid grid-cols-1 gap-x-5 gap-y-4 text-foreground sm:grid-cols-2"
        novalidate
      >
        <FeedbackMessage :message="serverError" toast class="sm:col-span-2" />
        <FeedbackMessage :message="successMessage" variant="success" class="sm:col-span-2" />

        <fieldset class="space-y-2.5 sm:col-span-2">
          <legend class="mb-2 text-base font-bold text-foreground">Choose your account</legend>
          <div class="grid grid-cols-2 gap-2">
            <button
              v-for="option in [{ id: 'student', label: 'Learner' }, { id: 'instructor', label: 'Instructor' }]"
              :key="option.id"
              type="button"
              :aria-pressed="accountType === option.id"
              class="min-h-14 border px-4 text-left text-base font-bold outline-none transition-colors focus-visible:ring-2 focus-visible:ring-primary"
              :class="accountType === option.id ? 'border-primary bg-primary/5 text-primary' : 'border-border bg-white text-muted-foreground hover:border-primary/40 hover:text-foreground'"
              @click="accountType = option.id; serverError = ''; successMessage = ''"
            >
              <span class="flex items-center justify-between gap-2">
                {{ option.label }}
                <span v-if="accountType === option.id" class="size-2 rounded-full bg-primary" aria-hidden="true" />
              </span>
            </button>
          </div>
          <p class="text-sm leading-6 text-muted-foreground">
            {{ accountType === 'instructor' ? 'Instructor tools stay locked until the owner reviews and approves your application.' : 'Learner access is available after email confirmation.' }}
          </p>
        </fieldset>

        <!-- Basic Account Fields (Name, Email, Phone) -->
        <RegisterAccountFields
          v-model:name="name"
          :name-error="nameError"
          v-model:email="emailValue"
          :email-error="emailError"
          v-model:phone="phone"
          :phone-error="phoneError"
        />

        <!-- Instructor Verification Fields -->
        <InstructorVerificationFields
          v-if="accountType === 'instructor'"
          v-model:organization="organization"
          :organization-error="organizationError"
          v-model:professional-title="professionalTitle"
          :professional-title-error="professionalTitleError"
          v-model:expertise="expertise"
          :expertise-error="expertiseError"
          v-model:experience-years="experienceYears"
          :experience-years-error="experienceYearsError"
          v-model:qualification="qualification"
          :qualification-error="qualificationError"
          v-model:verification-url="verificationUrl"
          :verification-url-error="verificationUrlError"
          v-model:teaching-statement="teachingStatement"
          :teaching-statement-error="teachingStatementError"
        />

        <div class="flex items-center gap-2 border-b border-border pb-2 pt-1 sm:col-span-2">
          <span class="text-xs font-bold text-primary">02</span>
          <h3 class="text-base font-bold">Secure your account</h3>
        </div>

        <div class="space-y-1.5">
          <Label for="password" class="text-base font-semibold text-foreground">Password</Label>
          <PasswordField
            id="password"
            v-model="password"
            placeholder="Create a password"
            :invalid="Boolean(passwordError)"
            :described-by="passwordError ? 'password-error password-strength' : 'password-strength'"
          />
          <p v-if="passwordError" id="password-error" role="alert" class="text-sm text-red-500">
            {{ passwordError }}
          </p>
          <PasswordStrength :password="password" />
        </div>

        <div class="space-y-1.5">
          <Label for="confirmPassword" class="text-base font-semibold text-foreground">Confirm Password</Label>
          <PasswordField
            id="confirmPassword"
            v-model="confirmPassword"
            placeholder="Confirm password"
            :invalid="Boolean(confirmPasswordError)"
            :described-by="confirmPasswordError ? 'confirm-password-error' : undefined"
          />
          <p v-if="confirmPasswordError" id="confirm-password-error" role="alert" class="text-sm text-red-500">
            {{ confirmPasswordError }}
          </p>
        </div>

        <div class="pt-2 sm:col-span-2">
          <Button
            type="submit"
            :disabled="isSubmitting"
            class="w-full bg-primary p-4 text-lg font-bold text-white hover:bg-primary/90 disabled:cursor-not-allowed disabled:opacity-60"
          >
            <LoaderCircle v-if="isSubmitting" class="mr-2 inline animate-spin" :size="20" aria-hidden="true" />
            {{ isSubmitting ? 'Creating Account...' : 'Create Account' }}
          </Button>
        </div>

        <div class="sm:col-span-2 pt-1 text-center text-base text-muted-foreground">
          Already have an account?
          <RouterLink to="/login" class="ml-1 font-bold text-primary underline underline-offset-4">
            Login
          </RouterLink>
        </div>
      </form>
    </section>
  </AuthPageLayout>
</template>