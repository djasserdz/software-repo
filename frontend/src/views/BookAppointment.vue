<template>
  <Layout>
    <div class="px-4 sm:px-6 lg:px-8 max-w-6xl mx-auto">
      <div class="mb-8">
        <button
          @click="$router.back()"
          class="text-primary-600 hover:text-primary-700 mb-4 flex items-center"
        >
          <svg class="h-5 w-5 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
          </svg>
          Back
        </button>
        <h1 class="text-3xl font-bold text-gray-900">Book Appointment</h1>
        <p class="mt-2 text-sm text-gray-600">Schedule your grain delivery in 4 easy steps</p>
      </div>

      <!-- Progress Steps -->
      <div class="mb-8">
        <div class="flex items-center justify-between">
          <div
            v-for="(step, index) in steps"
            :key="index"
            class="flex items-center flex-1"
          >
            <div class="flex items-center">
              <div
                class="flex items-center justify-center w-10 h-10 rounded-full border-2 transition-colors"
                :class="
                  currentStep > index
                    ? 'bg-primary-600 border-primary-600 text-white'
                    : currentStep === index
                    ? 'bg-primary-100 border-primary-600 text-primary-600'
                    : 'bg-white border-gray-300 text-gray-400'
                "
              >
                <span v-if="currentStep > index" class="text-white font-semibold">✓</span>
                <span v-else class="font-semibold">{{ index + 1 }}</span>
              </div>
              <div class="ml-3 hidden sm:block">
                <p
                  class="text-sm font-medium"
                  :class="
                    currentStep >= index ? 'text-gray-900' : 'text-gray-400'
                  "
                >
                  {{ step.title }}
                </p>
              </div>
            </div>
            <div
              v-if="index < steps.length - 1"
              class="flex-1 h-0.5 mx-4"
              :class="currentStep > index ? 'bg-primary-600' : 'bg-gray-300'"
            ></div>
          </div>
        </div>
      </div>

      <!-- Step Content -->
      <div class="card">
        <!-- Step 1: Grain Type & Quantity -->
        <div v-if="currentStep === 0" class="space-y-6">
          <div>
            <h2 class="text-2xl font-semibold text-gray-900 mb-2">Step 1: Select Grain Type & Quantity</h2>
            <p class="text-gray-600">Choose the type of grain and quantity you want to deliver</p>
          </div>

          <div>
            <label for="grainType" class="block text-sm font-medium text-gray-700 mb-2">
              Grain Type *
            </label>
            <select
              id="grainType"
              v-model="form.grainTypeId"
              required
              class="input-field"
              @change="onGrainTypeChange"
            >
              <option value="">Select grain type</option>
              <option v-for="grain in grains" :key="grain.grain_id" :value="grain.grain_id">
                {{ grain.name }} - ${{ grain.price }}/ton
              </option>
            </select>
          </div>

          <div>
            <label for="quantity" class="block text-sm font-medium text-gray-700 mb-2">
              Quantity (tons) *
            </label>
            <input
              id="quantity"
              v-model.number="form.requestedQuantity"
              type="number"
              min="1"
              step="0.01"
              required
              class="input-field"
              placeholder="Enter quantity in tons"
            />
          </div>

          <div v-if="form.grainTypeId && form.requestedQuantity" class="bg-primary-50 border border-primary-200 rounded-lg p-4">
            <h3 class="text-sm font-medium text-primary-900 mb-2">Estimated Cost</h3>
            <div class="space-y-1">
              <div class="flex justify-between text-sm">
                <span class="text-primary-700">Quantity:</span>
                <span class="font-medium text-primary-900">{{ form.requestedQuantity }} tons</span>
              </div>
              <div class="flex justify-between text-sm">
                <span class="text-primary-700">Price per ton:</span>
                <span class="font-medium text-primary-900">${{ selectedGrainPrice }}</span>
              </div>
              <div class="border-t border-primary-200 pt-2 mt-2 flex justify-between">
                <span class="font-semibold text-primary-900">Total:</span>
                <span class="text-xl font-bold text-primary-600">${{ estimatedTotal }}</span>
              </div>
            </div>
          </div>

          <div class="flex justify-end">
            <button
              @click="nextStep"
              :disabled="!form.grainTypeId || !form.requestedQuantity || form.requestedQuantity <= 0"
              class="btn-primary"
            >
              Next: Choose Warehouse
            </button>
          </div>
        </div>

        <!-- Step 2: Choose Warehouse (Map) -->
        <div v-if="currentStep === 1" class="space-y-6">
          <div>
            <h2 class="text-2xl font-semibold text-gray-900 mb-2">Step 2: Choose Warehouse</h2>
            <p class="text-gray-600">Select a warehouse from the map or list below</p>
          </div>

          <div class="flex gap-4 mb-4">
            <button
              @click="getUserLocation"
              class="btn-secondary"
              :disabled="loadingLocation"
            >
              <span v-if="loadingLocation">Getting location...</span>
              <span v-else>📍 Use My Location</span>
            </button>
            <input
              v-model="warehouseSearch"
              type="text"
              placeholder="Search warehouses..."
              class="input-field flex-1"
            />
          </div>

          <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <!-- Map -->
            <div class="h-96 bg-gray-100 rounded-lg overflow-hidden border border-gray-300">
              <div id="map" class="w-full h-full"></div>
            </div>

            <!-- Warehouse List -->
            <div class="space-y-3 max-h-96 overflow-y-auto">
              <div
                v-for="warehouse in filteredWarehouses"
                :key="warehouse.warehouse_id"
                @click="selectWarehouse(warehouse)"
                class="p-4 border-2 rounded-lg cursor-pointer transition-all"
                :class="
                  selectedWarehouse?.warehouse_id === warehouse.warehouse_id
                    ? 'border-primary-500 bg-primary-50'
                    : 'border-gray-200 hover:border-primary-300'
                "
              >
                <div class="flex justify-between items-start mb-2">
                  <h3 class="font-semibold text-gray-900">{{ warehouse.name }}</h3>
                  <span
                    v-if="warehouse.distance"
                    class="text-xs font-medium text-primary-600"
                  >
                    {{ warehouse.distance.toFixed(2) }} km
                  </span>
                </div>
                <p class="text-sm text-gray-600 mb-2">{{ warehouse.location }}</p>
                <div class="flex items-center text-xs text-gray-500">
                  <svg class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
                  </svg>
                  <span>{{ warehouse.x_float }}, {{ warehouse.y_float }}</span>
                </div>
              </div>
            </div>
          </div>

          <div class="flex justify-between">
            <button @click="prevStep" class="btn-secondary">Previous</button>
            <button
              @click="nextStep"
              :disabled="!selectedWarehouse"
              class="btn-primary"
            >
              Next: Choose Zone
            </button>
          </div>
        </div>

        <!-- Step 3: Choose Zone -->
        <div v-if="currentStep === 2" class="space-y-6">
          <div>
            <h2 class="text-2xl font-semibold text-gray-900 mb-2">Step 3: Choose Storage Zone</h2>
            <p class="text-gray-600">Select a storage zone from the selected warehouse</p>
          </div>

          <div v-if="selectedWarehouse" class="bg-gray-50 rounded-lg p-4 mb-4">
            <p class="text-sm text-gray-600">Selected Warehouse:</p>
            <p class="font-semibold text-gray-900">{{ selectedWarehouse.name }}</p>
          </div>

          <div v-if="loadingZones" class="text-center py-8 text-gray-500">
            Loading zones...
          </div>
          <div v-else-if="availableZones.length === 0" class="text-center py-8 text-gray-500">
            No available zones for this grain type
          </div>
          <div v-else class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div
              v-for="zone in availableZones"
              :key="zone.zone_id"
              @click="selectZone(zone)"
              class="p-4 border-2 rounded-lg cursor-pointer transition-all"
              :class="
                selectedZone?.zone_id === zone.zone_id
                  ? 'border-primary-500 bg-primary-50'
                  : 'border-gray-200 hover:border-primary-300'
              "
            >
              <div class="flex justify-between items-start mb-2">
                <h3 class="font-semibold text-gray-900">{{ zone.name }}</h3>
                <span
                  class="px-2 py-1 text-xs font-medium rounded-full"
                  :class="zone.status === 'active' ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-800'"
                >
                  {{ zone.status }}
                </span>
              </div>
              <p class="text-sm text-gray-600 mb-3">
                Grain: {{ getGrainName(zone.grain_type_id) }}
              </p>
              <div class="mb-3">
                <div class="flex justify-between text-sm text-gray-600 mb-1">
                  <span>Available Capacity</span>
                  <span>{{ zone.available_capacity }} / {{ zone.total_capacity }} tons</span>
                </div>
                <div class="w-full bg-gray-200 rounded-full h-2">
                  <div
                    class="bg-primary-600 h-2 rounded-full transition-all"
                    :style="{ width: `${(zone.available_capacity / zone.total_capacity) * 100}%` }"
                  ></div>
                </div>
              </div>
              <div
                v-if="form.requestedQuantity > zone.available_capacity"
                class="text-xs text-red-600 mt-2"
              >
                ⚠️ Requested quantity exceeds available capacity
              </div>
            </div>
          </div>

          <div class="flex justify-between">
            <button @click="prevStep" class="btn-secondary">Previous</button>
            <button
              @click="nextStep"
              :disabled="!selectedZone || form.requestedQuantity > selectedZone.available_capacity"
              class="btn-primary"
            >
              Next: Choose Time Slot
            </button>
          </div>
        </div>

        <!-- Step 4: Choose Time Slot -->
        <div v-if="currentStep === 3" class="space-y-6">
          <div>
            <h2 class="text-2xl font-semibold text-gray-900 mb-2">Step 4: Choose Time Slot</h2>
            <p class="text-gray-600">Select an available time slot for your delivery</p>
          </div>

          <div class="bg-gray-50 rounded-lg p-4 mb-4">
            <div class="grid grid-cols-2 gap-4 text-sm">
              <div>
                <p class="text-gray-600">Warehouse:</p>
                <p class="font-semibold text-gray-900">{{ selectedWarehouse?.name }}</p>
              </div>
              <div>
                <p class="text-gray-600">Zone:</p>
                <p class="font-semibold text-gray-900">{{ selectedZone?.name }}</p>
              </div>
              <div>
                <p class="text-gray-600">Grain Type:</p>
                <p class="font-semibold text-gray-900">{{ getGrainName(form.grainTypeId) }}</p>
              </div>
              <div>
                <p class="text-gray-600">Quantity:</p>
                <p class="font-semibold text-gray-900">{{ form.requestedQuantity }} tons</p>
              </div>
            </div>
          </div>

          <div v-if="loadingTimeSlots" class="text-center py-8 text-gray-500">
            Loading available time slots...
          </div>
          <div v-else-if="availableTimeSlots.length === 0" class="text-center py-8 text-gray-500">
            No available time slots. Please try a different zone or check back later.
          </div>
          <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            <div
              v-for="slot in availableTimeSlots"
              :key="slot.time_id"
              @click="selectTimeSlot(slot)"
              class="p-4 border-2 rounded-lg cursor-pointer transition-all"
              :class="
                selectedTimeSlot?.time_id === slot.time_id
                  ? 'border-primary-500 bg-primary-50'
                  : 'border-gray-200 hover:border-primary-300'
              "
            >
              <div class="text-center">
                <p class="font-semibold text-gray-900">{{ formatDate(slot.start_at) }}</p>
                <p class="text-sm text-gray-600 mt-1">
                  {{ formatTime(slot.start_at) }} - {{ formatTime(slot.end_at) }}
                </p>
              </div>
            </div>
          </div>

          <div v-if="error" class="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg">
            {{ error }}
          </div>

          <div class="flex justify-between">
            <button @click="prevStep" class="btn-secondary">Previous</button>
            <button
              @click="handleSubmit"
              :disabled="!selectedTimeSlot || loading"
              class="btn-primary"
            >
              <span v-if="loading">Booking...</span>
              <span v-else>Complete Booking</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  </Layout>
