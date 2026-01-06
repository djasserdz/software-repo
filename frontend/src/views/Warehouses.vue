<template>
  <Layout>
    <div class="px-4 sm:px-6 lg:px-8">
      <div class="mb-8">
        <h1 class="text-3xl font-bold text-gray-900">Warehouses</h1>
        <p class="mt-2 text-sm text-gray-600">Find and explore available warehouses</p>
      </div>

      <div class="mb-6">
        <div class="flex flex-col sm:flex-row gap-4">
          <div class="flex-1">
            <input
              v-model="searchQuery"
              type="text"
              placeholder="Search warehouses..."
              class="input-field"
            />
          </div>
          <div class="flex gap-2">
            <button
              @click="getUserLocation"
              class="btn-secondary whitespace-nowrap"
              :disabled="loadingLocation"
            >
              <span v-if="loadingLocation">Getting location...</span>
              <span v-else>📍 Find Nearest</span>
            </button>
            <select v-model="selectedGrainType" class="input-field w-48">
              <option value="">All Grain Types</option>
              <option v-for="grain in grains" :key="grain.grain_id" :value="grain.grain_id">
                {{ grain.name }}
              </option>
            </select>
          </div>
        </div>
      </div>

      <div v-if="loading" class="text-center py-12">
        <div class="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600"></div>
        <p class="mt-2 text-gray-500">Loading warehouses...</p>
      </div>

      <div v-else-if="warehouses.length === 0" class="text-center py-12">
        <p class="text-gray-500">No warehouses found</p>
      </div>

      <div v-else>
        <!-- Map Section -->
        <div class="mb-6">
          <div id="warehouse-map" class="w-full h-96 rounded-lg shadow-lg border border-gray-200"></div>
        </div>

        <!-- Warehouse Cards Grid -->
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <div
          v-for="warehouse in filteredWarehouses"
          :key="warehouse.warehouse_id"
          class="card hover:shadow-lg transition-shadow cursor-pointer"
          @click="$router.push(`/warehouses/${warehouse.warehouse_id}`)"
        >
          <div class="flex items-start justify-between mb-4">
            <h3 class="text-xl font-semibold text-gray-900">{{ warehouse.name }}</h3>
            <span
              class="px-2 py-1 text-xs font-medium rounded-full"
              :class="warehouse.status === 'active' ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-800'"
            >
              {{ warehouse.status }}
            </span>
          </div>
          <p class="text-gray-600 mb-4">{{ warehouse.location }}</p>
          <div class="flex items-center text-sm text-gray-500">
            <svg class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
            </svg>
            <span>{{ getWarehouseAddressSync(warehouse) }}</span>
            <span v-if="warehouse.distance" class="ml-4 font-medium text-primary-600">
              {{ warehouse.distance.toFixed(2) }} km away
            </span>
          </div>
        </div>
        </div>
      </div>
    </div>
  </Layout>
</template>

<script setup>
import { ref, computed, onMounted, watch, nextTick, onUnmounted } from 'vue'
import { warehouseAPI } from '../api/warehouse'
import { grainAPI } from '../api/grain'
import { geolocationAPI } from '../api/geolocation'
import { locationAPI } from '../api/location'
import Layout from '../components/Layout.vue'

const warehouses = ref([])
const grains = ref([])
const searchQuery = ref('')
const selectedGrainType = ref('')
const loading = ref(true)
const loadingLocation = ref(false)
const userLocation = ref(null)
const warehouseAddresses = ref({}) // Cache for addresses
let map = null
let mapMarkers = []

const filteredWarehouses = computed(() => {
  let filtered = warehouses.value

  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase()
    filtered = filtered.filter(
      (w) =>
        w.name.toLowerCase().includes(query) ||
        w.location.toLowerCase().includes(query) ||
        (w.street && w.street.toLowerCase().includes(query)) ||
        (w.city && w.city.toLowerCase().includes(query))
    )
  }

  if (selectedGrainType.value) {
    // This filter can be enhanced based on your backend grain availability data
    // For now, we're just filtering by grain type through the API call
  }

  return filtered
})

// Function to get address from coordinates
const getWarehouseAddress = async (warehouse) => {
  if (!warehouse.x_float || !warehouse.y_float) {
    return warehouse.location || 'Location not available'
  }

  // Check cache first
  const cacheKey = `${warehouse.warehouse_id}`
  if (warehouseAddresses.value[cacheKey]) {
    return warehouseAddresses.value[cacheKey]
  }

  // If location field already has a good address, use it
  if (warehouse.location && warehouse.location.includes(',')) {
    warehouseAddresses.value[cacheKey] = warehouse.location
    return warehouse.location
  }

  // Try to get address from coordinates
  try {
    const response = await locationAPI.getLocationByCoordinates(warehouse.y_float, warehouse.x_float)
    const data = response.data
    let address = warehouse.location

    if (data?.display_name) {
      address = data.display_name
    } else if (data?.address) {
      const addr = data.address
      const parts = [
        addr.road,
        addr.city || addr.town || addr.village,
        addr.state || addr.region,
        addr.country
      ].filter(Boolean)
      address = parts.length > 0 ? parts.join(', ') : warehouse.location
    }

    warehouseAddresses.value[cacheKey] = address
    return address
  } catch (error) {
    console.error('Error getting address:', error)
    return warehouse.location || `${warehouse.x_float}, ${warehouse.y_float}`
  }
}

