from fastapi.middleware.cors import CORSMiddleware
from fastapi import FastAPI, Request, status
from fastapi.responses import JSONResponse
from contextlib import asynccontextmanager
from src.config.database import Database

from src.routes.user import router as user_router
from src.routes.warehouse import router as warehouse_router
from src.routes.grain import router as grain_router
from src.routes.storagezone import router as storagezone_router
from src.routes.timeslot import router as time_router
from src.routes.appointment import router as appointment_router
from src.routes.delivery import router as delivery_router
from src.routes.location import router as location_router
from src.routes.geolocation import router as geolocation_router
from src.services.scheduler import setup_scheduler, shutdown_scheduler

import os
import logging
import time
from logging.handlers import RotatingFileHandler

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
LOG_FILE = os.path.join(BASE_DIR, "app.log")

file_handler = RotatingFileHandler(
    LOG_FILE,
    maxBytes=5 * 1024 * 1024,  # 5MB
    backupCount=5,
)

formatter = logging.Formatter("%(asctime)s - %(levelname)s - %(name)s - %(message)s")

file_handler.setFormatter(formatter)

stream_handler = logging.StreamHandler()
stream_handler.setFormatter(formatter)

root_logger = logging.getLogger()
root_logger.setLevel(logging.INFO)
root_logger.addHandler(file_handler)
root_logger.addHandler(stream_handler)


@asynccontextmanager
async def lifespan(app: FastAPI):
    print("✅ Connected!")

    await Database.create_db()
    await Database.init_db()

    # Start the scheduler for time slot generation
    await setup_scheduler()

    yield

    # Shutdown scheduler on app close
    shutdown_scheduler()

    print("❌ Disconnected.")


app = FastAPI(lifespan=lifespan)

origins = ["*"]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=[
        "Content-Disposition",
    ],
)

# Request logging middleware
@app.middleware("http")
async def log_requests(request: Request, call_next):
    start_time = time.time()
    
    # Log incoming request
    logger = logging.getLogger("request_logger")
    logger.info(
        f"📥 INCOMING: {request.method} {request.url.path} | "
        f"Query: {dict(request.query_params)} | "
        f"Headers: {dict(request.headers)}"
    )
    
    try:
        response = await call_next(request)
        process_time = time.time() - start_time
        
        logger.info(
            f"📤 OUTGOING: {request.method} {request.url.path} | "
            f"Status: {response.status_code} | "
            f"Time: {process_time:.3f}s"
        )
        
        return response
    except Exception as e:
        process_time = time.time() - start_time
        logger.error(
            f"❌ ERROR: {request.method} {request.url.path} | "
            f"Error: {str(e)} | "
            f"Time: {process_time:.3f}s",
            exc_info=True
        )
        raise

# Exception handler for better error logging
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    logger = logging.getLogger("error_logger")
    logger.error(
        f"💥 UNHANDLED EXCEPTION: {request.method} {request.url.path} | "
        f"Error: {str(exc)}",
        exc_info=True
    )
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={"detail": f"Internal server error: {str(exc)}"}
    )

app.include_router(user_router, prefix="/user", tags=["user"])
# Also add auth routes for frontend compatibility
app.include_router(user_router, prefix="/auth", tags=["auth"])
app.include_router(warehouse_router, prefix="/warehouse", tags=["warehouse"])
app.include_router(grain_router, prefix="/grain", tags=["grain"])
app.include_router(storagezone_router, prefix="/zone", tags=["zone"])
# Also add warehouse-zones route for frontend compatibility
app.include_router(storagezone_router, prefix="/warehouse-zones", tags=["warehouse-zones"])
app.include_router(time_router, prefix="/time", tags=["time"])
# Also add time-slots route for frontend compatibility
app.include_router(time_router, prefix="/time-slots", tags=["time-slots"])
app.include_router(appointment_router, prefix="/appointment", tags=["appointment"])
# Also add appointments route for frontend compatibility
app.include_router(appointment_router, prefix="/appointments", tags=["appointments"])
app.include_router(delivery_router, prefix="/delivery", tags=["delivery"])
# Also add deliveries route for frontend compatibility
app.include_router(delivery_router, prefix="/deliveries", tags=["deliveries"])
app.include_router(location_router, prefix="/location", tags=["location"])
app.include_router(geolocation_router, prefix="/geolocation", tags=["geolocation"])