</template>

<script setup>
import { ref, computed, onMounted, watch, nextTick } from 'vue'
import { useRouter } from 'vue-router'
import { grainAPI } from '../api/grain'
import { warehouseAPI } from '../api/warehouse'
import { zoneAPI } from '../api/zone'
import { timeslotAPI } from '../api/timeslot'
import { appointmentAPI } from '../api/appointment'
import { geolocationAPI } from '../api/geolocation'
import Layout from '../components/Layout.vue'

const router = useRouter()

const steps = [
  { title: 'Grain & Quantity' },
  { title: 'Warehouse' },
  { title: 'Storage Zone' },
  { title: 'Time Slot' },
]

const currentStep = ref(0)
const form = ref({
  grainTypeId: '',
  requestedQuantity: '',
  warehouseZoneId: '',
  timeSlotId: '',
})

const grains = ref([])
const warehouses = ref([])
const availableZones = ref([])
const availableTimeSlots = ref([])
const selectedWarehouse = ref(null)
const selectedZone = ref(null)
const selectedTimeSlot = ref(null)
const warehouseSearch = ref('')
const loading = ref(false)
const loadingLocation = ref(false)
const loadingZones = ref(false)
const loadingTimeSlots = ref(false)
const error = ref(null)
const userLocation = ref(null)
let map = null
let mapMarkers = []

