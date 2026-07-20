"""Celery application for CurfewCam."""
import os
from celery import Celery

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'src.config.settings')

app = Celery('curfewcam')
app.config_from_object('django.conf:settings', namespace='CELERY')
app.autodiscover_tasks()


@app.task(bind=True, ignore_result=True)
def debug_task(self):
    """Debug task for testing Celery."""
    print(f'Request: {self.request!r}')
