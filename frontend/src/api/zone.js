import api from './index'

export const zoneAPI = {
  getAll: (params) => api.get('/zone/', { params }),
  getById: (id) => api.get(`/zone/${id}`),
  create: (warehouseId, data) => api.post(`/zone/?warehouse_id=${warehouseId}`, data),
  update: (id, data) => api.patch(`/zone/${id}`, data),
}



