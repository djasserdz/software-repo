import React from 'react';
import { Link, useNavigate, useLocation } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

const Layout = ({ children }) => {
  const { user, logout, isFarmer, isWarehouseAdmin, isSystemAdmin } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  const navigation = [
    ...(isFarmer ? [
      { name: 'Dashboard', path: '/farmer/dashboard' },
      { name: 'Appointments', path: '/farmer/appointments' },
      { name: 'Waiting Lists', path: '/farmer/waiting-lists' },
      { name: 'History', path: '/farmer/history' },
      { name: 'Profile', path: '/farmer/profile' }
    ] : []),
    ...(isWarehouseAdmin ? [
      { name: 'Dashboard', path: '/warehouse/dashboard' },
      { name: 'Appointments', path: '/warehouse/appointments' },
      { name: 'Deliveries', path: '/warehouse/deliveries' },
      { name: 'Storage', path: '/warehouse/storage' },
      { name: 'Profile', path: '/warehouse/profile' }
    ] : []),
    ...(isSystemAdmin ? [
      { name: 'Dashboard', path: '/admin/dashboard' },
      { name: 'Warehouse Admins', path: '/admin/warehouse-admins' },
      { name: 'Profile', path: '/admin/profile' }
    ] : [])
  ];

  return (
    <div className="min-h-screen bg-gray-50">
      <nav className="bg-white shadow-sm border-b border-gray-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between h-16">
            <div className="flex">
              <div className="flex-shrink-0 flex items-center">
                <span className="text-2xl font-bold text-primary-600">MAHSOULE</span>
              </div>
              <div className="hidden sm:ml-8 sm:flex sm:space-x-8">
                {navigation.map((item) => (
                  <Link
                    key={item.path}
                    to={item.path}
                    className={`inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium ${
                      location.pathname === item.path
                        ? 'border-primary-500 text-gray-900'
                        : 'border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700'
                    }`}
                  >
                    {item.name}
                  </Link>
                ))}
              </div>
            </div>
            <div className="flex items-center space-x-4">
              <div className="text-sm text-gray-700">
                <span className="font-medium">{user?.firstName} {user?.lastName}</span>
                <span className="ml-2 text-gray-500">({user?.role.replace('_', ' ')})</span>
              </div>
              <button
                onClick={handleLogout}
                className="btn btn-secondary text-sm"
              >
                Logout
              </button>
            </div>
          </div>
        </div>
      </nav>

      <main className="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
        {children}
      </main>
    </div>
  );
};

export default Layout;
