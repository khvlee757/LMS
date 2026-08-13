<script setup>
const savedForm = localStorage.getItem('form');
const user = savedForm ? JSON.parse(savedForm) : null;

import icon from '@/assets/book.png';
</script>


<template>
  <div class="drawer lg:drawer-open h-screen">
    <input id="my-drawer-4" type="checkbox" class="drawer-toggle" />
    <div class="drawer-content">
        
      <!-- Navbar -->
      <nav class="navbar w-full">
        <label for="my-drawer-4" aria-label="open sidebar" class="btn btn-square bg-primary drawer-button">
          <!-- Sidebar toggle icon -->
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" stroke-linejoin="round" stroke-linecap="round" stroke-width="2" fill="none" stroke="currentColor" class="my-1.5 inline-block size-4"><path d="M4 4m0 2a2 2 0 0 1 2 -2h12a2 2 0 0 1 2 2v12a2 2 0 0 1 -2 2h-12a2 2 0 0 1 -2 -2z"></path><path d="M9 4v16"></path><path d="M14 10l2 2l-2 2"></path></svg>
        </label>
        <div class="px-4">Navbar Title</div>
      </nav>
      <!-- Page content here -->
      <div class="p-4"><slot /></div>
    </div>

    <div class="drawer-side">
      <label for="my-drawer-4" aria-label="close sidebar" class="drawer-overlay"></label>
      
      <div class="flex min-h-full flex-col items-start bg-primary/30 is-drawer-close:w-14 is-drawer-open:w-64">
        <div class="w-full px-4 mt-3">
          <img
            :src="icon"
            alt="icon"
            class="w-full h-32 object-cover transition-all duration-200 ease-in-out is-drawer-close:w-10 is-drawer-close:h-10 is-drawer-close:rounded-full is-drawer-close:mx-auto"
          />
        </div>
        <!-- Sidebar content here -->
        <ul class="menu w-full grow mt-4 px-2 text-lg space-y-3 is-drawer-close:space-y-0 is-drawer-close:gap-2 is-drawer-close:overflow-hidden is-drawer-close:pt-4 is-drawer-close:text-center">
          <!-- List item -->
          <li>
            <button class="is-drawer-close:tooltip is-drawer-close:tooltip-right" data-tip="Homepage">
              <!-- Home icon -->
              <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" stroke-linejoin="round" stroke-linecap="round" stroke-width="2" fill="none" stroke="currentColor" class="my-1.5 inline-block size-4 transition-transform duration-200 ease-in-out is-drawer-close:scale-90 is-drawer-open:scale-100"><path d="M15 21v-8a1 1 0 0 0-1-1h-4a1 1 0 0 0-1 1v8"></path><path d="M3 10a2 2 0 0 1 .709-1.528l7-5.999a2 2 0 0 1 2.582 0l7 5.999A2 2 0 0 1 21 10v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"></path></svg>
              <span class="is-drawer-close:hidden">Homepage</span>
            </button>
          </li>

          <!-- List item -->
          <li>
            <button class="is-drawer-close:tooltip is-drawer-close:tooltip-right" data-tip="Settings">
              <!-- Settings icon -->
              <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" stroke-linejoin="round" stroke-linecap="round" stroke-width="2" fill="none" stroke="currentColor" class="my-1.5 inline-block size-4 transition-transform duration-200 ease-in-out is-drawer-close:scale-90 is-drawer-open:scale-100"><path d="M20 7h-9"></path><path d="M14 17H5"></path><circle cx="17" cy="17" r="3"></circle><circle cx="7" cy="7" r="3"></circle></svg>
              <span class="is-drawer-close:hidden">Settings</span>
            </button>
          </li>

           <li>
            <button class="is-drawer-close:tooltip is-drawer-close:tooltip-right" >
              <!-- Settings icon -->
              <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" stroke-linejoin="round" stroke-linecap="round" stroke-width="2" fill="none" stroke="currentColor" class="my-1.5 inline-block size-4 transition-transform duration-200 ease-in-out is-drawer-close:scale-90 is-drawer-open:scale-100"><path d="M20 7h-9"></path><path d="M14 17H5"></path><circle cx="17" cy="17" r="3"></circle><circle cx="7" cy="7" r="3"></circle></svg>
              <span class="is-drawer-close:hidden">Courses</span>
            </button>
          </li>
        </ul>

        <div class="w-full p-4 mt-auto">
          <div class="flex items-center gap-3 mb-3">
            <div class="flex flex-col">
              <span class="font-bold text-base">{{ user?.name || 'Guest' }}</span>
              <span class="text-sm text-muted-foreground">{{ user?.email || 'john.doe@example.com' }}</span>
            </div>
          </div>
          <button class="btn btn-block btn-primary">Logout</button>
        </div>
      </div>
    </div>
  </div>

</template>