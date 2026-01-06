<template>
  <Layout>
    <div class="px-4 sm:px-6 lg:px-8">
      <div class="mb-8 flex justify-between items-center">
        <div>
          <h1 class="text-3xl font-bold text-gray-900">Grain Type Management</h1>
          <p class="mt-2 text-sm text-gray-600">Manage grain types and their prices</p>
        </div>
        <button @click="showCreateModal = true" class="btn-primary">
          Add Grain Type
        </button>
      </div>

      <div v-if="loading" class="text-center py-12">
        <div class="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600"></div>
        <p class="mt-2 text-gray-500">Loading grain types...</p>
      </div>

      <div v-else-if="grains.length === 0" class="text-center py-12">
        <p class="text-gray-500">No grain types found</p>
      </div>

      <div v-else class="card overflow-hidden">
        <div class="overflow-x-auto">
          <table class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50">
              <tr>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Name</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Price</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Created</th>
                <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
              </tr>
            </thead>
            <tbody class="bg-white divide-y divide-gray-200">
              <tr v-for="grain in grains" :key="grain.grain_id">
                <td class="px-6 py-4 whitespace-nowrap">
                  <div class="text-sm font-medium text-gray-900">{{ grain.name }}</div>
                </td>
                <td class="px-6 py-4 whitespace-nowrap">
                  <div class="text-sm text-gray-900">{{ formatPrice(parseFloat(grain.price) / 1000) }} DZD/kg</div>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                  {{ formatDate(grain.created_at) }}
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                  <button
                    @click="editGrain(grain)"
                    class="text-primary-600 hover:text-primary-900 mr-4"
                  >
                    Edit
                  </button>
                  <button
                    @click="deleteGrain(grain.grain_id)"
                    class="text-red-600 hover:text-red-900"
                    :disabled="deleting === grain.grain_id"
                  >
                    {{ deleting === grain.grain_id ? 'Deleting...' : 'Delete' }}
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <!-- Create/Edit Modal -->
      <div v-if="showCreateModal || editingGrain" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
        <div class="bg-white rounded-lg p-6 max-w-md w-full mx-4">
          <h2 class="text-2xl font-bold text-gray-900 mb-4">
            {{ editingGrain ? 'Edit Grain Type' : 'Create Grain Type' }}
          </h2>
          <form @submit.prevent="saveGrain">
            <div class="space-y-4">
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Name</label>
                <input v-model="grainForm.name" type="text" required class="input-field" />
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Price per kg (DZD)</label>
                <input v-model.number="grainForm.price" type="number" step="0.01" min="0" required class="input-field" placeholder="Enter price per kilogram" />
                <p class="text-xs text-gray-500 mt-1">Note: Price is stored per ton, but displayed per kg</p>
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
import { grainAPI } from '../../api/grain'
import Layout from '../../components/Layout.vue'

const grains = ref([])
const loading = ref(true)
const showCreateModal = ref(false)
const editingGrain = ref(null)
const saving = ref(false)
const deleting = ref(null)

const grainForm = ref({
  name: '',
  price: 0,
})

const loadGrains = async () => {
  loading.value = true
  try {
    const response = await grainAPI.getAll()
    grains.value = response.data || []
  } catch (error) {
    console.error('Error loading grains:', error)
  } finally {
    loading.value = false
  }
}

const formatPrice = (price) => {
  if (!price) return '0'
  return new Intl.NumberFormat('ar-DZ', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  }).format(price)
}

const editGrain = (grain) => {
  editingGrain.value = grain
  grainForm.value = {
    name: grain.name,
    price: parseFloat(grain.price) / 1000, // Convert from per ton to per kg for editing
  }
}

const closeModal = () => {
  showCreateModal.value = false
  editingGrain.value = null
  grainForm.value = {
    name: '',
    price: 0,
  }
}

const saveGrain = async () => {
  saving.value = true
  try {
    // Convert price from per kg to per ton for backend
    const grainData = {
      name: grainForm.value.name,
      price: grainForm.value.price * 1000 // Convert from per kg to per ton
    }
    
    if (editingGrain.value) {
      await grainAPI.update(editingGrain.value.grain_id, grainData)
    } else {
      await grainAPI.create(grainData)
    }
    await loadGrains()
    closeModal()
  } catch (error) {
    console.error('Error saving grain:', error)
    alert('Failed to save grain type')
  } finally {
    saving.value = false
  }
}

const deleteGrain = async (grainId) => {
  if (!confirm('Are you sure you want to delete this grain type?')) return
  
  deleting.value = grainId
  try {
    await grainAPI.delete(grainId)
    await loadGrains()
  } catch (error) {
    console.error('Error deleting grain:', error)
    alert('Failed to delete grain type')
  } finally {
    deleting.value = null
  }
}

const formatDate = (dateString) => {
  return new Date(dateString).toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  })
}

onMounted(() => {
  loadGrains()
})
</script>

