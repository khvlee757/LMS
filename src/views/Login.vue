<script setup>
import { useRouter } from "vue-router";
import { defineRule, useForm, useField } from "vee-validate";
import { required, email, min } from "@vee-validate/rules";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { DotLottieVue } from "@lottiefiles/dotlottie-vue";
import animation from "@/assets/Login.lottie";

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
const { validate } = useForm();

const { value: emailValue, errorMessage: emailError } = useField(
  "email",
  "required|email"
);

const { value: password, errorMessage: passwordError } = useField(
  "password",
  "required|min:8"
);

const handleSubmit = async () => {
  const result = await validate();

  if (!result.valid) {
    return;
  }

  alert("Login successful!");
  router.push("/dashboard");
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
      class="flex min-h-screen items-center justify-center  px-6 py-12"
    >
      <Card class="w-full max-w-lg border-0 bg-transparent shadow-none">
        <CardHeader class="space-y-2">
          <CardTitle class="text-5xl font-extrabold text-primary">
            Welcome back
          </CardTitle>

          <CardDescription class="text-xl text-primary/70">
            Sign in to continue to your LMS dashboard.
          </CardDescription>
        </CardHeader>

        <CardContent>
          <form
            @submit.prevent="handleSubmit"
            class="grid grid-cols-1 gap-5 text-primary"
          >
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
                for="password"
                class="text-xl text-primary"
              >
                Password
              </Label>

              <Input
                id="password"
                v-model="password"
                type="password"
                placeholder="Enter your password"
                class="h-12 border-primary/30 bg-white text-base"
              />

              <p
                v-if="passwordError"
                class="text-sm text-red-500"
              >
                {{ passwordError }}
              </p>
            </div>

            <div class="pt-2">
              <Button
              @click="handleSubmit"
                type="submit"
                class="w-full bg-primary p-6 text-xl font-bold text-white hover:bg-primary/90"
              >
                Login
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

          <div class="mt-3 text-center text-sm text-primary/70">
            Admin?
            <button type="button" @click="router.push('/admin-login')" class="ml-1 font-semibold text-primary underline underline-offset-4">Admin login</button>
          </div>
        </CardContent>
      </Card>
    </section>
  </main>
</template>