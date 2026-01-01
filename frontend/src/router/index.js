import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '../stores/auth'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      path: '/',
      redirect: '/dashboard',
    },
    {
      path: '/login',
      name: 'Login',
      component: () => import('../views/Login.vue'),
      meta: { requiresGuest: true },
    },
    {
      path: '/register',
      name: 'Register',
      component: () => import('../views/Register.vue'),
      meta: { requiresGuest: true },
    },
    {
      path: '/dashboard',
      name: 'Dashboard',
      component: () => import('../views/Dashboard.vue'),
      meta: { requiresAuth: true },
    },
    {
      path: '/admin',
      name: 'AdminDashboard',
      component: () => import('../views/AdminDashboard.vue'),
      meta: { requiresAuth: true, requiresAdmin: true },
    },
    {
      path: '/warehouse-admin',
      name: 'WarehouseAdminDashboard',
      component: () => import('../views/WarehouseAdminDashboard.vue'),
      meta: { requiresAuth: true, requiresWarehouseAdmin: true },
    },
    {
      path: '/warehouses',
      name: 'Warehouses',
      component: () => import('../views/Warehouses.vue'),
      meta: { requiresAuth: true },
    },
    {
      path: '/warehouses/:id',
      name: 'WarehouseDetail',
      component: () => import('../views/WarehouseDetail.vue'),
      meta: { requiresAuth: true },
    },
    {
      path: '/appointments',
      name: 'Appointments',
      component: () => import('../views/Appointments.vue'),
      meta: { requiresAuth: true },
    },
    {
      path: '/appointments/book',
      name: 'BookAppointment',
      component: () => import('../views/BookAppointment.vue'),
      meta: { requiresAuth: true },
    },
    {
      path: '/deliveries',
      name: 'Deliveries',
      component: () => import('../views/Deliveries.vue'),
      meta: { requiresAuth: true },
    },
    {
      path: '/profile',
      name: 'Profile',
      component: () => import('../views/Profile.vue'),
      meta: { requiresAuth: true },
    },
  ],
})

router.beforeEach((to, from, next) => {
  const authStore = useAuthStore()

  if (to.meta.requiresAuth && !authStore.isAuthenticated) {
    next({ name: 'Login', query: { redirect: to.fullPath } })
  } else if (to.meta.requiresGuest && authStore.isAuthenticated) {
    // Redirect to appropriate dashboard based on role
    if (authStore.isAdmin) {
      next({ name: 'AdminDashboard' })
    } else if (authStore.isWarehouseAdmin) {
      next({ name: 'WarehouseAdminDashboard' })
    } else {
      next({ name: 'Dashboard' })
    }
  } else if (to.meta.requiresAdmin && !authStore.isAdmin) {
    next({ name: 'Dashboard' })
  } else if (to.meta.requiresWarehouseAdmin && !authStore.isWarehouseAdmin) {
    next({ name: 'Dashboard' })
  } else {
    next()
  }
})

export default router
