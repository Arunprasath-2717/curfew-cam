"""Celery application for CurfewCam."""
import os
from celery import Celery

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'src.config.settings')

app = Celery('curfewcam')
app.config_from_object('django.conf:settings', namespace='CELERY')
app.autodiscover_tasks()

from celery.schedules import crontab

app.conf.beat_schedule = {
    'check-late-returns-every-5-minutes': {
        'task': 'apps.outpass.tasks.check_late_returns',
        'schedule': crontab(minute='*/5'),
    },
    'expire-old-pending-every-hour': {
        'task': 'apps.outpass.tasks.expire_old_pending_outpasses',
        'schedule': crontab(minute='0'),
    },
}


@app.task(bind=True, ignore_result=True)
def debug_task(self):
    """Debug task for testing Celery."""
    print(f'Request: {self.request!r}')
