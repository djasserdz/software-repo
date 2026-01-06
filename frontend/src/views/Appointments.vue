<template>
  <Layout>
    <div class="px-4 sm:px-6 lg:px-8">
      <div class="mb-8 flex justify-between items-center">
        <div>
          <h1 class="text-3xl font-bold text-gray-900">My Appointments</h1>
          <p class="mt-2 text-sm text-gray-600">Manage your grain delivery appointments</p>
        </div>
        <router-link
          v-if="isFarmer"
          to="/appointments/book"
          class="btn-primary"
        >
          Book New Appointment
        </router-link>
      </div>

      <div class="mb-6">
        <div class="flex gap-2">
          <button
            v-for="status in statusFilters"
            :key="status.value"
            @click="selectedStatus = status.value"
            class="px-4 py-2 rounded-lg font-medium transition-colors"
            :class="
              selectedStatus === status.value
                ? 'bg-primary-600 text-white'
                : 'bg-gray-200 text-gray-700 hover:bg-gray-300'
            "
          >
            {{ status.label }}
          </button>
        </div>
      </div>

      <div v-if="loading" class="text-center py-12">
        <div class="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600"></div>
        <p class="mt-2 text-gray-500">Loading appointments...</p>
      </div>

      <div v-else-if="appointments.length === 0" class="text-center py-12">
        <p class="text-gray-500">No appointments found</p>
      </div>

      <div v-else class="space-y-4">
        <div
          v-for="appointment in appointments"
          :key="appointment.appointment_id"
          class="card"
        >
          <div class="flex justify-between items-start mb-4">
            <div>
              <h3 class="text-lg font-semibold text-gray-900">
                Appointment #{{ appointment.appointment_id }}
              </h3>
              <p class="text-sm text-gray-500 mt-1">
                Created: {{ formatDate(appointment.created_at) }}
              </p>
            </div>
            <span
              class="px-3 py-1 text-sm font-medium rounded-full"
              :class="getStatusClass(appointment.status)"
            >
              {{ appointment.status }}
            </span>
          </div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
            <div>
              <p class="text-sm text-gray-500">Grain Type</p>
              <p class="font-medium text-gray-900">{{ getGrainName(appointment.grain_type_id) }}</p>
            </div>
            <div>
              <p class="text-sm text-gray-500">Quantity</p>
              <p class="font-medium text-gray-900">{{ formatNumber(appointment.requested_quantity * 1000) }} kg</p>
            </div>
            <div>
              <p class="text-sm text-gray-500">Zone ID</p>
              <p class="font-medium text-gray-900">{{ appointment.zone_id }}</p>
            </div>
            <div>
              <p class="text-sm text-gray-500">Time Slot</p>
              <p class="font-medium text-gray-900">Slot #{{ appointment.timeslot_id }}</p>
            </div>
          </div>

          <div class="flex gap-2">
            <button
              v-if="appointment.status === 'pending' && isFarmer"
              @click="cancelAppointment(appointment.appointment_id)"
              class="btn-secondary text-sm"
              :disabled="cancelling"
            >
              Cancel
            </button>
            <router-link
              :to="`/warehouses/${appointment.zone_id}`"
              class="btn-secondary text-sm"
            >
              View Warehouse
            </router-link>
          </div>
        </div>
      </div>
    </div>
  </Layout>
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { useAuthStore } from '../stores/auth'
import { appointmentAPI } from '../api/appointment'
import { grainAPI } from '../api/grain'
import Layout from '../components/Layout.vue'

const authStore = useAuthStore()
const isFarmer = computed(() => authStore.isFarmer)

const appointments = ref([])
const grains = ref([])
const loading = ref(true)
const cancelling = ref(false)
const selectedStatus = ref(null)

const statusFilters = [
  { label: 'All', value: null },
  { label: 'Pending', value: 'pending' },
  { label: 'Accepted', value: 'accepted' },
  { label: 'Completed', value: 'completed' },
  { label: 'Cancelled', value: 'cancelled' },
]

const loadAppointments = async () => {
  loading.value = true
  try {
    const [appointmentsRes, grainsRes] = await Promise.all([
      appointmentAPI.getMyAppointments(selectedStatus.value),
      grainAPI.getAll(),
    ])
    appointments.value = appointmentsRes.data?.appointments || []
    grains.value = grainsRes.data || []
  } catch (error) {
    console.error('Error loading appointments:', error)
  } finally {
    loading.value = false
  }
}

watch(selectedStatus, () => {
  loadAppointments()
})

onMounted(() => {
  loadAppointments()
})

const formatDate = (dateString) => {
  return new Date(dateString).toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
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

const getGrainName = (grainId) => {
  const grain = grains.value.find((g) => g.grain_id === grainId)
  return grain ? grain.name : 'Unknown'
}

const formatNumber = (num) => {
  if (!num) return '0'
  return new Intl.NumberFormat('ar-DZ', {
    minimumFractionDigits: 0,
    maximumFractionDigits: 0
  }).format(num)
}

const cancelAppointment = async (appointmentId) => {
  if (!confirm('Are you sure you want to cancel this appointment?')) return

  cancelling.value = true
  try {
    await appointmentAPI.cancel(appointmentId)
    await loadAppointments()
  } catch (error) {
    console.error('Error cancelling appointment:', error)
    alert('Failed to cancel appointment')
  } finally {
    cancelling.value = false
  }
}
</script>



