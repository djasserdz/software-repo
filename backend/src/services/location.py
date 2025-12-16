import requests

class LocationAPI:
    BASE_URL = "https://nominatim.openstreetmap.org/search"
    
    @staticmethod
    def fetch_by_location_name(location_name, limit=1):
        params = {
            'q': location_name,
            'format': 'json',
            'limit': limit
        }
        headers = {
            'User-Agent': 'LocationSearchApp/1.0'
        }
        
        try:
            response = requests.get(LocationAPI.BASE_URL, params=params, headers=headers)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            print(f"Error fetching location by name: {e}")
            return None
    
    @staticmethod
    def fetch_by_coordinates(latitude, longitude, zoom=18):
        reverse_url = "https://nominatim.openstreetmap.org/reverse"
        
        params = {
            'lat': latitude,
            'lon': longitude,
            'format': 'json',
            'zoom': zoom
        }
        headers = {
            'User-Agent': 'LocationSearchApp/1.0'
        }
        
        try:
            response = requests.get(reverse_url, params=params, headers=headers)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            print(f"Error fetching location by coordinates: {e}")
            return None