const selectedGrainPrice = computed(() => {
  const grain = grains.value.find((g) => g.grain_id === form.value.grainTypeId)
  return grain ? parseFloat(grain.price) : 0
})

const estimatedTotal = computed(() => {
  return (form.value.requestedQuantity * selectedGrainPrice.value).toFixed(2)
})

const filteredWarehouses = computed(() => {
  if (!warehouseSearch.value) return warehouses.value
  const query = warehouseSearch.value.toLowerCase()
  return warehouses.value.filter(
    (w) =>
      w.name.toLowerCase().includes(query) ||
      w.location.toLowerCase().includes(query)
  )
})

onMounted(async () => {
  try {
    const grainsRes = await grainAPI.getAll()
    grains.value = grainsRes.data || []
  } catch (error) {
    console.error('Error loading grains:', error)
  }
})

const onGrainTypeChange = () => {
  if (form.value.grainTypeId && userLocation.value) {
    loadNearestWarehouses()
  } else {
    loadAllWarehouses()
  }
}

const loadAllWarehouses = async () => {
  try {
    const response = await warehouseAPI.getAll()
    warehouses.value = response.data || []
    if (map) {
      updateMap()
    }
  } catch (error) {
    console.error('Error loading warehouses:', error)
  }
}

const loadNearestWarehouses = async () => {
  if (!userLocation.value || !form.value.grainTypeId) return

  loadingLocation.value = true
  try {
    const response = await geolocationAPI.getNearestWarehouses(
      userLocation.value.lat,
      userLocation.value.lng,
      form.value.grainTypeId
    )
    warehouses.value = response.data.data.allWarehouses || []
    if (map) {
      updateMap()
    }
  } catch (error) {
    console.error('Error loading nearest warehouses:', error)
  } finally {
    loadingLocation.value = false
  }
}

