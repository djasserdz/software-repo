import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import Layout from '../../components/Layout';
import LoadingSpinner from '../../components/LoadingSpinner';
import { appointmentAPI, deliveryAPI } from '../../services/api';
import { useAuth } from '../../context/AuthContext';
import { formatDateTime, formatWeight } from '../../utils/formatters';
import { APPOINTMENT_STATUS_COLORS } from '../../utils/constants';

const FarmerDashboard = () => {
  const [stats, setStats] = useState(null);
  const [upcomingAppointments, setUpcomingAppointments] = useState([]);
  const [recentDeliveries, setRecentDeliveries] = useState([]);
  const [loading, setLoading] = useState(true);
  const { user } = useAuth();

  useEffect(() => {
    fetchDashboardData();
  }, []);

  const fetchDashboardData = async () => {
    try {
      const [appointmentsRes, deliveriesRes] = await Promise.all([
        appointmentAPI.getMyAppointments(),
        deliveryAPI.getMyDeliveries()
      ]);

      const appointments = appointmentsRes.data.appointments;
      const deliveries = deliveriesRes.data.deliveries;

      const upcoming = appointments
        .filter(apt => apt.status === 'SCHEDULED')
        .slice(0, 5);

      const recent = deliveries.slice(0, 5);

      const totalDelivered = deliveries.reduce((sum, d) => sum + d.quantity, 0);

      setStats({
        totalAppointments: appointments.length,
        scheduledAppointments: appointments.filter(a => a.status === 'SCHEDULED').length,
        completedAppointments: appointments.filter(a => a.status === 'COMPLETED').length,
        totalDelivered,
        missedAppointments: user.missedAppointmentsCount || 0
      });

      setUpcomingAppointments(upcoming);
      setRecentDeliveries(recent);
    } catch (error) {
      console.error('Failed to fetch dashboard data:', error);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <Layout>
        <LoadingSpinner message="Loading dashboard..." />
      </Layout>
    );
  }

  return (
    <Layout>
      <div className="space-y-6">
        <div className="flex justify-between items-center">
          <h1 className="text-3xl font-bold text-gray-900">Dashboard</h1>
          <Link to="/farmer/appointments/new" className="btn btn-primary">
            Schedule New Appointment
          </Link>
        </div>

        {user.isSuspended && (
          <div className="bg-red-50 border border-red-200 rounded-lg p-4">
            <h3 className="text-red-800 font-semibold">Account Suspended</h3>
            <p className="text-red-700 text-sm mt-1">{user.suspensionReason}</p>
            <p className="text-red-600 text-sm mt-2">
              Please contact the warehouse administrator to reactivate your account.
            </p>
          </div>
        )}

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          <div className="card">
            <h3 className="text-sm font-medium text-gray-500">Total Appointments</h3>
            <p className="mt-2 text-3xl font-bold text-gray-900">{stats.totalAppointments}</p>
          </div>
          <div className="card">
            <h3 className="text-sm font-medium text-gray-500">Scheduled</h3>
            <p className="mt-2 text-3xl font-bold text-blue-600">{stats.scheduledAppointments}</p>
          </div>
          <div className="card">
            <h3 className="text-sm font-medium text-gray-500">Completed</h3>
            <p className="mt-2 text-3xl font-bold text-green-600">{stats.completedAppointments}</p>
          </div>
          <div className="card">
            <h3 className="text-sm font-medium text-gray-500">Total Delivered</h3>
            <p className="mt-2 text-3xl font-bold text-primary-600">{formatWeight(stats.totalDelivered)}</p>
          </div>
        </div>

        {stats.missedAppointments > 0 && (
          <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4">
            <p className="text-yellow-800">
              You have missed {stats.missedAppointments} appointment(s).
              {stats.missedAppointments >= 3 ? ' Your account has been suspended.' :
                ` ${3 - stats.missedAppointments} more missed appointment(s) will result in suspension.`}
            </p>
          </div>
        )}

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <div className="card">
            <h2 className="text-xl font-semibold text-gray-900 mb-4">Upcoming Appointments</h2>
            {upcomingAppointments.length === 0 ? (
              <p className="text-gray-500">No upcoming appointments</p>
            ) : (
              <div className="space-y-3">
                {upcomingAppointments.map((apt) => (
                  <div key={apt.id} className="border border-gray-200 rounded-lg p-3">
                    <div className="flex justify-between items-start">
                      <div>
                        <p className="font-medium text-gray-900">{apt.grainType}</p>
                        <p className="text-sm text-gray-600">{formatWeight(apt.requestedQuantity)}</p>
                        <p className="text-xs text-gray-500 mt-1">{formatDateTime(apt.scheduledDate)}</p>
                      </div>
                      <span className={`badge ${APPOINTMENT_STATUS_COLORS[apt.status]}`}>
                        {apt.status}
                      </span>
                    </div>
                  </div>
                ))}
              </div>
            )}
            <Link to="/farmer/appointments" className="text-primary-600 hover:text-primary-700 text-sm font-medium mt-4 inline-block">
              View all appointments →
            </Link>
          </div>

          <div className="card">
            <h2 className="text-xl font-semibold text-gray-900 mb-4">Recent Deliveries</h2>
            {recentDeliveries.length === 0 ? (
              <p className="text-gray-500">No deliveries yet</p>
            ) : (
              <div className="space-y-3">
                {recentDeliveries.map((delivery) => (
                  <div key={delivery.id} className="border border-gray-200 rounded-lg p-3">
                    <div className="flex justify-between items-start">
                      <div>
                        <p className="font-medium text-gray-900">{delivery.grainType}</p>
                        <p className="text-sm text-gray-600">{formatWeight(delivery.quantity)}</p>
                        <p className="text-xs text-gray-500 mt-1">{formatDateTime(delivery.deliveryDate)}</p>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}
            <Link to="/farmer/history" className="text-primary-600 hover:text-primary-700 text-sm font-medium mt-4 inline-block">
              View history →
            </Link>
          </div>
        </div>
      </div>
    </Layout>
  );
};

export default FarmerDashboard;
