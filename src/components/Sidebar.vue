<script setup>
import { ref } from "vue";
import { useRouter, useRoute, RouterLink } from "vue-router";
import icon from "@/assets/book.png";

const router = useRouter();
const route = useRoute();

const isOpen = ref(true);
const mobileOpen = ref(false);

const savedForm = localStorage.getItem("form");
const user = savedForm ? JSON.parse(savedForm) : null;

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
  router.push("/login");
};

const isActive = (path) => {
  return route.path === path || route.path.startsWith(`${path}/`);
};
</script>

<template>
  <div class="min-h-screen w-full overflow-x-hidden bg-background/50">

    <div
      v-if="mobileOpen"
      @click="closeMobileSidebar"
      class="fixed inset-0 z-40 bg-black/50 lg:hidden"
    ></div>

    <aside
      class="fixed left-0 top-0 z-50 flex h-screen w-72 flex-col overflow-hidden bg-primary text-white shadow-xl transition-[width,transform] duration-300 lg:border-r lg:border-primary/10"
      :class="[
        isOpen ? 'lg:w-64' : 'lg:w-20',
        mobileOpen
          ? 'translate-x-0'
          : '-translate-x-full lg:translate-x-0'
      ]"
    >

      <div
        class="flex h-24 shrink-0 items-center border-b border-white/10 px-4"
        :class="isOpen ? 'justify-between' : 'lg:justify-center'"
      >

        <img
          :src="icon"
          alt="LMS"
          class="rounded-2xl object-cover transition-all duration-300"
          :class="isOpen ? 'h-20 w-20' : 'h-12 w-12'"
        />

        <button
          type="button"
          @click="toggleSidebar"
          class="hidden rounded-lg p-2 text-white transition hover:bg-white/10 lg:block"
        >
          <svg
            v-if="isOpen"
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
            class="h-5 w-5"
          >
            <path d="M15 18l-6-6 6-6" />
          </svg>

          <svg
            v-else
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
            class="h-5 w-5"
          >
            <path d="M9 18l6-6-6-6" />
          </svg>
        </button>

        <button
          type="button"
          @click="closeMobileSidebar"
          class="rounded-lg p-2 text-white transition hover:bg-white/10 lg:hidden"
        >
          <svg
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
            class="h-6 w-6"
          >
            <path d="M6 6l12 12" />
            <path d="M18 6L6 18" />
          </svg>
        </button>

      </div>

      <nav class="flex-1 overflow-y-auto overflow-x-hidden px-3 py-6">

        <p
          v-if="isOpen"
          class="mb-4 px-3 text-xs font-bold uppercase tracking-widest text-white/50"
        >
          Main Menu
        </p>

        <div class="space-y-2">

          <RouterLink
            to="/dashboard"
            @click="closeMobileSidebar"
            class="group relative flex w-full items-center rounded-xl px-3 py-3 transition-all duration-200"
            :class="[
              isOpen ? 'gap-3' : 'lg:justify-center',
              isActive('/dashboard')
                ? 'bg-white text-primary shadow-md'
                : 'text-white hover:bg-white/10'
            ]"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="2"
              class="h-5 w-5 shrink-0"
            >
              <path d="M3 10.5L12 3l9 7.5" />
              <path d="M5 9.5V21h14V9.5" />
              <path d="M9 21v-6h6v6" />
            </svg>

            <span
              v-if="isOpen"
              class="whitespace-nowrap font-medium"
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
            class="group relative flex w-full items-center rounded-xl px-3 py-3 transition-all duration-200"
            :class="[
              isOpen ? 'gap-3' : 'lg:justify-center',
              isActive('/courses')
                ? 'bg-white text-primary shadow-md'
                : 'text-white hover:bg-white/10'
            ]"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="2"
              class="h-5 w-5 shrink-0"
            >
              <path d="M4 19.5A2.5 2.5 0 016.5 17H20" />
              <path
                d="M6.5 2H20v20H6.5A2.5 2.5 0 014 19.5v-15A2.5 2.5 0 016.5 2Z"
              />
            </svg>

            <span
              v-if="isOpen"
              class="whitespace-nowrap font-medium"
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
            to="/ my-learning"
            @click="closeMobileSidebar"
            class="group relative flex w-full items-center rounded-xl px-3 py-3 transition-all duration-200"
            :class="[
              isOpen ? 'gap-3' : 'lg:justify-center',
              isActive('/ my-learning')
                ? 'bg-white text-primary shadow-md'
                : 'text-white hover:bg-white/10'
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
  <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z" />
  <path d="M8 7h8" />
  <path d="M8 11h6" />
