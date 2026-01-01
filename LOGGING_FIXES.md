# Logging and API Routing Fixes

## Changes Made

### 1. Backend Logging Added
- **Request logging middleware**: Logs all incoming requests with method, path, query params, and headers
- **Response logging**: Logs outgoing responses with status codes and processing time
- **Error logging**: Comprehensive error logging with stack traces
- **Register endpoint logging**: Specific logging for registration attempts

### 2. Nginx Configuration Fixed
- Updated API routing to properly strip `/api` prefix
- Added access and error logging to nginx

### 3. Frontend API Configuration
- Set base URL to `/api` for reverse proxy routing

## To Apply Changes

```bash
# Stop containers
docker compose down

# Rebuild backend (for logging changes)
docker compose build backend

# Rebuild frontend (for API config)
docker compose build frontend

# Restart reverse proxy (for nginx config)
docker compose up -d reverse_proxy

# Start all services
docker compose up -d

# Watch logs
docker compose logs -f backend
```

## How to Debug

### Check Backend Logs
```bash
docker compose logs backend | grep -E "(INCOMING|OUTGOING|ERROR|Register)"
```

### Check Nginx Logs
```bash
docker compose logs reverse_proxy
```

### Check What Path Backend Receives
Look for logs like:
```
📥 INCOMING: POST /user/register | Query: {} | Headers: {...}
📤 OUTGOING: POST /user/register | Status: 200 | Time: 0.123s
```

### Test API Directly
```bash
# Test if backend is accessible
curl http://localhost:8000/user/register -X POST -H "Content-Type: application/json" -d '{"name":"Test","email":"test@test.com","password":"test1234","role":"farmer"}'

# Test through reverse proxy
curl http://localhost/api/user/register -X POST -H "Content-Type: application/json" -d '{"name":"Test","email":"test@test.com","password":"test1234","role":"farmer"}'
```

## Expected Behavior

1. Frontend makes request to: `/api/user/register`
2. Nginx receives: `/api/user/register`
3. Nginx rewrites to: `/user/register`
4. Nginx forwards to: `backend:8000/user/register`
5. Backend receives: `POST /user/register`
6. Backend logs: `📥 INCOMING: POST /user/register`
7. Backend processes and responds
8. Backend logs: `📤 OUTGOING: POST /user/register | Status: 200`

## Troubleshooting

If you still see 405 errors:

1. **Check the exact path backend receives:**
   ```bash
   docker compose logs backend | grep "INCOMING"
   ```

2. **Check nginx error logs:**
   ```bash
   docker compose exec reverse_proxy cat /var/log/nginx/error.log
   ```

3. **Verify backend routes:**
   - Backend route is: `/user/register` (POST)
   - If backend receives `/api/user/register`, the rewrite isn't working
   - If backend receives `/user/register`, check if the route exists

4. **Test backend directly:**
   ```bash
   docker compose exec backend curl http://localhost:8000/user/register -X POST -H "Content-Type: application/json" -d '{"name":"Test","email":"test@test.com","password":"test1234","role":"farmer"}'
   ```


