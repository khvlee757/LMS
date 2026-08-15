import { createRouter, createWebHistory } from 'vue-router';

const routes = [
  {
    path: '/',
    redirect: '/register',
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
    path: '/admin-login',
    name: 'admin-login',
    component: () => import('../views/AdminLogin.vue'),
  },
  {
    path: '/welcome',
    name: 'welcome',
    component: () => import('../views/Welcome.vue'),
  },
  {
    path: '/courses',
    name: 'courses',
    component: () => import('../views/Courses.vue'),
  },
  {
    path: '/dashboard',
    name: 'dashboard',
    component: () => import('../views/Dashboard.vue'),
  },
  {
    path: '/admin-dashboard',
    name: 'admin-dashboard',
    component: () => import('../views/AdminDashboard.vue'),
  },
];

const router = createRouter({
  history: createWebHistory(),
  routes,
});

router.beforeEach((to, from, next) => {
  const role = localStorage.getItem('lmsRole');

  // debug logs to trace navigation
  // eslint-disable-next-line no-console
  console.log('[router] navigating to', to.path, 'from', from.path, 'role=', role);

  if (to.path === '/admin-dashboard' && role !== 'admin') {
    // eslint-disable-next-line no-console
    console.log('[router] blocking access to admin-dashboard, redirecting to /admin-login');
    next('/admin-login');
    return;
  }

  if (to.path === '/admin-login' && role === 'admin') {
    // eslint-disable-next-line no-console
    console.log('[router] already admin, redirecting to /admin-dashboard');
    next('/admin-dashboard');
    return;
  }

  next();
});

export default router;