import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import Layout from '../../components/Layout';
import ErrorMessage from '../../components/ErrorMessage';
import SuccessMessage from '../../components/SuccessMessage';
import LoadingSpinner from '../../components/LoadingSpinner';
import { appointmentAPI, deliveryAPI } from '../../services/api';
import { formatDateTime, formatWeight } from '../../utils/formatters';

const RecordDelivery = () => {
  const [appointments, setAppointments] = useState([]);
  const [selectedAppointment, setSelectedAppointment] = useState(null);
  const [formData, setFormData] = useState({
    quantity: '',
    quality: '',
    moistureContent: '',
    notes: ''
  });
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const navigate = useNavigate();

  useEffect(() => {
    fetchAttendedAppointments();
  }, []);

  const fetchAttendedAppointments = async () => {
    try {
      const response = await appointmentAPI.getAll({ status: 'SCHEDULED' });
      const attended = response.data.appointments.filter(apt => apt.attended);
      setAppointments(attended);
    } catch (err) {
      setError('Failed to load appointments');
    } finally {
      setLoading(false);
    }
  };

  const handleAppointmentSelect = (apt) => {
    setSelectedAppointment(apt);
    setFormData({
      ...formData,
      quantity: apt.requestedQuantity.toString()
    });
  };

  const handleChange = (e) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setSuccess('');
    setSubmitting(true);

    try {
      await deliveryAPI.record({
        appointmentId: selectedAppointment.id,
        quantity: parseFloat(formData.quantity),
        quality: formData.quality,
        moistureContent: formData.moistureContent ? parseFloat(formData.moistureContent) : null,
        notes: formData.notes
      });

      setSuccess('Delivery recorded successfully!');
      setTimeout(() => {
        navigate('/warehouse/deliveries');
      }, 2000);
    } catch (err) {
      setError(err.response?.data?.message || 'Failed to record delivery');
    } finally {
      setSubmitting(false);
    }
  };

  if (loading) {
    return (
      <Layout>
        <LoadingSpinner message="Loading appointments..." />
      </Layout>
    );
  }

  return (
    <Layout>
      <div className="max-w-4xl mx-auto">
        <h1 className="text-3xl font-bold text-gray-900 mb-6">Record Delivery</h1>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <div className="card">
            <h2 className="text-lg font-semibold mb-4">Select Appointment</h2>
            {appointments.length === 0 ? (
              <p className="text-gray-500">No attended appointments available</p>
            ) : (
              <div className="space-y-2 max-h-96 overflow-y-auto">
                {appointments.map((apt) => (
                  <div
                    key={apt.id}
                    onClick={() => handleAppointmentSelect(apt)}
                    className={`border rounded-lg p-3 cursor-pointer transition-colors ${
                      selectedAppointment?.id === apt.id
                        ? 'border-primary-500 bg-primary-50'
                        : 'border-gray-200 hover:border-gray-300'
                    }`}
                  >
                    <p className="font-medium text-gray-900">
                      {apt.farmer?.firstName} {apt.farmer?.lastName}
                    </p>
                    <p className="text-sm text-gray-600">
                      {apt.grainType} - {formatWeight(apt.requestedQuantity)}
                    </p>
                    <p className="text-xs text-gray-500">{formatDateTime(apt.scheduledDate)}</p>
                  </div>
                ))}
              </div>
            )}
          </div>

          <div className="card">
            <h2 className="text-lg font-semibold mb-4">Delivery Details</h2>
            {!selectedAppointment ? (
              <p className="text-gray-500">Select an appointment to record delivery</p>
            ) : (
              <form onSubmit={handleSubmit} className="space-y-4">
                <ErrorMessage message={error} />
                <SuccessMessage message={success} />

                <div className="bg-gray-50 rounded-lg p-3 text-sm">
                  <p><span className="font-medium">Farmer:</span> {selectedAppointment.farmer?.firstName} {selectedAppointment.farmer?.lastName}</p>
                  <p><span className="font-medium">Grain:</span> {selectedAppointment.grainType}</p>
                  <p><span className="font-medium">Zone:</span> {selectedAppointment.warehouseZone?.name}</p>
                </div>

                <div>
                  <label htmlFor="quantity" className="label">
                    Actual Quantity (kg) *
                  </label>
                  <input
                    id="quantity"
                    name="quantity"
                    type="number"
                    step="0.01"
                    min="1"
                    required
                    className="input"
                    value={formData.quantity}
                    onChange={handleChange}
                  />
                </div>

                <div>
                  <label htmlFor="quality" className="label">
                    Quality Grade
                  </label>
                  <input
                    id="quality"
                    name="quality"
                    type="text"
                    className="input"
                    value={formData.quality}
                    onChange={handleChange}
                    placeholder="e.g., Grade A, Premium"
                  />
                </div>

                <div>
                  <label htmlFor="moistureContent" className="label">
                    Moisture Content (%)
                  </label>
                  <input
                    id="moistureContent"
                    name="moistureContent"
                    type="number"
                    step="0.1"
                    min="0"
                    max="100"
                    className="input"
                    value={formData.moistureContent}
                    onChange={handleChange}
                  />
                </div>

                <div>
                  <label htmlFor="notes" className="label">
                    Notes
                  </label>
                  <textarea
                    id="notes"
                    name="notes"
                    rows="3"
                    className="input"
                    value={formData.notes}
                    onChange={handleChange}
                  />
                </div>

                <div className="flex space-x-4">
                  <button
                    type="submit"
                    disabled={submitting}
                    className="btn btn-primary flex-1 disabled:opacity-50"
                  >
                    {submitting ? 'Recording...' : 'Record Delivery'}
                  </button>
                  <button
                    type="button"
                    onClick={() => navigate('/warehouse/deliveries')}
                    className="btn btn-secondary"
                  >
                    Cancel
                  </button>
                </div>
              </form>
            )}
          </div>
        </div>
      </div>
    </Layout>
  );
};

export default RecordDelivery;
