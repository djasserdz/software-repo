<template>
  <Layout>
    <div class="px-4 sm:px-6 lg:px-8 max-w-4xl mx-auto">
      <div class="mb-8">
        <h1 class="text-3xl font-bold text-gray-900">Profile Settings</h1>
        <p class="mt-2 text-sm text-gray-600">Manage your account information</p>
      </div>

      <div class="space-y-6">
        <!-- Profile Information -->
        <div class="card">
          <h2 class="text-xl font-semibold text-gray-900 mb-4">Profile Information</h2>
          <form @submit.prevent="handleUpdateProfile" class="space-y-4">
            <div>
              <label for="name" class="block text-sm font-medium text-gray-700 mb-1">
                Full Name
              </label>
              <input
                id="name"
                v-model="profileForm.name"
                type="text"
                class="input-field"
                required
              />
            </div>
            <div>
              <label for="email" class="block text-sm font-medium text-gray-700 mb-1">
                Email
              </label>
              <input
                id="email"
                v-model="profileForm.email"
                type="email"
                class="input-field"
                required
              />
            </div>
            <div>
              <label for="phone" class="block text-sm font-medium text-gray-700 mb-1">
                Phone
              </label>
              <input
                id="phone"
                v-model="profileForm.phone"
                type="tel"
                class="input-field"
              />
            </div>
            <div>
              <label for="address" class="block text-sm font-medium text-gray-700 mb-1">
                Address
              </label>
              <input
                id="address"
                v-model="profileForm.address"
                type="text"
                class="input-field"
              />
            </div>
            <div v-if="profileError" class="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg">
              {{ profileError }}
            </div>
            <div v-if="profileSuccess" class="bg-green-50 border border-green-200 text-green-700 px-4 py-3 rounded-lg">
              {{ profileSuccess }}
            </div>
            <button type="submit" :disabled="profileLoading" class="btn-primary">
              <span v-if="profileLoading">Updating...</span>
              <span v-else>Update Profile</span>
            </button>
          </form>
        </div>

        <!-- Change Password -->
        <div class="card">
          <h2 class="text-xl font-semibold text-gray-900 mb-4">Change Password</h2>
          <form @submit.prevent="handleChangePassword" class="space-y-4">
            <div>
              <label for="currentPassword" class="block text-sm font-medium text-gray-700 mb-1">
                Current Password
              </label>
              <input
                id="currentPassword"
                v-model="passwordForm.currentPassword"
                type="password"
                class="input-field"
                required
              />
            </div>
            <div>
              <label for="newPassword" class="block text-sm font-medium text-gray-700 mb-1">
                New Password
              </label>
              <input
                id="newPassword"
                v-model="passwordForm.newPassword"
                type="password"
                class="input-field"
                required
                minlength="8"
              />
              <p class="mt-1 text-xs text-gray-500">Must be at least 8 characters</p>
            </div>
            <div v-if="passwordError" class="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg">
              {{ passwordError }}
            </div>
            <div v-if="passwordSuccess" class="bg-green-50 border border-green-200 text-green-700 px-4 py-3 rounded-lg">
              {{ passwordSuccess }}
            </div>
            <button type="submit" :disabled="passwordLoading" class="btn-primary">
              <span v-if="passwordLoading">Changing...</span>
              <span v-else>Change Password</span>
            </button>
          </form>
        </div>

        <!-- Account Information -->
        <div class="card">
          <h2 class="text-xl font-semibold text-gray-900 mb-4">Account Information</h2>
          <dl class="space-y-3">
            <div>
              <dt class="text-sm font-medium text-gray-500">Role</dt>
              <dd class="mt-1 text-sm text-gray-900 capitalize">{{ user?.role }}</dd>
            </div>
            <div>
              <dt class="text-sm font-medium text-gray-500">Account Status</dt>
              <dd class="mt-1">
                <span
                  class="px-2 py-1 text-xs font-medium rounded-full"
                  :class="user?.account_status ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'"
                >
                  {{ user?.account_status ? 'Active' : 'Inactive' }}
                </span>
              </dd>
            </div>
            <div>
              <dt class="text-sm font-medium text-gray-500">Member Since</dt>
              <dd class="mt-1 text-sm text-gray-900">{{ formatDate(user?.created_at) }}</dd>
            </div>
          </dl>
        </div>
      </div>
    </div>
  </Layout>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useAuthStore } from '../stores/auth'
import Layout from '../components/Layout.vue'

const authStore = useAuthStore()
const user = computed(() => authStore.user)

const profileForm = ref({
  name: '',
  email: '',
  phone: '',
  address: '',
})

const passwordForm = ref({
  currentPassword: '',
  newPassword: '',
})

const profileLoading = ref(false)
const passwordLoading = ref(false)
const profileError = ref(null)
const profileSuccess = ref(null)
const passwordError = ref(null)
const passwordSuccess = ref(null)

onMounted(() => {
  if (user.value) {
    profileForm.value = {
      name: user.value.name || '',
      email: user.value.email || '',
      phone: user.value.phone || '',
      address: user.value.address || '',
    }
  }
})

const handleUpdateProfile = async () => {
  profileLoading.value = true
  profileError.value = null
  profileSuccess.value = null

  try {
    await authStore.updateProfile(profileForm.value)
    profileSuccess.value = 'Profile updated successfully'
    setTimeout(() => {
      profileSuccess.value = null
    }, 3000)
  } catch (error) {
    profileError.value = authStore.error || 'Failed to update profile'
  } finally {
    profileLoading.value = false
  }
}

const handleChangePassword = async () => {
  passwordLoading.value = true
  passwordError.value = null
  passwordSuccess.value = null

  try {
    await authStore.changePassword(passwordForm.value)
    passwordSuccess.value = 'Password changed successfully'
    passwordForm.value = {
      currentPassword: '',
      newPassword: '',
    }
    setTimeout(() => {
      passwordSuccess.value = null
    }, 3000)
  } catch (error) {
    passwordError.value = authStore.error || 'Failed to change password'
  } finally {
    passwordLoading.value = false
  }
}

const formatDate = (dateString) => {
  if (!dateString) return 'N/A'
  return new Date(dateString).toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  })
}
</script>



