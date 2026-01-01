<template>
  <div class="min-h-screen flex items-center justify-center bg-gradient-to-br from-primary-50 to-primary-100 py-12 px-4 sm:px-6 lg:px-8">
    <div class="max-w-md w-full space-y-8">
      <div>
        <h1 class="text-4xl font-bold text-center text-primary-600 mb-2">Mahsoul</h1>
        <h2 class="text-center text-3xl font-extrabold text-gray-900">Create your account</h2>
        <p class="mt-2 text-center text-sm text-gray-600">
          Or
          <router-link to="/login" class="font-medium text-primary-600 hover:text-primary-500">
            sign in to existing account
          </router-link>
        </p>
      </div>
      <form class="mt-8 space-y-6" @submit.prevent="handleRegister">
        <div class="rounded-md shadow-sm space-y-4">
          <div>
            <label for="name" class="block text-sm font-medium text-gray-700 mb-1">
              Full Name
            </label>
            <input
              id="name"
              v-model="form.name"
              name="name"
              type="text"
              required
              class="input-field"
              placeholder="John Doe"
            />
          </div>
          <div>
            <label for="email" class="block text-sm font-medium text-gray-700 mb-1">
              Email address
            </label>
            <input
              id="email"
              v-model="form.email"
              name="email"
              type="email"
              autocomplete="email"
              required
              class="input-field"
              placeholder="you@example.com"
            />
          </div>
          <div>
            <label for="password" class="block text-sm font-medium text-gray-700 mb-1">
              Password
            </label>
            <input
              id="password"
              v-model="form.password"
              name="password"
              type="password"
              autocomplete="new-password"
              required
              minlength="8"
              class="input-field"
              placeholder="••••••••"
            />
            <p class="mt-1 text-xs text-gray-500">Must be at least 8 characters</p>
          </div>
          <div>
            <label for="phone" class="block text-sm font-medium text-gray-700 mb-1">
              Phone Number
            </label>
            <input
              id="phone"
              v-model="form.phone"
              name="phone"
              type="tel"
              class="input-field"
              placeholder="+1234567890"
            />
          </div>
          <div>
            <label for="address" class="block text-sm font-medium text-gray-700 mb-1">
              Address
            </label>
            <input
              id="address"
              v-model="form.address"
              name="address"
              type="text"
              class="input-field"
              placeholder="123 Main Street, City"
            />
          </div>
          <div>
            <label for="role" class="block text-sm font-medium text-gray-700 mb-1">
              Role
            </label>
            <select
              id="role"
              v-model="form.role"
              name="role"
              required
              class="input-field"
            >
              <option value="farmer">Farmer</option>
              <option value="warehouse_admin">Warehouse Admin</option>
            </select>
          </div>
        </div>

        <div v-if="error" class="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg">
          {{ error }}
        </div>

        <div>
          <button
            type="submit"
            :disabled="loading"
            class="btn-primary w-full py-3 text-base"
          >
            <span v-if="loading">Creating account...</span>
            <span v-else>Create account</span>
          </button>
        </div>
      </form>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'

const router = useRouter()
const authStore = useAuthStore()

const form = ref({
  name: '',
  email: '',
  password: '',
  phone: '',
  address: '',
  role: 'farmer',
})

const loading = ref(false)
const error = ref(null)

const handleRegister = async () => {
  loading.value = true
  error.value = null

  try {
    await authStore.register(form.value)
    router.push('/dashboard')
  } catch (err) {
    error.value = authStore.error || 'Registration failed'
  } finally {
    loading.value = false
  }
}
</script>



