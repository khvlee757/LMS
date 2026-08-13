<script setup>
import { ref } from 'vue';
import { useRouter } from 'vue-router';
import CourseCard from '@/components/dashboard/CourseCard.vue';
import Sidebar from '@/components/Sidebar.vue';

const router = useRouter();

const available = ref([
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
    {
    id: 'marketing',
    title: 'Marketing Strategy',
    category: 'Business',
    mentor: 'Sophia Green',
    lessons: 9,
    progress: 0,
    image: new URL('@/assets/book.png', import.meta.url).href,
  },
]);

function addCourse(course) {
  const stored = localStorage.getItem('enrolledCourses');
  let enrolled = [];
  try {
    enrolled = stored ? JSON.parse(stored) : [];
  } catch (e) {
    enrolled = [];
  }

  if (!enrolled.find((c) => c.id === course.id)) {
    enrolled.push({ ...course });
    localStorage.setItem('enrolledCourses', JSON.stringify(enrolled));
  }

  // navigate back to dashboard to show added course
  router.push('/dashboard');
}
</script>

<template>
  <Sidebar>
    <main class="p-6">
      <div class="mb-6 flex items-center justify-between">
        <div>
          <p class="text-sm text-muted-foreground">Explore</p>
          <h1 class="text-2xl font-bold">Available courses</h1>
        </div>
      </div>

      <div class="grid gap-6 md:grid-cols-2 xl:grid-cols-3">
        <div v-for="course in available" :key="course.id">
          <div class="space-y-4">
            <CourseCard :course="course" />
            <div class="flex items-center justify-center">
              <button @click="addCourse(course)" class="rounded-md bg-primary px-4 py-2 text-white">Add</button>
            </div>
          </div>
        </div>
      </div>
    </main>
  </Sidebar>
</template>
