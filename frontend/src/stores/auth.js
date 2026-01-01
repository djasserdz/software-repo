import { defineStore } from 'pinia'
import { authAPI } from '../api/auth'

export const useAuthStore = defineStore('auth', {
  state: () => ({
    user: JSON.parse(localStorage.getItem('user') || 'null'),
    token: localStorage.getItem('token') || null,
    loading: false,
    error: null,
  }),

  getters: {
    isAuthenticated: (state) => !!state.token && !!state.user,
    isFarmer: (state) => state.user?.role === 'farmer',
    isWarehouseAdmin: (state) => state.user?.role === 'warehouse_admin',
    isAdmin: (state) => state.user?.role === 'admin',
  },

  actions: {
    async login(email, password) {
      this.loading = true
      this.error = null
      try {
        const response = await authAPI.login({ email, password })
        this.token = response.data.token
        this.user = response.data.user
        localStorage.setItem('token', this.token)
        localStorage.setItem('user', JSON.stringify(this.user))
        return response.data
      } catch (error) {
        this.error = error.response?.data?.detail || 'Login failed'
        throw error
      } finally {
        this.loading = false
      }
    },

    async register(userData) {
      this.loading = true
      this.error = null
      try {
        const response = await authAPI.register(userData)
        this.token = response.data.token
        this.user = response.data.user
        localStorage.setItem('token', this.token)
        localStorage.setItem('user', JSON.stringify(this.user))
        return response.data
      } catch (error) {
        this.error = error.response?.data?.detail || 'Registration failed'
        throw error
      } finally {
        this.loading = false
      }
    },

    async fetchCurrentUser() {
      try {
        const response = await authAPI.getCurrentUser()
        this.user = response.data
        localStorage.setItem('user', JSON.stringify(this.user))
        return response.data
      } catch (error) {
        this.logout()
        throw error
      }
    },

    async updateProfile(data) {
      try {
        const response = await authAPI.updateProfile(data)
        this.user = response.data
        localStorage.setItem('user', JSON.stringify(this.user))
        return response.data
      } catch (error) {
        this.error = error.response?.data?.detail || 'Update failed'
        throw error
      }
    },

    async changePassword(data) {
      try {
        await authAPI.changePassword(data)
        return true
      } catch (error) {
        this.error = error.response?.data?.detail || 'Password change failed'
        throw error
      }
    },

    logout() {
      this.user = null
      this.token = null
      this.error = null
      localStorage.removeItem('token')
      localStorage.removeItem('user')
    },
  },
})



