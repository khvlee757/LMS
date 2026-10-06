<script setup>
import { computed, onMounted, ref } from "vue";
import { RouterLink, RouterView, useRoute, useRouter } from "vue-router";
import {
  BookOpen,
  ChartNoAxesCombined,
  GraduationCap,
  LayoutDashboard,
  LogOut,
  Menu,
  SquarePen,
  ShieldCheck,
  X,
} from "lucide-vue-next";
import { getAuthenticatedProfile } from "@/lib/auth";
import { supabase } from "@/lib/supabase";
import northstarMark from "@/assets/northstar-mark.png";

const route = useRoute();
const router = useRouter();
const profile = ref(null);
const userEmail = ref("");
const menuOpen = ref(false);
const signingOut = ref(false);
const navigation = computed(() => [
  { label: "Overview", to: "/dashboard", icon: LayoutDashboard },
  { label: "Course catalog", to: "/courses", icon: BookOpen },
  { label: "Books", to: "/books", icon: BookOpen },
  { label: "My learning", to: "/learning", icon: GraduationCap },
  ...(["instructor", "super_admin"].includes(profile.value?.role)
    ? [{ label: "Instructor studio", to: "/instructor", icon: SquarePen }]
    : []),
  ...(profile.value?.role === "super_admin"
    ? [{ label: "Administration", to: "/admin", icon: ShieldCheck }]
    : []),
]);
const pageTitle = computed(() => {
  const titles = {
    dashboard: "Overview",
    courses: "Course catalog",
    books: "Books",
    learning: "My learning",
    instructor: "Instructor studio",
    admin: "Administration",
  };
  return titles[route.name] ?? "Learning space";
});
const displayName = computed(
  () => profile.value?.full_name || userEmail.value || "Learner"
);
const initials = computed(() =>
  displayName.value
    .split(/[\s@._-]+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((part) => part[0].toUpperCase())
    .join("")
);

onMounted(async () => {
  const { user, profile: userProfile } = await getAuthenticatedProfile();
  profile.value = userProfile;
  userEmail.value = user?.email ?? "";
});

async function signOut() {
  if (!supabase || signingOut.value) return;
  signingOut.value = true;
  await supabase.auth.signOut();
  await router.replace({ name: "login" });
  signingOut.value = false;
}
</script>

<template>
  <div class="min-h-screen bg-secondary text-foreground lg:flex">
    <header class="sticky top-0 z-30 flex h-16 items-center justify-between border-b border-border bg-white px-4 lg:hidden">
      <RouterLink to="/dashboard" class="flex items-center gap-2 font-extrabold text-primary">
        <img :src="northstarMark" alt="" class="size-9" />
        <span>Northstar Learning</span>
      </RouterLink>
      <button
        type="button"
        class="grid size-10 place-items-center rounded-md text-primary outline-none hover:bg-secondary focus-visible:ring-2 focus-visible:ring-primary"
        :aria-label="menuOpen ? 'Close navigation' : 'Open navigation'"
        :aria-expanded="menuOpen"
        @click="menuOpen = !menuOpen"
      >
        <X v-if="menuOpen" :size="21" />
        <Menu v-else :size="21" />
      </button>
    </header>

    <aside
      class="fixed inset-y-16 left-0 z-20 w-72 border-r border-border bg-primary px-4 py-5 transition-transform lg:inset-y-0 lg:w-64 lg:translate-x-0"
      :class="menuOpen ? 'translate-x-0' : '-translate-x-full'"
    >
      <RouterLink to="/dashboard" class="hidden items-center gap-3 px-3 pb-9 pt-3 lg:flex">
        <img :src="northstarMark" alt="" class="size-10" />
        <span>
          <span class="block font-extrabold text-foreground">Northstar Learning</span>
          <span class="block text-xs text-muted-foreground">Learning platform</span>
        </span>
      </RouterLink>

      <p class="px-3 pb-3 text-[11px] font-bold uppercase tracking-[0.14em] text-muted-foreground">Workspace</p>
      <nav aria-label="Main navigation" class="space-y-1">
        <RouterLink
          v-for="item in navigation"
          :key="item.to"
          :to="item.to"
          class="flex min-h-11 items-center gap-3 rounded-md px-3 text-sm font-semibold transition-colors outline-none focus-visible:ring-2 focus-visible:ring-primary"
          :class="route.path === item.to ? 'bg-secondary text-primary' : 'text-foreground/75 hover:bg-primary hover:text-secondary'"
          @click="menuOpen = false"
        >
          <component :is="item.icon" :size="18" aria-hidden="true" />
          {{ item.label }}
        </RouterLink>
      </nav>

      <div class="absolute inset-x-4 bottom-4 border-t border-border pt-4">
        <div class="flex items-center gap-3 px-2 pb-3">
          <span class="grid size-10 shrink-0 place-items-center rounded-full bg-accent font-bold text-accent-foreground">{{ initials }}</span>
          <span class="min-w-0 flex-1">
            <span class="block truncate text-sm font-semibold">{{ displayName }}</span>
            <span class="block truncate text-xs capitalize text-muted-foreground">{{ profile?.role?.replace('_', ' ') || 'student' }}</span>
          </span>
          <ChartNoAxesCombined v-if="profile?.role === 'super_admin'" :size="16" class="text-primary" aria-label="Super admin" />
        </div>
        <button
          type="button"
          class="flex min-h-10 w-full items-center gap-3 rounded-md px-3 text-sm font-semibold text-muted-foreground outline-none hover:bg-secondary hover:text-foreground focus-visible:ring-2 focus-visible:ring-primary disabled:opacity-50"
          :disabled="signingOut"
          @click="signOut"
        >
          <LogOut :size="17" aria-hidden="true" />
          {{ signingOut ? 'Signing out...' : 'Sign out' }}
        </button>
      </div>
    </aside>

    <div v-if="menuOpen" class="fixed inset-0 z-10 bg-foreground/20 lg:hidden" @click="menuOpen = false" />

    <main class="min-w-0 flex-1 lg:ml-64">
      <div class="hidden h-16 items-center justify-between border-b border-border bg-white px-8 lg:flex">
        <div class="flex items-center gap-2 text-sm text-muted-foreground">
          <span>Workspace</span><span aria-hidden="true">/</span><span class="font-semibold text-foreground">{{ pageTitle }}</span>
        </div>
        <div class="flex items-center gap-2 text-sm font-medium text-foreground/80">
          <span class="size-2 rounded-full bg-emerald-500" aria-hidden="true" />
          Learning space
        </div>
      </div>
      <div class="mx-auto w-full max-w-7xl px-4 py-7 sm:px-6 lg:px-8 lg:py-9">
        <RouterView />
      </div>
    </main>
  </div>
</template>
