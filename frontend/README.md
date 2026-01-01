# Mahsoul - Frontend Application

A modern Vue.js frontend application for the Mahsoul grain warehouse management system.

## Features

- 🔐 User Authentication (Login/Register)
- 📊 Dashboard with statistics and quick actions
- 🏢 Warehouse browsing and search
- 📅 Appointment booking and management
- 📦 Delivery tracking
- 👤 User profile management
- 📍 Geolocation-based warehouse search
- 🎨 Modern, responsive UI with Tailwind CSS

## Tech Stack

- **Vue 3** - Progressive JavaScript framework
- **Vite** - Next generation frontend tooling
- **Vue Router** - Official router for Vue.js
- **Pinia** - State management for Vue
- **Axios** - HTTP client
- **Tailwind CSS** - Utility-first CSS framework
- **Heroicons** - Beautiful SVG icons

## Prerequisites

- Node.js 16+ and npm/yarn
- Backend API running on `http://localhost:8000` (or configure via environment variable)

## Installation

1. Install dependencies:
```bash
npm install
```

2. Create a `.env` file (optional):
```bash
VITE_API_URL=http://localhost:8000
```

3. Start the development server:
```bash
npm run dev
```

The application will be available at `http://localhost:3000`

## Build for Production

```bash
npm run build
```

The built files will be in the `dist` directory.

## Project Structure

```
src/
├── api/              # API service layer
│   ├── index.js      # Axios instance and interceptors
│   ├── auth.js       # Authentication API
│   ├── warehouse.js  # Warehouse API
│   ├── zone.js       # Storage zone API
│   ├── timeslot.js   # Time slot API
│   ├── appointment.js # Appointment API
│   ├── grain.js      # Grain type API
│   ├── delivery.js   # Delivery API
│   └── geolocation.js # Geolocation API
├── components/       # Reusable Vue components
│   └── Layout.vue    # Main layout component
├── router/          # Vue Router configuration
│   └── index.js
├── stores/          # Pinia stores
│   └── auth.js      # Authentication store
├── views/           # Page components
│   ├── Login.vue
│   ├── Register.vue
│   ├── Dashboard.vue
│   ├── Warehouses.vue
│   ├── WarehouseDetail.vue
│   ├── Appointments.vue
│   ├── BookAppointment.vue
│   ├── Deliveries.vue
│   └── Profile.vue
├── App.vue          # Root component
├── main.js          # Application entry point
└── style.css        # Global styles
```

## Features Overview

### Authentication
- User registration with role selection (Farmer/Warehouse Admin)
- Secure login with JWT tokens
- Protected routes based on authentication status
- Automatic token refresh and error handling

### Dashboard
- Overview statistics (warehouses, appointments, deliveries, grains)
- Quick action buttons
- Recent appointments display
- Role-based navigation

### Warehouse Management
- Browse all warehouses
- Search warehouses by name or location
- Filter by grain type
- Find nearest warehouses using geolocation
- View warehouse details and storage zones
- Capacity visualization

### Appointment Booking
- Select grain type and warehouse zone
- View available time slots
- Book appointments with quantity selection
- View estimated costs
- Manage existing appointments
- Cancel appointments (if pending)

### Delivery Tracking
- View all deliveries
- Receipt code display
- Total price information
- Link to related appointments

### Profile Management
- Update profile information
- Change password
- View account status and role
- Account creation date

## API Integration

The frontend communicates with the backend API through the service layer in `src/api/`. All API calls are automatically authenticated using JWT tokens stored in localStorage.

### Environment Variables

- `VITE_API_URL` - Backend API base URL (default: `http://localhost:8000`)

## Development

### Code Style
- Follow Vue 3 Composition API patterns
- Use `<script setup>` syntax
- Maintain consistent component structure
- Use Tailwind utility classes for styling

### Adding New Features

1. Create API service in `src/api/` if needed
2. Add route in `src/router/index.js`
3. Create view component in `src/views/`
4. Update navigation in `Layout.vue` if needed

## Browser Support

- Chrome (latest)
- Firefox (latest)
- Safari (latest)
- Edge (latest)

## License

This project is part of the Mahsoul grain warehouse management system.



