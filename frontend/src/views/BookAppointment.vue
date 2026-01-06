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
                {{ grain.name }} - {{ formatPrice(grain.price / 1000) }} DZD/kg
              </option>
            </select>
          </div>

          <div>
            <label for="quantity" class="block text-sm font-medium text-gray-700 mb-2">
              Quantity (kg) *
            </label>
            <input
              id="quantity"
              v-model.number="form.requestedQuantityKg"
              type="number"
              min="1"
              step="0.01"
              required
              class="input-field"
              placeholder="Enter quantity in kilograms"
            />
          </div>

          <div v-if="form.grainTypeId && form.requestedQuantityKg" class="bg-primary-50 border border-primary-200 rounded-lg p-4">
            <h3 class="text-sm font-medium text-primary-900 mb-2">Estimated Cost</h3>
            <div class="space-y-1">
              <div class="flex justify-between text-sm">
                <span class="text-primary-700">Quantity:</span>
                <span class="font-medium text-primary-900">{{ formatNumber(form.requestedQuantityKg) }} kg</span>
              </div>
              <div class="flex justify-between text-sm">
                <span class="text-primary-700">Price per kg:</span>
                <span class="font-medium text-primary-900">{{ formatPrice(selectedGrainPricePerKg) }} DZD</span>
              </div>
              <div class="border-t border-primary-200 pt-2 mt-2 flex justify-between">
                <span class="font-semibold text-primary-900">Total:</span>
                <span class="text-xl font-bold text-primary-600">{{ formatPrice(estimatedTotal) }} DZD</span>
              </div>
            </div>
          </div>

          <div class="flex justify-end">
            <button
              @click="nextStep"
              :disabled="!form.grainTypeId || !form.requestedQuantityKg || form.requestedQuantityKg <= 0"
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

          <div v-if="loadingLocation && warehouses.length === 0" class="text-center py-12">
            <div class="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600"></div>
            <p class="mt-2 text-gray-500">Loading warehouses...</p>
          </div>

          <div v-else-if="warehouses.length === 0" class="text-center py-12">
            <p class="text-gray-500">No warehouses found with the selected grain type</p>
          </div>

          <div v-else class="grid grid-cols-1 lg:grid-cols-2 gap-6">
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
                  <span>{{ formatNumber(zone.available_capacity * 1000) }} / {{ formatNumber(zone.total_capacity * 1000) }} kg</span>
                </div>
                <div class="w-full bg-gray-200 rounded-full h-2">
                  <div
                    class="bg-primary-600 h-2 rounded-full transition-all"
                    :style="{ width: `${(zone.available_capacity / zone.total_capacity) * 100}%` }"
                  ></div>
                </div>
              </div>
              <div
                v-if="form.requestedQuantityKg > (zone.available_capacity * 1000)"
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
              :disabled="!selectedZone || form.requestedQuantityKg > (selectedZone.available_capacity * 1000)"
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
                <p class="font-semibold text-gray-900">{{ formatNumber(form.requestedQuantityKg) }} kg</p>
              </div>
            </div>
          </div>

          <!-- Toggle between available slots and custom time request -->
          <div class="mb-4 flex gap-2 border-b border-gray-200">
            <button
              @click="showCustomTime = false"
              class="px-4 py-2 font-medium transition-colors"
              :class="!showCustomTime ? 'text-primary-600 border-b-2 border-primary-600' : 'text-gray-500 hover:text-gray-700'"
            >
              Available Slots
            </button>
            <button
              @click="showCustomTime = true"
              class="px-4 py-2 font-medium transition-colors"
              :class="showCustomTime ? 'text-primary-600 border-b-2 border-primary-600' : 'text-gray-500 hover:text-gray-700'"
            >
              Request Custom Time
            </button>
          </div>

          <!-- Available Time Slots -->
          <div v-if="!showCustomTime">
            <div v-if="loadingTimeSlots" class="text-center py-8 text-gray-500">
              Loading available time slots...
            </div>
            <div v-else-if="availableTimeSlots.length === 0" class="text-center py-8">
              <p class="text-gray-500 mb-4">No available time slots for this zone.</p>
              <p class="text-sm text-gray-400 mb-4">You can request a custom time slot using the "Request Custom Time" tab above.</p>
            </div>
            <div v-else>
              <p class="text-sm text-gray-600 mb-4">
                Found {{ availableTimeSlots.length }} available time slot{{ availableTimeSlots.length !== 1 ? 's' : '' }}
              </p>
              <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              <div
                v-for="slot in availableTimeSlots"
                :key="slot.time_id"
                @click="selectTimeSlot(slot)"
                  class="p-4 border-2 rounded-lg cursor-pointer transition-all hover:shadow-md"
                :class="
                  selectedTimeSlot?.time_id === slot.time_id
                      ? 'border-primary-500 bg-primary-50 shadow-md'
                    : 'border-gray-200 hover:border-primary-300'
                "
              >
                <div class="text-center">
                    <p class="font-semibold text-gray-900 text-lg">{{ formatDate(slot.start_at) }}</p>
                    <p class="text-base text-primary-600 font-medium mt-2">
                    {{ formatTime(slot.start_at) }} - {{ formatTime(slot.end_at) }}
                  </p>
                    <p v-if="slot.date" class="text-xs text-gray-500 mt-1">
                      {{ getDayName(slot.start_at) }}
                    </p>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Custom Time Request Form -->
          <div v-else class="space-y-4">
            <div class="bg-blue-50 border border-blue-200 rounded-lg p-4 mb-4">
              <p class="text-sm text-blue-800">
                <strong>Request a custom time slot:</strong> Choose your preferred date and time. The warehouse admin will review and confirm your request.
              </p>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-2">
                  Preferred Date <span class="text-red-500">*</span>
                </label>
                <input
                  v-model="customTimeForm.date"
                  type="date"
                  :min="minDate"
                  class="input-field"
                  required
                />
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-2">
                  Preferred Start Time <span class="text-red-500">*</span>
                </label>
                <input
                  v-model="customTimeForm.startTime"
                  type="time"
                  class="input-field"
                  required
                />
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-2">
                  Preferred End Time <span class="text-red-500">*</span>
                </label>
                <input
                  v-model="customTimeForm.endTime"
                  type="time"
                  class="input-field"
                  :min="customTimeForm.startTime"
                  required
                />
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-2">
                  Notes (Optional)
                </label>
                <textarea
                  v-model="customTimeForm.notes"
                  rows="3"
                  class="input-field"
                  placeholder="Any special requirements or notes..."
                ></textarea>
              </div>
            </div>

            <div v-if="customTimeError" class="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg">
              {{ customTimeError }}
            </div>

            <button
              @click="requestCustomTimeSlot"
              :disabled="!isCustomTimeFormValid || requestingCustomTime"
              class="btn-primary w-full"
            >
              <span v-if="requestingCustomTime">Requesting...</span>
              <span v-else>Request This Time Slot</span>
            </button>
          </div>

          <div v-if="error" class="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg">
            {{ error }}
          </div>

          <div class="flex justify-between">
            <button @click="prevStep" class="btn-secondary">Previous</button>
            <button
              @click="handleSubmit"
              :disabled="(!selectedTimeSlot && !customTimeSlot) || loading"
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
  requestedQuantityKg: '',
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

