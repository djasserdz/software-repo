<template>
  <Layout>
    <div class="px-4 sm:px-6 lg:px-8">
      <div class="mb-8 flex justify-between items-center">
        <div>
          <h1 class="text-3xl font-bold text-gray-900">Warehouse Management</h1>
          <p class="mt-2 text-sm text-gray-600">Manage all warehouses in the system</p>
        </div>
        <button @click="openCreateModal" class="btn-primary">
          Add Warehouse
        </button>
      </div>

      <div v-if="loading" class="text-center py-12">
        <div class="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600"></div>
        <p class="mt-2 text-gray-500">Loading warehouses...</p>
      </div>

      <div v-else-if="warehouses.length === 0" class="text-center py-12">
        <p class="text-gray-500">No warehouses found</p>
      </div>

      <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <div
          v-for="warehouse in warehouses"
          :key="warehouse.warehouse_id"
          class="card"
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
          <div class="flex items-center text-sm text-gray-500 mb-4">
            <svg class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
            </svg>
            <span>{{ warehouse.location || 'Address not available' }}</span>
          </div>
          <div class="flex gap-2">
            <button
              @click="editWarehouse(warehouse)"
              class="btn-secondary text-sm flex-1"
            >
              Edit
            </button>
            <router-link
              :to="`/warehouses/${warehouse.warehouse_id}`"
              class="btn-secondary text-sm flex-1 text-center"
            >
              View Details
            </router-link>
          </div>
        </div>
      </div>

      <!-- Create/Edit Modal -->
      <div v-if="showCreateModal || editingWarehouse" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
        <div class="bg-white rounded-lg p-6 max-w-4xl w-full max-h-[90vh] overflow-y-auto">
          <h2 class="text-2xl font-bold text-gray-900 mb-4">
            {{ editingWarehouse ? 'Edit Warehouse' : 'Create Warehouse' }}
          </h2>
          <form @submit.prevent="saveWarehouse">
            <div class="space-y-4">
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Name</label>
                <input v-model="warehouseForm.name" type="text" required class="input-field" />
              </div>
              
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Select Location on Map</label>
                <p class="text-xs text-gray-500 mb-2">Click on the map to set the warehouse location. The address will be automatically filled.</p>
                <div id="warehouse-location-map" class="w-full h-64 rounded-lg border border-gray-300"></div>
                <div v-if="warehouseForm.x_float !== null && warehouseForm.y_float !== null" class="mt-2 space-y-1">
                  <div class="text-sm text-gray-600">
                    <span class="font-medium">Coordinates:</span> 
                    Longitude (x): {{ warehouseForm.x_float.toFixed(6) }}, 
                    Latitude (y): {{ warehouseForm.y_float.toFixed(6) }}
                  </div>
                  <div v-if="warehouseForm.location" class="text-sm text-gray-900">
                    <span class="font-medium">Address:</span> {{ warehouseForm.location }}
                  </div>
                  <div v-if="loadingAddress" class="text-xs text-gray-500">
                    Loading address...
                  </div>
                </div>
              </div>

              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-1">Manager</label>
                  <select v-model.number="warehouseForm.manager_id" required class="input-field">
                    <option value="">Select a warehouse admin</option>
                    <option 
                      v-for="admin in warehouseAdmins" 
                      :key="admin.user_id" 
                      :value="admin.user_id"
                    >
                      {{ admin.name }} ({{ admin.email }})
                    </option>
                  </select>
                  <p v-if="loadingAdmins" class="text-xs text-gray-500 mt-1">Loading warehouse admins...</p>
                  <p v-if="!loadingAdmins && warehouseAdmins.length === 0" class="text-xs text-red-500 mt-1">
                    No warehouse admins found. Please create warehouse admin users first.
                  </p>
                </div>
                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-1">Status</label>
                  <select v-model="warehouseForm.status" required class="input-field">
                    <option value="active">Active</option>
                    <option value="not_active">Not Active</option>
                  </select>
                </div>
              </div>
            </div>
            <div class="mt-6 flex gap-3">
              <button type="submit" class="btn-primary flex-1" :disabled="saving">
                {{ saving ? 'Saving...' : 'Save' }}
              </button>
              <button type="button" @click="closeModal" class="btn-secondary flex-1">
                Cancel
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  </Layout>
</template>

<script setup>
import { ref, onMounted, nextTick, onUnmounted } from 'vue'
import { warehouseAPI } from '../../api/warehouse'
import { userAPI } from '../../api/user'
import { geolocationAPI } from '../../api/geolocation'
import Layout from '../../components/Layout.vue'

const warehouses = ref([])
const loading = ref(true)
const showCreateModal = ref(false)
const editingWarehouse = ref(null)
const saving = ref(false)
const warehouseAdmins = ref([])
const loadingAdmins = ref(false)
const loadingAddress = ref(false)

let locationMap = null
let locationMarker = null

const warehouseForm = ref({
  name: '',
  location: '',
  x_float: null,
  y_float: null,
  status: 'active',
  manager_id: null,
})

