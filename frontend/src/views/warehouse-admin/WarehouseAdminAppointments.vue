<template>
  <Layout>
    <div>
      <div class="mb-8">
        <h1 class="text-3xl font-bold text-gray-900">Appointments Management</h1>
        <p class="mt-2 text-sm text-gray-600">Manage appointments for your warehouses</p>
      </div>

      <div class="mb-6 flex gap-2">
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

      <div v-if="loading" class="text-center py-12">
        <div class="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600"></div>
        <p class="mt-2 text-gray-500">Loading appointments...</p>
      </div>

      <div v-else-if="appointments.length === 0" class="text-center py-12">
        <p class="text-gray-500 mb-4">No appointments found</p>
        <button @click="loadAppointments" class="btn-secondary">Retry</button>
      </div>

      <div v-else class="space-y-4">
        <div
          v-for="appointment in appointments"
          :key="appointment.appointment_id"
          class="card"
        >
          <div class="flex justify-between items-start mb-4">
            <div>
              <h3 class="text-lg font-semibold text-gray-900">Appointment #{{ appointment.appointment_id }}</h3>
              <p class="text-sm text-gray-500 mt-1">
                Created: {{ formatDate(appointment.created_at) }}
              </p>
            </div>
            <span
              class="px-2 py-1 text-xs font-medium rounded-full"
              :class="getStatusClass(appointment.status)"
            >
              {{ appointment.status }}
            </span>
          </div>
          <div class="grid grid-cols-2 gap-4 text-sm mb-4">
            <div>
              <span class="text-gray-500">Farmer:</span>
              <span class="ml-2 font-medium text-gray-900">
                {{ getFarmerName(appointment.farmer_id) }}
              </span>
            </div>
            <div>
              <span class="text-gray-500">Zone:</span>
              <span class="ml-2 font-medium text-gray-900">
                {{ getZoneName(appointment.zone_id) }}
              </span>
            </div>
            <div>
              <span class="text-gray-500">Grain Type:</span>
              <span class="ml-2 font-medium text-gray-900">
                {{ getGrainName(appointment.grain_type_id) }}
              </span>
            </div>
            <div>
              <span class="text-gray-500">Quantity:</span>
              <span class="ml-2 font-medium text-gray-900">
                {{ formatNumber((appointment.requested_quantity || 0) * 1000) }} kg
              </span>
            </div>
            <div v-if="getTimeSlot(appointment.timeslot_id)" class="col-span-2">
              <span class="text-gray-500">Time Slot:</span>
              <span class="ml-2 font-medium text-gray-900">
                {{ formatTimeSlot(getTimeSlot(appointment.timeslot_id)) }}
              </span>
            </div>
          </div>
          <div v-if="appointment.status === 'pending'" class="mt-4 flex gap-2">
            <button
              @click="acceptAppointment(appointment.appointment_id)"
              class="btn-primary text-sm"
              :disabled="processing === appointment.appointment_id"
            >
              {{ processing === appointment.appointment_id ? 'Processing...' : 'Accept' }}
            </button>
            <button
              @click="refuseAppointment(appointment.appointment_id)"
              class="btn-secondary text-sm bg-red-600 hover:bg-red-700 text-white"
              :disabled="processing === appointment.appointment_id"
            >
              {{ processing === appointment.appointment_id ? 'Processing...' : 'Refuse' }}
            </button>
          </div>
          <div v-else-if="appointment.status === 'accepted'" class="mt-4 flex gap-2">
            <button
              @click="confirmAttendance(appointment.appointment_id)"
              class="btn-primary text-sm"
              :disabled="processing === appointment.appointment_id"
            >
              {{ processing === appointment.appointment_id ? 'Processing...' : 'Confirm Attendance' }}
            </button>
          </div>
        </div>
      </div>
    </div>
  </Layout>
</template>

<script setup>
import { ref, onMounted, watch } from 'vue'
import { appointmentAPI } from '../../api/appointment'
import { userAPI } from '../../api/user'
import { grainAPI } from '../../api/grain'
import { zoneAPI } from '../../api/zone'
import { timeslotAPI } from '../../api/timeslot'
import Layout from '../../components/Layout.vue'

const appointments = ref([])
const loading = ref(true)
const selectedStatus = ref(null)
const processing = ref(null)
const farmers = ref({})
const grains = ref({})
const zones = ref({})
const timeSlots = ref({})

const statusFilters = [
  { label: 'All', value: null },
  { label: 'Pending', value: 'pending' },
  { label: 'Accepted', value: 'accepted' },
  { label: 'Completed', value: 'completed' },
  { label: 'Refused', value: 'refused' },
  { label: 'Cancelled', value: 'cancelled' },
]

