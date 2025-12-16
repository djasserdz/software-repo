from fastapi.middleware.cors import CORSMiddleware
from fastapi import FastAPI
from contextlib import asynccontextmanager
from src.config.database import Database

from src.routes.user import router as user_router
from src.routes.warehouse import router as warehouse_router
from src.routes.grain import router as grain_router
from src.routes.storagezone import router as storagezone_router
from src.routes.timeslot import router as time_router
from src.routes.appointment import router as appointment_router
from src.routes.location import router as location_router

import os
import logging
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

    yield

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

app.include_router(user_router, prefix="/user", tags=["user"])
app.include_router(warehouse_router, prefix="/warehouse", tags=["warehouse"])
app.include_router(grain_router, prefix="/grain", tags=["grain"])
app.include_router(storagezone_router, prefix="/zone", tags=["zone"])
app.include_router(time_router, prefix="/time", tags=["time"])
app.include_router(appointment_router, prefix="/appointment", tags=["appointment"])
app.include_router(location_router, prefix="/location", tags=["location"])
