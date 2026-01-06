import api from './index'

export const timeslotAPI = {
  getAll: (zoneId, params) => api.get('/time/', { params: { zone_id: zoneId, ...params } }),
  getById: (id) => api.get(`/time/${id}`),
  getAvailable: (zoneId, grainTypeId) => {
    const params = { 
      zone_id: parseInt(zoneId, 10)
    }
    // Only add grain_type_id if it's provided and valid
    if (grainTypeId !== null && grainTypeId !== undefined && grainTypeId !== '') {
      const parsedGrainTypeId = parseInt(grainTypeId, 10)
      if (!isNaN(parsedGrainTypeId)) {
        params.grain_type_id = parsedGrainTypeId
      }
    }
    return api.get('/time/available', { params })
  },
  create: (data) => api.post('/time/', data),
  update: (id, data) => api.patch(`/time/${id}`, data),
  delete: (id) => api.delete(`/time/${id}`),
  generateNextDay: () => api.post('/time/generate'),
  generateWeek: () => api.post('/time/generate-week'),
}



