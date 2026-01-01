import api from './index'

export const grainAPI = {
  getAll: () => api.get('/grain/'),
  getById: (id) => api.get(`/grain/${id}`),
  create: (data) => api.post('/grain/', data),
  update: (id, data) => api.patch(`/grain/${id}`, data),
  delete: (id) => api.delete(`/grain/${id}`),
}