</svg>

            <span
              v-if="isOpen"
              class="whitespace-nowrap font-medium"
            >
             my-learning
            </span>

            <span
              v-if="!isOpen"
              class="pointer-events-none absolute left-16 hidden whitespace-nowrap rounded-lg bg-black px-3 py-2 text-sm text-white opacity-0 shadow-lg transition group-hover:opacity-100 lg:block"
            >
               my-learning
            </span>
          </RouterLink>

          <RouterLink
            to="/settings"
            @click="closeMobileSidebar"
            class="group relative flex w-full items-center rounded-xl px-3 py-3 transition-all duration-200"
            :class="[
              isOpen ? 'gap-3' : 'lg:justify-center',
              isActive('/settings')
                ? 'bg-white text-primary shadow-md'
                : 'text-white hover:bg-white/10'
            ]"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="2"
              class="h-5 w-5 shrink-0"
            >
              <path d="M12 15.5a3.5 3.5 0 100-7 3.5 3.5 0 000 7Z" />
              <path
                d="M19.4 15a1.7 1.7 0 00.34 1.88l.06.06-1.8 1.8-.06-.06a1.7 1.7 0 00-1.88-.34 1.7 1.7 0 00-1.03 1.56V20h-2.54v-.1a1.7 1.7 0 00-1.03-1.56 1.7 1.7 0 00-1.88.34l-.06.06-1.8-1.8-.06-.06A1.7 1.7 0 008.1 15a1.7 1.7 0 00-1.56-1.03H6.4v-2.54h.14A1.7 1.7 0 008.1 10.4a1.7 1.7 0 00-.34-1.88L7.7 8.46l1.8-1.8.06.06a1.7 1.7 0 001.88.34 1.7 1.7 0 001.03-1.56V5.4h2.54v.1a1.7 1.7 0 001.03 1.56 1.7 1.7 0 001.88-.34l.06-.06 1.8 1.8-.06.06A1.7 1.7 0 0019.4 10.4a1.7 1.7 0 001.56 1.03h.14v2.54h-.14A1.7 1.7 0 0019.4 15Z"
              />
            </svg>

            <span
              v-if="isOpen"
              class="whitespace-nowrap font-medium"
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

      <div class="shrink-0 border-t border-white/10 p-3">

        <div
          v-if="isOpen"
          class="mb-3 rounded-xl bg-white/10 p-3"
        >
          <p class="truncate text-sm font-semibold text-white">
            {{ user?.name || "Guest" }}
          </p>

          <p class="truncate text-xs text-white/60">
            {{ user?.email || "john.doe@example.com" }}
          </p>
        </div>

        <button
          type="button"
          @click="logout"
          class="group relative flex w-full items-center rounded-xl bg-white/10 px-3 py-3 text-white transition hover:bg-red-500/20 hover:text-red-200"
          :class="isOpen ? 'gap-3' : 'lg:justify-center'"
        >
          <svg
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
            class="h-5 w-5 shrink-0"
          >
            <path d="M10 17l5-5-5-5" />
            <path d="M15 12H3" />
            <path d="M21 19V5a2 2 0 00-2-2h-6" />
          </svg>

          <span
            v-if="isOpen"
            class="font-medium text-white"
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
      class="min-h-screen w-full transition-[margin,width] duration-300"
      :class="
        isOpen
          ? 'lg:ml-64 lg:w-[calc(100%-16rem)]'
          : 'lg:ml-20 lg:w-[calc(100%-5rem)]'
      "
    >

      <header
        class="sticky top-0 z-30 flex h-20 items-center border-b bg-white/90 px-4 shadow-sm backdrop-blur-md sm:px-6 lg:px-8"
      >

        <button
          type="button"
          @click="toggleMobileSidebar"
          class="mr-3 rounded-xl bg-primary p-3 text-white shadow-sm transition hover:opacity-90 lg:hidden"
        >
          <svg
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
            class="h-5 w-5"
          >
            <path d="M4 6h16" />
            <path d="M4 12h16" />
            <path d="M4 18h16" />
          </svg>
        </button>

        <h2 class="text-2xl font-bold text-primary sm:text-xl">
          <span class="text-md text-black">Welcome</span>
          {{ user?.name || "Guest" }}
        </h2>

      </header>

      <section class="p-4 sm:p-6 lg:p-8">
        <slot />
      </section>

    </main>

  </div>
</template>