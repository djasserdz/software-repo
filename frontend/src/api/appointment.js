import api from './index'

export const appointmentAPI = {
  getAll: (params) => api.get('/appointment/', { params }),
  getById: (id) => api.get(`/appointment/${id}`),
  getMyAppointments: (status) => api.get('/appointment/my-appointments', { params: { status } }),
  getHistory: () => api.get('/appointment/history'),
  create: (data) => api.post('/appointment/', data),
  cancel: (id) => api.put(`/appointment/${id}/cancel`, {}),
  accept: (id) => api.put(`/appointment/${id}/accept`),
  refuse: (id) => api.put(`/appointment/${id}/refuse`),
  confirmAttendance: (id) => api.put(`/appointment/${id}/confirm-attendance`),
}



