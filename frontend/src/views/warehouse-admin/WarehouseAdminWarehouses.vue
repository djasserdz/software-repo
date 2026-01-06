<template>
  <Layout>
    <div>
      <div class="mb-8">
        <h1 class="text-3xl font-bold text-gray-900">My Warehouses</h1>
        <p class="mt-2 text-sm text-gray-600">View and manage your assigned warehouses</p>
      </div>

      <div v-if="loading" class="text-center py-12">
        <div class="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600"></div>
        <p class="mt-2 text-gray-500">Loading warehouses...</p>
      </div>

      <div v-else-if="warehouses.length === 0" class="text-center py-12">
        <p class="text-gray-500 mb-4">No warehouses assigned to you</p>
        <button @click="loadWarehouses" class="btn-secondary">Retry</button>
      </div>

      <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <div
          v-for="warehouse in warehouses"
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
          <p class="text-gray-600 mb-4">{{ warehouse.location || 'Address not available' }}</p>
        </div>
      </div>
    </div>
  </Layout>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { warehouseAPI } from '../../api/warehouse'
import Layout from '../../components/Layout.vue'

const warehouses = ref([])
const loading = ref(true)

const loadWarehouses = async () => {
  loading.value = true
  try {
    const response = await warehouseAPI.getAll()
    warehouses.value = response.data || []
  } catch (error) {
    console.error('Error loading warehouses:', error)
    warehouses.value = []
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  loadWarehouses()
})
</script>

