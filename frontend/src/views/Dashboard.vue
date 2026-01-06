<template>
  <Layout>
    <div class="px-4 sm:px-6 lg:px-8">
      <div class="mb-8">
        <h1 class="text-3xl font-bold text-gray-900">Dashboard</h1>
        <p class="mt-2 text-sm text-gray-600">Welcome back, {{ user?.name }}!</p>
      </div>

      <div class="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-4 mb-8">
        <div class="card">
          <div class="flex items-center">
            <div class="flex-shrink-0 bg-primary-100 rounded-lg p-3">
              <svg class="h-6 w-6 text-primary-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
              </svg>
            </div>
            <div class="ml-4">
              <p class="text-sm font-medium text-gray-500">Warehouses</p>
              <p class="text-2xl font-semibold text-gray-900">{{ stats.warehouses }}</p>
            </div>
          </div>
        </div>

        <div class="card">
          <div class="flex items-center">
            <div class="flex-shrink-0 bg-green-100 rounded-lg p-3">
              <svg class="h-6 w-6 text-green-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
              </svg>
            </div>
            <div class="ml-4">
              <p class="text-sm font-medium text-gray-500">Appointments</p>
              <p class="text-2xl font-semibold text-gray-900">{{ stats.appointments }}</p>
            </div>
          </div>
        </div>

        <div class="card">
          <div class="flex items-center">
            <div class="flex-shrink-0 bg-yellow-100 rounded-lg p-3">
              <svg class="h-6 w-6 text-yellow-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
              </svg>
            </div>
            <div class="ml-4">
              <p class="text-sm font-medium text-gray-500">Deliveries</p>
              <p class="text-2xl font-semibold text-gray-900">{{ stats.deliveries }}</p>
            </div>
          </div>
        </div>

        <div class="card">
          <div class="flex items-center">
            <div class="flex-shrink-0 bg-purple-100 rounded-lg p-3">
              <svg class="h-6 w-6 text-purple-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
            </div>
            <div class="ml-4">
              <p class="text-sm font-medium text-gray-500">Grain Types</p>
              <p class="text-2xl font-semibold text-gray-900">{{ stats.grains }}</p>
            </div>
          </div>
        </div>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div class="card">
          <h2 class="text-xl font-semibold text-gray-900 mb-4">Quick Actions</h2>
          <div class="space-y-3">
            <router-link
              to="/warehouses"
              class="flex items-center justify-between p-4 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors"
            >
              <span class="font-medium text-gray-900">Browse Warehouses</span>
              <svg class="h-5 w-5 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
              </svg>
            </router-link>
            <router-link
              v-if="isFarmer"
              to="/appointments/book"
              class="flex items-center justify-between p-4 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors"
            >
              <span class="font-medium text-gray-900">Book Appointment</span>
              <svg class="h-5 w-5 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
              </svg>
            </router-link>
            <router-link
              to="/appointments"
              class="flex items-center justify-between p-4 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors"
            >
              <span class="font-medium text-gray-900">My Appointments</span>
              <svg class="h-5 w-5 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
              </svg>
            </router-link>
          </div>
        </div>

        <div class="card">
          <h2 class="text-xl font-semibold text-gray-900 mb-4">Recent Activity</h2>
          <div v-if="loading" class="text-center py-8 text-gray-500">Loading...</div>
          <div v-else-if="recentAppointments.length === 0" class="text-center py-8 text-gray-500">
            No recent appointments
          </div>
          <div v-else class="space-y-3">
            <div
              v-for="appointment in recentAppointments"
              :key="appointment.appointment_id"
              class="p-4 bg-gray-50 rounded-lg"
            >
              <div class="flex justify-between items-start">
                <div>
                  <p class="font-medium text-gray-900">Appointment #{{ appointment.appointment_id }}</p>
                  <p class="text-sm text-gray-500 mt-1">
                    {{ formatDate(appointment.created_at) }}
                  </p>
                </div>
                <span
                  class="px-2 py-1 text-xs font-medium rounded-full"
                  :class="getStatusClass(appointment.status)"
                >
                  {{ appointment.status }}
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Warehouse Map Section (for farmers) -->
      <div v-if="isFarmer" class="mt-6">
        <div class="card">
          <h2 class="text-xl font-semibold text-gray-900 mb-4">Warehouse Locations</h2>
          <div id="dashboard-map" class="w-full h-96 rounded-lg border border-gray-200"></div>
        </div>
      </div>
    </div>
  </Layout>
</template>

