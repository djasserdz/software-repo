<template>
  <Layout>
    <div>
      <div class="mb-8 flex justify-between items-center">
        <div>
          <h1 class="text-3xl font-bold text-gray-900">Storage Zones Management</h1>
          <p class="mt-2 text-sm text-gray-600">Manage storage zones for your warehouses</p>
        </div>
        <button @click="showCreateModal = true" class="btn-primary">
          Add Storage Zone
        </button>
      </div>

      <div class="mb-6">
        <select v-model="selectedWarehouse" @change="loadZones" class="input-field max-w-md">
          <option value="">All Warehouses</option>
          <option v-for="warehouse in warehouses" :key="warehouse.warehouse_id" :value="warehouse.warehouse_id">
            {{ warehouse.name }}
          </option>
        </select>
      </div>

      <div v-if="loading" class="text-center py-12">
        <div class="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600"></div>
        <p class="mt-2 text-gray-500">Loading zones...</p>
      </div>

      <div v-else-if="zones.length === 0" class="text-center py-12">
        <p class="text-gray-500 mb-4">No storage zones found</p>
        <button @click="loadZones" class="btn-secondary">Retry</button>
      </div>

      <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <div
          v-for="zone in zones"
          :key="zone.zone_id"
          class="card"
        >
          <div class="flex items-start justify-between mb-4">
            <h3 class="text-xl font-semibold text-gray-900">{{ zone.name }}</h3>
            <span
              class="px-2 py-1 text-xs font-medium rounded-full"
              :class="zone.status === 'active' ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-800'"
            >
              {{ zone.status }}
            </span>
          </div>
          <div class="space-y-2 text-sm text-gray-600">
            <p>Warehouse ID: {{ zone.warehouse_id }}</p>
            <p>Grain Type ID: {{ zone.grain_type_id }}</p>
            <p>Total Capacity: {{ zone.total_capacity }}</p>
            <p>Available: {{ zone.available_capacity }}</p>
            <div class="mt-2">
              <div class="w-full bg-gray-200 rounded-full h-2">
                <div
                  class="bg-primary-600 h-2 rounded-full"
                  :style="{ width: `${(zone.available_capacity / zone.total_capacity) * 100}%` }"
                ></div>
              </div>
            </div>
          </div>
          <div class="mt-4 flex gap-2">
            <button
              @click="editZone(zone)"
              class="btn-secondary text-sm flex-1"
            >
              Edit
            </button>
          </div>
        </div>
      </div>

      <!-- Create/Edit Modal -->
      <div v-if="showCreateModal || editingZone" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
        <div class="bg-white rounded-lg p-6 max-w-md w-full mx-4">
          <h2 class="text-2xl font-bold text-gray-900 mb-4">
            {{ editingZone ? 'Edit Storage Zone' : 'Create Storage Zone' }}
          </h2>
          <form @submit.prevent="saveZone">
            <div class="space-y-4">
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Warehouse</label>
                <select v-model.number="zoneForm.warehouse_id" required class="input-field">
                  <option value="">Select a warehouse</option>
                  <option 
                    v-for="warehouse in warehouses" 
                    :key="warehouse.warehouse_id" 
                    :value="warehouse.warehouse_id"
                  >
                    {{ warehouse.name }}
                  </option>
                </select>
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Name</label>
                <input v-model="zoneForm.name" type="text" required class="input-field" />
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Grain Type</label>
                <select v-model.number="zoneForm.grain_type_id" required class="input-field">
                  <option value="">Select a grain type</option>
                  <option 
                    v-for="grain in grains" 
                    :key="grain.grain_id" 
                    :value="grain.grain_id"
                  >
                    {{ grain.name }}
                  </option>
                </select>
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Total Capacity (tons)</label>
                <input v-model.number="zoneForm.total_capacity" type="number" required class="input-field" @input="updateAvailableCapacity" />
                <p class="text-xs text-gray-500 mt-1">Available capacity will be set automatically to match total capacity</p>
              </div>
              <div v-if="editingZone">
                <label class="block text-sm font-medium text-gray-700 mb-1">Available Capacity (tons)</label>
                <input v-model.number="zoneForm.available_capacity" type="number" required class="input-field" />
                <p class="text-xs text-gray-500 mt-1">You can edit available capacity when editing an existing zone</p>
              </div>
              <div v-else class="bg-gray-50 rounded-lg p-3">
                <label class="block text-sm font-medium text-gray-700 mb-1">Available Capacity (tons)</label>
                <p class="text-sm text-gray-600">{{ zoneForm.total_capacity }} tons</p>
                <p class="text-xs text-gray-500 mt-1">Automatically set to total capacity for new zones</p>
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Status</label>
                <select v-model="zoneForm.status" required class="input-field">
                  <option value="active">Active</option>
                  <option value="not_active">Not Active</option>
                </select>
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
import { ref, onMounted } from 'vue'
import { zoneAPI } from '../../api/zone'
import { warehouseAPI } from '../../api/warehouse'
import { grainAPI } from '../../api/grain'
import Layout from '../../components/Layout.vue'

