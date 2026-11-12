from celery import shared_task
from .engine import run_health_analysis

@shared_task
def analyze_flock(flock_id):
    """
    Task to run health rules on a given flock.
    """
    run_health_analysis(flock_id)