// Custom time slot request
const showCustomTime = ref(false)
const requestingCustomTime = ref(false)
const customTimeError = ref(null)
const customTimeForm = ref({
  date: '',
  startTime: '',
  endTime: '',
  notes: ''
})
const customTimeSlot = ref(null) // Store the created custom time slot

const selectedGrainPrice = computed(() => {
  const grain = grains.value.find((g) => g.grain_id === form.value.grainTypeId)
  return grain ? parseFloat(grain.price) : 0 // Price per ton from backend
})

const selectedGrainPricePerKg = computed(() => {
  return selectedGrainPrice.value / 1000 // Convert price per ton to price per kg
})

const estimatedTotal = computed(() => {
  if (!form.value.requestedQuantityKg) return 0
  // Calculate: quantity in kg * price per kg
  return form.value.requestedQuantityKg * selectedGrainPricePerKg.value
})

// Helper functions for formatting
const formatPrice = (price) => {
  if (!price) return '0'
  return new Intl.NumberFormat('ar-DZ', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  }).format(price)
}

const formatNumber = (num) => {
  if (!num) return '0'
  return new Intl.NumberFormat('ar-DZ', {
    minimumFractionDigits: 0,
    maximumFractionDigits: 0
  }).format(num)
}

const filteredWarehouses = computed(() => {
  if (!warehouseSearch.value) return warehouses.value
  const query = warehouseSearch.value.toLowerCase()
  return warehouses.value.filter(
    (w) =>
      w.name.toLowerCase().includes(query) ||
      w.location.toLowerCase().includes(query)
  )
})

