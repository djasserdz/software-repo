import React, { useEffect, useState } from 'react';
import Layout from '../../components/Layout';
import LoadingSpinner from '../../components/LoadingSpinner';
import { appointmentAPI, deliveryAPI } from '../../services/api';
import { formatDate, formatWeight, formatNumber } from '../../utils/formatters';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';

const WarehouseDashboard = () => {
  const [stats, setStats] = useState(null);
  const [storageData, setStorageData] = useState(null);
  const [todayAppointments, setTodayAppointments] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchDashboardData();
  }, []);

  const fetchDashboardData = async () => {
    try {
      const [appointmentsRes, storageRes] = await Promise.all([
        appointmentAPI.getAll({ status: 'SCHEDULED' }),
        deliveryAPI.getStorageReport()
      ]);

      const appointments = appointmentsRes.data.appointments;
      const storage = storageRes.data.statistics;

      const today = new Date().toISOString().split('T')[0];
      const todayApts = appointments.filter(apt =>
        apt.scheduledDate.startsWith(today)
      );

      setStats({
        totalAppointments: appointments.length,
        todayAppointments: todayApts.length,
        utilizationRate: storage.utilizationRate,
        totalCapacity: storage.totalCapacity,
        currentCapacity: storage.currentCapacity
      });

      setStorageData(storage.zoneDetails);
      setTodayAppointments(todayApts.slice(0, 5));
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
        <h1 className="text-3xl font-bold text-gray-900">Warehouse Dashboard</h1>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          <div className="card">
            <h3 className="text-sm font-medium text-gray-500">Scheduled Appointments</h3>
            <p className="mt-2 text-3xl font-bold text-gray-900">{stats.totalAppointments}</p>
          </div>
          <div className="card">
            <h3 className="text-sm font-medium text-gray-500">Today's Appointments</h3>
            <p className="mt-2 text-3xl font-bold text-blue-600">{stats.todayAppointments}</p>
          </div>
          <div className="card">
            <h3 className="text-sm font-medium text-gray-500">Storage Utilization</h3>
            <p className="mt-2 text-3xl font-bold text-primary-600">{stats.utilizationRate}%</p>
          </div>
          <div className="card">
            <h3 className="text-sm font-medium text-gray-500">Available Capacity</h3>
            <p className="mt-2 text-3xl font-bold text-green-600">
              {formatWeight(stats.totalCapacity - stats.currentCapacity)}
            </p>
          </div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <div className="card">
            <h2 className="text-xl font-semibold text-gray-900 mb-4">Storage by Zone</h2>
            <ResponsiveContainer width="100%" height={300}>
              <BarChart data={storageData}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="grainType" />
                <YAxis />
                <Tooltip />
                <Legend />
                <Bar dataKey="currentCapacity" fill="#16a34a" name="Current" />
                <Bar dataKey="availableCapacity" fill="#d1d5db" name="Available" />
              </BarChart>
            </ResponsiveContainer>
          </div>

          <div className="card">
            <h2 className="text-xl font-semibold text-gray-900 mb-4">Today's Appointments</h2>
            {todayAppointments.length === 0 ? (
              <p className="text-gray-500">No appointments scheduled for today</p>
            ) : (
              <div className="space-y-3">
                {todayAppointments.map((apt) => (
                  <div key={apt.id} className="border border-gray-200 rounded-lg p-3">
                    <div className="flex justify-between items-start">
                      <div>
                        <p className="font-medium text-gray-900">
                          {apt.farmer?.firstName} {apt.farmer?.lastName}
                        </p>
                        <p className="text-sm text-gray-600">
                          {apt.grainType} - {formatWeight(apt.requestedQuantity)}
                        </p>
                        <p className="text-xs text-gray-500">{apt.farmer?.phone}</p>
                      </div>
                      <span className="badge bg-blue-100 text-blue-800">
                        {new Date(apt.scheduledDate).toLocaleTimeString('en-US', {
                          hour: '2-digit',
                          minute: '2-digit'
                        })}
                      </span>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>

        <div className="card">
          <h2 className="text-xl font-semibold text-gray-900 mb-4">Zone Details</h2>
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Zone</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Grain Type</th>
                  <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase">Capacity</th>
                  <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase">Current</th>
                  <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase">Available</th>
                  <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase">Utilization</th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {storageData.map((zone) => (
                  <tr key={zone.id}>
                    <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                      {zone.name}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {zone.grainType}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500 text-right">
                      {formatNumber(zone.maxCapacity)} kg
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500 text-right">
                      {formatNumber(zone.currentCapacity)} kg
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500 text-right">
                      {formatNumber(zone.availableCapacity)} kg
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500 text-right">
                      <span className={`font-medium ${
                        zone.utilizationRate > 90 ? 'text-red-600' :
                        zone.utilizationRate > 70 ? 'text-yellow-600' :
                        'text-green-600'
                      }`}>
                        {zone.utilizationRate}%
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </Layout>
  );
};

export default WarehouseDashboard;
