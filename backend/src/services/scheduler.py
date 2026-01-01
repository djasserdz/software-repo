import asyncio
import logging
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.interval import IntervalTrigger
from src.config.database import ConManager
from src.services.timeslot import TimeSlotService

logger = logging.getLogger(__name__)

scheduler = AsyncIOScheduler()


async def generate_weekly_timeslots():
    """Background task to generate time slots for the next week"""
    try:
        logger.info("Starting scheduled time slot generation for next week...")
        
        # Get a database session
        async for session in ConManager.get_session():
            try:
                slots = await TimeSlotService.generate_timeslots_for_next_week(session)
                logger.info(f"Successfully generated {len(slots)} time slots")
            except Exception as e:
                logger.exception(f"Error generating time slots: {e}")
            finally:
                await session.close()
                break  # Exit after first session
                
    except Exception as e:
        logger.exception(f"Error in scheduled task: {e}")


async def setup_scheduler():
    """Setup and start the scheduler"""
    try:
        # Schedule task to run every 3 days
        scheduler.add_job(
            generate_weekly_timeslots,
            trigger=IntervalTrigger(days=3),
            id="generate_weekly_timeslots",
            name="Generate time slots for next week",
            replace_existing=True,
            max_instances=1,  # Prevent overlapping executions
        )
        
        scheduler.start()
        logger.info("Scheduler started: Time slots will be generated every 3 days for the next week")
        
        # Also run immediately on startup to ensure slots are available
        await generate_weekly_timeslots()
        logger.info("Initial time slot generation completed on startup")
        
    except Exception as e:
        logger.exception(f"Error setting up scheduler: {e}")


def shutdown_scheduler():
    """Shutdown the scheduler"""
    try:
        if scheduler.running:
            scheduler.shutdown(wait=True)
            logger.info("Scheduler shut down")
    except Exception as e:
        logger.exception(f"Error shutting down scheduler: {e}")