const getUserLocation = () => {
  if (!navigator.geolocation) {
    alert('Geolocation is not supported by your browser')
    return
  }

  loadingLocation.value = true
  navigator.geolocation.getCurrentPosition(
    async (position) => {
      userLocation.value = {
        lat: position.coords.latitude,
        lng: position.coords.longitude,
      }

      if (form.value.grainTypeId) {
        await loadNearestWarehouses()
      } else {
        await loadAllWarehouses()
      }

      if (map) {
        updateMap()
      }
    },
    (error) => {
      console.error('Error getting location:', error)
      alert('Unable to retrieve your location')
      loadingLocation.value = false
    }
  )
}

const initMap = async () => {
  await nextTick()
  if (typeof window === 'undefined') return
  
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
  const mapElement = document.getElementById('map')
  if (!mapElement || map) return

  const center = userLocation.value
    ? [userLocation.value.lat, userLocation.value.lng]
    : [31.0, 36.0] // Default center

  map = L.map('map').setView(center, 10)

  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    attribution: '© OpenStreetMap contributors',
  }).addTo(map)

  if (userLocation.value) {
    L.marker([userLocation.value.lat, userLocation.value.lng])
      .addTo(map)
      .bindPopup('Your Location')
      .openPopup()
  }

  updateMap()
}

