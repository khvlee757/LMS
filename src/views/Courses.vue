<script setup>
import Hero from '../assets/bg-1.jpeg'
// import Doodle from '../assets/doodle.mp4'
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import CourseCard from '@/components/dashboard/CourseCard.vue'
import Sidebar from '@/components/Sidebar.vue'

const router = useRouter()

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
]

const available = ref([])

onMounted(() => {
  const saved = localStorage.getItem('lmsCatalog')

  if (saved) {
    try {
      available.value = JSON.parse(saved)
    } catch {
      available.value = defaultAvailable
    }
  } else {
    available.value = defaultAvailable
  }
})

function addCourse(course) {
  const stored = localStorage.getItem('enrolledCourses')

  let enrolled = []

  try {
    enrolled = stored ? JSON.parse(stored) : []
  } catch {
    enrolled = []
  }

  if (!enrolled.find((c) => c.id === course.id)) {
    enrolled.push({
      ...course,
      progress: 0,
    })

    localStorage.setItem(
      'enrolledCourses',
      JSON.stringify(enrolled)
    )
  }

  // also update the current user record in lmsUsers (if present)
  try {
    const savedForm = localStorage.getItem('form')
    const savedUsers = localStorage.getItem('lmsUsers')
    if (savedForm && savedUsers) {
      const current = JSON.parse(savedForm)
      const users = JSON.parse(savedUsers)
      const idx = users.findIndex((u) => u.email === current.email)
      if (idx !== -1) {
        users[idx].enrolledCourses = users[idx].enrolledCourses || []
        // avoid duplicates
        if (!users[idx].enrolledCourses.find((c) => c.id === course.id)) {
          users[idx].enrolledCourses.push({ ...course, enrolledAt: new Date().toISOString() })
        }
        localStorage.setItem('lmsUsers', JSON.stringify(users))
        // notify admin dashboard that users/enrollments changed
        try { window.dispatchEvent(new CustomEvent('lms:usersUpdated')) } catch (e) {}
      }
    }
  } catch (e) {
    // ignore
  }

  router.push('/dashboard')
}
</script>

<template>
  <Sidebar>
    <main class="relative min-h-screen overflow-hidden">

      <div
        class="absolute inset-0 z-0 bg-cover bg-center bg-no-repeat"
        :style="{ backgroundImage: `url(${Hero})` }"
      ></div>

      <div class="absolute inset-0 z-10 bg-black/45"></div>

      <div class="absolute inset-0 z-10 bg-primary/10"></div>

      <div class="relative z-20 min-h-screen px-4 py-6 sm:px-6 lg:px-8">

        <div class="mx-auto max-w-7xl">

          <section
            class="relative mb-8 min-h-[320px] overflow-hidden rounded-3xl border border-white/20 bg-primary/70 px-6 py-8 text-white shadow-xl backdrop-blur-sm sm:px-8 sm:py-10"
          >

            <div
              class="absolute -right-16 -top-16 h-40 w-40 rounded-full bg-white/10"
            ></div>

            <div
              class="absolute -bottom-20 right-24 h-48 w-48 rounded-full bg-white/5"
            ></div>

            <div
              class="relative z-10 flex min-h-[270px] items-center justify-between gap-8"
            >

              <div class="max-w-2xl">

                <p
                  class="mb-2 text-sm font-medium uppercase tracking-[0.2em] text-white/70"
                >
                  Learning Centre
                </p>

                <h1
                  class="text-3xl font-bold tracking-tight sm:text-4xl lg:text-5xl"
                >
                  Explore Courses
                </h1>

                <p
                  class="mt-3 max-w-2xl text-sm leading-6 text-white/75 sm:text-base"
                >
                  Discover new skills, learn from experienced mentors, and choose
                  courses that help you grow.
                </p>

                <div class="mt-6 flex flex-wrap gap-3">

                  <div
                    class="rounded-full border border-white/20 bg-white/10 px-4 py-2 text-sm backdrop-blur-md"
                  >
                    {{ available.length }} Courses Available
                  </div>

                  <div
                    class="rounded-full border border-white/20 bg-white/10 px-4 py-2 text-sm backdrop-blur-md"
                  >
                    Learn at your own pace
                  </div>

                </div>

              </div>

              <div
                class="absolute right-0 top-0 hidden h-full w-[42%] items-center justify-center lg:flex"
              >

                <!-- <video
                  :src="Doodle"
                  autoplay
                  muted
                  loop
                  playsinline
                  class="h-full w-full object-contain"
                ></video> -->

              </div>

            </div>

          </section>

          <section
            class="mb-6 flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between"
          >

            <div>
              <p class="text-sm font-semibold text-white">
                Browse courses
              </p>

              <h2
                class="mt-1 text-2xl font-bold tracking-tight text-white drop-shadow-lg"
              >
                Available courses
              </h2>

              <p class="mt-1 text-sm text-white/80">
                Choose a course and start learning today.
              </p>
            </div>

            <div
              class="w-fit rounded-full border border-white/30 bg-white/90 px-4 py-2 text-sm font-semibold text-primary shadow-lg backdrop-blur-md"
            >
              {{ available.length }} courses
            </div>

          </section>

          <section
            v-if="available.length"
            class="grid gap-6 sm:grid-cols-2 xl:grid-cols-3"
          >

            <article
              v-for="course in available"
              :key="course.id"
              class="group overflow-hidden rounded-3xl border border-white/30 bg-white/95 p-4 shadow-xl backdrop-blur-sm transition duration-300 hover:-translate-y-1 hover:bg-white hover:shadow-2xl"
            >

              <div class="overflow-hidden rounded-2xl">
                <CourseCard :course="course" />
              </div>

              <div class="mt-4 flex items-center justify-between gap-3">

                <div class="min-w-0">

                  <p
                    class="text-xs font-medium uppercase tracking-wide text-primary/70"
                  >
                    {{ course.category }}
                  </p>

                  <p
                    class="mt-1 truncate text-sm font-semibold text-gray-900"
                  >
                    {{ course.title }}
                  </p>

                </div>

                <button
                  type="button"
                  @click="addCourse(course)"
                  class="shrink-0 rounded-xl bg-primary px-5 py-2.5 text-sm font-semibold text-white shadow-sm transition hover:scale-[1.02] hover:bg-primary/90 active:scale-95"
                >
                  Add Course
                </button>

              </div>

              <div
                class="mt-4 flex items-center gap-4 border-t pt-4 text-xs text-muted-foreground"
              >

                <div class="flex items-center gap-1.5">
                  <span class="h-1.5 w-1.5 rounded-full bg-primary"></span>
                  {{ course.lessons }} lessons
                </div>

                <div class="flex items-center gap-1.5">
                  <span class="h-1.5 w-1.5 rounded-full bg-primary"></span>
                  {{ course.mentor }}
                </div>

              </div>

            </article>

          </section>

          <section
            v-else
            class="rounded-3xl border border-white/30 bg-white/95 px-6 py-16 text-center shadow-xl backdrop-blur-md"
          >

            <div
              class="mx-auto flex h-16 w-16 items-center justify-center rounded-2xl bg-primary/10 text-primary"
            >
              <span class="text-2xl font-bold">+</span>
            </div>

            <h2 class="mt-5 text-xl font-bold text-gray-900">
              No courses available
            </h2>

            <p
              class="mx-auto mt-2 max-w-md text-sm text-muted-foreground"
            >
              There are currently no courses available. Check back later for
              new learning opportunities.
            </p>

          </section>

        </div>

      </div>

    </main>
  </Sidebar>
</template>