from fastapi.middleware.cors import CORSMiddleware
from fastapi import FastAPI
from contextlib import asynccontextmanager
from src.config.database import Database

from src.routes.team import router as team_router
from src.routes.auth import router as auth_router
from src.routes.challenge import router as challenge_router
from src.routes.shop import router as shop_router
from src.routes.blackhole import router as black_hole_router
from src.routes.submit import router as submit_router


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


app.include_router(team_router, prefix="/teams", tags=["Teams"])
app.include_router(auth_router, tags=["auth"])
app.include_router(challenge_router, tags=["Challenge"])
app.include_router(shop_router, tags=["shop"], prefix="/shop")
app.include_router(black_hole_router, tags=["blackhole"], prefix="/blackhole")
app.include_router(submit_router, prefix="/submit", tags=["submits"])