const loadAppointments = async () => {
  loading.value = true
  try {
    const params = selectedStatus.value ? { status: selectedStatus.value } : {}
    const response = await appointmentAPI.getAll(params)
    const apps = response.data || []
    appointments.value = apps
    
    // Fetch related data for all appointments
    const uniqueFarmerIds = [...new Set(apps.map(a => a.farmer_id))]
    const uniqueGrainIds = [...new Set(apps.map(a => a.grain_type_id))]
    const uniqueZoneIds = [...new Set(apps.map(a => a.zone_id))]
    const uniqueTimeSlotIds = [...new Set(apps.map(a => a.timeslot_id).filter(Boolean))]
    
    // Load farmers
    for (const farmerId of uniqueFarmerIds) {
      if (!farmers.value[farmerId]) {
        try {
          const farmerRes = await userAPI.getById(farmerId)
          farmers.value[farmerId] = farmerRes.data
        } catch (e) {
          console.warn(`Failed to load farmer ${farmerId}:`, e)
        }
      }
    }
    
    // Load grains
    try {
      const grainsRes = await grainAPI.getAll()
      grainsRes.data?.forEach(grain => {
        grains.value[grain.grain_id] = grain
      })
    } catch (e) {
      console.warn('Failed to load grains:', e)
    }
    
    // Load zones
    for (const zoneId of uniqueZoneIds) {
      if (!zones.value[zoneId]) {
        try {
          const zoneRes = await zoneAPI.getById(zoneId)
          zones.value[zoneId] = zoneRes.data
        } catch (e) {
          console.warn(`Failed to load zone ${zoneId}:`, e)
        }
      }
    }
    
    // Load time slots
    for (const timeSlotId of uniqueTimeSlotIds) {
      if (!timeSlots.value[timeSlotId]) {
        try {
          const timeSlotRes = await timeslotAPI.getById(timeSlotId)
          timeSlots.value[timeSlotId] = timeSlotRes.data
        } catch (e) {
          console.warn(`Failed to load time slot ${timeSlotId}:`, e)
        }
      }
    }
  } catch (error) {
    console.error('Error loading appointments:', error)
    appointments.value = []
  } finally {
    loading.value = false
  }
}

const acceptAppointment = async (appointmentId) => {
  if (!confirm('Are you sure you want to accept this appointment?')) return
  
  processing.value = appointmentId
  try {
    await appointmentAPI.accept(appointmentId)
    alert('✅ Appointment accepted successfully!')
    await loadAppointments()
  } catch (error) {
    console.error('Error accepting appointment:', error)
    const errorMsg = error.response?.data?.detail || error.message || 'Failed to accept appointment'
    alert('❌ ' + errorMsg)
  } finally {
    processing.value = null
  }
}

const refuseAppointment = async (appointmentId) => {
  if (!confirm('Are you sure you want to refuse this appointment?')) return
  
  processing.value = appointmentId
  try {
    await appointmentAPI.refuse(appointmentId)
    alert('✅ Appointment refused successfully!')
    await loadAppointments()
  } catch (error) {
    console.error('Error refusing appointment:', error)
    const errorMsg = error.response?.data?.detail || error.message || 'Failed to refuse appointment'
    alert('❌ ' + errorMsg)
  } finally {
    processing.value = null
  }
}

const confirmAttendance = async (appointmentId) => {
  if (!confirm('Confirm that the farmer attended this appointment?')) return
  
  processing.value = appointmentId
  try {
    await appointmentAPI.confirmAttendance(appointmentId)
    alert('✅ Attendance confirmed successfully!')
    await loadAppointments()
  } catch (error) {
    console.error('Error confirming attendance:', error)
    const errorMsg = error.response?.data?.detail || error.message || 'Failed to confirm attendance'
    alert('❌ ' + errorMsg)
  } finally {
    processing.value = null
  }
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

const formatDate = (dateString) => {
  return new Date(dateString).toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  })
}

const formatNumber = (num) => {
  if (!num) return '0'
  return new Intl.NumberFormat('ar-DZ', {
    minimumFractionDigits: 0,
    maximumFractionDigits: 0
  }).format(num)
}

const getFarmerName = (farmerId) => {
  const farmer = farmers.value[farmerId]
  if (farmer) {
    return farmer.name || farmer.email || `Farmer #${farmerId}`
  }
  return `Farmer #${farmerId}`
}

const getGrainName = (grainId) => {
  const grain = grains.value[grainId]
  return grain ? grain.name : `Grain #${grainId}`
}

const getZoneName = (zoneId) => {
  const zone = zones.value[zoneId]
  return zone ? zone.name : `Zone #${zoneId}`
}

const getTimeSlot = (timeSlotId) => {
  return timeSlots.value[timeSlotId] || null
}

const formatTimeSlot = (timeSlot) => {
  if (!timeSlot) return 'N/A'
  const start = new Date(timeSlot.start_at)
  const end = new Date(timeSlot.end_at)
  return `${start.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })} ${start.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' })} - ${end.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' })}`
}

watch(selectedStatus, () => {
  loadAppointments()
})

onMounted(() => {
  loadAppointments()
})
</script>

