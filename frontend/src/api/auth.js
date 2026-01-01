import api from './index'

export const authAPI = {
  register: (data) => api.post('/user/register', data),
  login: (data) => api.post('/user/login', data),
  getCurrentUser: () => api.get('/user/me'),
  updateProfile: (data) => api.put('/user/profile', data),
  changePassword: (data) => api.put('/user/change-password', data),
}



