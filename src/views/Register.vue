<script setup>
import { onBeforeUnmount, ref, watch } from "vue";
import { useRouter } from "vue-router";
import { defineRule, useForm, useField } from "vee-validate";
import { required } from "@vee-validate/rules";
import { LoaderCircle } from "lucide-vue-next";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import animation from "@/assets/school.lottie";
import { supabase } from "@/lib/supabase";
import AuthPageLayout from "@/components/auth/AuthPageLayout.vue";
import PasswordField from "@/components/auth/PasswordField.vue";
import PasswordStrength from "@/components/auth/PasswordStrength.vue";
import FeedbackMessage from "@/components/FeedbackMessage.vue";




defineRule("required", required);
defineRule("fullName", (value) => {
  const words = String(value ?? "").trim().split(/\s+/).filter(Boolean);
  return words.length >= 2 || "Enter your first and last name.";
});
defineRule("emailFormat", (value) =>
  /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(String(value ?? "").trim()) ||
  "Enter a valid email address."
);
defineRule("internationalPhone", (value) => {
  const normalized = String(value ?? "").replace(/[\s().-]/g, "");
  return /^\+[1-9]\d{7,14}$/.test(normalized) ||
    "Enter an international number with country code, such as +1 202 555 0123.";
});
defineRule("strongPassword", (value) => {
  const candidate = String(value ?? "");
  return (
    candidate.length >= 8 &&
    /[a-z]/.test(candidate) &&
    /[A-Z]/.test(candidate) &&
    /\d/.test(candidate) &&
    /[^A-Za-z0-9\s]/.test(candidate)
  ) || "Use at least 8 characters with uppercase, lowercase, number, and symbol.";
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

const { value: name, errorMessage: nameError } = useField(
  "name",
  "required|fullName"
);

const { value: emailValue, errorMessage: emailError } = useField(
  "email",
  "required|emailFormat"
);

const { value: phone, errorMessage: phoneError } = useField(
  "phone",
  "required|internationalPhone"
);

const { value: organization, errorMessage: organizationError } = useField("organization", "instructorRequired");
const { value: professionalTitle, errorMessage: professionalTitleError } = useField("professionalTitle", "instructorRequired");
const { value: expertise, errorMessage: expertiseError } = useField("expertise", "instructorRequired");
const { value: experienceYears, errorMessage: experienceYearsError } = useField("experienceYears", "instructorExperience");
const { value: qualification, errorMessage: qualificationError } = useField("qualification", "instructorRequired");
const { value: verificationUrl, errorMessage: verificationUrlError } = useField("verificationUrl", "verificationUrl");
const { value: teachingStatement, errorMessage: teachingStatementError } = useField("teachingStatement", "instructorRequired");

const { value: password, errorMessage: passwordError } = useField(
  "password",
  "required|strongPassword"
);

const {
  value: confirmPassword,
  errorMessage: confirmPasswordError,
} = useField(
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

  if (!result.valid) {
    return;
  }

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
      <section class="reveal-on-enter" style="--reveal-delay: 80ms">
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

            <div class="flex items-center gap-2 border-b border-border pb-2 pt-1 sm:col-span-2">
              <span class="text-xs font-bold text-primary">01</span>
              <h3 class="text-base font-bold">Account details</h3>
            </div>

            <div class="space-y-1.5 sm:col-span-2">
              <Label
                for="name"
                class="text-base font-semibold text-foreground"
              >
                Full Name
              </Label>

              <Input
                id="name"
                v-model="name"
                type="text"
                autocomplete="name"
                placeholder="Enter your full name"
                class="h-12 border-border bg-white text-base"
                :aria-invalid="Boolean(nameError)"
                :aria-describedby="nameError ? 'name-error' : undefined"
              />

              <p
                v-if="nameError"
                id="name-error"
                role="alert"
                class="text-sm text-red-500"
              >
                {{ nameError }}
              </p>
            </div>

            <div class="space-y-1.5">
              <Label
                for="email"
                class="text-base font-semibold text-foreground"
              >
                Email
              </Label>

              <Input
                id="email"
                v-model="emailValue"
                type="email"
                autocomplete="email"
                placeholder="you@example.com"
                class="h-12 border-border bg-white text-base"
                :aria-invalid="Boolean(emailError)"
                :aria-describedby="emailError ? 'email-error' : undefined"
              />

              <p
                v-if="emailError"
                id="email-error"
                role="alert"
                class="text-sm text-red-500"
              >
                {{ emailError }}
              </p>
            </div>

            <div class="space-y-1.5">
              <Label
                for="phone"
                class="text-base font-semibold text-foreground"
              >
                Phone Number
              </Label>

              <Input
                id="phone"
                v-model="phone"
                type="tel"
                autocomplete="tel"
                inputmode="tel"
                placeholder="+234 801 234 5678"
                class="h-12 border-border bg-white text-base"
                :aria-invalid="Boolean(phoneError)"
                :aria-describedby="phoneError ? 'phone-error' : undefined"
              />
              <p class="text-sm leading-6 text-muted-foreground">Include your country calling code, for example +234 or +44.</p>

              <p
                v-if="phoneError"
                id="phone-error"
                role="alert"
                class="text-sm text-red-500"
              >
                {{ phoneError }}
              </p>
            </div>

            <fieldset v-if="accountType === 'instructor'" class="grid gap-4 border border-border bg-secondary/50 p-4 sm:col-span-2 sm:grid-cols-2 sm:p-5">
              <legend class="bg-secondary px-2 text-base font-bold text-primary">Instructor verification</legend>
              <label for="organization" class="space-y-1.5 text-base font-semibold">School or organization
                <Input id="organization" v-model="organization" autocomplete="organization" maxlength="160" placeholder="School, company, or independent" class="h-12 border-primary/30 bg-white text-base" :aria-invalid="Boolean(organizationError)" aria-describedby="organization-error" />
                <span v-if="organizationError" id="organization-error" role="alert" class="block text-sm font-normal text-red-600">{{ organizationError }}</span>
              </label>
              <label for="professional-title" class="space-y-1.5 text-base font-semibold">Professional title
                <Input id="professional-title" v-model="professionalTitle" maxlength="120" placeholder="Teacher, lecturer, coach..." class="h-12 border-primary/30 bg-white text-base" :aria-invalid="Boolean(professionalTitleError)" aria-describedby="professional-title-error" />
                <span v-if="professionalTitleError" id="professional-title-error" role="alert" class="block text-sm font-normal text-red-600">{{ professionalTitleError }}</span>
              </label>
              <label for="expertise" class="space-y-1.5 text-base font-semibold">Teaching subject or expertise
                <Input id="expertise" v-model="expertise" maxlength="160" placeholder="What would you teach?" class="h-12 border-primary/30 bg-white text-base" :aria-invalid="Boolean(expertiseError)" aria-describedby="expertise-error" />
                <span v-if="expertiseError" id="expertise-error" role="alert" class="block text-sm font-normal text-red-600">{{ expertiseError }}</span>
              </label>
              <label for="experience-years" class="space-y-1.5 text-base font-semibold">Teaching experience (years)
                <Input id="experience-years" v-model="experienceYears" type="number" min="0" max="60" step="1" inputmode="numeric" placeholder="0" class="h-12 border-primary/30 bg-white text-base" :aria-invalid="Boolean(experienceYearsError)" aria-describedby="experience-years-error" />
                <span v-if="experienceYearsError" id="experience-years-error" role="alert" class="block text-sm font-normal text-red-600">{{ experienceYearsError }}</span>
              </label>
              <label for="qualification" class="space-y-1.5 text-base font-semibold">Relevant qualifications
                <textarea id="qualification" v-model="qualification" rows="3" maxlength="1000" placeholder="Degrees, certifications, or relevant experience" class="w-full resize-y border border-primary/30 bg-white px-3 py-2 text-base font-normal outline-none focus-visible:ring-2 focus-visible:ring-primary" :aria-invalid="Boolean(qualificationError)" aria-describedby="qualification-error" />
                <span v-if="qualificationError" id="qualification-error" role="alert" class="block text-sm font-normal text-red-600">{{ qualificationError }}</span>
              </label>
              <label for="verification-url" class="space-y-1.5 text-base font-semibold">Verification link
                <Input id="verification-url" v-model="verificationUrl" type="url" maxlength="500" placeholder="https://institution.edu/profile" class="h-12 border-primary/30 bg-white text-base" :aria-invalid="Boolean(verificationUrlError)" aria-describedby="verification-url-help verification-url-error" />
                <span id="verification-url-help" class="block text-sm font-normal text-muted-foreground">Link a faculty page, professional profile, or portfolio.</span>
                <span v-if="verificationUrlError" id="verification-url-error" role="alert" class="block text-sm font-normal text-red-600">{{ verificationUrlError }}</span>
              </label>
              <label for="teaching-statement" class="space-y-1.5 text-base font-semibold sm:col-span-2">What will learners gain from your course?
                <textarea id="teaching-statement" v-model="teachingStatement" rows="3" maxlength="1500" placeholder="Briefly describe your teaching approach and course value." class="w-full resize-y border border-primary/30 bg-white px-3 py-2 text-base font-normal outline-none focus-visible:ring-2 focus-visible:ring-primary" :aria-invalid="Boolean(teachingStatementError)" aria-describedby="teaching-statement-error" />
                <span v-if="teachingStatementError" id="teaching-statement-error" role="alert" class="block text-sm font-normal text-red-600">{{ teachingStatementError }}</span>
              </label>
            </fieldset>

            <div class="flex items-center gap-2 border-b border-border pb-2 pt-1 sm:col-span-2">
              <span class="text-xs font-bold text-primary">02</span>
              <h3 class="text-base font-bold">Secure your account</h3>
            </div>

            <div class="space-y-1.5">
              <Label
                for="password"
                class="text-base font-semibold text-foreground"
              >
                Password
              </Label>

              <PasswordField
                id="password"
                v-model="password"
                placeholder="Create a password"
                :invalid="Boolean(passwordError)"
                :described-by="passwordError ? 'password-error password-strength' : 'password-strength'"
              />

              <p
                v-if="passwordError"
                id="password-error"
                role="alert"
                class="text-sm text-red-500"
              >
                {{ passwordError }}
              </p>
              <PasswordStrength :password="password" />
            </div>

            <div class="space-y-1.5">
              <Label
                for="confirmPassword"
                class="text-base font-semibold text-foreground"
              >
                Confirm Password
              </Label>

              <PasswordField
                id="confirmPassword"
                v-model="confirmPassword"
                placeholder="Confirm password"
                :invalid="Boolean(confirmPasswordError)"
                :described-by="confirmPasswordError ? 'confirm-password-error' : undefined"
              />

              <p
                v-if="confirmPasswordError"
                id="confirm-password-error"
                role="alert"
                class="text-sm text-red-500"
              >
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
              <RouterLink
                to="/login"
                class="ml-1 font-bold text-primary underline underline-offset-4"
              >
                Login
              </RouterLink>
            </div>
          </form>
      </section>
  </AuthPageLayout>
</template>