import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import Layout from '../../components/Layout';
import LoadingSpinner from '../../components/LoadingSpinner';
import ErrorMessage from '../../components/ErrorMessage';
import { appointmentAPI } from '../../services/api';
import { formatDateTime, formatWeight } from '../../utils/formatters';
import { APPOINTMENT_STATUS_COLORS } from '../../utils/constants';

const FarmerAppointments = () => {
  const [appointments, setAppointments] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [filter, setFilter] = useState('SCHEDULED');

  useEffect(() => {
    fetchAppointments();
  }, [filter]);

  const fetchAppointments = async () => {
    try {
      setLoading(true);
      const response = await appointmentAPI.getMyAppointments(filter);
      setAppointments(response.data.appointments);
    } catch (err) {
      setError('Failed to load appointments');
    } finally {
      setLoading(false);
    }
  };

  const handleCancel = async (id) => {
    if (!confirm('Are you sure you want to cancel this appointment?')) return;

    try {
      await appointmentAPI.cancel(id, 'Cancelled by farmer');
      fetchAppointments();
    } catch (err) {
      setError('Failed to cancel appointment');
    }
  };

  return (
    <Layout>
      <div className="space-y-6">
        <div className="flex justify-between items-center">
          <h1 className="text-3xl font-bold text-gray-900">My Appointments</h1>
          <Link to="/farmer/appointments/new" className="btn btn-primary">
            Schedule New
          </Link>
        </div>

        <ErrorMessage message={error} />

        <div className="flex space-x-2">
          {['SCHEDULED', 'COMPLETED', 'CANCELLED', 'MISSED'].map((status) => (
            <button
              key={status}
              onClick={() => setFilter(status)}
              className={`btn ${filter === status ? 'btn-primary' : 'btn-secondary'}`}
            >
              {status}
            </button>
          ))}
        </div>

        {loading ? (
          <LoadingSpinner message="Loading appointments..." />
        ) : appointments.length === 0 ? (
          <div className="card text-center py-12">
            <p className="text-gray-500">No appointments found</p>
          </div>
        ) : (
          <div className="grid gap-4">
            {appointments.map((apt) => (
              <div key={apt.id} className="card">
                <div className="flex justify-between items-start">
                  <div className="flex-1">
                    <div className="flex items-center space-x-3">
                      <h3 className="text-lg font-semibold text-gray-900">{apt.grainType}</h3>
                      <span className={`badge ${APPOINTMENT_STATUS_COLORS[apt.status]}`}>
                        {apt.status}
                      </span>
                    </div>
                    <div className="mt-2 grid grid-cols-2 gap-4 text-sm">
                      <div>
                        <p className="text-gray-500">Requested Quantity</p>
                        <p className="font-medium">{formatWeight(apt.requestedQuantity)}</p>
                      </div>
                      <div>
                        <p className="text-gray-500">Scheduled Date</p>
                        <p className="font-medium">{formatDateTime(apt.scheduledDate)}</p>
                      </div>
                      {apt.actualQuantity && (
                        <div>
                          <p className="text-gray-500">Delivered Quantity</p>
                          <p className="font-medium">{formatWeight(apt.actualQuantity)}</p>
                        </div>
                      )}
                      <div>
                        <p className="text-gray-500">Zone</p>
                        <p className="font-medium">{apt.warehouseZone?.name}</p>
                      </div>
                    </div>
                    {apt.notes && (
                      <div className="mt-2">
                        <p className="text-sm text-gray-500">Notes</p>
                        <p className="text-sm">{apt.notes}</p>
                      </div>
                    )}
                  </div>
                  {apt.status === 'SCHEDULED' && (
                    <button
                      onClick={() => handleCancel(apt.id)}
                      className="btn btn-danger ml-4"
                    >
                      Cancel
                    </button>
                  )}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </Layout>
  );
};

export default FarmerAppointments;
