<template>
  <Layout>
    <div class="px-4 sm:px-6 lg:px-8">
      <div class="mb-8">
        <h1 class="text-3xl font-bold text-gray-900">My Deliveries</h1>
        <p class="mt-2 text-sm text-gray-600">Track your grain deliveries</p>
      </div>

      <div v-if="loading" class="text-center py-12">
        <div class="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600"></div>
        <p class="mt-2 text-gray-500">Loading deliveries...</p>
      </div>

      <div v-else-if="deliveries.length === 0" class="text-center py-12">
        <p class="text-gray-500">No deliveries found</p>
      </div>

      <div v-else class="space-y-4">
        <div
          v-for="delivery in deliveries"
          :key="delivery.delivery_id"
          class="card"
        >
          <div class="flex justify-between items-start mb-4">
            <div>
              <h3 class="text-lg font-semibold text-gray-900">
                Delivery #{{ delivery.delivery_id }}
              </h3>
              <p class="text-sm text-gray-500 mt-1">
                Receipt Code: <span class="font-mono font-medium">{{ delivery.receipt_code }}</span>
              </p>
            </div>
            <div class="text-right">
              <p class="text-2xl font-bold text-primary-600">{{ formatPrice(delivery.total_price) }} DZD</p>
              <p class="text-xs text-gray-500 mt-1">
                {{ formatDate(delivery.created_at) }}
              </p>
            </div>
          </div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <p class="text-sm text-gray-500">Appointment ID</p>
              <p class="font-medium text-gray-900">#{{ delivery.appointment_id }}</p>
            </div>
            <div>
              <p class="text-sm text-gray-500">Delivery Date</p>
              <p class="font-medium text-gray-900">{{ formatDate(delivery.created_at) }}</p>
            </div>
          </div>

          <div class="mt-4 pt-4 border-t border-gray-200">
            <router-link
              :to="`/appointments`"
              class="text-primary-600 hover:text-primary-700 text-sm font-medium"
            >
              View Appointment Details →
            </router-link>
          </div>
        </div>
      </div>
    </div>
  </Layout>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { deliveryAPI } from '../api/delivery'
import Layout from '../components/Layout.vue'

const deliveries = ref([])
const loading = ref(true)

onMounted(async () => {
  try {
    const response = await deliveryAPI.getMyDeliveries()
    deliveries.value = response.data?.deliveries || []
  } catch (error) {
    console.error('Error loading deliveries:', error)
  } finally {
    loading.value = false
  }
})

const formatDate = (dateString) => {
  return new Date(dateString).toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  })
}

const formatPrice = (price) => {
  if (!price) return '0'
  return new Intl.NumberFormat('ar-DZ', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  }).format(price)
}
</script>



