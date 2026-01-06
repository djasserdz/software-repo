import api from './index'

export const userAPI = {
  getAll: () => api.get('/user/'),
  getById: (id) => api.get(`/user/${id}`),
  create: (data) => api.post('/user/register', data),
  suspend: (id, reason) => api.post(`/user/suspend/${id}?reason=${encodeURIComponent(reason)}`),
  unsuspend: (userId) => api.post(`/user/unsuspend?user_id=${userId}`),
}
