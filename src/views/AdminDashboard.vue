<script setup lang="ts">
import { computed, onMounted, ref } from "vue";
import Sidebar from "@/components/Sidebar.vue";
import AdminStats from "@/components/admin/AdminStats.vue";
import AdminChartPanel from "@/components/admin/AdminChartPanel.vue";
import RecentEnrollmentsCard from "@/components/admin/RecentEnrollmentsCard.vue";
import CourseTable from "@/components/admin/CourseTable.vue";
import AddCourseForm from "@/components/admin/AddCourseForm.vue";

const courses = ref<any[]>([]);
const registeredUsers = ref<any[]>([]);

const defaultCourses = [
  {
    id: "uiux",
    title: "UI/UX Fundamentals",
    category: "Design",
    mentor: "Maya Ali",
    lessons: 12,
    progress: 0,
    image: new URL("@/assets/book.png", import.meta.url).href,
  },
  {
    id: "js",
    title: "JavaScript Essentials",
    category: "Development",
    mentor: "Noah Reed",
    lessons: 18,
    progress: 0,
    image: new URL("@/assets/book.png", import.meta.url).href,
  },
  {
    id: "marketing",
    title: "Marketing Strategy",
    category: "Business",
    mentor: "Sophia Green",
    lessons: 9,
    progress: 0,
    image: new URL("@/assets/book.png", import.meta.url).href,
  },
];

const totalUsers = computed(() => registeredUsers.value.length);
const totalCourses = computed(() => courses.value.length);

const completedUsers = computed(
  () =>
    registeredUsers.value.filter(
      (user) =>
        Array.isArray(user.completedCourses) && user.completedCourses.length > 0
    ).length
);

const completionRate = computed(() => {
  if (!totalUsers.value) return 0;
  return Math.round((completedUsers.value / totalUsers.value) * 100);
});

const loadState = () => {
  const savedCourses = localStorage.getItem("lmsCatalog");
  const savedUsers = localStorage.getItem("lmsUsers");

  courses.value = savedCourses ? JSON.parse(savedCourses) : defaultCourses;

  if (!savedCourses) {
    localStorage.setItem("lmsCatalog", JSON.stringify(defaultCourses));
  }

  registeredUsers.value = savedUsers ? JSON.parse(savedUsers) : [];
};

onMounted(() => {
  loadState();
  // listen for updates made elsewhere in the app (register/enroll)
  window.addEventListener('lms:usersUpdated', loadState)
});
import { onUnmounted } from 'vue'

onUnmounted(() => {
  window.removeEventListener('lms:usersUpdated', loadState)
})

const addCourse = (payload: {
  title: string;
  category: string;
  mentor: string;
  lessons: number;
}) => {
  if (!payload.title || !payload.category || !payload.mentor) {
    return;
  }

  const newCourse = {
    id: `${payload.title.toLowerCase().replace(/\s+/g, "-")}-${Date.now()}`,
    title: payload.title,
    category: payload.category,
    mentor: payload.mentor,
    lessons: Number(payload.lessons) || 8,
    progress: 0,
    image: new URL("@/assets/book.png", import.meta.url).href,
  };

  const nextCourses = [newCourse, ...courses.value];
  courses.value = nextCourses;
  localStorage.setItem("lmsCatalog", JSON.stringify(nextCourses));
};

const removeCourse = (courseId: string) => {
  const nextCourses = courses.value.filter((course) => course.id !== courseId);
  courses.value = nextCourses;
  localStorage.setItem("lmsCatalog", JSON.stringify(nextCourses));
};

// chart: compute monthly enrollments from stored users/enrollments
const totalEnrollments = computed(() =>
  registeredUsers.value.reduce((total, user) => total + (user.enrolledCourses?.length || 0), 0)
)

const getLastSixMonths = () => {
  const res = []
  const now = new Date()
  for (let i = 5; i >= 0; i--) {
    const d = new Date(now.getFullYear(), now.getMonth() - i, 1)
    res.push({ label: d.toLocaleString(undefined, { month: "short" }), month: d.getMonth(), year: d.getFullYear() })
  }
  return res
}

const chartData = computed(() => {
  const months = getLastSixMonths()
  const counts = new Array(months.length).fill(0)

  const hasTimestamps = registeredUsers.value.some((u: any) => {
    if (u.registeredAt || u.createdAt || u.registrationDate) return true
    if (Array.isArray(u.enrolledCourses)) {
      return u.enrolledCourses.some((c: any) => c.enrolledAt || c.addedAt || c.createdAt)
    }
    return false
  })

  if (hasTimestamps) {
    registeredUsers.value.forEach((u: any) => {
      if (Array.isArray(u.enrolledCourses) && u.enrolledCourses.length) {
        u.enrolledCourses.forEach((c: any) => {
          const ts = c.enrolledAt || c.addedAt || c.createdAt || u.registeredAt || u.createdAt || u.registrationDate
          if (!ts) return
          const d = new Date(ts)
          months.forEach((m, idx) => {
            if (d.getMonth() === m.month && d.getFullYear() === m.year) counts[idx]++
          })
        })
      } else {
        const ts = u.registeredAt || u.createdAt || u.registrationDate
        if (!ts) return
        const d = new Date(ts)
        months.forEach((m, idx) => {
          if (d.getMonth() === m.month && d.getFullYear() === m.year) counts[idx]++
        })
      }
    })
  } else {
    counts[counts.length - 1] = totalEnrollments.value
  }

  return months.map((m, idx) => ({ month: m.label, desktop: counts[idx] }))
})
</script>

<template>
  <Sidebar>
    <main class="space-y-6 p-6">
      <div
        class="flex flex-col gap-2 sm:flex-row sm:items-end sm:justify-between"
      >
        <div>
          <p class="text-sm uppercase tracking-wide text-muted-foreground">
            Overview
          </p>
          <h1 class="text-3xl font-bold text-primary">Admin dashboard</h1>
        </div>
      </div>

      <AdminStats
        :total-users="totalUsers"
        :total-courses="totalCourses"
        :completion-rate="completionRate"
      />

      <section class="grid gap-6 lg:grid-cols-[2fr_1fr]">
        <AdminChartPanel :data="chartData" :config="{ desktop: { label: 'Enrollments', color: 'var(--chart-1)' } }" xKey="month" yKey="desktop" />
        <RecentEnrollmentsCard :users="registeredUsers" />
      </section>

      <section class="grid gap-6 xl:grid-cols-[1.2fr_0.8fr]">
        <CourseTable :courses="courses" @remove-course="removeCourse" />
        <AddCourseForm @add-course="addCourse" />
      </section>
    </main>
  </Sidebar>
</template>
