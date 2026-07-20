"""QR Celery tasks."""
from celery import shared_task
from django.utils import timezone
import logging

logger = logging.getLogger(__name__)


@shared_task
def cleanup_expired_qr_passes():
    """Delete QR images for expired passes."""
    from .models import QRPass
    expired = QRPass.objects.filter(expires_at__lt=timezone.now(), is_used=False)
    count = expired.count()
    for qr in expired:
        if qr.qr_image:
            qr.qr_image.delete(save=False)
    expired.update(is_used=True)
    if count:
        logger.info('Cleaned up %d expired QR passes', count)
