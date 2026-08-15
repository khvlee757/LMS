<script setup>
import { ref } from 'vue';
import { useRouter } from 'vue-router';

const router = useRouter();
const email = ref('admin@lms.com');
const password = ref('admin123');
const error = ref('');

const loginAdmin = () => {
  const ADMIN_EMAIL = 'admin@lms.com';
  const ADMIN_PASSWORD = 'admin123';

  if (email.value.trim() === ADMIN_EMAIL && password.value === ADMIN_PASSWORD) {
    localStorage.setItem('lmsRole', 'admin');
    localStorage.setItem('adminSession', JSON.stringify({ email: email.value, role: 'admin' }));
    router.push('/admin-dashboard');
    return;
  }

  error.value = 'Invalid admin credentials.';
};
</script>

<template>
  <main class="flex min-h-screen items-center justify-center bg-secondary px-4 py-8">
    <div class="w-full max-w-md rounded-2xl border bg-white p-6 shadow-lg">
      <div class="mb-6 text-center">
        <p class="text-sm uppercase tracking-[0.2em] text-primary/70">Admin access</p>
        <h1 class="mt-2 text-3xl font-bold text-primary">Admin login</h1>
      </div>

      <form class="space-y-4" @submit.prevent="loginAdmin">
        <div>
          <label class="mb-1 block text-sm font-medium text-primary">Email</label>
          <input v-model="email" type="email" class="w-full rounded-lg border px-3 py-2 outline-none focus:border-primary" placeholder="admin@lms.com" />
        </div>

        <div>
          <label class="mb-1 block text-sm font-medium text-primary">Password</label>
          <input v-model="password" type="password" class="w-full rounded-lg border px-3 py-2 outline-none focus:border-primary" placeholder="••••••••" />
        </div>

        <p v-if="error" class="text-sm text-red-500">{{ error }}</p>

        <button type="submit" class="w-full rounded-lg bg-primary px-4 py-3 font-semibold text-white hover:bg-primary/90">
          Login as admin
        </button>
      </form>
    </div>
  </main>
</template>