const zones = ref([])
const warehouses = ref([])
const grains = ref([])
const loading = ref(true)
const selectedWarehouse = ref('')
const showCreateModal = ref(false)
const editingZone = ref(null)
const saving = ref(false)

const zoneForm = ref({
  warehouse_id: null,
  name: '',
  grain_type_id: null,
  total_capacity: 0,
  available_capacity: 0,
  status: 'active',
})

const loadWarehouses = async () => {
  try {
    const response = await warehouseAPI.getAll()
    warehouses.value = response.data || []
  } catch (error) {
    console.error('Error loading warehouses:', error)
    warehouses.value = []
  }
}

const loadGrains = async () => {
  try {
    const response = await grainAPI.getAll()
    grains.value = response.data || []
  } catch (error) {
    console.error('Error loading grains:', error)
    grains.value = []
  }
}

const loadZones = async () => {
  loading.value = true
  try {
    const params = selectedWarehouse.value ? { warehouse_id: parseInt(selectedWarehouse.value) } : {}
    const response = await zoneAPI.getAll(params)
    zones.value = response.data || []
  } catch (error) {
    console.error('Error loading zones:', error)
    zones.value = []
  } finally {
    loading.value = false
  }
}

const editZone = (zone) => {
  editingZone.value = zone
  zoneForm.value = {
    warehouse_id: zone.warehouse_id,
    name: zone.name,
    grain_type_id: zone.grain_type_id,
    total_capacity: zone.total_capacity,
    available_capacity: zone.available_capacity,
    status: zone.status,
  }
}

const updateAvailableCapacity = () => {
  // When creating a new zone, set available capacity to total capacity
  if (!editingZone.value) {
    zoneForm.value.available_capacity = zoneForm.value.total_capacity
  }
}

const closeModal = () => {
  showCreateModal.value = false
  editingZone.value = null
  zoneForm.value = {
    warehouse_id: null,
    name: '',
    grain_type_id: null,
    total_capacity: 0,
    available_capacity: 0,
    status: 'active',
  }
}

const saveZone = async () => {
  saving.value = true
  try {
    if (editingZone.value) {
      await zoneAPI.update(editingZone.value.zone_id, zoneForm.value)
    } else {
      // When creating, set available_capacity to total_capacity
      await zoneAPI.create(zoneForm.value.warehouse_id, {
        name: zoneForm.value.name,
        grain_type_id: zoneForm.value.grain_type_id,
        total_capacity: zoneForm.value.total_capacity,
        available_capacity: zoneForm.value.total_capacity, // Auto-set to total capacity
        status: zoneForm.value.status,
      })
    }
    await loadZones()
    closeModal()
  } catch (error) {
    console.error('Error saving zone:', error)
    alert('Failed to save storage zone')
  } finally {
    saving.value = false
  }
}

onMounted(async () => {
  await loadWarehouses()
  await loadGrains()
  await loadZones()
})
</script>

