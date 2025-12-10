import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import Layout from '../../components/Layout';
import ErrorMessage from '../../components/ErrorMessage';
import SuccessMessage from '../../components/SuccessMessage';
import AlgeriaMap from '../../components/AlgeriaMap';
import TimeSlotPicker from '../../components/TimeSlotPicker';
import { appointmentAPI, waitingListAPI } from '../../services/api';
import { GRAIN_TYPES } from '../../utils/constants';
import { useAuth } from '../../context/AuthContext';

const STEPS = {
  SELECT_GRAIN: 1,
  SELECT_WAREHOUSE: 2,
  SELECT_TIMESLOT: 3,
  CONFIRM: 4
};

const NewAppointment = () => {
  const [currentStep, setCurrentStep] = useState(STEPS.SELECT_GRAIN);
  const [formData, setFormData] = useState({
    grainType: '',
    requestedQuantity: '',
    warehouseZoneId: null,
    timeSlotId: null
  });
  const [selectedWarehouse, setSelectedWarehouse] = useState(null);
  const [selectedTimeSlot, setSelectedTimeSlot] = useState(null);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [loading, setLoading] = useState(false);
  const [showWaitingListModal, setShowWaitingListModal] = useState(false);
  const [waitingListSlot, setWaitingListSlot] = useState(null);
  const { user } = useAuth();
  const navigate = useNavigate();

  const handleGrainSelection = (e) => {
    e.preventDefault();
    if (!formData.grainType || !formData.requestedQuantity) {
      setError('Please select grain type and enter quantity');
      return;
    }
    setError('');
    setCurrentStep(STEPS.SELECT_WAREHOUSE);
  };

  const handleWarehouseSelection = (warehouse) => {
    setSelectedWarehouse(warehouse);
    setFormData({ ...formData, warehouseZoneId: warehouse.id });
    setCurrentStep(STEPS.SELECT_TIMESLOT);
  };

  const handleTimeSlotSelection = (slot) => {
    setSelectedTimeSlot(slot);
    setFormData({ ...formData, timeSlotId: slot.id });
    setCurrentStep(STEPS.CONFIRM);
  };

  const handleWaitingListRequest = (slot) => {
    setWaitingListSlot(slot);
    setShowWaitingListModal(true);
  };

  const joinWaitingList = async () => {
    try {
      setLoading(true);
      await waitingListAPI.join({
        appointmentId: null, // Will be created by backend
        warehouseZoneId: selectedWarehouse.id,
        timeSlotId: waitingListSlot.id,
        grainType: formData.grainType,
        requestedQuantity: parseFloat(formData.requestedQuantity)
      });

      setSuccess('Successfully joined the waiting list! We will notify you when a slot becomes available.');
      setTimeout(() => {
        navigate('/farmer/appointments');
      }, 2000);
    } catch (err) {
      setError(err.response?.data?.message || 'Failed to join waiting list');
    } finally {
      setLoading(false);
      setShowWaitingListModal(false);
    }
  };

  const handleSubmit = async () => {
    if (user.isSuspended) {
      setError('Your account is suspended. Please contact the warehouse administrator.');
      return;
    }

    setLoading(true);
    setError('');
    setSuccess('');

    try {
      await appointmentAPI.create({
        grainType: formData.grainType,
        requestedQuantity: parseFloat(formData.requestedQuantity),
        warehouseZoneId: formData.warehouseZoneId,
        timeSlotId: formData.timeSlotId
      });

      setSuccess('Appointment scheduled successfully!');
      setTimeout(() => {
        navigate('/farmer/appointments');
      }, 2000);
    } catch (err) {
      setError(err.response?.data?.message || 'Failed to schedule appointment');
    } finally {
      setLoading(false);
    }
  };

  const goBack = () => {
    setError('');
    if (currentStep > STEPS.SELECT_GRAIN) {
      setCurrentStep(currentStep - 1);
    }
  };

  return (
    <Layout>
      <div className="max-w-6xl mx-auto">
        <h1 className="text-3xl font-bold text-gray-900 mb-6">Schedule New Appointment</h1>

        {/* Progress Steps */}
        <div className="mb-8">
          <div className="flex items-center justify-between">
            {[
              { step: STEPS.SELECT_GRAIN, label: 'Grain & Quantity' },
              { step: STEPS.SELECT_WAREHOUSE, label: 'Select Warehouse' },
              { step: STEPS.SELECT_TIMESLOT, label: 'Select Time Slot' },
              { step: STEPS.CONFIRM, label: 'Confirm' }
            ].map((item, index) => (
              <div key={item.step} className="flex items-center flex-1">
                <div className="flex flex-col items-center flex-1">
                  <div
                    className={`w-10 h-10 rounded-full flex items-center justify-center font-bold ${
                      currentStep >= item.step
                        ? 'bg-green-500 text-white'
                        : 'bg-gray-300 text-gray-600'
                    }`}
                  >
                    {item.step}
                  </div>
                  <span className={`mt-2 text-sm ${
                    currentStep >= item.step ? 'text-green-600 font-medium' : 'text-gray-500'
                  }`}>
                    {item.label}
                  </span>
                </div>
                {index < 3 && (
                  <div
                    className={`h-1 flex-1 ${
                      currentStep > item.step ? 'bg-green-500' : 'bg-gray-300'
                    }`}
                  />
                )}
              </div>
            ))}
          </div>
        </div>

        <ErrorMessage message={error} />
        <SuccessMessage message={success} />

        {/* Step 1: Select Grain Type and Quantity */}
        {currentStep === STEPS.SELECT_GRAIN && (
          <div className="card">
            <h2 className="text-xl font-semibold text-gray-900 mb-6">Select Grain Type and Quantity</h2>
            <form onSubmit={handleGrainSelection} className="space-y-6">
              <div>
                <label htmlFor="grainType" className="label">
                  Grain Type
                </label>
                <select
                  id="grainType"
                  name="grainType"
                  required
                  className="input"
                  value={formData.grainType}
                  onChange={(e) => setFormData({ ...formData, grainType: e.target.value })}
                >
                  <option value="">Select grain type</option>
                  {GRAIN_TYPES.map((type) => (
                    <option key={type.value} value={type.value}>
                      {type.label}
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label htmlFor="requestedQuantity" className="label">
                  Requested Quantity (tons)
                </label>
                <input
                  id="requestedQuantity"
                  name="requestedQuantity"
                  type="number"
                  step="0.01"
                  min="0.1"
                  required
                  className="input"
                  value={formData.requestedQuantity}
                  onChange={(e) => setFormData({ ...formData, requestedQuantity: e.target.value })}
                  placeholder="Enter quantity in tons"
                />
              </div>

              <div className="flex space-x-4">
                <button
                  type="submit"
                  className="btn btn-primary flex-1"
                >
                  Next: Select Warehouse
                </button>
                <button
                  type="button"
                  onClick={() => navigate('/farmer/appointments')}
                  className="btn btn-secondary"
                >
                  Cancel
                </button>
              </div>
            </form>
          </div>
        )}

        {/* Step 2: Select Warehouse */}
        {currentStep === STEPS.SELECT_WAREHOUSE && (
          <div className="space-y-4">
            <div className="flex justify-between items-center">
              <h2 className="text-xl font-semibold text-gray-900">Select Nearest Warehouse</h2>
              <button onClick={goBack} className="btn btn-secondary">
                Back
              </button>
            </div>

            <div className="bg-blue-50 border border-blue-200 rounded-lg p-4 mb-4">
              <p className="text-blue-900">
                <strong>Selected:</strong> {formData.grainType} - {formData.requestedQuantity} tons
              </p>
            </div>

            <AlgeriaMap
              grainType={formData.grainType}
              onWarehouseSelect={handleWarehouseSelection}
            />
          </div>
        )}

        {/* Step 3: Select Time Slot */}
        {currentStep === STEPS.SELECT_TIMESLOT && (
          <div className="space-y-4">
            <div className="flex justify-between items-center">
              <h2 className="text-xl font-semibold text-gray-900">Select Time Slot</h2>
              <button onClick={goBack} className="btn btn-secondary">
                Back
              </button>
            </div>

            <div className="bg-blue-50 border border-blue-200 rounded-lg p-4 mb-4">
              <p className="text-blue-900 font-medium">
                {selectedWarehouse?.name}
              </p>
              <p className="text-blue-800 text-sm">
                {formData.grainType} - {formData.requestedQuantity} tons | Distance: {selectedWarehouse?.distance?.toFixed(1)} km
              </p>
            </div>

            <div className="card">
              <TimeSlotPicker
                warehouseZoneId={formData.warehouseZoneId}
                grainType={formData.grainType}
                onSlotSelect={handleTimeSlotSelection}
                onWaitingListRequest={handleWaitingListRequest}
              />
            </div>
          </div>
        )}

        {/* Step 4: Confirm */}
        {currentStep === STEPS.CONFIRM && (
          <div className="card">
            <h2 className="text-xl font-semibold text-gray-900 mb-6">Confirm Appointment</h2>

            <div className="space-y-6">
              <div className="bg-gray-50 rounded-lg p-6 space-y-4">
                <div>
                  <h3 className="text-sm font-medium text-gray-600">Warehouse</h3>
                  <p className="text-lg font-semibold text-gray-900">{selectedWarehouse?.name}</p>
                  <p className="text-sm text-gray-600">
                    Distance: {selectedWarehouse?.distance?.toFixed(1)} km
                  </p>
                  {selectedWarehouse?.address && (
                    <p className="text-sm text-gray-600">{selectedWarehouse.address}</p>
                  )}
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <h3 className="text-sm font-medium text-gray-600">Grain Type</h3>
                    <p className="text-lg font-semibold text-gray-900">{formData.grainType}</p>
                  </div>
                  <div>
                    <h3 className="text-sm font-medium text-gray-600">Quantity</h3>
                    <p className="text-lg font-semibold text-gray-900">{formData.requestedQuantity} tons</p>
                  </div>
                </div>

                <div>
                  <h3 className="text-sm font-medium text-gray-600">Date & Time</h3>
                  <p className="text-lg font-semibold text-gray-900">
                    {selectedTimeSlot?.date}
                  </p>
                  <p className="text-lg font-semibold text-gray-900">
                    {selectedTimeSlot?.startTime} - {selectedTimeSlot?.endTime}
                  </p>
                </div>
              </div>

              <div className="flex space-x-4">
                <button
                  onClick={handleSubmit}
                  disabled={loading}
                  className="btn btn-primary flex-1 disabled:opacity-50"
                >
                  {loading ? 'Scheduling...' : 'Confirm Appointment'}
                </button>
                <button
                  onClick={goBack}
                  disabled={loading}
                  className="btn btn-secondary"
                >
                  Back
                </button>
              </div>
            </div>
          </div>
        )}

        {/* Waiting List Modal */}
        {showWaitingListModal && (
          <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
            <div className="bg-white rounded-lg p-6 max-w-md w-full mx-4">
              <h3 className="text-xl font-bold text-gray-900 mb-4">Time Slot Full</h3>
              <p className="text-gray-700 mb-4">
                This time slot is currently full. Would you like to join the waiting list?
                You will be notified if a spot becomes available.
              </p>

              <div className="bg-blue-50 border border-blue-200 rounded-lg p-4 mb-4">
                <p className="text-sm text-blue-900">
                  <strong>Time Slot:</strong> {waitingListSlot?.startTime} - {waitingListSlot?.endTime}
                </p>
                <p className="text-sm text-blue-800 mt-1">
                  Maximum 5 farmers per waiting list. You'll have 2 hours to confirm if a spot opens.
                </p>
              </div>

              <div className="flex space-x-4">
                <button
                  onClick={joinWaitingList}
                  disabled={loading}
                  className="btn btn-primary flex-1 disabled:opacity-50"
                >
                  {loading ? 'Joining...' : 'Join Waiting List'}
                </button>
                <button
                  onClick={() => setShowWaitingListModal(false)}
                  disabled={loading}
                  className="btn btn-secondary"
                >
                  Cancel
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
    </Layout>
  );
};

export default NewAppointment;
