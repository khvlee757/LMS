<script setup>
import { ref } from "vue";
import { useRouter, useRoute, RouterLink } from "vue-router";
import Footer from "@/components/footer.vue";
import icon from "@/assets/book.png";

const router = useRouter();
const route = useRoute();

const isOpen = ref(true);
const mobileOpen = ref(false);

const savedForm = localStorage.getItem("form");
const savedAdmin = localStorage.getItem("adminSession");

let user = null;
let admin = null;

try {
  user = savedForm ? JSON.parse(savedForm) : null;
} catch {
  user = null;
}

try {
  admin = savedAdmin ? JSON.parse(savedAdmin) : null;
} catch {
  admin = null;
}

const toggleSidebar = () => {
  isOpen.value = !isOpen.value;
};

const toggleMobileSidebar = () => {
  mobileOpen.value = !mobileOpen.value;
};

const closeMobileSidebar = () => {
  mobileOpen.value = false;
};

const logout = () => {
  localStorage.removeItem("form");
  localStorage.removeItem("lmsRole");
  localStorage.removeItem("adminSession");
  localStorage.removeItem("firstTimeUser");

  router.push("/login");
};

const isActive = (path) => {
  return route.path === path || route.path.startsWith(`${path}/`);
};
</script>

<template>
  <div class="min-h-screen w-full overflow-x-hidden bg-secondary/40">

    <div
      v-if="mobileOpen"
      @click="closeMobileSidebar"
      class="fixed inset-0 z-40 bg-black/50 backdrop-blur-sm lg:hidden"
    ></div>

    <aside
      class="fixed left-0 top-0 z-50 flex h-screen flex-col overflow-hidden bg-primary text-white shadow-2xl transition-all duration-300"
      :class="[
        isOpen ? 'w-64' : 'w-20',
        mobileOpen
          ? 'translate-x-0'
          : '-translate-x-full lg:translate-x-0'
      ]"
    >

      <div
        class="relative shrink-0 overflow-hidden border-b border-white/10"
        :class="isOpen ? 'h-40' : 'h-20'"
      >

        <img
          :src="icon"
          alt="LMS"
          class="absolute inset-0 h-full w-full object-cover"
        />

        <div
          class="absolute inset-0 bg-black/20"
        ></div>

        <div
          class="absolute inset-0 bg-primary/20"
        ></div>

        <button
          type="button"
          @click="toggleSidebar"
          class="absolute right-3 top-3 z-10 hidden h-9 w-9 items-center justify-center rounded-full bg-black/30 text-white backdrop-blur-md transition hover:bg-white hover:text-primary lg:flex"
        >

          <svg
            v-if="isOpen"
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
            stroke-linecap="round"
            stroke-linejoin="round"
            class="h-5 w-5"
          >
            <path d="m15 18-6-6 6-6" />
          </svg>

          <svg
            v-else
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
            stroke-linecap="round"
            stroke-linejoin="round"
            class="h-5 w-5"
          >
            <path d="m9 18 6-6-6-6" />
          </svg>

        </button>

        <button
          type="button"
          @click="closeMobileSidebar"
          class="absolute right-3 top-3 z-10 flex h-10 w-10 items-center justify-center rounded-full bg-black/30 text-white backdrop-blur-md transition hover:bg-white hover:text-primary lg:hidden"
        >

          <svg
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
            stroke-linecap="round"
            stroke-linejoin="round"
            class="h-6 w-6"
          >
            <path d="M6 6l12 12" />
            <path d="M18 6L6 18" />
          </svg>

        </button>

        <div
          v-if="isOpen"
          class="absolute bottom-4 left-4 z-10"
        >
          <p class="text-lg font-bold text-white drop-shadow-lg">
            LMS
          </p>

          <p class="text-xs text-white/80">
            Learning Management System
          </p>
        </div>

      </div>

      <nav class="flex-1 overflow-y-auto overflow-x-hidden px-2 py-4">

        <p
          v-if="isOpen"
          class="mb-3 px-3 text-[10px] font-bold uppercase tracking-[0.2em] text-white/40"
        >
          Main Menu
        </p>

        <div class="space-y-1.5">

          <RouterLink
            to="/dashboard"
            @click="closeMobileSidebar"
            class="group relative flex w-full items-center rounded-xl py-3 transition-all duration-200"
            :class="[
              isOpen ? 'gap-3 px-3' : 'justify-center px-0',
              isActive('/dashboard')
                ? 'bg-white text-primary shadow-lg'
                : 'text-white/80 hover:bg-white/10 hover:text-white'
            ]"
          >

            <svg
              xmlns="http://www.w3.org/2000/svg"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="2"
              stroke-linecap="round"
              stroke-linejoin="round"
              class="h-5 w-5 shrink-0"
            >
              <path d="M3 10.5L12 3l9 7.5" />
              <path d="M5 9.5V21h14V9.5" />
              <path d="M9 21v-6h6v6" />
            </svg>

            <span
              v-if="isOpen"
              class="whitespace-nowrap text-sm font-medium"
            >
              Dashboard
            </span>

            <span
              v-if="!isOpen"
              class="pointer-events-none absolute left-16 hidden whitespace-nowrap rounded-lg bg-black px-3 py-2 text-sm text-white opacity-0 shadow-lg transition group-hover:opacity-100 lg:block"
            >
              Dashboard
            </span>

          </RouterLink>

          <RouterLink
            to="/courses"
            @click="closeMobileSidebar"
            class="group relative flex w-full items-center rounded-xl py-3 transition-all duration-200"
            :class="[
              isOpen ? 'gap-3 px-3' : 'justify-center px-0',
              isActive('/courses')
                ? 'bg-white text-primary shadow-lg'
                : 'text-white/80 hover:bg-white/10 hover:text-white'
            ]"
          >

            <svg
              xmlns="http://www.w3.org/2000/svg"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="2"
              stroke-linecap="round"
              stroke-linejoin="round"
              class="h-5 w-5 shrink-0"
            >
              <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20" />
              <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2Z" />
            </svg>

            <span
              v-if="isOpen"
              class="whitespace-nowrap text-sm font-medium"
            >
              Courses
            </span>

            <span
              v-if="!isOpen"
              class="pointer-events-none absolute left-16 hidden whitespace-nowrap rounded-lg bg-black px-3 py-2 text-sm text-white opacity-0 shadow-lg transition group-hover:opacity-100 lg:block"
            >
              Courses
            </span>

          </RouterLink>

          <RouterLink
            to="/my-learning"
            @click="closeMobileSidebar"
            class="group relative flex w-full items-center rounded-xl py-3 transition-all duration-200"
            :class="[
              isOpen ? 'gap-3 px-3' : 'justify-center px-0',
              isActive('/my-learning')
                ? 'bg-white text-primary shadow-lg'
                : 'text-white/80 hover:bg-white/10 hover:text-white'
            ]"
          >

            <svg
              xmlns="http://www.w3.org/2000/svg"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="2"
              stroke-linecap="round"
              stroke-linejoin="round"
              class="h-5 w-5 shrink-0"
            >
              <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20" />
              <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2Z" />
              <path d="M8 7h8" />
              <path d="M8 11h6" />
            </svg>

            <span
              v-if="isOpen"
              class="whitespace-nowrap text-sm font-medium"
            >
              My Learning
            </span>

            <span
              v-if="!isOpen"
              class="pointer-events-none absolute left-16 hidden whitespace-nowrap rounded-lg bg-black px-3 py-2 text-sm text-white opacity-0 shadow-lg transition group-hover:opacity-100 lg:block"
            >
              My Learning
            </span>

          </RouterLink>

          <RouterLink
            to="/settings"
            @click="closeMobileSidebar"
            class="group relative flex w-full items-center rounded-xl py-3 transition-all duration-200"
            :class="[
              isOpen ? 'gap-3 px-3' : 'justify-center px-0',
              isActive('/settings')
                ? 'bg-white text-primary shadow-lg'
                : 'text-white/80 hover:bg-white/10 hover:text-white'
            ]"
          >

            <svg
              xmlns="http://www.w3.org/2000/svg"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="2"
              stroke-linecap="round"
              stroke-linejoin="round"
              class="h-5 w-5 shrink-0"
            >
              <circle cx="12" cy="12" r="3" />
              <path d="M19.4 15a1.7 1.7 0 0 0 .34 1.88l.06.06-1.8 1.8-.06-.06a1.7 1.7 0 0 0-1.88-.34 1.7 1.7 0 0 0-1.03 1.56V20h-2.54v-.1a1.7 1.7 0 0 0-1.03-1.56 1.7 1.7 0 0 0-1.88.34l-.06.06-1.8-1.8.06-.06A1.7 1.7 0 0 0 8.1 15a1.7 1.7 0 0 0-1.56-1.03H6.4v-2.54h.14A1.7 1.7 0 0 0 8.1 10.4a1.7 1.7 0 0 0-.34-1.88L7.7 8.46l1.8-1.8.06.06a1.7 1.7 0 0 0 1.88.34 1.7 1.7 0 0 0 1.03-1.56V5.4h2.54v.1a1.7 1.7 0 0 0 1.03 1.56 1.7 1.7 0 0 0 1.88-.34l.06-.06 1.8 1.8-.06.06A1.7 1.7 0 0 0 19.4 10.4a1.7 1.7 0 0 0 1.56 1.03h.14v2.54h-.14A1.7 1.7 0 0 0 19.4 15Z" />
            </svg>

            <span
              v-if="isOpen"
              class="whitespace-nowrap text-sm font-medium"
            >
              Settings
            </span>

            <span
              v-if="!isOpen"
              class="pointer-events-none absolute left-16 hidden whitespace-nowrap rounded-lg bg-black px-3 py-2 text-sm text-white opacity-0 shadow-lg transition group-hover:opacity-100 lg:block"
            >
              Settings
            </span>

          </RouterLink>

        </div>
      </nav>

      <div class="shrink-0 border-t border-white/10 p-2">

        <div v-if="isOpen" class="mb-2 rounded-xl bg-white/10 px-3 py-2.5">
          <p class="truncate text-sm font-semibold text-white">
            {{ (admin?.email ? 'Admin' : user?.name) || "Guest" }}
          </p>

          <p class="truncate text-xs text-white/50">
            {{ admin?.email || user?.email || "john.doe@example.com" }}
          </p>
        </div>

        <button
          type="button"
          @click="logout"
          class="group relative flex w-full items-center rounded-xl bg-white/10 py-3 text-white transition hover:bg-red-500/20 hover:text-red-200"
          :class="isOpen ? 'gap-3 px-3' : 'justify-center px-0'"
        >

          <svg
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
            stroke-linecap="round"
            stroke-linejoin="round"
            class="h-5 w-5 shrink-0"
          >
            <path d="M10 17l5-5-5-5" />
            <path d="M15 12H3" />
            <path d="M21 19V5a2 2 0 0 0-2-2h-6" />
          </svg>

          <span
            v-if="isOpen"
            class="text-sm font-medium"
          >
            Logout
          </span>

          <span
            v-if="!isOpen"
            class="pointer-events-none absolute left-16 hidden whitespace-nowrap rounded-lg bg-black px-3 py-2 text-sm text-white opacity-0 shadow-lg transition group-hover:opacity-100 lg:block"
          >
            Logout
          </span>

        </button>

      </div>

    </aside>

    <main
      class="min-h-screen w-full transition-all duration-300"
      :class="
        isOpen
          ? 'lg:ml-64 lg:w-[calc(100%-16rem)]'
          : 'lg:ml-20 lg:w-[calc(100%-5rem)]'
      "
    >

      <header
        class="sticky top-0 z-30 flex h-16 items-center border-b border-black/5 bg-white/90 px-4 shadow-sm backdrop-blur-md sm:px-6 lg:px-7"
      >

        <button
          type="button"
          @click="toggleMobileSidebar"
          class="mr-3 flex h-10 w-10 items-center justify-center rounded-xl bg-primary text-white shadow-sm transition hover:bg-primary/90 lg:hidden"
        >

          <svg
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
            stroke-linecap="round"
            stroke-linejoin="round"
            class="h-5 w-5"
          >
            <path d="M4 6h16" />
            <path d="M4 12h16" />
            <path d="M4 18h16" />
          </svg>

        </button>

        <div>
          <p class="text-[11px] text-gray-400">
            Welcome back
          </p>

          <h2 class="text-lg font-bold leading-tight text-primary sm:text-xl">
            {{ user?.name || "Guest" }}
          </h2>
        </div>

      </header>

      <section class="min-h-[calc(100vh-4rem)] w-full">
        <slot />
      </section>

      <Footer />

    </main>

  </div>
</template>