<script setup>
import { useRouter } from "vue-router";
import { defineRule, useForm, useField } from "vee-validate";
import { required, email, min } from "@vee-validate/rules";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { DotLottieVue } from "@lottiefiles/dotlottie-vue";
import animation from "@/assets/school.lottie";

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

function capitalizeFirstLetter(str) {
  if (!str) return ''; 
  return str.charAt(0).toUpperCase() + str.slice(1);
}
const router = useRouter();

const { validate } = useForm();

const { value: name, errorMessage: nameError } = useField(
  "name",
  "required"
);

const { value: emailValue, errorMessage: emailError } = useField(
  "email",
  "required|email"
);

const { value: phone, errorMessage: phoneError } = useField(
  "phone",
  "required|min:11"
);

const { value: password, errorMessage: passwordError } = useField(
  "password",
  "required|min:8"
);

const {
  value: confirmPassword,
  errorMessage: confirmPasswordError,
} = useField(
  "confirmPassword",
  "required"
);

const handleSubmit = async () => {
  const result = await validate();

  if (!result.valid) {
    return;
  }

  if (password.value !== confirmPassword.value) {
    alert("Passwords do not match");
    return;
  }

  const form = {
    name: name.value,
    email: emailValue.value,
    phone: phone.value,
    password: password.value,
    confirmPassword: confirmPassword.value,
  };

  localStorage.setItem("form", JSON.stringify(form));

  console.log(form);

  alert("Account created successfully!");

  router.push("/login");
};
</script>

<template>
  <main class="grid min-h-screen lg:grid-cols-2 bg-secondary">
    <section
      class="relative hidden min-h-screen overflow-hidden rounded-br-full bg-primary/40 lg:block"
    >
      <div class="absolute inset-0 flex items-center justify-center">
        <DotLottieVue
          :src="animation"
          autoplay
          loop
          class="h-full w-full"
        />
      </div>
    </section>

    <section
      class="flex min-h-screen items-center justify-center bg-secondary px-6 py-12"
    >
      <Card class="w-full max-w-lg border-0 bg-transparent shadow-none">
        <CardHeader class="space-y-2">
          <CardTitle class="text-5xl font-extrabold text-primary">
            Create an account
          </CardTitle>

          <CardDescription class="text-xl text-primary/70">
            Register your account to get started with LMS.
          </CardDescription>
        </CardHeader>

        <CardContent>
          <form
            @submit.prevent="handleSubmit"
            class="grid grid-cols-1 gap-5 text-primary sm:grid-cols-2"
          >
            <div class="space-y-2 sm:col-span-2">
              <Label
                for="name"
                class="text-xl text-primary"
              >
                Full Name
              </Label>

              <Input
                id="name"
                v-model="name"
                type="text"
                placeholder="Enter your full name"
                class="h-12 border-primary/30 bg-white text-base"
              />

              <p
                v-if="nameError"
                class="text-sm text-red-500"
              >
                {{ nameError }}
              </p>
            </div>

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
                placeholder="you@example.com"
                class="h-12 border-primary/30 bg-white text-base"
              />

              <p
                v-if="emailError"
                class="text-sm text-red-500"
              >
                {{ emailError }}
              </p>
            </div>

            <div class="space-y-2">
              <Label
                for="phone"
                class="text-xl text-primary"
              >
                Phone Number
              </Label>

              <Input
                id="phone"
                v-model="phone"
                type="tel"
                placeholder="08012345678"
                class="h-12 border-primary/30 bg-white text-base"
              />

              <p
                v-if="phoneError"
                class="text-sm text-red-500"
              >
                {{ phoneError }}
              </p>
            </div>

            <div class="space-y-2">
              <Label
                for="password"
                class="text-xl text-primary"
              >
                Password
              </Label>

              <Input
                id="password"
                v-model="password"
                type="password"
                placeholder="Create a password"
                class="h-12 border-primary/30 bg-white text-base"
              />

              <p
                v-if="passwordError"
                class="text-sm text-red-500"
              >
                {{ passwordError }}
              </p>
            </div>

            <div class="space-y-2">
              <Label
                for="confirmPassword"
                class="text-xl text-primary"
              >
                Confirm Password
              </Label>

              <Input
                id="confirmPassword"
                v-model="confirmPassword"
                type="password"
                placeholder="Confirm password"
                class="h-12 border-primary/30 bg-white text-base"
              />

              <p
                v-if="confirmPasswordError"
                class="text-sm text-red-500"
              >
                {{ confirmPasswordError }}
              </p>
            </div>

            <div class="pt-2 sm:col-span-2">
              <Button
                type="submit"
                class="w-full bg-primary p-6 text-xl font-bold text-white hover:bg-primary/90"
              >
                Create Account
              </Button>
            </div>

            <div class="sm:col-span-2 pt-2 text-center text-base text-primary/80">
              Already have an account?
              <RouterLink
                to="/login"
                class="ml-1 font-semibold text-primary underline underline-offset-4"
              >
                Login
              </RouterLink>
            </div>
          </form>
        </CardContent>
      </Card>
    </section>
  </main>
</template>