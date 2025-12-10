import { useState, useEffect } from 'react';
import { timeSlotAPI } from '../services/api';
import { format, addDays, startOfWeek, isBefore, startOfDay } from 'date-fns';

export default function TimeSlotPicker({ warehouseZoneId, grainType, onSlotSelect, onWaitingListRequest }) {
  const [selectedDate, setSelectedDate] = useState(new Date());
  const [timeSlots, setTimeSlots] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  useEffect(() => {
    if (warehouseZoneId) {
      fetchTimeSlots();
    }
  }, [selectedDate, warehouseZoneId, grainType]);

  const fetchTimeSlots = async () => {
    try {
      setLoading(true);
      setError(null);
      const response = await timeSlotAPI.getAvailable({
        warehouseZoneId,
        date: format(selectedDate, 'yyyy-MM-dd'),
        grainType
      });
      setTimeSlots(response.data.timeSlots || []);
    } catch (err) {
      setError(err.response?.data?.message || 'Failed to fetch time slots');
      setTimeSlots([]);
    } finally {
      setLoading(false);
    }
  };

  const getOccupancyColor = (slot) => {
    const rate = (slot.currentAppointments / slot.maxAppointments) * 100;
    if (rate >= 100) return 'bg-red-100 border-red-500 text-red-900';
    if (rate >= 60) return 'bg-yellow-100 border-yellow-500 text-yellow-900';
    return 'bg-green-100 border-green-500 text-green-900';
  };

  const getOccupancyLabel = (slot) => {
    const available = slot.maxAppointments - slot.currentAppointments;
    if (available === 0) return 'Full';
    if (available === 1) return '1 spot left';
    return `${available} spots left`;
  };

  const handleSlotClick = (slot) => {
    const available = slot.maxAppointments - slot.currentAppointments;
    if (available > 0) {
      onSlotSelect(slot);
    } else {
      if (onWaitingListRequest) {
        onWaitingListRequest(slot);
      }
    }
  };

  const generateWeekDays = () => {
    const start = startOfWeek(new Date(), { weekStartsOn: 0 }); // Sunday
    return Array.from({ length: 7 }, (_, i) => addDays(start, i));
  };

  const weekDays = generateWeekDays();
  const today = startOfDay(new Date());

  return (
    <div className="space-y-6">
      {/* Date Selection */}
      <div>
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Select a Date</h3>
        <div className="grid grid-cols-7 gap-2">
          {weekDays.map((day) => {
            const isPast = isBefore(day, today);
            const isSelected = format(day, 'yyyy-MM-dd') === format(selectedDate, 'yyyy-MM-dd');

            return (
              <button
                key={day.toString()}
                onClick={() => !isPast && setSelectedDate(day)}
                disabled={isPast}
                className={`
                  p-3 rounded-lg border-2 text-center transition-all
                  ${isPast ? 'bg-gray-100 text-gray-400 cursor-not-allowed opacity-50' : ''}
                  ${isSelected && !isPast ? 'bg-green-500 text-white border-green-600' : ''}
                  ${!isSelected && !isPast ? 'bg-white border-gray-300 hover:border-green-500 hover:bg-green-50' : ''}
                `}
              >
                <div className="text-xs font-medium">{format(day, 'EEE')}</div>
                <div className="text-lg font-bold mt-1">{format(day, 'd')}</div>
                <div className="text-xs">{format(day, 'MMM')}</div>
              </button>
            );
          })}
        </div>
      </div>

      {/* Time Slots */}
      <div>
        <h3 className="text-lg font-semibold text-gray-900 mb-4">
          Available Time Slots for {format(selectedDate, 'MMMM d, yyyy')}
        </h3>

        {loading && (
          <div className="text-center py-8">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-green-500 mx-auto"></div>
            <p className="mt-2 text-gray-600">Loading time slots...</p>
          </div>
        )}

        {error && (
          <div className="bg-red-50 border border-red-200 rounded-lg p-4 text-red-800">
            {error}
          </div>
        )}

        {!loading && !error && timeSlots.length === 0 && (
          <div className="bg-gray-50 border border-gray-200 rounded-lg p-8 text-center">
            <p className="text-gray-600">No time slots available for this date.</p>
            <p className="text-sm text-gray-500 mt-2">Please select a different date or contact the warehouse.</p>
          </div>
        )}

        {!loading && !error && timeSlots.length > 0 && (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {timeSlots.map((slot) => {
              const available = slot.maxAppointments - slot.currentAppointments;
              const isFull = available === 0;

              return (
                <button
                  key={slot.id}
                  onClick={() => handleSlotClick(slot)}
                  className={`
                    p-4 rounded-lg border-2 text-left transition-all
                    ${getOccupancyColor(slot)}
                    ${isFull ? 'cursor-pointer' : 'hover:shadow-md'}
                  `}
                >
                  <div className="flex items-center justify-between mb-2">
                    <span className="text-lg font-bold">
                      {slot.startTime} - {slot.endTime}
                    </span>
                    {isFull && (
                      <span className="text-xs bg-red-500 text-white px-2 py-1 rounded">
                        Full
                      </span>
                    )}
                  </div>

                  <div className="text-sm font-medium mb-1">
                    {getOccupancyLabel(slot)}
                  </div>

                  <div className="flex items-center justify-between text-xs">
                    <span>{slot.currentAppointments}/{slot.maxAppointments} booked</span>
                    {isFull && (
                      <span className="font-medium">Join Waiting List</span>
                    )}
                  </div>

                  {/* Progress bar */}
                  <div className="mt-2 bg-white rounded-full h-2 overflow-hidden">
                    <div
                      className={`h-full transition-all ${
                        available === 0 ? 'bg-red-500' :
                        available <= 2 ? 'bg-yellow-500' :
                        'bg-green-500'
                      }`}
                      style={{ width: `${(slot.currentAppointments / slot.maxAppointments) * 100}%` }}
                    />
                  </div>
                </button>
              );
            })}
          </div>
        )}
      </div>

      {/* Legend */}
      <div className="flex items-center justify-center gap-6 pt-4 border-t">
        <div className="flex items-center gap-2">
          <div className="w-4 h-4 bg-green-500 rounded"></div>
          <span className="text-sm text-gray-600">Available</span>
        </div>
        <div className="flex items-center gap-2">
          <div className="w-4 h-4 bg-yellow-500 rounded"></div>
          <span className="text-sm text-gray-600">Limited</span>
        </div>
        <div className="flex items-center gap-2">
          <div className="w-4 h-4 bg-red-500 rounded"></div>
          <span className="text-sm text-gray-600">Full</span>
        </div>
      </div>
    </div>
  );
}
