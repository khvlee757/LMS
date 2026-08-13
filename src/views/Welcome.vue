<script setup>
import { useRouter } from 'vue-router';

const router = useRouter();

function start() {
  // clear first-time flag and go to dashboard where user can choose courses
  localStorage.removeItem('firstTimeUser');
  router.push('/dashboard');
}

function skip() {
  localStorage.removeItem('firstTimeUser');
  router.push('/dashboard');
}
</script>

<template>
  <main class="min-h-screen flex items-center justify-center bg-secondary p-6">
    <div class="max-w-2xl w-full">
      <div class="rounded-xl bg-primary p-8 text-center shadow-md">
        <h1 class="text-4xl font-bold mb-4">Welcome to LMS</h1>
        <p class="text-muted-foreground mb-6">Thanks for creating your account. Before you start, take a moment to set up your interests and pick courses.</p>

        <div class="flex justify-center gap-4">
          <button @click="start" class="rounded-md bg-primary px-6 py-3 text-white font-semibold">Start choosing courses</button>
          <button @click="skip" class="rounded-md border px-6 py-3">Skip for now</button>
        </div>
      </div>
    </div>
  </main>
</template>
