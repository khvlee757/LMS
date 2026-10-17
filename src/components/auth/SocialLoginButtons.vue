<script setup>
import { ref } from "vue";
import { LoaderCircle } from "lucide-vue-next";
import { supabase } from "@/lib/supabase";

const emit = defineEmits(["error"]);

const authenticatingProvider = ref("");

async function signInWithProvider(provider) {
  if (authenticatingProvider.value) return;
  if (!supabase) {
    emit("error", "Supabase authentication is not configured yet.");
    return;
  }

  authenticatingProvider.value = provider;
  try {
    const { error } = await supabase.auth.signInWithOAuth({
      provider,
      options: {
        redirectTo: `${window.location.origin}/dashboard`,
      },
    });
    if (error) throw error;
  } catch (err) {
    emit("error", err.message || `Failed to sign in with ${provider}.`);
  } finally {
    authenticatingProvider.value = "";
  }
}
</script>

<template>
  <div class="space-y-4">
    <!-- Divider -->
    <div class="relative flex items-center justify-center">
      <div class="w-full border-t border-border" />
      <span class="absolute bg-white px-3 text-xs font-semibold uppercase tracking-wider text-muted-foreground">
        Or continue with
      </span>
    </div>

    <!-- Social SSO Providers -->
    <div class="grid grid-cols-3 gap-2.5">
      <!-- Google -->
      <button
        type="button"
        :disabled="Boolean(authenticatingProvider)"
        class="inline-flex min-h-11 items-center justify-center gap-2 rounded-lg border border-border bg-white px-3 text-xs font-bold text-foreground transition-all hover:bg-secondary/60 hover:border-primary/30 focus-visible:ring-2 focus-visible:ring-primary disabled:opacity-50"
        aria-label="Sign in with Google"
        @click="signInWithProvider('google')"
      >
        <LoaderCircle v-if="authenticatingProvider === 'google'" :size="15" class="animate-spin" />
        <svg v-else class="size-4 shrink-0" viewBox="0 0 24 24">
          <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" />
          <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" />
          <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.06H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.94l2.85-2.22.81-.63z" />
          <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.06l3.66 2.84c.87-2.6 3.3-4.52 6.16-4.52z" />
        </svg>
        <span class="hidden sm:inline">Google</span>
      </button>

      <!-- Microsoft -->
      <button
        type="button"
        :disabled="Boolean(authenticatingProvider)"
        class="inline-flex min-h-11 items-center justify-center gap-2 rounded-lg border border-border bg-white px-3 text-xs font-bold text-foreground transition-all hover:bg-secondary/60 hover:border-primary/30 focus-visible:ring-2 focus-visible:ring-primary disabled:opacity-50"
        aria-label="Sign in with Microsoft"
        @click="signInWithProvider('azure')"
      >
        <LoaderCircle v-if="authenticatingProvider === 'azure'" :size="15" class="animate-spin" />
        <svg v-else class="size-4 shrink-0" viewBox="0 0 21 21">
          <path fill="#f25022" d="M1 1h9v9H1z"/>
          <path fill="#00a4ef" d="M1 11h9v9H1z"/>
          <path fill="#7fba00" d="M11 1h9v9h-9z"/>
          <path fill="#ffb900" d="M11 11h9v9h-9z"/>
        </svg>
        <span class="hidden sm:inline">Microsoft</span>
      </button>

      <!-- Apple -->
      <button
        type="button"
        :disabled="Boolean(authenticatingProvider)"
        class="inline-flex min-h-11 items-center justify-center gap-2 rounded-lg border border-border bg-white px-3 text-xs font-bold text-foreground transition-all hover:bg-secondary/60 hover:border-primary/30 focus-visible:ring-2 focus-visible:ring-primary disabled:opacity-50"
        aria-label="Sign in with Apple"
        @click="signInWithProvider('apple')"
      >
        <LoaderCircle v-if="authenticatingProvider === 'apple'" :size="15" class="animate-spin" />
        <svg v-else class="size-4 shrink-0 fill-current text-foreground" viewBox="0 0 170 170">
          <path d="M150.37 130.25c-2.45 5.66-5.35 10.87-8.71 15.66-4.58 6.53-8.33 11.05-11.22 13.56-4.48 4.12-9.28 6.23-14.42 6.35-3.69 0-8.14-1.05-13.32-3.18-5.19-2.12-9.97-3.17-14.34-3.17-4.58 0-9.49 1.05-14.75 3.17-5.26 2.13-9.5 3.24-12.74 3.35-4.35.13-9.16-1.9-14.42-6.08-3.7-3.04-7.69-7.85-11.96-14.42-6.73-10.33-12-22.18-15.82-35.53-3.82-13.36-5.73-25.9-5.73-37.64 0-16.74 4.35-30.43 13.06-41.07 8.7-10.64 19.46-16.14 32.28-16.51 4.58 0 9.87 1.15 15.88 3.44 6 2.29 10.02 3.48 12.06 3.58 1.62-.1 5.9-1.33 12.82-3.68 6.92-2.35 12.56-3.4 16.92-3.17 12.86.64 23.32 5.38 31.39 14.23-11.33 6.84-16.89 16.35-16.68 28.53.22 9.5 3.82 17.5 10.81 24.01 6.99 6.51 15.22 10.22 24.69 11.13-2.18 6.53-4.79 13.35-7.85 20.47zM119.22 33.31c0-7.39 2.67-14.36 8.01-20.91 5.34-6.55 11.98-10.74 19.92-12.57.87 7.07-1.14 14.04-6.03 20.91-4.89 6.87-11.41 11.08-19.56 12.63-.44-.06-1.18-.06-2.34-.06z"/>
        </svg>
        <span class="hidden sm:inline">Apple</span>
      </button>
    </div>
  </div>
</template>

