# Docker Setup Guide for Mahsoul

This guide explains how to build and run the Mahsoul application using Docker and Docker Compose.

## Prerequisites

- Docker Engine 20.10+
- Docker Compose 2.0+
- A `.env` file in the root directory with required environment variables

## Project Structure

```
.
├── backend/          # FastAPI backend
│   ├── Dockerfile
│   └── src/
├── frontend/         # Vue.js frontend
│   ├── Dockerfile    # Production build
│   ├── Dockerfile.dev # Development build
│   └── nginx.conf    # Nginx configuration
├── reverse_proxy/    # Nginx reverse proxy
│   └── nginx.conf
├── docker-compose.yml
└── .env
```

## Services

The Docker Compose setup includes:

1. **backend** - FastAPI application (port 8000)
2. **db** - PostgreSQL database (internal)
3. **frontend** - Vue.js application served by Nginx (port 3000)
4. **reverse_proxy** - Nginx reverse proxy (port 80)

## Environment Variables

Create a `.env` file in the root directory with the following variables:

```env
# Project
PROJECT_NAME=Mahsoul
DOMAIN_NAME=localhost

# Database
POSTGRES_DB=mahsoul_db
POSTGRES_USER=mahsoul_user
POSTGRES_PASSWORD=your_secure_password

# Redis (if used)
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=

# Security
SECRET_KEY=your_secret_key_here
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=1440
```

## Building and Running

### Production Build

1. Build all services:
```bash
docker compose build
```

2. Start all services:
```bash
docker compose up -d
```

3. View logs:
```bash
docker compose logs -f
```

4. Stop all services:
```bash
docker compose down
```

### Development Mode

For development with hot-reload, you can use the development Dockerfile:

1. Update `docker-compose.yml` frontend service to use `Dockerfile.dev`:
```yaml
frontend:
  build:
    context: ./frontend
    dockerfile: Dockerfile.dev
  volumes:
    - ./frontend:/app
    - /app/node_modules
```

2. Run in development mode:
```bash
docker compose up --build
```

## Accessing the Application

- **Frontend**: http://localhost:80 (via reverse proxy)
- **Frontend (direct)**: http://localhost:3000
- **Backend API**: http://localhost:8000
- **Backend API (via proxy)**: http://localhost:80/api/
- **API Documentation**: http://localhost:80/docs
- **API ReDoc**: http://localhost:80/redoc

## Frontend Dockerfile Details

### Production Dockerfile

The production Dockerfile uses a multi-stage build:

1. **Builder stage**: Builds the Vue.js application
   - Uses Node.js 20 Alpine
   - Installs dependencies
   - Builds the production bundle

2. **Production stage**: Serves the built application
   - Uses Nginx Alpine
   - Copies built files
   - Configures Nginx for SPA routing

### Features

- **Gzip compression** for better performance
- **Security headers** for protection
- **Static asset caching** (1 year)
- **SPA routing support** (Vue Router)
- **API proxy** configuration (optional)

## Troubleshooting

### Frontend not loading

1. Check if the frontend container is running:
```bash
docker compose ps
```

2. Check frontend logs:
```bash
docker compose logs frontend
```

3. Rebuild the frontend:
```bash
docker compose build frontend
docker compose up -d frontend
```

### Backend API not accessible

1. Check backend logs:
```bash
docker compose logs backend
```

2. Verify database connection:
```bash
docker compose logs db
```

3. Check network connectivity:
```bash
docker compose exec backend ping db
```

### Port conflicts

If ports 80, 3000, or 8000 are already in use:

1. Update port mappings in `docker-compose.yml`:
```yaml
ports:
  - "8080:80"  # Change 80 to 8080
```

2. Update API URLs in frontend if needed

### Rebuilding after code changes

For production builds, rebuild the frontend:
```bash
docker compose build frontend
docker compose up -d frontend
```

For development, changes are reflected automatically with volume mounts.

## Volumes

- `software_app`: PostgreSQL data persistence
- Frontend source code (development mode only)

## Networks

- `public_net`: Public-facing services (frontend, reverse_proxy)
- `private_net`: Internal services (backend, database)

## Health Checks

The frontend includes a health check endpoint at `/health` that returns "healthy" when the service is running.

## Production Considerations

1. **Environment Variables**: Use secure secrets management
2. **SSL/TLS**: Add SSL certificates for HTTPS
3. **Logging**: Configure centralized logging
4. **Monitoring**: Add health checks and monitoring
5. **Backup**: Set up database backups
6. **Scaling**: Configure for horizontal scaling if needed

## Cleanup

To remove all containers, networks, and volumes:

```bash
docker compose down -v
```

To remove images as well:

```bash
docker compose down --rmi all -v
```



