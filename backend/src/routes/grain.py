from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession
from src.config.database import ConManager
from src.models.grain import GrainCreate, GrainUpdate
from src.services.grain import GrainService


router = APIRouter()


@router.get("/", description="get all grains")
async def list_all(session: AsyncSession = Depends(ConManager.get_session)):
    grains = await GrainService.get_grains(session)
    return grains


@router.post("/", description="create a grain")
async def create(
    data: GrainCreate, session: AsyncSession = Depends(ConManager.get_session)
):
    grain = await GrainService.create_grain(session, data)
    return grain


@router.get("/{grain_id}", description="get grain")
async def get_grain(
    grain_id: int, session: AsyncSession = Depends(ConManager.get_session)
):
    grain = await GrainService.get_grain(session, grain_id)
    return grain


@router.patch("/{grain_id}", description="update a grain")
async def update_grain(
    data: GrainUpdate,
    grain_id: int,
    session: AsyncSession = Depends(ConManager.get_session),
):
    grain = await GrainService.update_grain(session, grain_id, data)
    return grain


@router.delete("/{grain_id}", description="delete a grain")
async def delete_grain(
    grain_id: int, session: AsyncSession = Depends(ConManager.get_session)
):
    grain = await GrainService.delete_grain(session, grain_id)
    if grain:
        return "grain Deleted!"
