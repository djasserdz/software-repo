# Rebuild Instructions

To apply the reverse proxy fixes, run:

```bash
# Stop all containers
docker compose down

# Rebuild frontend (to get updated API config)
docker compose build frontend

# Start all services
docker compose up -d

# Check logs
docker compose logs -f
```

## Verify the connection:

1. **Check reverse proxy logs:**
```bash
docker compose logs reverse_proxy
```

2. **Check frontend logs:**
```bash
docker compose logs frontend
```

3. **Check backend logs:**
```bash
docker compose logs backend
```

4. **Test the API connection:**
- Open browser: http://localhost
- Open browser console (F12)
- Try to login or make an API call
- Check Network tab to see if API calls go to `/api/...`

## Expected behavior:

- Frontend at: http://localhost
- API calls should go to: http://localhost/api/user/login (for example)
- Backend receives requests without `/api` prefix
- All services should be on the same network


