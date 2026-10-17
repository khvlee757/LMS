<script setup>
import { computed, onMounted, ref } from "vue";
import { RouterLink, RouterView, useRoute, useRouter } from "vue-router";
import {
  BookOpen,
  CircleDollarSign,
  ExternalLink,
  GraduationCap,
  LayoutDashboard,
  LogOut,
  Menu,
  ShieldCheck,
  SlidersHorizontal,
  UserCheck,
  Users,
  X,
  Sparkles,
} from "lucide-vue-next";
import { useAdminData } from "@/lib/useAdminData";
import { supabase } from "@/lib/supabase";
import northstarMark from "@/assets/northstar-mark.png";

const route = useRoute();
const router = useRouter();
const menuOpen = ref(false);
const signingOut = ref(false);

const {
  currentProfile,
  fetchAdminData,
  pendingApplicationsCount,
} = useAdminData();

onMounted(async () => {
  await fetchAdminData();
});

const adminNavigation = computed(() => [
  { label: "Dashboard", to: "/admin", icon: LayoutDashboard, exact: true },
  { label: "Users & Learners", to: "/admin/users", icon: Users },
  {
    label: "Instructor Reviews",
    to: "/admin/applications",
    icon: UserCheck,
    badge: pendingApplicationsCount.value > 0 ? pendingApplicationsCount.value : null,
  },
  { label: "Course Management", to: "/admin/courses", icon: GraduationCap },
  { label: "Books & Library", to: "/admin/books", icon: BookOpen },
  { label: "Financials & Orders", to: "/admin/payments", icon: CircleDollarSign },
  { label: "Platform Settings", to: "/admin/settings", icon: SlidersHorizontal },
]);

const currentSectionTitle = computed(() => {
  const titles = {
    admin: "Executive Overview",
    "admin-users": "Users & Learners",
    "admin-applications": "Instructor Applications",
    "admin-courses": "Courses Administration",
    "admin-books": "Books & Library",
    "admin-payments": "Financials & Payments",
    "admin-settings": "Platform Configuration",
  };
  return titles[route.name] || "Administration";
});

const displayName = computed(
  () => currentProfile.value?.full_name || currentProfile.value?.email || "Super Admin"
);

