import api from './index'

export const deliveryAPI = {
  getAll: (params) => api.get('/delivery/', { params }),
  getById: (id) => api.get(`/delivery/${id}`),
  getMyDeliveries: () => api.get('/delivery/my-deliveries'),
  create: (data) => api.post('/delivery/', data),
}