const minDate = computed(() => {
  const tomorrow = new Date()
  tomorrow.setDate(tomorrow.getDate() + 1)
  return tomorrow.toISOString().split('T')[0]
})

const isCustomTimeFormValid = computed(() => {
  return customTimeForm.value.date && 
         customTimeForm.value.startTime && 
         customTimeForm.value.endTime &&
         customTimeForm.value.endTime > customTimeForm.value.startTime
})

onMounted(async () => {
  try {
    const grainsRes = await grainAPI.getAll()
    grains.value = grainsRes.data || []
    // Don't load warehouses until grain type is selected
    warehouses.value = []
  } catch (error) {
    console.error('Error loading grains:', error)
  }
})

const onGrainTypeChange = () => {
  if (form.value.grainTypeId) {
    if (userLocation.value) {
      loadNearestWarehouses()
    } else {
      loadAllWarehouses()
    }
  } else {
    warehouses.value = []
    if (map) {
      updateMap()
    }
  }
}

const loadAllWarehouses = async () => {
  if (!form.value.grainTypeId) {
    warehouses.value = []
    return
  }

  loadingLocation.value = true
  try {
    // First, get all warehouses
    const warehousesRes = await warehouseAPI.getAll()
    const allWarehouses = warehousesRes.data || []
    
    // Then, get all zones with the selected grain type to find which warehouses have this grain type
    const zonesRes = await zoneAPI.getAll({
      grain_type_id: form.value.grainTypeId,
      status: 'active',
    })
    const zones = zonesRes.data || []
    
    // Get unique warehouse IDs that have zones with this grain type
    const warehouseIdsWithGrainType = [...new Set(zones.map(zone => zone.warehouse_id))]
    
    // Filter warehouses to only include those that have zones with the selected grain type
    warehouses.value = allWarehouses.filter(warehouse => 
      warehouseIdsWithGrainType.includes(warehouse.warehouse_id)
    )
    
    // If no warehouses found, show all warehouses anyway (user can see which ones don't have the grain type)
    if (warehouses.value.length === 0 && allWarehouses.length > 0) {
      warehouses.value = allWarehouses
    }
    
    if (map) {
      updateMap()
    }
  } catch (error) {
    console.error('Error loading warehouses:', error)
    error.value = `Failed to load warehouses: ${error.message || error}`
    warehouses.value = []
  } finally {
    loadingLocation.value = false
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
    // Load warehouses when entering step 2 (warehouse selection)
    if (!warehouses.value.length && form.value.grainTypeId) {
      if (userLocation.value) {
        loadNearestWarehouses()
      } else {
        loadAllWarehouses()
      }
    }
    nextTick(() => {
      initMap()
    })
  } else if (newStep === 2) {
    loadZones()
  } else if (newStep === 3) {
    loadTimeSlots()
    // Reset custom time form when entering time slot selection
    customTimeForm.value = {
      date: '',
      startTime: '',
      endTime: '',
      notes: ''
    }
    customTimeSlot.value = null
    showCustomTime.value = false
  }
})