<script setup>
import { ref, computed, onMounted, nextTick, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'
import { appointmentAPI } from '../api/appointment'
import { warehouseAPI } from '../api/warehouse'
import { grainAPI } from '../api/grain'
import { deliveryAPI } from '../api/delivery'
import Layout from '../components/Layout.vue'

const router = useRouter()
const authStore = useAuthStore()
const user = computed(() => authStore.user)
const isFarmer = computed(() => authStore.isFarmer)

let map = null
let mapMarkers = []
const allWarehouses = ref([])

const stats = ref({
  warehouses: 0,
  appointments: 0,
  deliveries: 0,
  grains: 0,
})

const recentAppointments = ref([])
const loading = ref(true)

// Redirect based on role and load data
onMounted(async () => {
  if (authStore.isAdmin) {
    router.replace('/admin')
    return
  } else if (authStore.isWarehouseAdmin) {
    router.replace('/warehouse-admin')
    return
  }
  
  try {
    const [warehouses, appointments, deliveries, grains] = await Promise.all([
      warehouseAPI.getAll(),
      appointmentAPI.getMyAppointments(),
      deliveryAPI.getMyDeliveries(),
      grainAPI.getAll(),
    ])

    stats.value = {
      warehouses: warehouses.data?.length || 0,
      appointments: appointments.data?.appointments?.length || 0,
      deliveries: deliveries.data?.deliveries?.length || 0,
      grains: grains.data?.length || 0,
    }

    recentAppointments.value = (appointments.data?.appointments || []).slice(0, 5)
    
    // Store warehouses for map display (for farmers)
    if (isFarmer.value) {
      allWarehouses.value = warehouses.data || []
      await nextTick()
      initMap()
    }
  } catch (error) {
    console.error('Error loading dashboard data:', error)
  } finally {
    loading.value = false
  }
})

const formatDate = (dateString) => {
  return new Date(dateString).toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  })
}

const getStatusClass = (status) => {
  const classes = {
    pending: 'bg-yellow-100 text-yellow-800',
    accepted: 'bg-green-100 text-green-800',
    cancelled: 'bg-red-100 text-red-800',
    refused: 'bg-gray-100 text-gray-800',
    completed: 'bg-blue-100 text-blue-800',
  }
  return classes[status] || 'bg-gray-100 text-gray-800'
}

const initMap = async () => {
  await nextTick()
  if (typeof window === 'undefined' || !isFarmer.value) return
  
  // Wait for Leaflet to be available
  let L = window.L
  if (!L) {
    // Retry after a short delay
    setTimeout(() => {
      L = window.L
      if (L) createMap(L)
    }, 100)
    return
  }
  
  createMap(L)
}

const createMap = (L) => {
  const mapElement = document.getElementById('dashboard-map')
  if (!mapElement || map) return

  // Calculate center based on warehouses or use default
  let center = [31.0, 36.0] // Default center
  
  if (allWarehouses.value.length > 0) {
    const validWarehouses = allWarehouses.value.filter(w => w.y_float != null && w.x_float != null)
    if (validWarehouses.length > 0) {
      const avgLat = validWarehouses.reduce((sum, w) => sum + w.y_float, 0) / validWarehouses.length
      const avgLng = validWarehouses.reduce((sum, w) => sum + w.x_float, 0) / validWarehouses.length
      center = [avgLat, avgLng]
    }
  }

  map = L.map('dashboard-map').setView(center, 10)

  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    attribution: '© OpenStreetMap contributors',
    maxZoom: 19,
  }).addTo(map)

  updateMap()
}

const updateMap = () => {
  if (!map || !isFarmer.value) {
    if (window.L && isFarmer.value) {
      initMap()
    }
    return
  }
  
  const L = window.L
  if (!L) return

  // Remove existing markers
  mapMarkers.forEach((marker) => map.removeLayer(marker))
  mapMarkers = []

  // Add markers for each warehouse
  const validWarehouses = allWarehouses.value.filter(w => w.y_float != null && w.x_float != null)
  
  validWarehouses.forEach((warehouse) => {
    const popupContent = `
      <div class="p-2">
        <h3 class="font-semibold text-gray-900 mb-1">${warehouse.name}</h3>
        <p class="text-sm text-gray-600 mb-2">${warehouse.location}</p>
        <button 
          onclick="window.location.href='/warehouses/${warehouse.warehouse_id}'"
          class="mt-2 px-3 py-1 bg-primary-600 text-white text-xs rounded hover:bg-primary-700"
        >
          View Details
        </button>
      </div>
    `
    
    const marker = L.marker([warehouse.y_float, warehouse.x_float])
      .addTo(map)
      .bindPopup(popupContent)

    mapMarkers.push(marker)
  })

  // Fit map bounds to show all warehouses
  if (validWarehouses.length > 0) {
    const bounds = L.latLngBounds(
      validWarehouses.map((w) => [w.y_float, w.x_float])
    )
    map.fitBounds(bounds, { padding: [50, 50] })
  }
}

// Cleanup map on component unmount
onUnmounted(() => {
  if (map) {
    map.remove()
    map = null
    mapMarkers = []
  }
})
</script>

