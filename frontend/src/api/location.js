import api from './index'

export const locationAPI = {
  getLocationByCoordinates: (latitude, longitude) =>
    api.get('/location/coordinates/', {
      params: { latitude, longitude },
    }),
  getLocationByName: (locationName) =>
    api.get(`/location/name/${encodeURIComponent(locationName)}`),
}

