<script setup>
import { ref, onMounted } from 'vue'
import { RouterLink } from 'vue-router'

import Sidebar from '@/components/Sidebar.vue'
import DashboardHeader from '@/components/dashboard/DashboardHeader.vue'
import CourseCard from '@/components/dashboard/CourseCard.vue'
import TimeSpentChart from '@/components/dashboard/TimeSpentChart.vue'
import HoursSummary from '@/components/dashboard/HoursSummary.vue'

import Hero from '@/assets/bg-1.jpeg'

const savedForm = localStorage.getItem('form')

let user = null

try {
  user = savedForm ? JSON.parse(savedForm) : null
} catch {
  user = null
}

const courses = ref([])

onMounted(() => {
  const stored = localStorage.getItem('enrolledCourses')

  if (stored) {
    try {
      courses.value = JSON.parse(stored)
    } catch {
      courses.value = []
    }
  } else {
    courses.value = []
  }
})

const timeData = [
  { label: 'Mon', value: 2.5, height: '100%' },
  { label: 'Tue', value: 4.2, height: '58%' },
  { label: 'Wed', value: 3.8, height: '52%' },
  { label: 'Thu', value: 5.4, height: '72%' },
  { label: 'Fri', value: 6.1, height: '83%' },
  { label: 'Sat', value: 4.6, height: '63%' },
  { label: 'Sun', value: 3.2, height: '44%' },
]

const totalHours = timeData
  .reduce((sum, day) => sum + day.value, 0)
  .toFixed(1)

const weeklyStats = [
  {
    label: 'Design',
    value: '7.8h',
    bg: 'bg-primary/10',
  },
  {
    label: 'Development',
    value: '12.6h',
    bg: 'bg-cyan-50',
  },
  {
    label: 'Business',
    value: '9.7h',
    bg: 'bg-emerald-50',
  },
]
</script>

<template>
  <Sidebar>

    <main class="relative min-h-screen overflow-hidden">

      <div
        class="absolute inset-0 z-0 bg-cover bg-center bg-no-repeat"
        :style="{ backgroundImage: `url(${Hero})` }"
      ></div>

      <div
        class="absolute inset-0 z-10 bg-black/50"
      ></div>

      <div
        class="absolute inset-0 z-10 bg-primary/15"
      ></div>

      <div
        class="relative z-20 min-h-screen px-4 py-6 sm:px-6 lg:px-8"
      >

        <div class="mx-auto max-w-7xl">

          <div
            class="relative mb-8 min-h-[120px] overflow-hidden rounded-3xl border border-white/20 bg-primary/70 px-6 py-8 text-white shadow-xl backdrop-blur-sm sm:px-8 sm:py-10"
          >
            <DashboardHeader />
          </div>

          <section class="mb-8 ">

            <div
              class="mb-5 flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between"
            >

              <div>

                <p
                  class="text-sm font-medium uppercase tracking-widest text-white/70"
                >
                  Your learning
                </p>

                <h1
                  class="mt-1 text-2xl font-bold text-white drop-shadow-lg sm:text-3xl"
                >
                  My Courses
                </h1>

                <p class="mt-1 text-sm text-white/75">
                  Continue learning and keep building your skills.
                </p>

              </div>

              <RouterLink
                to="/courses"
                class="w-fit rounded-xl bg-white px-5 py-2.5 text-sm font-semibold text-primary shadow-lg transition hover:scale-[1.02] hover:bg-white/90"
              >
                Browse Courses
              </RouterLink>

            </div>

            <div
              v-if="courses.length"
              class="grid gap-6 md:grid-cols-2 xl:grid-cols-3"
            >

              <div
                v-for="course in courses"
                :key="course.id || course.title"
                class="overflow-hidden rounded-3xl border border-white/20 bg-white/95 p-4 shadow-xl backdrop-blur-sm transition duration-300 hover:-translate-y-1 hover:bg-white"
              >

                <CourseCard :course="course" />

              </div>

            </div>

            <div
              v-else
              class="rounded-3xl border border-white/20 bg-white/95 px-6 py-12 text-center shadow-xl backdrop-blur-md"
            >

              <div
                class="mx-auto flex h-16 w-16 items-center justify-center rounded-2xl bg-primary/10"
              >
                <span class="text-2xl font-bold text-primary">
                  +
                </span>
              </div>

              <h2 class="mt-5 text-xl font-bold text-gray-900">
                No courses yet
              </h2>

              <p
                class="mx-auto mt-2 max-w-md text-sm leading-6 text-gray-500"
              >
                You haven't enrolled in any courses yet.
                Browse available courses and start learning today.
              </p>

              <RouterLink
                to="/courses"
                class="mt-5 inline-flex rounded-xl bg-primary px-6 py-3 text-sm font-semibold text-white shadow-md transition hover:bg-primary/90"
              >
                Browse Courses
              </RouterLink>

            </div>

          </section>

          <section
            class="grid gap-6 lg:grid-cols-[2fr_1fr]"
          >

            <div
              class="rounded-3xl border border-white/20 bg-white/95 p-4 shadow-xl backdrop-blur-md sm:p-6"
            >
              <TimeSpentChart :data="timeData" />
            </div>

            <div
              class="rounded-3xl border border-white/20 bg-white/95 p-4 shadow-xl backdrop-blur-md sm:p-6"
            >
              <HoursSummary
                :total-hours="totalHours"
                :stats="weeklyStats"
              />
            </div>

          </section>

        </div>

      </div>

    </main>

  </Sidebar>
</template>