import api from './index'

export const timeslotAPI = {
  getAll: (zoneId, params) => api.get('/time/', { params: { zone_id: zoneId, ...params } }),
  getById: (id) => api.get(`/time/${id}`),
  getAvailable: (zoneId, grainTypeId) => 
    api.get('/time/available', { params: { zone_id: zoneId, grain_type_id: grainTypeId } }),
  create: (data) => api.post('/time/', data),
  update: (id, data) => api.patch(`/time/${id}`, data),
  delete: (id) => api.delete(`/time/${id}`),
  generateNextDay: () => api.post('/time/generate'),
  generateWeek: () => api.post('/time/generate-week'),
}