const loadWarehouses = async () => {
  loading.value = true
  try {
    const response = await warehouseAPI.getAll()
    warehouses.value = response.data || []
  } catch (error) {
    console.error('Error loading warehouses:', error)
  } finally {
    loading.value = false
  }
}

const loadWarehouseAdmins = async () => {
  loadingAdmins.value = true
  try {
    const response = await userAPI.getAll()
    const allUsers = response.data || []
    warehouseAdmins.value = allUsers.filter(user => user.role === 'warehouse_admin')
  } catch (error) {
    console.error('Error loading warehouse admins:', error)
    warehouseAdmins.value = []
  } finally {
    loadingAdmins.value = false
  }
}

const openCreateModal = () => {
  showCreateModal.value = true
  warehouseForm.value = {
    name: '',
    location: '',
    x_float: null,
    y_float: null,
    status: 'active',
    manager_id: null,
  }
  nextTick(() => {
    initLocationMap()
    loadWarehouseAdmins()
  })
}

const editWarehouse = (warehouse) => {
  editingWarehouse.value = warehouse
  warehouseForm.value = {
    name: warehouse.name,
    location: warehouse.location,
    x_float: warehouse.x_float,
    y_float: warehouse.y_float,
    status: warehouse.status,
    manager_id: warehouse.manager_id,
  }
  nextTick(() => {
    initLocationMap()
    loadWarehouseAdmins()
  })
}

const closeModal = () => {
  showCreateModal.value = false
  editingWarehouse.value = null
  warehouseForm.value = {
    name: '',
    location: '',
    x_float: null,
    y_float: null,
    status: 'active',
    manager_id: null,
  }
  destroyLocationMap()
}

const initLocationMap = () => {
  if (!window.L) {
    setTimeout(initLocationMap, 100)
    return
  }

  const L = window.L
  const mapElement = document.getElementById('warehouse-location-map')
  if (!mapElement || locationMap) return

  // Initialize map with default center or existing coordinates
  const center = warehouseForm.value.y_float && warehouseForm.value.x_float
    ? [warehouseForm.value.y_float, warehouseForm.value.x_float]
    : [31.0, 36.0] // Default center

  locationMap = L.map('warehouse-location-map').setView(center, 10)

  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    attribution: '© OpenStreetMap contributors',
    maxZoom: 19,
  }).addTo(locationMap)

  // Add existing marker if editing
  if (warehouseForm.value.y_float && warehouseForm.value.x_float) {
    locationMarker = L.marker([warehouseForm.value.y_float, warehouseForm.value.x_float])
      .addTo(locationMap)
      .bindPopup('Warehouse Location')
  }

  // Handle map click to set location
  locationMap.on('click', async (e) => {
    const lat = e.latlng.lat
    const lng = e.latlng.lng
    
    warehouseForm.value.y_float = lat
    warehouseForm.value.x_float = lng

    // Update or create marker
    if (locationMarker) {
      locationMarker.setLatLng([lat, lng])
    } else {
      locationMarker = L.marker([lat, lng])
        .addTo(locationMap)
        .bindPopup('Warehouse Location')
    }
    locationMarker.openPopup()

    // Get address from coordinates using reverse geocoding
    loadingAddress.value = true
    try {
      const response = await geolocationAPI.reverseGeocode(lat, lng)
      const data = response.data
      if (data?.display_name) {
        warehouseForm.value.location = data.display_name
      } else if (data?.address) {
        // Format address nicely from address object
        const addr = data.address
        const parts = [
          addr.road,
          addr.city || addr.town || addr.village,
          addr.state || addr.region,
          addr.country
        ].filter(Boolean)
        warehouseForm.value.location = parts.length > 0 
          ? parts.join(', ')
          : `${lat.toFixed(6)}, ${lng.toFixed(6)}`
      } else {
        warehouseForm.value.location = `${lat.toFixed(6)}, ${lng.toFixed(6)}`
      }
    } catch (error) {
      console.error('Error getting address:', error)
      warehouseForm.value.location = `${lat.toFixed(6)}, ${lng.toFixed(6)}`
    } finally {
      loadingAddress.value = false
    }
  })
}

const destroyLocationMap = () => {
  if (locationMap) {
    locationMap.remove()
    locationMap = null
    locationMarker = null
  }
}


const saveWarehouse = async () => {
  saving.value = true
  try {
    if (editingWarehouse.value) {
      await warehouseAPI.update(editingWarehouse.value.warehouse_id, warehouseForm.value)
    } else {
      await warehouseAPI.create(warehouseForm.value)
    }
    await loadWarehouses()
    closeModal()
  } catch (error) {
    console.error('Error saving warehouse:', error)
    alert('Failed to save warehouse')
  } finally {
    saving.value = false
  }
}

onMounted(() => {
  loadWarehouses()
  loadWarehouseAdmins()
})

onUnmounted(() => {
  destroyLocationMap()
})
</script>

