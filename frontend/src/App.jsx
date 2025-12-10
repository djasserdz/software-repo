import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider } from './context/AuthContext';
import ProtectedRoute from './components/ProtectedRoute';

// Auth pages
import Login from './pages/Login';
import Register from './pages/Register';

// Shared pages
import Profile from './pages/Profile';

// Farmer pages
import FarmerDashboard from './pages/farmer/FarmerDashboard';
import FarmerAppointments from './pages/farmer/FarmerAppointments';
import NewAppointment from './pages/farmer/NewAppointment';
import WaitingLists from './pages/farmer/WaitingLists';

// Warehouse pages
import WarehouseDashboard from './pages/warehouse/WarehouseDashboard';
import WarehouseAppointments from './pages/warehouse/WarehouseAppointments';
import RecordDelivery from './pages/warehouse/RecordDelivery';
import ZoneManagement from './pages/warehouse/ZoneManagement';

// Admin pages
import AdminDashboard from './pages/admin/AdminDashboard';

function App() {
  return (
    <AuthProvider>
      <Router>
        <Routes>
          <Route path="/login" element={<Login />} />
          <Route path="/register" element={<Register />} />

          {/* Farmer Routes */}
          <Route
            path="/farmer/dashboard"
            element={
              <ProtectedRoute allowedRoles={['FARMER']}>
                <FarmerDashboard />
              </ProtectedRoute>
            }
          />
          <Route
            path="/farmer/appointments"
            element={
              <ProtectedRoute allowedRoles={['FARMER']}>
                <FarmerAppointments />
              </ProtectedRoute>
            }
          />
          <Route
            path="/farmer/appointments/new"
            element={
              <ProtectedRoute allowedRoles={['FARMER']}>
                <NewAppointment />
              </ProtectedRoute>
            }
          />
          <Route
            path="/farmer/history"
            element={
              <ProtectedRoute allowedRoles={['FARMER']}>
                <FarmerAppointments />
              </ProtectedRoute>
            }
          />
          <Route
            path="/farmer/waiting-lists"
            element={
              <ProtectedRoute allowedRoles={['FARMER']}>
                <WaitingLists />
              </ProtectedRoute>
            }
          />
          <Route
            path="/farmer/profile"
            element={
              <ProtectedRoute allowedRoles={['FARMER']}>
                <Profile />
              </ProtectedRoute>
            }
          />

          {/* Warehouse Admin Routes */}
          <Route
            path="/warehouse/dashboard"
            element={
              <ProtectedRoute allowedRoles={['WAREHOUSE_ADMIN']}>
                <WarehouseDashboard />
              </ProtectedRoute>
            }
          />
          <Route
            path="/warehouse/appointments"
            element={
              <ProtectedRoute allowedRoles={['WAREHOUSE_ADMIN']}>
                <WarehouseAppointments />
              </ProtectedRoute>
            }
          />
          <Route
            path="/warehouse/deliveries"
            element={
              <ProtectedRoute allowedRoles={['WAREHOUSE_ADMIN']}>
                <RecordDelivery />
              </ProtectedRoute>
            }
          />
          <Route
            path="/warehouse/storage"
            element={
              <ProtectedRoute allowedRoles={['WAREHOUSE_ADMIN']}>
                <ZoneManagement />
              </ProtectedRoute>
            }
          />
          <Route
            path="/warehouse/profile"
            element={
              <ProtectedRoute allowedRoles={['WAREHOUSE_ADMIN']}>
                <Profile />
              </ProtectedRoute>
            }
          />

          {/* System Admin Routes */}
          <Route
            path="/admin/dashboard"
            element={
              <ProtectedRoute allowedRoles={['SYSTEM_ADMIN']}>
                <AdminDashboard />
              </ProtectedRoute>
            }
          />
          <Route
            path="/admin/warehouse-admins"
            element={
              <ProtectedRoute allowedRoles={['SYSTEM_ADMIN']}>
                <AdminDashboard />
              </ProtectedRoute>
            }
          />
          <Route
            path="/admin/profile"
            element={
              <ProtectedRoute allowedRoles={['SYSTEM_ADMIN']}>
                <Profile />
              </ProtectedRoute>
            }
          />

          {/* Default redirect */}
          <Route path="/" element={<Navigate to="/login" replace />} />
          <Route path="*" element={<Navigate to="/login" replace />} />
        </Routes>
      </Router>
    </AuthProvider>
  );
}

export default App;
