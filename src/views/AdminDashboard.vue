<script setup>
import { computed, onMounted, ref } from 'vue';
import Sidebar from '@/components/Sidebar.vue';

const form = ref({
  title: '',
  category: '',
  mentor: '',
  lessons: 8,
});

const courses = ref([]);
const registeredUsers = ref([]);

const defaultCourses = [
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

const totalUsers = computed(() => registeredUsers.value.length);
const totalCourses = computed(() => courses.value.length);
const completedUsers = computed(() =>
  registeredUsers.value.filter((user) => Array.isArray(user.completedCourses) && user.completedCourses.length > 0).length,
);
const completionRate = computed(() => {
  if (!totalUsers.value) return 0;
  return Math.round((completedUsers.value / totalUsers.value) * 100);
});

const chartData = computed(() => [
  { label: 'Mon', value: 18 },
  { label: 'Tue', value: 26 },
  { label: 'Wed', value: 22 },
  { label: 'Thu', value: 31 },
  { label: 'Fri', value: 42 },
  { label: 'Sat', value: 34 },
  { label: 'Sun', value: 28 },
]);

const loadState = () => {
  const savedCourses = localStorage.getItem('lmsCatalog');
  const savedUsers = localStorage.getItem('lmsUsers');

  courses.value = savedCourses ? JSON.parse(savedCourses) : defaultCourses;
  if (!savedCourses) {
    localStorage.setItem('lmsCatalog', JSON.stringify(defaultCourses));
  }

  registeredUsers.value = savedUsers ? JSON.parse(savedUsers) : [];
};

onMounted(() => {
  loadState();
});

const addCourse = () => {
  if (!form.value.title || !form.value.category || !form.value.mentor) {
    return;
  }

  const newCourse = {
    id: `${form.value.title.toLowerCase().replace(/\s+/g, '-')}-${Date.now()}`,
    title: form.value.title,
    category: form.value.category,
    mentor: form.value.mentor,
    lessons: Number(form.value.lessons) || 8,
    progress: 0,
    image: new URL('@/assets/book.png', import.meta.url).href,
  };

  const nextCourses = [newCourse, ...courses.value];
  courses.value = nextCourses;
  localStorage.setItem('lmsCatalog', JSON.stringify(nextCourses));

  form.value = {
    title: '',
    category: '',
    mentor: '',
    lessons: 8,
  };
};
</script>

<template>
  <Sidebar>
    <main class="space-y-6 p-6">
      <div class="flex flex-col gap-2 sm:flex-row sm:items-end sm:justify-between">
        <div>
          <p class="text-sm uppercase tracking-wide text-muted-foreground">Overview</p>
          <h1 class="text-3xl font-bold text-primary">Admin dashboard</h1>
        </div>
      </div>

      <section class="grid gap-4 md:grid-cols-3">
        <div class="rounded-2xl border bg-white p-5 shadow-sm">
          <p class="text-sm text-muted-foreground">Registered users</p>
          <h2 class="mt-3 text-3xl font-bold text-primary">{{ totalUsers }}</h2>
        </div>

        <div class="rounded-2xl border bg-white p-5 shadow-sm">
          <p class="text-sm text-muted-foreground">Courses available</p>
          <h2 class="mt-3 text-3xl font-bold text-primary">{{ totalCourses }}</h2>
        </div>

        <div class="rounded-2xl border bg-white p-5 shadow-sm">
          <p class="text-sm text-muted-foreground">Course completion</p>
          <h2 class="mt-3 text-3xl font-bold text-primary">{{ completionRate }}%</h2>
        </div>
      </section>

      <section class="grid gap-6 lg:grid-cols-[2fr_1fr]">
        <div class="rounded-2xl border bg-white p-5 shadow-sm">
          <div class="mb-4 flex items-center justify-between">
            <h3 class="text-xl font-semibold text-primary">Sign-ups</h3>
            <span class="text-sm text-muted-foreground">This week</span>
          </div>

          <div class="flex h-52 items-end gap-3">
            <div
              v-for="day in chartData"
              :key="day.label"
              class="flex flex-1 flex-col items-center justify-end gap-2"
            >
              <span class="text-xs text-muted-foreground">{{ day.value }}</span>
              <div
                class="w-full rounded-t-xl bg-primary/80"
                :style="{ height: `${day.value}%` }"
              ></div>
              <span class="text-xs text-muted-foreground">{{ day.label }}</span>
            </div>
          </div>
        </div>

        <div class="rounded-2xl border bg-white p-5 shadow-sm">
          <h3 class="mb-4 text-xl font-semibold text-primary">Completed learners</h3>
          <div class="space-y-3">
            <div class="flex items-center justify-between rounded-xl bg-primary/5 px-3 py-2">
              <span class="text-sm text-muted-foreground">Completed users</span>
              <span class="font-semibold text-primary">{{ completedUsers }}</span>
            </div>
            <div class="flex items-center justify-between rounded-xl bg-primary/5 px-3 py-2">
              <span class="text-sm text-muted-foreground">In progress</span>
              <span class="font-semibold text-primary">{{ Math.max(totalUsers - completedUsers, 0) }}</span>
            </div>
            <div class="flex items-center justify-between rounded-xl bg-primary/5 px-3 py-2">
              <span class="text-sm text-muted-foreground">Avg. completion</span>
              <span class="font-semibold text-primary">{{ completionRate }}%</span>
            </div>
          </div>
        </div>
      </section>

      <section class="grid gap-6 xl:grid-cols-[1.2fr_0.8fr]">
        <div class="rounded-2xl border bg-white p-5 shadow-sm">
          <div class="mb-4 flex items-center justify-between">
            <h3 class="text-xl font-semibold text-primary">Course catalog</h3>
            <span class="text-sm text-muted-foreground">{{ courses.length }} items</span>
          </div>

          <div class="space-y-3">
            <div
              v-for="course in courses"
              :key="course.id || course.title"
              class="flex items-center justify-between rounded-xl border px-3 py-3"
            >
              <div>
                <p class="font-semibold text-primary">{{ course.title }}</p>
                <p class="text-sm text-muted-foreground">{{ course.category }} · {{ course.mentor }}</p>
              </div>
              <span class="rounded-full bg-primary/10 px-2 py-1 text-xs font-medium text-primary">
                {{ course.lessons }} lessons
              </span>
            </div>
          </div>
        </div>

        <div class="rounded-2xl border bg-white p-5 shadow-sm">
          <h3 class="mb-4 text-xl font-semibold text-primary">Add new course</h3>

          <form class="space-y-4" @submit.prevent="addCourse">
            <div>
              <label class="mb-1 block text-sm font-medium text-primary">Course name</label>
              <input v-model="form.title" type="text" class="w-full rounded-lg border px-3 py-2 outline-none focus:border-primary" placeholder="e.g. Product Design" />
            </div>

            <div>
              <label class="mb-1 block text-sm font-medium text-primary">Category</label>
              <input v-model="form.category" type="text" class="w-full rounded-lg border px-3 py-2 outline-none focus:border-primary" placeholder="e.g. Design" />
            </div>

            <div>
              <label class="mb-1 block text-sm font-medium text-primary">Mentor</label>
              <input v-model="form.mentor" type="text" class="w-full rounded-lg border px-3 py-2 outline-none focus:border-primary" placeholder="e.g. Sarah Lee" />
            </div>

            <div>
              <label class="mb-1 block text-sm font-medium text-primary">Lessons</label>
              <input v-model="form.lessons" type="number" min="1" class="w-full rounded-lg border px-3 py-2 outline-none focus:border-primary" placeholder="8" />
            </div>

            <button type="submit" class="w-full rounded-lg bg-primary px-4 py-3 font-semibold text-white hover:bg-primary/90">
              Save course
            </button>
          </form>
        </div>
      </section>
    </main>
  </Sidebar>
</template>