// Synchronous version for template (uses cached value)
const getWarehouseAddressSync = (warehouse) => {
  const cacheKey = `${warehouse.warehouse_id}`
  if (warehouseAddresses.value[cacheKey]) {
    return warehouseAddresses.value[cacheKey]
  }
  // If location looks like an address, use it
  if (warehouse.location && warehouse.location.includes(',')) {
    return warehouse.location
  }
  // Otherwise return coordinates as fallback
  return warehouse.location || `${warehouse.x_float}, ${warehouse.y_float}`
}

onMounted(async () => {
  try {
    const [warehousesRes, grainsRes] = await Promise.all([
      warehouseAPI.getAll(),
      grainAPI.getAll(),
    ])
    warehouses.value = warehousesRes.data || []
    grains.value = grainsRes.data || []
    
    // Pre-load addresses for all warehouses (with error handling)
    await Promise.allSettled(
      warehouses.value.map(async (w) => {
        try {
          await getWarehouseAddress(w)
        } catch (e) {
          console.warn(`Failed to load address for warehouse ${w.warehouse_id}:`, e)
        }
      })
    )
  } catch (error) {
    console.error('Error loading warehouses:', error)
    // Show user-friendly error message
    if (error.response?.status === 401) {
      alert('Session expired. Please login again.')
    } else if (error.response?.status >= 500) {
      alert('Server error. Please try again later.')
    } else {
      alert(`Failed to load warehouses: ${error.message || 'Unknown error'}`)
    }
  } finally {
    loading.value = false
    // Initialize map after warehouses are loaded
    await nextTick()
    initMap()
  }
})

watch(selectedGrainType, async (newValue) => {
  if (newValue && userLocation.value) {
    loadingLocation.value = true
    try {
      const response = await geolocationAPI.getNearestWarehouses(
        userLocation.value.lat,
        userLocation.value.lng,
        newValue
      )
      warehouses.value = response.data.data.allWarehouses || []
      updateMap()
    } catch (error) {
      console.error('Error getting nearest warehouses:', error)
    } finally {
      loadingLocation.value = false
    }
  }
})

// Watch search query to update map when searching
watch(searchQuery, () => {
  updateMap()
})

// Watch for changes in filtered warehouses to update the map
watch([warehouses, filteredWarehouses], () => {
  updateMap()
}, { deep: true })

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

      try {
        const grainTypeId = selectedGrainType.value || null
        const response = await geolocationAPI.getNearestWarehouses(
          userLocation.value.lat,
          userLocation.value.lng,
          grainTypeId
        )
        warehouses.value = response.data.data.allWarehouses || []
        updateMap()
      } catch (error) {
        console.error('Error getting nearest warehouses:', error)
      } finally {
        loadingLocation.value = false
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
  const mapElement = document.getElementById('warehouse-map')
  if (!mapElement || map) return

  // Calculate center based on warehouses or use default
  let center = [31.0, 36.0] // Default center (roughly middle of common regions)
  
  if (warehouses.value.length > 0) {
    const validWarehouses = warehouses.value.filter(w => w.y_float != null && w.x_float != null)
    if (validWarehouses.length > 0) {
      const avgLat = validWarehouses.reduce((sum, w) => sum + w.y_float, 0) / validWarehouses.length
      const avgLng = validWarehouses.reduce((sum, w) => sum + w.x_float, 0) / validWarehouses.length
      center = [avgLat, avgLng]
    }
  }

  map = L.map('warehouse-map').setView(center, 10)

  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    attribution: '© OpenStreetMap contributors',
    maxZoom: 19,
  }).addTo(map)

  // Add user location marker if available
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

  // Remove existing markers
  mapMarkers.forEach((marker) => map.removeLayer(marker))
  mapMarkers = []

  // Get warehouses to display (use filtered if search is active, otherwise all)
  const warehousesToDisplay = searchQuery.value ? filteredWarehouses.value : warehouses.value
  
  // Add markers for each warehouse
  const validWarehouses = warehousesToDisplay.filter(w => w.y_float != null && w.x_float != null)
  
  validWarehouses.forEach((warehouse) => {
    const popupContent = `
      <div class="p-2">
        <h3 class="font-semibold text-gray-900 mb-1">${warehouse.name}</h3>
        <p class="text-sm text-gray-600 mb-2">${warehouse.location}</p>
        ${warehouse.distance ? `<p class="text-xs text-primary-600 font-medium">Distance: ${warehouse.distance.toFixed(2)} km</p>` : ''}
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
      .on('click', () => {
        // Optional: Handle marker click
      })

    mapMarkers.push(marker)
  })

  // Fit map bounds to show all warehouses
  if (validWarehouses.length > 0) {
    const bounds = L.latLngBounds(
      validWarehouses.map((w) => [w.y_float, w.x_float])
    )
    if (userLocation.value) {
      bounds.extend([userLocation.value.lat, userLocation.value.lng])
    }
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



