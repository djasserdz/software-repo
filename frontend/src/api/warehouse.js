import api from './index'

export const warehouseAPI = {
  getAll: () => api.get('/warehouse/'),
  getById: (id) => api.get(`/warehouse/${id}`),
  create: (data) => api.post('/warehouse/', data),
  update: (id, data) => api.patch(`/warehouse/${id}`, data),
}



