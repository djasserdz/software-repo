import { useState, useEffect } from 'react';
import { MapContainer, TileLayer, Marker, Popup, Circle } from 'react-leaflet';
import L from 'leaflet';
import { geolocationAPI } from '../services/api';
import 'leaflet/dist/leaflet.css';

// Fix for default marker icons in React-Leaflet
delete L.Icon.Default.prototype._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-icon-2x.png',
  iconUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-icon.png',
  shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-shadow.png',
});

// Custom marker icons
const farmerIcon = new L.Icon({
  iconUrl: 'https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-2x-blue.png',
  shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-shadow.png',
  iconSize: [25, 41],
  iconAnchor: [12, 41],
  popupAnchor: [1, -34],
  shadowSize: [41, 41]
});

const warehouseIcon = new L.Icon({
  iconUrl: 'https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-2x-green.png',
  shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-shadow.png',
  iconSize: [25, 41],
  iconAnchor: [12, 41],
  popupAnchor: [1, -34],
  shadowSize: [41, 41]
});

export default function AlgeriaMap({ grainType, onWarehouseSelect }) {
  const [farmerLocation, setFarmerLocation] = useState(null);
  const [warehouses, setWarehouses] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [locationError, setLocationError] = useState(null);

  useEffect(() => {
    getCurrentLocation();
  }, []);

  useEffect(() => {
    if (farmerLocation) {
      fetchNearestWarehouses();
      updateFarmerLocation();
    }
  }, [farmerLocation, grainType]);

  const getCurrentLocation = () => {
    setLoading(true);
    setLocationError(null);

    if (!navigator.geolocation) {
      setLocationError('Geolocation is not supported by your browser');
      setLoading(false);
      // Use default location (center of Algeria)
      setFarmerLocation({ lat: 28.0339, lng: 1.6596 });
      return;
    }

    navigator.geolocation.getCurrentPosition(
      (position) => {
        const location = {
          lat: position.coords.latitude,
          lng: position.coords.longitude
        };
        setFarmerLocation(location);
        setLoading(false);
      },
      (error) => {
        console.error('Error getting location:', error);
        setLocationError('Unable to get your location. Using default location.');
        // Use default location (center of Algeria)
        setFarmerLocation({ lat: 28.0339, lng: 1.6596 });
        setLoading(false);
      },
      {
        enableHighAccuracy: true,
        timeout: 5000,
        maximumAge: 0
      }
    );
  };

  const updateFarmerLocation = async () => {
    try {
      await geolocationAPI.updateFarmerLocation({
        latitude: farmerLocation.lat,
        longitude: farmerLocation.lng
      });
    } catch (err) {
      console.error('Failed to update farmer location:', err);
    }
  };

  const fetchNearestWarehouses = async () => {
    try {
      setError(null);
      const response = await geolocationAPI.getNearestWarehouses(
        farmerLocation.lat,
        farmerLocation.lng,
        grainType
      );
      setWarehouses(response.data.data.allWarehouses || []);
    } catch (err) {
      setError(err.response?.data?.message || 'Failed to fetch warehouses');
      setWarehouses([]);
    }
  };

  const handleWarehouseClick = (warehouse) => {
    if (onWarehouseSelect) {
      onWarehouseSelect(warehouse);
    }
  };

  if (loading) {
    return (
      <div className="bg-white rounded-lg shadow p-6">
        <div className="text-center py-8">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-green-500 mx-auto"></div>
          <p className="mt-2 text-gray-600">Getting your location...</p>
        </div>
      </div>
    );
  }

  if (!farmerLocation) {
    return (
      <div className="bg-white rounded-lg shadow p-6">
        <div className="bg-red-50 border border-red-200 rounded-lg p-4 text-red-800">
          Failed to get your location. Please enable location services and try again.
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-4">
      {locationError && (
        <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4 text-yellow-800">
          {locationError}
        </div>
      )}

      {error && (
        <div className="bg-red-50 border border-red-200 rounded-lg p-4 text-red-800">
          {error}
        </div>
      )}

      <div className="bg-white rounded-lg shadow overflow-hidden">
        <div className="p-4 border-b border-gray-200">
          <h3 className="text-lg font-semibold text-gray-900">Nearby Warehouses</h3>
          <p className="text-sm text-gray-600 mt-1">
            Your location and nearest warehouses {grainType ? `accepting ${grainType}` : ''}
          </p>
        </div>

        <div className="relative">
          <MapContainer
            center={[farmerLocation.lat, farmerLocation.lng]}
            zoom={6}
            style={{ height: '500px', width: '100%' }}
          >
            <TileLayer
              attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
              url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
            />

            {/* Farmer's location */}
            <Marker
              position={[farmerLocation.lat, farmerLocation.lng]}
              icon={farmerIcon}
            >
              <Popup>
                <div className="text-center">
                  <strong>Your Location</strong>
                  <br />
                  <small>
                    {farmerLocation.lat.toFixed(4)}, {farmerLocation.lng.toFixed(4)}
                  </small>
                </div>
              </Popup>
            </Marker>

            {/* Circle around farmer (50km radius) */}
            <Circle
              center={[farmerLocation.lat, farmerLocation.lng]}
              radius={50000}
              pathOptions={{
                color: 'blue',
                fillColor: 'blue',
                fillOpacity: 0.1
              }}
            />

            {/* Warehouse markers */}
            {warehouses.map((warehouse) => (
              <Marker
                key={warehouse.id}
                position={[warehouse.latitude, warehouse.longitude]}
                icon={warehouseIcon}
                eventHandlers={{
                  click: () => handleWarehouseClick(warehouse)
                }}
              >
                <Popup>
                  <div className="min-w-[200px]">
                    <h4 className="font-bold text-gray-900 mb-2">{warehouse.name}</h4>

                    <div className="space-y-1 text-sm">
                      <p>
                        <strong>Distance:</strong> {warehouse.distance?.toFixed(1)} km
                      </p>

                      <p>
                        <strong>Grain Type:</strong> {warehouse.grainType}
                      </p>

                      <p>
                        <strong>Capacity:</strong> {warehouse.currentStock || 0}/{warehouse.maxCapacity} tons
                      </p>

                      <p>
                        <strong>Available:</strong>{' '}
                        <span className={warehouse.availableCapacity > 100 ? 'text-green-600' : 'text-orange-600'}>
                          {warehouse.availableCapacity} tons
                        </span>
                      </p>

                      {warehouse.address && (
                        <p className="text-gray-600">
                          <strong>Address:</strong> {warehouse.address}
                        </p>
                      )}
                    </div>

                    <button
                      onClick={() => handleWarehouseClick(warehouse)}
                      className="mt-3 w-full px-3 py-2 bg-green-500 text-white rounded hover:bg-green-600 text-sm font-medium"
                    >
                      Select This Warehouse
                    </button>
                  </div>
                </Popup>
              </Marker>
            ))}
          </MapContainer>
        </div>
      </div>

      {/* Warehouse list */}
      {warehouses.length > 0 && (
        <div className="bg-white rounded-lg shadow">
          <div className="p-4 border-b border-gray-200">
            <h3 className="text-lg font-semibold text-gray-900">
              Warehouses Sorted by Distance
            </h3>
          </div>
          <div className="divide-y divide-gray-200">
            {warehouses.map((warehouse, index) => (
              <div
                key={warehouse.id}
                className="p-4 hover:bg-gray-50 cursor-pointer transition-colors"
                onClick={() => handleWarehouseClick(warehouse)}
              >
                <div className="flex items-start justify-between">
                  <div className="flex-1">
                    <div className="flex items-center gap-2">
                      <span className="flex items-center justify-center w-6 h-6 rounded-full bg-green-500 text-white text-xs font-bold">
                        {index + 1}
                      </span>
                      <h4 className="font-semibold text-gray-900">{warehouse.name}</h4>
                    </div>

                    <div className="mt-2 grid grid-cols-2 md:grid-cols-4 gap-3 text-sm">
                      <div>
                        <span className="text-gray-600">Distance:</span>
                        <p className="font-medium">{warehouse.distance?.toFixed(1)} km</p>
                      </div>
                      <div>
                        <span className="text-gray-600">Grain Type:</span>
                        <p className="font-medium">{warehouse.grainType}</p>
                      </div>
                      <div>
                        <span className="text-gray-600">Available:</span>
                        <p className={`font-medium ${warehouse.availableCapacity > 100 ? 'text-green-600' : 'text-orange-600'}`}>
                          {warehouse.availableCapacity} tons
                        </p>
                      </div>
                      <div>
                        <span className="text-gray-600">Utilization:</span>
                        <p className="font-medium">
                          {((warehouse.currentStock / warehouse.maxCapacity) * 100).toFixed(0)}%
                        </p>
                      </div>
                    </div>
                  </div>

                  <button
                    onClick={(e) => {
                      e.stopPropagation();
                      handleWarehouseClick(warehouse);
                    }}
                    className="ml-4 px-4 py-2 bg-green-500 text-white rounded-lg hover:bg-green-600 text-sm font-medium"
                  >
                    Select
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {warehouses.length === 0 && !error && (
        <div className="bg-white rounded-lg shadow p-6">
          <div className="text-center py-8">
            <svg className="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
            </svg>
            <h3 className="mt-2 text-sm font-medium text-gray-900">No warehouses found</h3>
            <p className="mt-1 text-sm text-gray-500">
              No warehouses found in your area {grainType ? `that accept ${grainType}` : ''}.
            </p>
          </div>
        </div>
      )}
    </div>
  );
}
