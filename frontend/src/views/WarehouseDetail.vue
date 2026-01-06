<template>
  <Layout>
    <div class="px-4 sm:px-6 lg:px-8">
      <div v-if="loading" class="text-center py-12">
        <div class="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600"></div>
        <p class="mt-2 text-gray-500">Loading warehouse...</p>
      </div>

      <div v-else-if="warehouse">
        <div class="mb-6">
          <button
            @click="$router.back()"
            class="text-primary-600 hover:text-primary-700 mb-4 flex items-center"
          >
            <svg class="h-5 w-5 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
            </svg>
            Back
          </button>
          <h1 class="text-3xl font-bold text-gray-900">{{ warehouse.name }}</h1>
          <p class="mt-2 text-gray-600">{{ warehouse.location }}</p>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <div class="lg:col-span-2">
            <div class="card mb-6">
              <h2 class="text-xl font-semibold text-gray-900 mb-4">Storage Zones</h2>
              <div v-if="zonesLoading" class="text-center py-8 text-gray-500">Loading zones...</div>
              <div v-else-if="zones.length === 0" class="text-center py-8 text-gray-500">
                No storage zones available
              </div>
              <div v-else class="space-y-4">
                <div
                  v-for="zone in zones"
                  :key="zone.zone_id"
                  class="p-4 border border-gray-200 rounded-lg hover:border-primary-300 transition-colors"
                >
                  <div class="flex justify-between items-start mb-2">
                    <div>
                      <h3 class="font-semibold text-gray-900">{{ zone.name }}</h3>
                      <p class="text-sm text-gray-500 mt-1">
                        Grain Type: {{ getGrainName(zone.grain_type_id) }}
                      </p>
                    </div>
                    <span
                      class="px-2 py-1 text-xs font-medium rounded-full"
                      :class="zone.status === 'active' ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-800'"
                    >
                      {{ zone.status }}
                    </span>
                  </div>
                  <div class="mt-3">
                    <div class="flex justify-between text-sm text-gray-600 mb-1">
                      <span>Capacity</span>
                      <span>{{ formatNumber(zone.available_capacity * 1000) }} / {{ formatNumber(zone.total_capacity * 1000) }} kg</span>
                    </div>
                    <div class="w-full bg-gray-200 rounded-full h-2">
                      <div
                        class="bg-primary-600 h-2 rounded-full"
                        :style="{ width: `${(zone.available_capacity / zone.total_capacity) * 100}%` }"
                      ></div>
                    </div>
                  </div>
                  <button
                    v-if="isFarmer && zone.status === 'active'"
                    @click="bookAppointment(zone)"
                    class="mt-4 btn-primary w-full"
                  >
                    Book Appointment
                  </button>
                </div>
              </div>
            </div>
          </div>

          <div>
            <div class="card">
              <h2 class="text-xl font-semibold text-gray-900 mb-4">Warehouse Details</h2>
              <dl class="space-y-3">
                <div>
                  <dt class="text-sm font-medium text-gray-500">Status</dt>
                  <dd class="mt-1">
                    <span
                      class="px-2 py-1 text-xs font-medium rounded-full"
                      :class="warehouse.status === 'active' ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-800'"
                    >
                      {{ warehouse.status }}
                    </span>
                  </dd>
                </div>
                <div>
                  <dt class="text-sm font-medium text-gray-500">Address</dt>
                  <dd class="mt-1 text-sm text-gray-900">{{ warehouseAddress || warehouse.location || 'Loading address...' }}</dd>
                </div>
              </dl>
            </div>
          </div>
        </div>
      </div>
    </div>
  </Layout>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'
import { warehouseAPI } from '../api/warehouse'
import { zoneAPI } from '../api/zone'
import { grainAPI } from '../api/grain'
import { locationAPI } from '../api/location'
import Layout from '../components/Layout.vue'

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()

const warehouse = ref(null)
const zones = ref([])
const grains = ref([])
const loading = ref(true)
const zonesLoading = ref(true)
const warehouseAddress = ref('')

const isFarmer = computed(() => authStore.isFarmer)

onMounted(async () => {
  const warehouseId = parseInt(route.params.id)
  
  try {
    const [warehouseRes, zonesRes, grainsRes] = await Promise.all([
      warehouseAPI.getById(warehouseId),
      zoneAPI.getAll({ warehouse_id: warehouseId }),
      grainAPI.getAll(),
    ])
    
    warehouse.value = warehouseRes.data
    zones.value = zonesRes.data || []
    grains.value = grainsRes.data || []
    
    // Get address from coordinates
    if (warehouse.value && warehouse.value.x_float && warehouse.value.y_float) {
      try {
        const response = await locationAPI.getLocationByCoordinates(
          warehouse.value.y_float,
          warehouse.value.x_float
        )
        const data = response.data
        if (data?.display_name) {
          warehouseAddress.value = data.display_name
        } else if (data?.address) {
          const addr = data.address
          const parts = [
            addr.road,
            addr.city || addr.town || addr.village,
            addr.state || addr.region,
            addr.country
          ].filter(Boolean)
          warehouseAddress.value = parts.length > 0 ? parts.join(', ') : warehouse.value.location
        } else {
          warehouseAddress.value = warehouse.value.location
        }
      } catch (error) {
        console.error('Error getting address:', error)
        warehouseAddress.value = warehouse.value.location
      }
    } else {
      warehouseAddress.value = warehouse.value?.location || ''
    }
  } catch (error) {
    console.error('Error loading warehouse:', error)
  } finally {
    loading.value = false
    zonesLoading.value = false
  }
})

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

const bookAppointment = (zone) => {
  router.push({
    name: 'BookAppointment',
    query: { warehouseZoneId: zone.zone_id, grainTypeId: zone.grain_type_id },
  })
}
</script>



