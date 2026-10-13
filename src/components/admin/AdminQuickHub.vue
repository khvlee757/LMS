<script setup>
import { RouterLink } from "vue-router";
import {
  ArrowRight,
  CircleDollarSign,
  GraduationCap,
  ShieldCheck,
  UserCheck,
  Users,
} from "lucide-vue-next";

defineProps({
  pendingApplicationsCount: { type: Number, required: true },
});
</script>

<template>
  <div class="flex flex-col justify-between rounded-xl border border-border bg-[#163b32] p-6 text-white">
    <div>
      <span class="inline-flex items-center gap-1 rounded bg-white/10 px-2 py-0.5 text-xs font-bold text-emerald-300">
        <ShieldCheck :size="14" /> Super Admin Center
      </span>
      <h2 class="mt-3 text-xl font-black">Administration Hub</h2>
      <p class="mt-1 text-xs text-white/80">
        Full governance across user permissions, instructor reviews, course moderation, and financial records.
      </p>

      <div class="mt-6 space-y-2.5">
        <RouterLink
          to="/admin/applications"
          class="flex items-center justify-between rounded-lg bg-white/10 px-3.5 py-2.5 text-xs font-bold text-white transition-colors hover:bg-white/20"
        >
          <span class="flex items-center gap-2">
            <UserCheck :size="16" /> Review Applications
          </span>
          <span v-if="pendingApplicationsCount > 0" class="rounded bg-amber-400 px-1.5 py-0.5 text-[10px] font-black text-black">
            {{ pendingApplicationsCount }}
          </span>
        </RouterLink>

        <RouterLink
          to="/admin/users"
          class="flex items-center justify-between rounded-lg bg-white/10 px-3.5 py-2.5 text-xs font-bold text-white transition-colors hover:bg-white/20"
        >
          <span class="flex items-center gap-2">
            <Users :size="16" /> User Directory & Roles
          </span>
          <ArrowRight :size="14" />
        </RouterLink>

        <RouterLink
          to="/admin/payments"
          class="flex items-center justify-between rounded-lg bg-white/10 px-3.5 py-2.5 text-xs font-bold text-white transition-colors hover:bg-white/20"
        >
          <span class="flex items-center gap-2">
            <CircleDollarSign :size="16" /> Transaction Records
          </span>
          <ArrowRight :size="14" />
        </RouterLink>

        <RouterLink
          to="/admin/courses"
          class="flex items-center justify-between rounded-lg bg-white/10 px-3.5 py-2.5 text-xs font-bold text-white transition-colors hover:bg-white/20"
        >
          <span class="flex items-center gap-2">
            <GraduationCap :size="16" /> Course Catalog Manager
          </span>
          <ArrowRight :size="14" />
        </RouterLink>
      </div>
    </div>

    <div class="mt-6 border-t border-white/10 pt-4 text-[11px] text-white/70">
      <p>Standard Platform Fee: 10% · Paystack Connected</p>
    </div>
  </div>
</template>
