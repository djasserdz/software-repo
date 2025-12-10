import { useState, useEffect } from 'react';
import { MapContainer, TileLayer, Marker, Popup, useMapEvents } from 'react-leaflet';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';

// Fix for default marker icons in React-Leaflet
delete L.Icon.Default.prototype._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-icon-2x.png',
  iconUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-icon.png',
  shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-shadow.png',
});

// Component to handle map clicks
function LocationMarker({ position, setPosition }) {
  useMapEvents({
    click(e) {
      setPosition({
        lat: e.latlng.lat,
        lng: e.latlng.lng
      });
    },
  });

  return position ? (
    <Marker position={[position.lat, position.lng]}>
      <Popup>
        Selected Location<br />
        Lat: {position.lat.toFixed(6)}<br />
        Lng: {position.lng.toFixed(6)}
      </Popup>
    </Marker>
  ) : null;
}

export default function WarehouseLocationPicker({ initialLocation, onLocationChange, address, onAddressChange }) {
  const [position, setPosition] = useState(
    initialLocation || { lat: 28.0339, lng: 1.6596 }
  );

  useEffect(() => {
    if (onLocationChange) {
      onLocationChange(position);
    }
  }, [position, onLocationChange]);

  return (
    <div className="space-y-4">
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-2">
          Warehouse Address
        </label>
        <input
          type="text"
          value={address || ''}
          onChange={(e) => onAddressChange && onAddressChange(e.target.value)}
          className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-green-500"
          placeholder="Enter warehouse address"
        />
      </div>

      <div>
        <label className="block text-sm font-medium text-gray-700 mb-2">
          Click on the map to set warehouse location
        </label>
        <div className="border border-gray-300 rounded-lg overflow-hidden">
          <MapContainer
            center={[position.lat, position.lng]}
            zoom={5}
            style={{ height: '400px', width: '100%' }}
          >
            <TileLayer
              attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
              url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
            />
            <LocationMarker position={position} setPosition={setPosition} />
          </MapContainer>
        </div>
      </div>

      <div className="grid grid-cols-2 gap-4">
        <div>
          <label className="block text-sm font-medium text-gray-700">Latitude</label>
          <input
            type="number"
            step="0.000001"
            value={position.lat}
            onChange={(e) => setPosition({ ...position, lat: parseFloat(e.target.value) || 0 })}
            className="mt-1 w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-green-500"
          />
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700">Longitude</label>
          <input
            type="number"
            step="0.000001"
            value={position.lng}
            onChange={(e) => setPosition({ ...position, lng: parseFloat(e.target.value) || 0 })}
            className="mt-1 w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-green-500"
          />
        </div>
      </div>
    </div>
  );
}
