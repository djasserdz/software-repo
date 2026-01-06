<template>
  <Layout>
    <div class="px-4 sm:px-6 lg:px-8">
      <div class="mb-8 flex justify-between items-center">
        <div>
          <h1 class="text-3xl font-bold text-gray-900">User Management</h1>
          <p class="mt-2 text-sm text-gray-600">Manage all system users</p>
        </div>
        <button @click="showCreateModal = true" class="btn-primary">
          Add User
        </button>
      </div>

      <div class="mb-6">
        <input
          v-model="searchQuery"
          type="text"
          placeholder="Search users by name or email..."
          class="input-field max-w-md"
        />
      </div>

      <div v-if="loading" class="text-center py-12">
        <div class="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600"></div>
        <p class="mt-2 text-gray-500">Loading users...</p>
      </div>

      <div v-else-if="filteredUsers.length === 0" class="text-center py-12">
        <p class="text-gray-500">No users found</p>
      </div>

      <div v-else class="card overflow-hidden">
        <div class="overflow-x-auto">
          <table class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50">
              <tr>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">User</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Role</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Created</th>
                <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
              </tr>
            </thead>
            <tbody class="bg-white divide-y divide-gray-200">
              <tr v-for="user in filteredUsers" :key="user.user_id">
                <td class="px-6 py-4 whitespace-nowrap">
                  <div>
                    <div class="text-sm font-medium text-gray-900">{{ user.name }}</div>
                    <div class="text-sm text-gray-500">{{ user.email }}</div>
                  </div>
                </td>
                <td class="px-6 py-4 whitespace-nowrap">
                  <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full"
                    :class="getRoleClass(user.role)">
                    {{ user.role }}
                  </span>
                </td>
                <td class="px-6 py-4 whitespace-nowrap">
                  <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full"
                    :class="user.account_status ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'">
                    {{ user.account_status ? 'Active' : 'Suspended' }}
                  </span>
                  <div v-if="!user.account_status && user.suspended_reason" class="text-xs text-gray-500 mt-1">
                    Reason: {{ user.suspended_reason }}
                  </div>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                  {{ formatDate(user.created_at) }}
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                  <button
                    v-if="user.account_status"
                    @click="suspendUser(user.user_id)"
                    class="text-red-600 hover:text-red-900 mr-4"
                    :disabled="suspending === user.user_id"
                  >
                    {{ suspending === user.user_id ? 'Suspending...' : 'Suspend' }}
                  </button>
                  <button
                    v-else
                    @click="unsuspendUser(user.user_id)"
                    class="text-green-600 hover:text-green-900 mr-4"
                    :disabled="unsuspending === user.user_id"
                  >
                    {{ unsuspending === user.user_id ? 'Unsuspending...' : 'Unsuspend' }}
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <!-- Create User Modal -->
      <div v-if="showCreateModal" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
        <div class="bg-white rounded-lg p-6 max-w-md w-full mx-4">
          <h2 class="text-2xl font-bold text-gray-900 mb-4">Create New User</h2>
          <form @submit.prevent="createUser">
            <div class="space-y-4">
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Name</label>
                <input v-model="userForm.name" type="text" required class="input-field" />
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Email</label>
                <input v-model="userForm.email" type="email" required class="input-field" />
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Password</label>
                <input v-model="userForm.password" type="password" required class="input-field" minlength="6" />
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Role</label>
                <select v-model="userForm.role" required class="input-field">
                  <option value="farmer">Farmer</option>
                  <option value="warehouse_admin">Warehouse Admin</option>
                  <option value="admin">Admin</option>
                </select>
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Phone</label>
                <input v-model="userForm.phone" type="tel" class="input-field" />
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Address</label>
                <input v-model="userForm.address" type="text" class="input-field" />
              </div>
            </div>
            <div class="mt-6 flex gap-3">
              <button type="submit" class="btn-primary flex-1" :disabled="creating">
                {{ creating ? 'Creating...' : 'Create User' }}
              </button>
              <button type="button" @click="closeCreateModal" class="btn-secondary flex-1">
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
import { ref, computed, onMounted } from 'vue'
import { userAPI } from '../../api/user'
import Layout from '../../components/Layout.vue'

const users = ref([])
const loading = ref(true)
const searchQuery = ref('')
const suspending = ref(null)
const unsuspending = ref(null)
const showCreateModal = ref(false)
const creating = ref(false)

const userForm = ref({
  name: '',
  email: '',
  password: '',
  role: 'farmer',
  phone: '',
  address: '',
})

const filteredUsers = computed(() => {
  if (!searchQuery.value) return users.value
  
  const query = searchQuery.value.toLowerCase()
  return users.value.filter(user => 
    user.name.toLowerCase().includes(query) ||
    user.email.toLowerCase().includes(query)
  )
})

const loadUsers = async () => {
  loading.value = true
  try {
    const response = await userAPI.getAll()
    users.value = response.data || []
  } catch (error) {
    console.error('Error loading users:', error)
  } finally {
    loading.value = false
  }
}

const suspendUser = async (userId) => {
  const reason = prompt('Enter suspension reason:')
  if (!reason || reason.trim() === '') return
  
  suspending.value = userId
  try {
    await userAPI.suspend(userId, reason)
    await loadUsers()
  } catch (error) {
    console.error('Error suspending user:', error)
    alert('Failed to suspend user')
  } finally {
    suspending.value = null
  }
}

const unsuspendUser = async (userId) => {
  if (!confirm('Are you sure you want to unsuspend this user?')) return
  
  unsuspending.value = userId
  try {
    await userAPI.unsuspend(userId)
    await loadUsers()
  } catch (error) {
    console.error('Error unsuspending user:', error)
    alert('Failed to unsuspend user')
  } finally {
    unsuspending.value = null
  }
}

const formatDate = (dateString) => {
  return new Date(dateString).toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  })
}

const getRoleClass = (role) => {
  const classes = {
    admin: 'bg-purple-100 text-purple-800',
    warehouse_admin: 'bg-blue-100 text-blue-800',
    farmer: 'bg-green-100 text-green-800',
  }
  return classes[role] || 'bg-gray-100 text-gray-800'
}

const createUser = async () => {
  creating.value = true
  try {
    await userAPI.create(userForm.value)
    await loadUsers()
    closeCreateModal()
    alert('User created successfully')
  } catch (error) {
    console.error('Error creating user:', error)
    const message = error.response?.data?.detail || 'Failed to create user'
    alert(message)
  } finally {
    creating.value = false
  }
}

const closeCreateModal = () => {
  showCreateModal.value = false
  userForm.value = {
    name: '',
    email: '',
    password: '',
    role: 'farmer',
    phone: '',
    address: '',
  }
}

onMounted(() => {
  loadUsers()
})
</script>

