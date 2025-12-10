import React, { useEffect, useState } from 'react';
import Layout from '../../components/Layout';
import LoadingSpinner from '../../components/LoadingSpinner';
import WarehouseLocationPicker from '../../components/WarehouseLocationPicker';
import { warehouseAPI } from '../../services/api';
import { GRAIN_TYPES } from '../../utils/constants';
import { formatWeight } from '../../utils/formatters';

const ZoneManagement = () => {
  const [zones, setZones] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [editingZone, setEditingZone] = useState(null);
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState({ type: '', text: '' });
  const [formData, setFormData] = useState({
    name: '',
    grainType: 'WHEAT',
    maxCapacity: '',
    location: '',
    latitude: null,
    longitude: null,
    address: ''
  });

  useEffect(() => {
    fetchZones();
  }, []);

  const fetchZones = async () => {
    try {
      const response = await warehouseAPI.getZones();
      setZones(response.data.zones);
    } catch (error) {
      setMessage({ type: 'error', text: 'Failed to load zones' });
    } finally {
      setLoading(false);
    }
  };

  const handleChange = (e) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value
    });
  };

  const openCreateModal = () => {
    setEditingZone(null);
    setFormData({
      name: '',
      grainType: 'WHEAT',
      maxCapacity: '',
      location: '',
      latitude: null,
      longitude: null,
      address: ''
    });
    setShowModal(true);
    setMessage({ type: '', text: '' });
  };

  const openEditModal = (zone) => {
    setEditingZone(zone);
    setFormData({
      name: zone.name,
      grainType: zone.grainType,
      maxCapacity: zone.maxCapacity,
      location: zone.location || '',
      latitude: zone.latitude || null,
      longitude: zone.longitude || null,
      address: zone.address || ''
    });
    setShowModal(true);
    setMessage({ type: '', text: '' });
  };

  const closeModal = () => {
    setShowModal(false);
    setEditingZone(null);
    setFormData({
      name: '',
      grainType: 'WHEAT',
      maxCapacity: '',
      location: '',
      latitude: null,
      longitude: null,
      address: ''
    });
    setMessage({ type: '', text: '' });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setSaving(true);
    setMessage({ type: '', text: '' });

    try {
      const dataToSubmit = {
        ...formData,
        maxCapacity: parseFloat(formData.maxCapacity)
      };

      if (editingZone) {
        await warehouseAPI.updateZone(editingZone.id, dataToSubmit);
        setMessage({ type: 'success', text: 'Zone updated successfully' });
      } else {
        await warehouseAPI.createZone(dataToSubmit);
        setMessage({ type: 'success', text: 'Zone created successfully' });
      }

      fetchZones();
      closeModal();
    } catch (error) {
      setMessage({
        type: 'error',
        text: error.response?.data?.message || `Failed to ${editingZone ? 'update' : 'create'} zone`
      });
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (zone) => {
    if (!window.confirm(`Are you sure you want to delete "${zone.name}"? This action cannot be undone.`)) {
      return;
    }

    setMessage({ type: '', text: '' });

    try {
      await warehouseAPI.deleteZone(zone.id);
      setMessage({ type: 'success', text: 'Zone deleted successfully' });
      fetchZones();
    } catch (error) {
      setMessage({
        type: 'error',
        text: error.response?.data?.message || 'Failed to delete zone'
      });
    }
  };

  const getUtilizationColor = (rate) => {
    if (rate >= 90) return 'text-red-600';
    if (rate >= 70) return 'text-yellow-600';
    return 'text-green-600';
  };

  if (loading) {
    return (
      <Layout>
        <LoadingSpinner message="Loading zones..." />
      </Layout>
    );
  }

  return (
    <Layout>
      <div className="space-y-6">
        <div className="flex justify-between items-center">
          <h1 className="text-3xl font-bold text-gray-900">Zone Management</h1>
          <button onClick={openCreateModal} className="btn btn-primary">
            Add New Zone
          </button>
        </div>

        {message.text && (
          <div className={`p-4 rounded-lg ${
            message.type === 'success'
              ? 'bg-green-50 text-green-800 border border-green-200'
              : 'bg-red-50 text-red-800 border border-red-200'
          }`}>
            {message.text}
          </div>
        )}

        {/* Zones Table */}
        <div className="card overflow-hidden">
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Zone Name
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Grain Type
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Max Capacity
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Current Stock
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Available
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Utilization
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Location
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Status
                  </th>
                  <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {zones.length === 0 ? (
                  <tr>
                    <td colSpan="9" className="px-6 py-8 text-center text-gray-500">
                      No zones found. Click "Add New Zone" to create one.
                    </td>
                  </tr>
                ) : (
                  zones.map((zone) => {
                    const availableCapacity = zone.maxCapacity - zone.currentCapacity;
                    const utilizationRate = ((zone.currentCapacity / zone.maxCapacity) * 100).toFixed(1);

                    return (
                      <tr key={zone.id} className={!zone.isActive ? 'bg-gray-50' : ''}>
                        <td className="px-6 py-4 whitespace-nowrap">
                          <div className="text-sm font-medium text-gray-900">{zone.name}</div>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap">
                          <div className="text-sm text-gray-900">
                            {GRAIN_TYPES.find(g => g.value === zone.grainType)?.label || zone.grainType}
                          </div>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap">
                          <div className="text-sm text-gray-900">{formatWeight(zone.maxCapacity)}</div>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap">
                          <div className="text-sm text-gray-900">{formatWeight(zone.currentCapacity)}</div>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap">
                          <div className="text-sm text-gray-900">{formatWeight(availableCapacity)}</div>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap">
                          <div className={`text-sm font-semibold ${getUtilizationColor(utilizationRate)}`}>
                            {utilizationRate}%
                          </div>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap">
                          <div className="text-sm text-gray-900">{zone.location || '-'}</div>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap">
                          <span className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${
                            zone.isActive
                              ? 'bg-green-100 text-green-800'
                              : 'bg-gray-100 text-gray-800'
                          }`}>
                            {zone.isActive ? 'Active' : 'Inactive'}
                          </span>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                          <button
                            onClick={() => openEditModal(zone)}
                            className="text-primary-600 hover:text-primary-900 mr-4"
                          >
                            Edit
                          </button>
                          <button
                            onClick={() => handleDelete(zone)}
                            className="text-red-600 hover:text-red-900"
                          >
                            Delete
                          </button>
                        </td>
                      </tr>
                    );
                  })
                )}
              </tbody>
            </table>
          </div>
        </div>

        {/* Create/Edit Modal */}
        {showModal && (
          <div className="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50 flex items-center justify-center">
            <div className="relative bg-white rounded-lg shadow-xl max-w-4xl w-full mx-4 max-h-[90vh] overflow-y-auto">
              <div className="p-6">
                <h3 className="text-lg font-semibold text-gray-900 mb-4">
                  {editingZone ? 'Edit Zone' : 'Create New Zone'}
                </h3>

                <form onSubmit={handleSubmit} className="space-y-4">
                  <div>
                    <label htmlFor="name" className="block text-sm font-medium text-gray-700">
                      Zone Name *
                    </label>
                    <input
                      type="text"
                      id="name"
                      name="name"
                      value={formData.name}
                      onChange={handleChange}
                      required
                      className="input mt-1"
                      placeholder="e.g., Zone A - Wheat Storage"
                    />
                  </div>

                  <div>
                    <label htmlFor="grainType" className="block text-sm font-medium text-gray-700">
                      Grain Type *
                    </label>
                    <select
                      id="grainType"
                      name="grainType"
                      value={formData.grainType}
                      onChange={handleChange}
                      required
                      className="input mt-1"
                    >
                      {GRAIN_TYPES.map((grain) => (
                        <option key={grain.value} value={grain.value}>
                          {grain.label}
                        </option>
                      ))}
                    </select>
                  </div>

                  <div>
                    <label htmlFor="maxCapacity" className="block text-sm font-medium text-gray-700">
                      Max Capacity (kg) *
                    </label>
                    <input
                      type="number"
                      id="maxCapacity"
                      name="maxCapacity"
                      value={formData.maxCapacity}
                      onChange={handleChange}
                      required
                      min="1"
                      step="1"
                      className="input mt-1"
                      placeholder="e.g., 10000"
                    />
                  </div>

                  <div>
                    <label htmlFor="location" className="block text-sm font-medium text-gray-700">
                      Physical Location Description
                    </label>
                    <input
                      type="text"
                      id="location"
                      name="location"
                      value={formData.location}
                      onChange={handleChange}
                      className="input mt-1"
                      placeholder="e.g., Building A, Section 1"
                    />
                  </div>

                  <div>
                    <WarehouseLocationPicker
                      initialLocation={
                        formData.latitude && formData.longitude
                          ? { lat: parseFloat(formData.latitude), lng: parseFloat(formData.longitude) }
                          : null
                      }
                      onLocationChange={(location) => {
                        setFormData({
                          ...formData,
                          latitude: location.lat,
                          longitude: location.lng
                        });
                      }}
                      address={formData.address}
                      onAddressChange={(address) => {
                        setFormData({ ...formData, address });
                      }}
                    />
                  </div>

                  {editingZone && (
                    <div className="bg-blue-50 border border-blue-200 rounded-lg p-3">
                      <p className="text-sm text-blue-800">
                        <strong>Current Stock:</strong> {formatWeight(editingZone.currentCapacity)}
                      </p>
                      <p className="text-sm text-blue-700 mt-1">
                        Note: Max capacity cannot be less than current stock.
                      </p>
                    </div>
                  )}

                  <div className="flex space-x-3 pt-4">
                    <button
                      type="submit"
                      disabled={saving}
                      className="btn btn-primary flex-1"
                    >
                      {saving ? 'Saving...' : (editingZone ? 'Update Zone' : 'Create Zone')}
                    </button>
                    <button
                      type="button"
                      onClick={closeModal}
                      disabled={saving}
                      className="btn btn-secondary flex-1"
                    >
                      Cancel
                    </button>
                  </div>
                </form>
              </div>
            </div>
          </div>
        )}
      </div>
    </Layout>
  );
};

export default ZoneManagement;
