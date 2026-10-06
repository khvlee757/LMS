import { createRouter, createWebHistory } from 'vue-router'
import { getAuthenticatedProfile } from '@/lib/auth'

const routes = [
  {
    path: '/',
    redirect: '/dashboard',
  },
  {
    path: '/register',
    name: 'register',
    component: () => import('../views/Register.vue'),
  },
  {
    path: '/login',
    name: 'login',
    component: () => import('../views/Login.vue'),
  },
  {
    path: '/',
    component: () => import('../layouts/LmsLayout.vue'),
    meta: { requiresAuth: true },
    children: [
      {
        path: 'dashboard',
        name: 'dashboard',
        component: () => import('../views/Dashboard.vue'),
      },
      {
        path: 'courses',
        name: 'courses',
        component: () => import('../views/Courses.vue'),
      },
      {
        path: 'courses/:id',
        name: 'course-detail',
        component: () => import('../views/CourseDetail.vue'),
      },
      {
        path: 'books',
        name: 'books',
        component: () => import('../views/Books.vue'),
      },
      {
        path: 'payment/return',
        name: 'payment-return',
        component: () => import('../views/PaymentReturn.vue'),
      },
      {
        path: 'instructor',
        name: 'instructor',
        component: () => import('../views/Instructor.vue'),
        meta: { requiresInstructor: true },
      },
      {
        path: 'learning',
        name: 'learning',
        component: () => import('../views/Learning.vue'),
      },
      {
        path: 'admin',
        name: 'admin',
        component: () => import('../views/Admin.vue'),
        meta: { requiresSuperAdmin: true },
      },
    ],
  },
  {
    path: '/:pathMatch(.*)*',
    redirect: '/dashboard',
  },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

router.beforeEach(async (to) => {
  if (!to.meta.requiresAuth) return true

  const { user, profile } = await getAuthenticatedProfile()
  if (!user) return { name: 'login', query: { redirect: to.fullPath } }
  if (to.matched.some((record) => record.meta.requiresInstructor) && !['instructor', 'super_admin'].includes(profile?.role)) {
    return { name: 'dashboard' }
  }
  if (to.matched.some((record) => record.meta.requiresSuperAdmin) && profile?.role !== 'super_admin') {
    return { name: 'dashboard' }
  }

  return true
})

export default router