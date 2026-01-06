import api from './index'

export const timeslotTemplateAPI = {
  getAll: async (params) => {
    const response = await api.get('/time-template/', { params })
    // Ensure times are strings
    if (response.data && Array.isArray(response.data)) {
      response.data = response.data.map(template => ({
        ...template,
        start_time: typeof template.start_time === 'string' 
          ? template.start_time 
          : template.start_time?.toString() || '',
        end_time: typeof template.end_time === 'string' 
          ? template.end_time 
          : template.end_time?.toString() || '',
      }))
    }
    return response
  },
  getById: (id) => api.get(`/time-template/${id}`),
  getByZone: (zoneId) => api.get(`/time-template/zone/${zoneId}`),
  create: (data) => api.post('/time-template/', data),
  update: (id, data) => api.patch(`/time-template/${id}`, data),
  delete: (id) => api.delete(`/time-template/${id}`),
}