watch(selectedZone, () => {
  // Reset custom time form when zone changes
  customTimeForm.value = {
    date: '',
    startTime: '',
    endTime: '',
    notes: ''
  }
  customTimeSlot.value = null
  selectedTimeSlot.value = null
  form.value.timeSlotId = ''
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

const requestCustomTimeSlot = async () => {
  if (!isCustomTimeFormValid.value || !selectedZone.value) return

  requestingCustomTime.value = true
  customTimeError.value = null

  try {
    // Combine date and time into datetime strings
    const startDateTime = `${customTimeForm.value.date}T${customTimeForm.value.startTime}:00`
    const endDateTime = `${customTimeForm.value.date}T${customTimeForm.value.endTime}:00`

    // Create the time slot
    const timeSlotData = {
      zone_id: selectedZone.value.zone_id,
      start_at: startDateTime,
      end_at: endDateTime,
      status: 'active'
    }

    const response = await timeslotAPI.create(timeSlotData)
    const createdSlot = response.data

    // Select the newly created slot
    customTimeSlot.value = createdSlot
    selectedTimeSlot.value = {
      time_id: createdSlot.time_id,
      start_at: createdSlot.start_at,
      end_at: createdSlot.end_at
    }
    form.value.timeSlotId = createdSlot.time_id

    // Switch back to available slots view and show success
    showCustomTime.value = false
    await loadTimeSlots() // Refresh the list

    alert('✅ Custom time slot created successfully! You can now complete your booking.')
  } catch (error) {
    console.error('Error creating custom time slot:', error)
    customTimeError.value = error.response?.data?.detail || error.message || 'Failed to create custom time slot. Please try again.'
  } finally {
    requestingCustomTime.value = false
  }
}

const loadZones = async () => {
  if (!selectedWarehouse.value || !form.value.grainTypeId) return

  loadingZones.value = true
  error.value = null
  try {
    const response = await zoneAPI.getAll({
      warehouse_id: selectedWarehouse.value.warehouse_id,
      grain_type_id: form.value.grainTypeId,
      status: 'active',
    })
    // Convert requestedQuantityKg to tons for comparison (backend uses tons)
    const requestedQuantityTons = form.value.requestedQuantityKg ? form.value.requestedQuantityKg / 1000 : 0
    availableZones.value = (response.data || []).filter(
      (zone) => zone.available_capacity >= requestedQuantityTons
    )
    
    if (availableZones.value.length === 0) {
      error.value = 'No available zones with sufficient capacity for the requested quantity'
    }
  } catch (error) {
    console.error('Error loading zones:', error)
    error.value = `Failed to load zones: ${error.message || error}`
    availableZones.value = []
  } finally {
    loadingZones.value = false
  }
}

const loadTimeSlots = async () => {
  if (!selectedZone.value || !form.value.grainTypeId) {
    console.warn('Cannot load time slots: missing zone or grain type', {
      zone: selectedZone.value,
      grainTypeId: form.value.grainTypeId
    })
    return
  }

  loadingTimeSlots.value = true
  error.value = null
  try {
    // Ensure we're passing integers
    const zoneId = parseInt(selectedZone.value.zone_id)
    const grainTypeId = parseInt(form.value.grainTypeId)
    
    const response = await timeslotAPI.getAvailable(zoneId, grainTypeId)
    
    // Handle response structure: response.data.data or response.data
    const slots = response.data?.data || response.data || []
    availableTimeSlots.value = Array.isArray(slots) ? slots : []
    
    if (availableTimeSlots.value.length === 0) {
      // Don't set error, just show message in UI
      console.log('No available time slots found for this zone')
    }
  } catch (error) {
    console.error('Error loading time slots:', error)
    let errorMsg = 'Failed to load available time slots'
    if (error.response?.data?.detail) {
      if (Array.isArray(error.response.data.detail)) {
        errorMsg = error.response.data.detail.map(e => e.msg || JSON.stringify(e)).join(', ')
      } else {
        errorMsg = error.response.data.detail
      }
    } else if (error.message) {
      errorMsg = error.message
    }
    error.value = `Error: ${errorMsg}. Please try again.`
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

const getDayName = (dateString) => {
  const date = new Date(dateString)
  const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
  return days[date.getDay()]
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
    // Use custom time slot if available, otherwise use selected time slot
    const timeSlotId = customTimeSlot.value?.time_id || form.value.timeSlotId
    
    if (!timeSlotId) {
      error.value = 'Please select or request a time slot'
      loading.value = false
      return
    }

    // Validate all required fields
    if (!form.value.grainTypeId || !form.value.warehouseZoneId || !form.value.requestedQuantityKg) {
      error.value = 'Please complete all steps'
      loading.value = false
      return
    }

    // Convert kg to tons for backend (backend expects tons)
    const requestedQuantityTons = form.value.requestedQuantityKg / 1000

    await appointmentAPI.create({
      grainTypeId: parseInt(form.value.grainTypeId),
      warehouseZoneId: parseInt(form.value.warehouseZoneId),
      requestedQuantity: requestedQuantityTons,
      timeSlotId: parseInt(timeSlotId),
    })
    
    // Show success message
    alert('Appointment booked successfully!')
    router.push('/appointments')
  } catch (err) {
    console.error('Error booking appointment:', err)
    let errorMsg = 'Failed to book appointment'
    if (err.response?.data?.detail) {
      if (Array.isArray(err.response.data.detail)) {
        errorMsg = err.response.data.detail.map(e => e.msg || JSON.stringify(e)).join(', ')
      } else {
        errorMsg = err.response.data.detail
      }
    } else if (err.message) {
      errorMsg = err.message
    }
    error.value = errorMsg
  } finally {
    loading.value = false
  }
}
</script>

<style>
/* Leaflet styles are loaded from CDN in index.html */
</style>