const updateMap = () => {
  if (!map) {
    // Try to initialize map if it doesn't exist
    if (window.L) {
      initMap()
    }
    return
  }
  
  const L = window.L
  if (!L) return

  mapMarkers.forEach((marker) => map.removeLayer(marker))
  mapMarkers = []

  warehouses.value.forEach((warehouse) => {
    const marker = L.marker([warehouse.y_float, warehouse.x_float])
      .addTo(map)
      .bindPopup(warehouse.name)
      .on('click', () => selectWarehouse(warehouse))

    mapMarkers.push(marker)
  })

  if (warehouses.value.length > 0) {
    const bounds = L.latLngBounds(
      warehouses.value.map((w) => [w.y_float, w.x_float])
    )
    if (userLocation.value) {
      bounds.extend([userLocation.value.lat, userLocation.value.lng])
    }
    map.fitBounds(bounds, { padding: [50, 50] })
  }
}

watch(currentStep, (newStep) => {
  if (newStep === 1) {
    if (!warehouses.value.length) {
      loadAllWarehouses()
    }
    nextTick(() => {
      initMap()
    })
  } else if (newStep === 2) {
    loadZones()
  } else if (newStep === 3) {
    loadTimeSlots()
  }
})

const selectWarehouse = (warehouse) => {
  selectedWarehouse.value = warehouse
  if (map && window.L) {
    map.setView([warehouse.y_float, warehouse.x_float], 13)
    mapMarkers.forEach((marker) => {
      if (marker.getLatLng().lat === warehouse.y_float) {
        marker.openPopup()
      }
    })
  }
}

const selectZone = (zone) => {
  selectedZone.value = zone
  form.value.warehouseZoneId = zone.zone_id
}

const selectTimeSlot = (slot) => {
  selectedTimeSlot.value = slot
  form.value.timeSlotId = slot.time_id
}

const loadZones = async () => {
  if (!selectedWarehouse.value || !form.value.grainTypeId) return

  loadingZones.value = true
  try {
    const response = await zoneAPI.getAll({
      warehouse_id: selectedWarehouse.value.warehouse_id,
      grain_type_id: form.value.grainTypeId,
      status: 'active',
    })
    availableZones.value = (response.data || []).filter(
      (zone) => zone.available_capacity >= form.value.requestedQuantity
    )
  } catch (error) {
    console.error('Error loading zones:', error)
    availableZones.value = []
  } finally {
    loadingZones.value = false
  }
}

const loadTimeSlots = async () => {
  if (!selectedZone.value || !form.value.grainTypeId) return

  loadingTimeSlots.value = true
  try {
    const response = await timeslotAPI.getAvailable(
      selectedZone.value.zone_id,
      form.value.grainTypeId
    )
    availableTimeSlots.value = response.data.data || []
  } catch (error) {
    console.error('Error loading time slots:', error)
    availableTimeSlots.value = []
  } finally {
    loadingTimeSlots.value = false
  }
}

const getGrainName = (grainId) => {
  const grain = grains.value.find((g) => g.grain_id === grainId)
  return grain ? grain.name : 'Unknown'
}

const formatDate = (dateString) => {
  return new Date(dateString).toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  })
}

const formatTime = (dateString) => {
  return new Date(dateString).toLocaleTimeString('en-US', {
    hour: '2-digit',
    minute: '2-digit',
  })
}

const nextStep = () => {
  if (currentStep.value < steps.length - 1) {
    currentStep.value++
  }
}

const prevStep = () => {
  if (currentStep.value > 0) {
    currentStep.value--
  }
}

const handleSubmit = async () => {
  loading.value = true
  error.value = null

  try {
    await appointmentAPI.create({
      grainTypeId: form.value.grainTypeId,
      warehouseZoneId: form.value.warehouseZoneId,
      requestedQuantity: form.value.requestedQuantity,
      timeSlotId: form.value.timeSlotId,
    })
    router.push('/appointments')
  } catch (err) {
    error.value = err.response?.data?.detail || 'Failed to book appointment'
  } finally {
    loading.value = false
  }
}
</script>

<style>
/* Leaflet styles are loaded from CDN in index.html */
</style>
