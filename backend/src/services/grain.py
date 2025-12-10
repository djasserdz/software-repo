from src.models.grain import GrainCreate, GrainUpdate
from sqlalchemy.ext.asyncio import AsyncSession
from src.repositories.grain import GrainRepo


class GrainService:
    @staticmethod
    async def create_grain(session: AsyncSession, data: GrainCreate):
        grain = await GrainRepo.create(session, data)
        return grain

    @staticmethod
    async def get_grains(session: AsyncSession):
        grains = await GrainRepo.get_all(session)
        return grains

    @staticmethod
    async def get_grain(session: AsyncSession, grain_id: int):
        grain = await GrainRepo.get_by_id(session, grain_id)
        return grain

    @staticmethod
    async def update_grain(session: AsyncSession, grain_id: int, data: GrainUpdate):
        updated_data = data.model_dump(exclude_unset=True)
        grain = await GrainRepo.update(session, grain_id, **updated_data)
        return grain

    @staticmethod
    async def delete_grain(session: AsyncSession, grain_id: int):
        grain = await GrainRepo.soft_delete(session, grain_id)
        return grain
