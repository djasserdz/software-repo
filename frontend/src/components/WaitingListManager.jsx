import { useState, useEffect } from 'react';
import { waitingListAPI } from '../services/api';
import { format, formatDistanceToNow } from 'date-fns';

export default function WaitingListManager() {
  const [waitingLists, setWaitingLists] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [actionLoading, setActionLoading] = useState(null);

  useEffect(() => {
    fetchMyWaitingLists();
  }, []);

  const fetchMyWaitingLists = async () => {
    try {
      setLoading(true);
      setError(null);
      const response = await waitingListAPI.getMyList();
      setWaitingLists(response.data.waitingLists || []);
    } catch (err) {
      setError(err.response?.data?.message || 'Failed to fetch waiting lists');
    } finally {
      setLoading(false);
    }
  };

  const handleConfirm = async (entryId) => {
    try {
      setActionLoading(entryId);
      await waitingListAPI.confirm(entryId);
      await fetchMyWaitingLists();
      alert('Time slot confirmed successfully! You can view your appointment in My Appointments.');
    } catch (err) {
      alert(err.response?.data?.message || 'Failed to confirm slot');
    } finally {
      setActionLoading(null);
    }
  };

  const handleDecline = async (entryId) => {
    if (!confirm('Are you sure you want to decline this time slot? You will lose your position in the waiting list.')) {
      return;
    }

    try {
      setActionLoading(entryId);
      await waitingListAPI.decline(entryId);
      await fetchMyWaitingLists();
      alert('Time slot declined. Your position has been removed from the waiting list.');
    } catch (err) {
      alert(err.response?.data?.message || 'Failed to decline slot');
    } finally {
      setActionLoading(null);
    }
  };

  const getStatusBadge = (status) => {
    const badges = {
      WAITING: { bg: 'bg-blue-100', text: 'text-blue-800', label: 'Waiting' },
      NOTIFIED: { bg: 'bg-yellow-100', text: 'text-yellow-800', label: 'Action Required' },
      CONFIRMED: { bg: 'bg-green-100', text: 'text-green-800', label: 'Confirmed' },
      DECLINED: { bg: 'bg-gray-100', text: 'text-gray-800', label: 'Declined' },
      EXPIRED: { bg: 'bg-red-100', text: 'text-red-800', label: 'Expired' },
    };

    const badge = badges[status] || badges.WAITING;

    return (
      <span className={`px-3 py-1 rounded-full text-sm font-medium ${badge.bg} ${badge.text}`}>
        {badge.label}
      </span>
    );
  };

  const getTimeRemaining = (expiresAt) => {
    if (!expiresAt) return null;
    const expiry = new Date(expiresAt);
    const now = new Date();

    if (expiry <= now) {
      return <span className="text-red-600 font-medium">Expired</span>;
    }

    return (
      <span className="text-orange-600 font-medium">
        Expires {formatDistanceToNow(expiry, { addSuffix: true })}
      </span>
    );
  };

  if (loading) {
    return (
      <div className="bg-white rounded-lg shadow p-6">
        <div className="text-center py-8">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-green-500 mx-auto"></div>
          <p className="mt-2 text-gray-600">Loading waiting lists...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="bg-white rounded-lg shadow p-6">
        <div className="bg-red-50 border border-red-200 rounded-lg p-4 text-red-800">
          {error}
        </div>
      </div>
    );
  }

  if (waitingLists.length === 0) {
    return (
      <div className="bg-white rounded-lg shadow p-6">
        <div className="text-center py-8">
          <svg className="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
          </svg>
          <h3 className="mt-2 text-sm font-medium text-gray-900">No waiting lists</h3>
          <p className="mt-1 text-sm text-gray-500">You are not on any waiting lists at the moment.</p>
        </div>
      </div>
    );
  }

  return (
    <div className="bg-white rounded-lg shadow">
      <div className="px-6 py-4 border-b border-gray-200">
        <h2 className="text-xl font-bold text-gray-900">My Waiting Lists</h2>
        <p className="mt-1 text-sm text-gray-600">
          Track your position in waiting lists and respond to slot availability
        </p>
      </div>

      <div className="divide-y divide-gray-200">
        {waitingLists.map((entry) => (
          <div key={entry.id} className="p-6">
            <div className="flex items-start justify-between">
              <div className="flex-1">
                <div className="flex items-center gap-3 mb-2">
                  <h3 className="text-lg font-semibold text-gray-900">
                    {entry.appointment?.warehouseZone?.name || 'Warehouse'}
                  </h3>
                  {getStatusBadge(entry.status)}
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mt-4">
                  <div>
                    <p className="text-sm text-gray-600">Date & Time</p>
                    <p className="font-medium">
                      {format(new Date(entry.appointment?.appointmentDate), 'MMM d, yyyy')}
                    </p>
                    <p className="font-medium">
                      {entry.appointment?.timeSlot?.startTime} - {entry.appointment?.timeSlot?.endTime}
                    </p>
                  </div>

                  <div>
                    <p className="text-sm text-gray-600">Grain Type</p>
                    <p className="font-medium">{entry.grainType}</p>
                  </div>

                  <div>
                    <p className="text-sm text-gray-600">Requested Quantity</p>
                    <p className="font-medium">{entry.requestedQuantity} tons</p>
                  </div>

                  <div>
                    <p className="text-sm text-gray-600">Position in Queue</p>
                    <p className="font-medium">#{entry.position}</p>
                  </div>
                </div>

                {entry.status === 'WAITING' && (
                  <div className="mt-4 bg-blue-50 border border-blue-200 rounded-lg p-4">
                    <p className="text-sm text-blue-800">
                      You are in position #{entry.position} in the waiting list. We will notify you when a slot becomes available.
                    </p>
                  </div>
                )}

                {entry.status === 'NOTIFIED' && (
                  <div className="mt-4 bg-yellow-50 border border-yellow-200 rounded-lg p-4">
                    <p className="text-sm text-yellow-800 mb-2">
                      <strong>A time slot is now available for you!</strong>
                    </p>
                    <p className="text-sm text-yellow-700 mb-3">
                      {getTimeRemaining(entry.expiresAt)}
                    </p>
                    <div className="flex gap-3">
                      <button
                        onClick={() => handleConfirm(entry.id)}
                        disabled={actionLoading === entry.id}
                        className="px-4 py-2 bg-green-500 text-white rounded-lg hover:bg-green-600 disabled:opacity-50"
                      >
                        {actionLoading === entry.id ? 'Processing...' : 'Confirm Slot'}
                      </button>
                      <button
                        onClick={() => handleDecline(entry.id)}
                        disabled={actionLoading === entry.id}
                        className="px-4 py-2 bg-gray-500 text-white rounded-lg hover:bg-gray-600 disabled:opacity-50"
                      >
                        Decline
                      </button>
                    </div>
                  </div>
                )}

                {entry.status === 'CONFIRMED' && (
                  <div className="mt-4 bg-green-50 border border-green-200 rounded-lg p-4">
                    <p className="text-sm text-green-800">
                      Time slot confirmed! Check your appointments to see the details.
                    </p>
                  </div>
                )}

                {entry.status === 'EXPIRED' && (
                  <div className="mt-4 bg-red-50 border border-red-200 rounded-lg p-4">
                    <p className="text-sm text-red-800">
                      This notification has expired. The slot was offered to the next person in line.
                    </p>
                  </div>
                )}

                {entry.notifiedAt && (
                  <p className="mt-2 text-xs text-gray-500">
                    Notified {formatDistanceToNow(new Date(entry.notifiedAt), { addSuffix: true })}
                  </p>
                )}
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
