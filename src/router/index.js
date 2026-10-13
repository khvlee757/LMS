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
    path: '/admin/login',
    name: 'admin-login',
    component: () => import('../views/admin/AdminLogin.vue'),
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
    ],
  },
  {
    path: '/admin',
    component: () => import('../layouts/AdminLayout.vue'),
    meta: { requiresAuth: true, requiresSuperAdmin: true },
    children: [
      {
        path: '',
        name: 'admin',
        component: () => import('../views/admin/AdminDashboard.vue'),
      },
      {
        path: 'users',
        name: 'admin-users',
        component: () => import('../views/admin/AdminUsers.vue'),
      },
      {
        path: 'applications',
        name: 'admin-applications',
        component: () => import('../views/admin/AdminApplications.vue'),
      },
      {
        path: 'courses',
        name: 'admin-courses',
        component: () => import('../views/admin/AdminCourses.vue'),
      },
      {
        path: 'books',
        name: 'admin-books',
        component: () => import('../views/admin/AdminBooks.vue'),
      },
      {
        path: 'payments',
        name: 'admin-payments',
        component: () => import('../views/admin/AdminPayments.vue'),
      },
      {
        path: 'settings',
        name: 'admin-settings',
        component: () => import('../views/admin/AdminSettings.vue'),
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
  if (to.path === '/login' && to.query.type === 'super_admin') {
    return { name: 'admin-login' }
  }

  if (to.name === 'admin-login') {
    const { user, profile } = await getAuthenticatedProfile()
    if (user && profile?.role === 'super_admin') {
      return { name: 'admin' }
    }
    return true
  }

  if (!to.meta.requiresAuth) return true

  const { user, profile } = await getAuthenticatedProfile()
  if (!user) return { name: 'login', query: { redirect: to.fullPath } }

  if (to.matched.some((record) => record.meta.requiresSuperAdmin) && profile?.role !== 'super_admin') {
    return { name: 'dashboard' }
  }

  if (to.matched.some((record) => record.meta.requiresInstructor) && !['instructor', 'super_admin'].includes(profile?.role)) {
    return { name: 'dashboard' }
  }

  return true
})

export default router