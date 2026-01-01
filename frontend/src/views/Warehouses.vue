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

      <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
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
            <span>{{ warehouse.x_float }}, {{ warehouse.y_float }}</span>
            <span v-if="warehouse.distance" class="ml-4 font-medium text-primary-600">
              {{ warehouse.distance.toFixed(2) }} km away
            </span>
          </div>
        </div>
      </div>
    </div>
  </Layout>
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { warehouseAPI } from '../api/warehouse'
import { grainAPI } from '../api/grain'
import { geolocationAPI } from '../api/geolocation'
import Layout from '../components/Layout.vue'

const warehouses = ref([])
const grains = ref([])
const searchQuery = ref('')
const selectedGrainType = ref('')
const loading = ref(true)
const loadingLocation = ref(false)
const userLocation = ref(null)

const filteredWarehouses = computed(() => {
  let filtered = warehouses.value

  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase()
    filtered = filtered.filter(
      (w) =>
        w.name.toLowerCase().includes(query) ||
        w.location.toLowerCase().includes(query)
    )
  }

  return filtered
})

onMounted(async () => {
  try {
    const [warehousesRes, grainsRes] = await Promise.all([
      warehouseAPI.getAll(),
      grainAPI.getAll(),
    ])
    warehouses.value = warehousesRes.data || []
    grains.value = grainsRes.data || []
  } catch (error) {
    console.error('Error loading warehouses:', error)
  } finally {
    loading.value = false
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
    } catch (error) {
      console.error('Error getting nearest warehouses:', error)
    } finally {
      loadingLocation.value = false
    }
  }
})

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
</script>



