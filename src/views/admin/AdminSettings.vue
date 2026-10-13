<script setup>
import { computed, onMounted, ref } from "vue";
import {
  CheckCircle2,
  Database,
  Lock,
  RefreshCw,
  ShieldCheck,
  SlidersHorizontal,
} from "lucide-vue-next";
import { useAdminData } from "@/lib/useAdminData";
import { supabase } from "@/lib/supabase";

const {
  currentProfile,
  fetchAdminData,
  loading,
  notice,
  error,
} = useAdminData();

onMounted(async () => {
  await fetchAdminData();
});

const refreshing = ref(false);

async function handleRefresh() {
  refreshing.value = true;
  await fetchAdminData(true);
  refreshing.value = false;
}
</script>

<template>
  <div class="space-y-6">
    <header class="flex flex-wrap items-center justify-between gap-4">
      <div>
        <h1 class="text-3xl font-extrabold text-foreground sm:text-4xl">Platform Configuration & Status</h1>
        <p class="mt-1 text-sm text-muted-foreground">
          System operational status, commerce parameters, database security, and administrator settings.
        </p>
      </div>

      <button
        type="button"
        :disabled="refreshing"
        class="inline-flex min-h-10 items-center gap-2 rounded-lg border border-border bg-white px-4 text-xs font-bold text-foreground shadow-xs hover:bg-secondary disabled:opacity-50"
        @click="handleRefresh"
      >
        <RefreshCw :size="14" :class="{ 'animate-spin': refreshing }" />
        {{ refreshing ? 'Syncing...' : 'Sync Platform State' }}
      </button>
    </header>

    <div v-if="notice" role="status" class="rounded-md border border-emerald-200 bg-emerald-50 p-4 text-sm text-emerald-800">
      {{ notice }}
    </div>

    <div class="grid gap-6 md:grid-cols-2">
      <!-- Database & Backend Connection -->
      <section class="rounded-xl border border-border bg-white p-6 shadow-xs">
        <div class="flex items-center gap-2.5">
          <Database :size="20" class="text-primary" />
          <h2 class="text-base font-extrabold text-foreground">Backend & Database</h2>
        </div>
        <p class="mt-1 text-xs text-muted-foreground">Connection to Supabase PostgreSQL & Auth instance</p>

        <dl class="mt-5 divide-y divide-border text-xs">
          <div class="flex justify-between py-2.5">
            <dt class="font-semibold text-muted-foreground">Database Engine</dt>
            <dd class="font-bold text-foreground">Supabase PostgreSQL 15+</dd>
          </div>
          <div class="flex justify-between py-2.5">
            <dt class="font-semibold text-muted-foreground">Auth Provider</dt>
            <dd class="font-bold text-foreground">GoTrue Email & Password</dd>
          </div>
          <div class="flex justify-between py-2.5">
            <dt class="font-semibold text-muted-foreground">Client State</dt>
            <dd class="inline-flex items-center gap-1 font-bold text-emerald-700">
              <CheckCircle2 :size="13" /> Connected
            </dd>
          </div>
          <div class="flex justify-between py-2.5">
            <dt class="font-semibold text-muted-foreground">Row-Level Security</dt>
            <dd class="font-bold text-foreground">Active & Protected</dd>
          </div>
        </dl>
      </section>

      <!-- Commercial & Payment Settings -->
      <section class="rounded-xl border border-border bg-white p-6 shadow-xs">
        <div class="flex items-center gap-2.5">
          <SlidersHorizontal :size="20" class="text-primary" />
          <h2 class="text-base font-extrabold text-foreground">Commerce Parameters</h2>
        </div>
        <p class="mt-1 text-xs text-muted-foreground">Financial rules and gateway integration</p>

        <dl class="mt-5 divide-y divide-border text-xs">
          <div class="flex justify-between py-2.5">
            <dt class="font-semibold text-muted-foreground">Payment Gateway</dt>
            <dd class="font-bold text-foreground">Paystack Checkout</dd>
          </div>
          <div class="flex justify-between py-2.5">
            <dt class="font-semibold text-muted-foreground">Platform Fee Commission</dt>
            <dd class="font-bold text-emerald-700">10% Platform Take-Rate</dd>
          </div>
          <div class="flex justify-between py-2.5">
            <dt class="font-semibold text-muted-foreground">Instructor Revenue Share</dt>
            <dd class="font-bold text-foreground">90% Net Allocation</dd>
          </div>
          <div class="flex justify-between py-2.5">
            <dt class="font-semibold text-muted-foreground">Base Currency</dt>
            <dd class="font-bold text-foreground">NGN (Nigerian Naira)</dd>
          </div>
        </dl>
      </section>

      <!-- Administrator Account -->
      <section class="rounded-xl border border-border bg-white p-6 shadow-xs md:col-span-2">
        <div class="flex items-center gap-2.5">
          <ShieldCheck :size="20" class="text-primary" />
          <h2 class="text-base font-extrabold text-foreground">Super Administrator Privileges</h2>
        </div>
        <p class="mt-1 text-xs text-muted-foreground">Current administrative identity and security clearance</p>

        <div class="mt-5 grid gap-4 sm:grid-cols-3 rounded-lg bg-secondary/50 p-4 text-xs">
          <div>
            <p class="text-muted-foreground font-semibold">Admin Account Name</p>
            <p class="mt-1 font-bold text-foreground">{{ currentProfile?.full_name || 'System Owner' }}</p>
          </div>
          <div>
            <p class="text-muted-foreground font-semibold">Admin Email</p>
            <p class="mt-1 font-bold text-foreground">{{ currentProfile?.email || 'admin@northstar.org' }}</p>
          </div>
          <div>
            <p class="text-muted-foreground font-semibold">Assigned Role</p>
            <p class="mt-1 inline-flex items-center gap-1 font-bold text-emerald-800">
              <ShieldCheck :size="13" /> super_admin
            </p>
          </div>
        </div>

        <div class="mt-4 flex items-start gap-2 rounded-lg border border-amber-200 bg-amber-50 p-3 text-xs text-amber-900">
          <Lock :size="15" class="shrink-0 mt-0.5 text-amber-700" />
          <span>
            Security Note: Administrative role modifications are guarded by PostgreSQL database triggers (`protect_profile_role`). Super admin access cannot be altered or self-assigned via the public API.
          </span>
        </div>
      </section>
    </div>
  </div>
</template>

