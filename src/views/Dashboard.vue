<script setup>
import Sidebar from '@/components/Sidebar.vue';

const savedForm = localStorage.getItem('form');
const user = savedForm ? JSON.parse(savedForm) : null;
</script>

<template>
    <Sidebar>
        <main class="p-6">
            <h1 class="text-3xl font-bold">Dashboard</h1>
            <p class="mt-2 text-lg">Welcome, {{ user?.name || 'Guest' }}.</p>
        </main>
    </Sidebar>
</template>