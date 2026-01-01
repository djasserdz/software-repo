<template>
  <Layout>
    <div class="px-4 sm:px-6 lg:px-8">
      <div class="mb-8">
        <h1 class="text-3xl font-bold text-gray-900">Warehouse Admin Dashboard</h1>
        <p class="mt-2 text-sm text-gray-600">Manage your warehouse operations</p>
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
              <p class="text-sm font-medium text-gray-500">My Warehouses</p>
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
              <p class="text-sm font-medium text-gray-500">Pending Appointments</p>
              <p class="text-2xl font-semibold text-gray-900">{{ stats.pendingAppointments }}</p>
            </div>
          </div>
        </div>

        <div class="card">
          <div class="flex items-center">
            <div class="flex-shrink-0 bg-blue-100 rounded-lg p-3">
              <svg class="h-6 w-6 text-blue-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
              </svg>
            </div>
            <div class="ml-4">
              <p class="text-sm font-medium text-gray-500">Storage Zones</p>
              <p class="text-2xl font-semibold text-gray-900">{{ stats.zones }}</p>
            </div>
          </div>
        </div>

        <div class="card">
          <div class="flex items-center">
            <div class="flex-shrink-0 bg-yellow-100 rounded-lg p-3">
              <svg class="h-6 w-6 text-yellow-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
            </div>
            <div class="ml-4">
              <p class="text-sm font-medium text-gray-500">Time Slots</p>
              <p class="text-2xl font-semibold text-gray-900">{{ stats.timeSlots }}</p>
            </div>
          </div>
        </div>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div class="card">
          <h2 class="text-xl font-semibold text-gray-900 mb-4">Quick Actions</h2>
          <div class="space-y-3">
            <router-link
              to="/warehouse-admin/warehouses"
              class="flex items-center justify-between p-4 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors"
            >
              <span class="font-medium text-gray-900">Manage Warehouses</span>
              <svg class="h-5 w-5 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
              </svg>
            </router-link>
            <router-link
              to="/warehouse-admin/appointments"
              class="flex items-center justify-between p-4 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors"
            >
              <span class="font-medium text-gray-900">Manage Appointments</span>
              <svg class="h-5 w-5 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
              </svg>
            </router-link>
            <router-link
              to="/warehouse-admin/zones"
              class="flex items-center justify-between p-4 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors"
            >
              <span class="font-medium text-gray-900">Manage Storage Zones</span>
              <svg class="h-5 w-5 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
              </svg>
            </router-link>
            <router-link
              to="/warehouse-admin/timeslots"
              class="flex items-center justify-between p-4 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors"
            >
              <span class="font-medium text-gray-900">Manage Time Slots</span>
              <svg class="h-5 w-5 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
              </svg>
            </router-link>
          </div>
        </div>

        <div class="card">
          <h2 class="text-xl font-semibold text-gray-900 mb-4">Recent Appointments</h2>
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
    </div>
  </Layout>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { warehouseAPI } from '../api/warehouse'
import { appointmentAPI } from '../api/appointment'
import { zoneAPI } from '../api/zone'
import { timeslotAPI } from '../api/timeslot'
import Layout from '../components/Layout.vue'

const stats = ref({
  warehouses: 0,
  pendingAppointments: 0,
  zones: 0,
  timeSlots: 0,
})

const recentAppointments = ref([])
const loading = ref(true)

onMounted(async () => {
  try {
    const [warehouses, appointments, zones] = await Promise.all([
      warehouseAPI.getAll(),
      appointmentAPI.getAll({ status: 'pending' }),
      zoneAPI.getAll(),
    ])

    stats.value = {
      warehouses: warehouses.data?.length || 0,
      pendingAppointments: appointments.data?.length || 0,
      zones: zones.data?.length || 0,
      timeSlots: 0, // Would need to count from zones
    }

    const allAppointments = await appointmentAPI.getAll()
    recentAppointments.value = (allAppointments.data || []).slice(0, 5)
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
</script>



