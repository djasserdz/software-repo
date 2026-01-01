<template>
  <div class="min-h-screen bg-gray-50">
    <nav class="bg-white shadow-sm border-b border-gray-200">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex justify-between h-16">
          <div class="flex">
            <div class="flex-shrink-0 flex items-center">
              <router-link to="/dashboard" class="text-2xl font-bold text-primary-600">
                Mahsoul
              </router-link>
            </div>
            <div class="hidden sm:ml-6 sm:flex sm:space-x-8">
              <router-link
                v-for="item in navigation"
                :key="item.name"
                :to="item.to"
                class="inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium transition-colors"
                :class="[
                  $route.path.startsWith(item.to)
                    ? 'border-primary-500 text-gray-900'
                    : 'border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700',
                ]"
              >
                {{ item.name }}
              </router-link>
            </div>
          </div>
          <div class="flex items-center space-x-4">
            <router-link
              to="/profile"
              class="text-gray-700 hover:text-gray-900 px-3 py-2 rounded-md text-sm font-medium"
            >
              <div class="flex items-center space-x-2">
                <span>{{ user?.name }}</span>
                <div class="w-8 h-8 bg-primary-100 rounded-full flex items-center justify-center">
                  <span class="text-primary-600 font-semibold text-sm">
                    {{ user?.name?.charAt(0).toUpperCase() }}
                  </span>
                </div>
              </div>
            </router-link>
            <button
              @click="handleLogout"
              class="text-gray-500 hover:text-gray-700 px-3 py-2 rounded-md text-sm font-medium"
            >
              Logout
            </button>
          </div>
        </div>
      </div>
    </nav>

    <main class="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
      <slot />
    </main>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'

const router = useRouter()
const authStore = useAuthStore()

const user = computed(() => authStore.user)

const navigation = computed(() => {
  if (authStore.isAdmin) {
    return [
      { name: 'Admin Dashboard', to: '/admin' },
      { name: 'Warehouses', to: '/warehouses' },
    ]
  } else if (authStore.isWarehouseAdmin) {
    return [
      { name: 'Dashboard', to: '/warehouse-admin' },
      { name: 'Warehouses', to: '/warehouses' },
      { name: 'Appointments', to: '/appointments' },
    ]
  } else {
    // Farmer navigation
    return [
      { name: 'Dashboard', to: '/dashboard' },
      { name: 'Warehouses', to: '/warehouses' },
      { name: 'My Appointments', to: '/appointments' },
      { name: 'Deliveries', to: '/deliveries' },
    ]
  }
})

const handleLogout = () => {
  authStore.logout()
  router.push('/login')
}
</script>