const initials = computed(() =>
  displayName.value
    .split(/[\s@._-]+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((part) => part[0].toUpperCase())
    .join("") || "SA"
);

function isActive(item) {
  if (item.exact) {
    return route.path === item.to;
  }
  return route.path.startsWith(item.to);
}

async function signOut() {
  if (!supabase || signingOut.value) return;
  signingOut.value = true;
  await supabase.auth.signOut();
  await router.replace({ name: "login" });
  signingOut.value = false;
}
</script>

<template>
  <div class="min-h-screen bg-[#f3f7f4] text-foreground lg:flex">
    <!-- Mobile header -->
    <header class="sticky top-0 z-30 flex h-16 items-center justify-between border-b border-border bg-[#112922] px-4 text-white lg:hidden">
      <RouterLink to="/admin" class="flex items-center gap-2.5 font-extrabold tracking-tight">
        <img :src="northstarMark" alt="" class="size-8" />
        <span class="flex items-center gap-1.5 text-md font-extrabold text-white">
          Northstar <span class="rounded bg-emerald-500/20 px-1.5 py-0.5 text-xs font-semibold text-emerald-300">Admin</span>
        </span>
      </RouterLink>
      <button
        type="button"
        class="grid size-10 place-items-center rounded-md text-white outline-none hover:bg-white/10 focus-visible:ring-2 focus-visible:ring-emerald-400"
        :aria-label="menuOpen ? 'Close navigation' : 'Open navigation'"
        :aria-expanded="menuOpen"
        @click="menuOpen = !menuOpen"
      >
        <X v-if="menuOpen" :size="22" />
        <Menu v-else :size="22" />
      </button>
    </header>

    <!-- Sidebar desktop & mobile drawer -->
    <aside
      class="fixed inset-y-0 left-0 z-40 flex w-72 flex-col justify-between border-r border-[#1e4438] bg-[#112922] px-4 py-5 text-white transition-transform lg:w-68 lg:translate-x-0"
      :class="menuOpen ? 'translate-x-0 shadow-2xl' : '-translate-x-full lg:translate-x-0'"
    >
      <div>
        <!-- Brand -->
        <div class="flex items-center justify-between px-2 pb-6 pt-1">
          <RouterLink to="/admin" class="flex items-center gap-3 font-extrabold" @click="menuOpen = false">
            <img :src="northstarMark" alt="" class="size-9 drop-shadow" />
            <div>
              <span class="block text-base leading-tight font-extrabold text-white">Northstar Admin</span>
              <span class="block text-xs font-semibold text-emerald-300/80">Executive Control</span>
            </div>
          </RouterLink>
          <span class="inline-flex items-center gap-1 rounded bg-emerald-500/20 px-2 py-0.5 text-[11px] font-bold text-emerald-300">
            <ShieldCheck :size="12" /> Super Admin
          </span>
        </div>

        <!-- Section Label -->
        <p class="px-3 pb-2 text-[11px] font-bold uppercase tracking-[0.18em] text-emerald-200/50">
          Platform Controls
        </p>

        <!-- Navigation Links -->
        <nav aria-label="Admin navigation" class="space-y-1">
          <RouterLink
            v-for="item in adminNavigation"
            :key="item.to"
            :to="item.to"
            class="group flex min-h-11 items-center justify-between rounded-lg px-3 text-sm font-semibold transition-all outline-none focus-visible:ring-2 focus-visible:ring-emerald-400"
            :class="isActive(item) ? 'bg-emerald-600/30 text-emerald-200 font-bold border border-emerald-500/40' : 'text-slate-300 hover:bg-white/5 hover:text-white'"
            @click="menuOpen = false"
          >
            <span class="flex items-center gap-3">
              <component
                :is="item.icon"
                :size="18"
                class="transition-colors"
                :class="isActive(item) ? 'text-emerald-300' : 'text-slate-400 group-hover:text-white'"
              />
              {{ item.label }}
            </span>
            <span
              v-if="item.badge"
              class="grid min-w-5 place-items-center rounded-full bg-amber-500 px-1.5 py-0.5 text-[11px] font-black text-black animate-pulse"
            >
              {{ item.badge }}
            </span>
          </RouterLink>
        </nav>

        <!-- Switch to Learner LMS View -->
        <div class="mt-6 rounded-lg border border-white/10 bg-white/5 p-3">
          <p class="text-xs font-bold text-slate-300">Learner Perspective</p>
          <p class="mt-1 text-[11px] text-slate-400">
            Preview the learning space as students and instructors see it.
          </p>
          <RouterLink
            to="/dashboard"
            class="mt-2.5 flex items-center justify-center gap-1.5 rounded bg-white/10 py-2 text-xs font-bold text-white transition-colors hover:bg-white/20"
            @click="menuOpen = false"
          >
            <ExternalLink :size="13" /> Open Learner LMS
          </RouterLink>
        </div>
      </div>

      <!-- User footer -->
      <div class="border-t border-white/10 pt-4">
        <div class="flex items-center gap-3 px-2 pb-3">
          <span class="grid size-9 shrink-0 place-items-center rounded-full bg-emerald-600 font-bold text-white shadow-sm">
            {{ initials }}
          </span>
          <div class="min-w-0 flex-1">
            <span class="block truncate text-sm font-bold text-white">{{ displayName }}</span>
            <span class="block truncate text-xs text-emerald-300/80">Platform Owner</span>
          </div>
        </div>
        <button
          type="button"
          class="flex min-h-10 w-full items-center gap-3 rounded-lg px-3 text-sm font-semibold text-slate-300 transition-colors hover:bg-white/10 hover:text-white disabled:opacity-50"
          :disabled="signingOut"
          @click="signOut"
        >
          <LogOut :size="17" aria-hidden="true" />
          {{ signingOut ? "Signing out..." : "Sign out" }}
        </button>
      </div>
    </aside>

    <!-- Mobile overlay -->
    <div
      v-if="menuOpen"
      class="fixed inset-0 z-30 bg-black/50 backdrop-blur-xs lg:hidden"
      @click="menuOpen = false"
    />

    <!-- Main Workspace -->
    <main class="min-w-0 flex-1 lg:ml-68">
      <!-- Top header bar -->
      <header class="sticky top-0 z-20 hidden h-16 items-center justify-between border-b border-border bg-white px-8 lg:flex">
        <div class="flex items-center gap-2 text-sm text-muted-foreground">
          <span class="font-bold text-primary">Admin Console</span>
          <span aria-hidden="true">/</span>
          <span class="font-semibold text-foreground">{{ currentSectionTitle }}</span>
        </div>

        <div class="flex items-center gap-4">
          <div class="flex items-center gap-2 rounded-full border border-border bg-secondary/60 px-3 py-1 text-xs font-semibold text-foreground/80">
            <span class="size-2 rounded-full bg-emerald-500 animate-ping" />
            <span>Platform Active</span>
          </div>

          <RouterLink
            to="/dashboard"
            class="inline-flex items-center gap-1.5 rounded-md border border-primary/30 px-3 py-1.5 text-xs font-bold text-primary hover:bg-secondary"
          >
            <ExternalLink :size="13" />
            Switch to Learner View
          </RouterLink>

          <span class="inline-flex items-center gap-1.5 rounded-full bg-[#163b32] px-3 py-1 text-xs font-bold text-white">
            <ShieldCheck :size="14" />
            Super Admin
          </span>
        </div>
      </header>

      <!-- Main content view -->
      <div class="mx-auto w-full max-w-7xl px-4 py-6 sm:px-6 lg:px-8 lg:py-8">
        <RouterView />
      </div>
    </main>
  </div>
</template>

