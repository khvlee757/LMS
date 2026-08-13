<script setup>
import Sidebar from '@/components/Sidebar.vue';
import DashboardHeader from '@/components/dashboard/DashboardHeader.vue';
import CourseCard from '@/components/dashboard/CourseCard.vue';
import TimeSpentChart from '@/components/dashboard/TimeSpentChart.vue';
import HoursSummary from '@/components/dashboard/HoursSummary.vue';

const savedForm = localStorage.getItem('form');
const user = savedForm ? JSON.parse(savedForm) : null;

import { ref, onMounted } from 'vue';

const defaultAvailable = [
  {
    id: 'uiux',
    title: 'UI/UX Fundamentals',
    category: 'Design',
    mentor: 'Maya Ali',
    lessons: 12,
    progress: 0,
    image: new URL('@/assets/book.png', import.meta.url).href,
  },
  {
    id: 'js',
    title: 'JavaScript Essentials',
    category: 'Development',
    mentor: 'Noah Reed',
    lessons: 18,
    progress: 0,
    image: new URL('@/assets/book.png', import.meta.url).href,
  },
  {
    id: 'marketing',
    title: 'Marketing Strategy',
    category: 'Business',
    mentor: 'Sophia Green',
    lessons: 9,
    progress: 0,
    image: new URL('@/assets/book.png', import.meta.url).href,
  },
];

const courses = ref([]);

onMounted(() => {
  const stored = localStorage.getItem('enrolledCourses');
  if (stored) {
    try {
      courses.value = JSON.parse(stored);
    } catch (e) {
      courses.value = [];
    }
  } else {
    // start plain for first-time users (no enrolled courses)
    courses.value = [];
  }
});

const timeData = [
  { label: 'Mon', value: 2.5, height: '100%' },
  { label: 'Tue', value: 4.2, height: '58%' },
  { label: 'Wed', value: 3.8, height: '52%' },
  { label: 'Thu', value: 5.4, height: '72%' },
  { label: 'Fri', value: 6.1, height: '83%' },
  { label: 'Sat', value: 4.6, height: '63%' },
  { label: 'Sun', value: 3.2, height: '44%' },
];

const totalHours = timeData.reduce((sum, day) => sum + day.value, 0).toFixed(1);

const weeklyStats = [
  { label: 'Design', value: '7.8h', bg: 'bg-primary50' },
  { label: 'Development', value: '12.6h', bg: 'bg-cyan-50' },
  { label: 'Business', value: '9.7h', bg: 'bg-emerald-50' },
];
</script>

<template>
  <Sidebar>
    <main class="p-6">
      <DashboardHeader />

      <div class="grid gap-6 md:grid-cols-2 xl:grid-cols-3">
        <template v-if="courses.length">
          <CourseCard v-for="course in courses" :key="course.id || course.title" :course="course" />
        </template>
        <template v-else>
          <div class="col-span-full">
            <div class="rounded-xl border px-6 py-8 text-center">
              <h2 class="text-xl font-semibold mb-2">No courses yet</h2>
              <p class="text-sm text-muted-foreground mb-4">You haven't enrolled in any courses. Browse available courses to get started.</p>
              <RouterLink to="/courses" class="inline-block rounded-md bg-primary px-4 py-2 text-white">Browse courses</RouterLink>
            </div>
          </div>
        </template>
      </div>

      <div class="mt-8 grid gap-6 lg:grid-cols-[2fr_1fr]">
        <TimeSpentChart :data="timeData" />
        <HoursSummary :total-hours="totalHours" :stats="weeklyStats" />
      </div>
    </main>
  </Sidebar>
</template>
