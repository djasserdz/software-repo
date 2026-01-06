import api from './index'

export const geolocationAPI = {
  getNearestWarehouses: (lat, lng, grainType, limit = 10) =>
    api.get('/geolocation/nearest', {
      params: { lat, lng, grainType, limit },
    }),
  updateWarehouseLocation: (warehouseId, latitude, longitude) =>
    api.put(`/geolocation/warehouse/${warehouseId}/location`, null, {
      params: { latitude, longitude },
    }),
  updateFarmerLocation: (data) => api.post('/geolocation/update-location', data),
  reverseGeocode: (latitude, longitude) =>
    api.get('/location/coordinates/', {
      params: { latitude, longitude },
    }),
}



