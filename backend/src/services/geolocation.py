import math
from typing import List, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from src.repositories.warehouse import WarehouseRepo
from src.repositories.storagezone import StorageZoneRepo
from src.repositories.grain import GrainRepo
from src.database.db import ZoneStatus
import logging


def calculate_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """
    Calculate the distance between two points on Earth using Haversine formula.
    Returns distance in kilometers.
    """
    # Radius of Earth in kilometers
    R = 6371.0

    # Convert latitude and longitude from degrees to radians
    lat1_rad = math.radians(lat1)
    lon1_rad = math.radians(lon1)
    lat2_rad = math.radians(lat2)
    lon2_rad = math.radians(lon2)

    # Haversine formula
    dlat = lat2_rad - lat1_rad
    dlon = lon2_rad - lon1_rad

    a = (
        math.sin(dlat / 2) ** 2
        + math.cos(lat1_rad) * math.cos(lat2_rad) * math.sin(dlon / 2) ** 2
    )
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))

    distance = R * c
    return distance


class GeolocationService:
    @staticmethod
    async def get_nearest_warehouses(
        session: AsyncSession,
        latitude: float,
        longitude: float,
        grain_type_id: Optional[int] = None,
        limit: int = 10,
    ) -> List[dict]:
        """
        Get nearest warehouses that have zones for the specified grain type.
        Returns warehouses with distance, zones, and capacity information.
        """
        try:
            # Get all active warehouses
            warehouses = await WarehouseRepo.get_all(
                session=session,
                skip=0,
                limit=1000,  # Get all warehouses to calculate distances
                status=ZoneStatus.ACTIVE,
            )

            # Filter warehouses that have zones for the specified grain type
            warehouse_data = []
            for warehouse in warehouses:
                # Get zones for this warehouse
                zones = await StorageZoneRepo.get_all(
                    session=session,
                    warehouse_id=warehouse.warehouse_id,
                    grain_type_id=grain_type_id,
                    status=ZoneStatus.ACTIVE,
                )

                # Only include warehouses that have zones for this grain type
                if zones:
                    # Calculate distance
                    distance = calculate_distance(
                        latitude,
                        longitude,
                        warehouse.y_float,
                        warehouse.x_float,
                    )

                    # Calculate total capacity and available capacity
                    total_capacity = sum(zone.total_capacity for zone in zones)
                    available_capacity = sum(
                        zone.available_capacity for zone in zones
                    )

                    # Get grain type name if grain_type_id is provided
                    grain_name = None
                    if grain_type_id:
                        try:
                            grain = await GrainRepo.get_by_id(session, grain_type_id)
                            grain_name = grain.name
                        except Exception:
                            pass

                    warehouse_data.append(
                        {
                            "id": warehouse.warehouse_id,
                            "name": warehouse.name,
                            "location": warehouse.location,
                            "latitude": warehouse.y_float,
                            "longitude": warehouse.x_float,
                            "distance": round(distance, 2),
                            "zones": [
                                {
                                    "zone_id": zone.zone_id,
                                    "name": zone.name,
                                    "total_capacity": zone.total_capacity,
                                    "available_capacity": zone.available_capacity,
                                    "grain_type_id": zone.grain_type_id,
                                }
                                for zone in zones
                            ],
                            "grainType": grain_name,
                            "maxCapacity": total_capacity,
                            "currentStock": total_capacity - available_capacity,
                            "availableCapacity": available_capacity,
                            "address": warehouse.location,
                        }
                    )

            # Sort by distance and limit results
            warehouse_data.sort(key=lambda x: x["distance"])
            return warehouse_data[:limit]

        except Exception as e:
            logging.exception(f"Error getting nearest warehouses: {e}")
            raise

    @staticmethod
    async def update_warehouse_location(
        session: AsyncSession,
        warehouse_id: int,
        latitude: float,
        longitude: float,
    ):
        """Update warehouse location coordinates"""
        try:
            await WarehouseRepo.update(
                session=session,
                warehouse_id=warehouse_id,
                x_float=longitude,
                y_float=latitude,
            )
        except Exception as e:
            logging.exception(f"Error updating warehouse location: {e}")
            raise

    @staticmethod
    async def update_farmer_location(
        session: AsyncSession,
        user_id: int,
        latitude: float,
        longitude: float,
    ):
        """Update farmer location (can be stored in user profile if needed)"""
        # For now, we just log it. In the future, you might want to store
        # this in a user_location table or add fields to the User model
        logging.info(f"Farmer {user_id} location updated: {latitude}, {longitude}")
        # You can extend this to actually store the location if needed
        pass

