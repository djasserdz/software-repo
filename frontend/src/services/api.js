import axios from 'axios';

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:5000/api';

const api = axios.create({
  baseURL: API_URL,
  headers: {
    'Content-Type': 'application/json'
  }
});

// Add token to requests
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Handle responses
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      localStorage.removeItem('token');
      localStorage.removeItem('user');
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

// Auth API
export const authAPI = {
  register: (data) => api.post('/auth/register', data),
  login: (data) => api.post('/auth/login', data),
  getProfile: () => api.get('/auth/profile'),
  updateProfile: (data) => api.put('/auth/profile', data),
  changePassword: (data) => api.put('/auth/change-password', data),
  deleteAccount: () => api.delete('/auth/account'),
  requestReactivation: (email) => api.post('/auth/request-reactivation', { email })
};

// Appointment API
export const appointmentAPI = {
  create: (data) => api.post('/appointments', data),
  getMyAppointments: (status) => api.get('/appointments/my-appointments', { params: { status } }),
  getHistory: () => api.get('/appointments/history'),
  getAll: (params) => api.get('/appointments', { params }),
  getById: (id) => api.get(`/appointments/${id}`),
  confirmAttendance: (id) => api.put(`/appointments/${id}/confirm-attendance`),
  cancel: (id, reason) => api.put(`/appointments/${id}/cancel`, { reason })
};

// Delivery API
export const deliveryAPI = {
  record: (data) => api.post('/deliveries', data),
  getAll: (params) => api.get('/deliveries', { params }),
  getMyDeliveries: () => api.get('/deliveries/my-deliveries'),
  getById: (id) => api.get(`/deliveries/${id}`),
  getStorageReport: () => api.get('/deliveries/reports/storage')
};

// User API
export const userAPI = {
  createWarehouseAdmin: (data) => api.post('/users/warehouse-admins', data),
  getWarehouseAdmins: () => api.get('/users/warehouse-admins'),
  updateWarehouseAdmin: (id, data) => api.put(`/users/warehouse-admins/${id}`, data),
  deleteWarehouseAdmin: (id) => api.delete(`/users/warehouse-admins/${id}`),
  getFarmers: (params) => api.get('/users/farmers', { params }),
  getFarmerById: (id) => api.get(`/users/farmers/${id}`),
  reactivateFarmer: (id) => api.put(`/users/farmers/${id}/reactivate`)
};

// Warehouse API
export const warehouseAPI = {
  getZones: (params) => api.get('/warehouse-zones', { params }),
  getZoneById: (id) => api.get(`/warehouse-zones/${id}`),
  createZone: (data) => api.post('/warehouse-zones', data),
  updateZone: (id, data) => api.put(`/warehouse-zones/${id}`, data),
  deleteZone: (id) => api.delete(`/warehouse-zones/${id}`)
};

// Geolocation API
export const geolocationAPI = {
  getNearestWarehouses: (lat, lng, grainType) =>
    api.get(`/geolocation/nearest?lat=${lat}&lng=${lng}${grainType ? `&grainType=${grainType}` : ''}`),
  updateWarehouseLocation: (id, data) =>
    api.put(`/geolocation/warehouse/${id}/location`, data),
  updateFarmerLocation: (data) =>
    api.post('/geolocation/update-location', data)
};

// Waiting List API
export const waitingListAPI = {
  join: (data) => api.post('/waiting-list/join', data),
  getMyPosition: (appointmentId) => api.get(`/waiting-list/my-position/${appointmentId}`),
  confirm: (id) => api.post(`/waiting-list/confirm/${id}`),
  decline: (id) => api.post(`/waiting-list/decline/${id}`),
  getMyList: () => api.get('/waiting-list/my-list')
};

// Time Slot API
export const timeSlotAPI = {
  getAvailable: (params) => api.get('/time-slots/available', { params }),
  create: (data) => api.post('/time-slots', data),
  generate: (data) => api.post('/time-slots/generate', data),
  update: (id, data) => api.put(`/time-slots/${id}`, data),
  delete: (id) => api.delete(`/time-slots/${id}`)
};

export default api;
