"""Celery tasks for accounts."""
from celery import shared_task
import logging

logger = logging.getLogger(__name__)


@shared_task
def cleanup_expired_otps():
    """Clean up expired OTPs from cache. Cache handles TTL automatically."""
    logger.info('OTP cleanup task executed (cache auto-expires)')


@shared_task
def send_otp_email_task(email, otp, purpose='email_verification'):
    """Async send OTP email."""
    from .emails import send_otp_email
    send_otp_email(email, otp, purpose)

@shared_task
def send_password_reset_email_task(email, code):
    """Async send password reset email."""
    from .emails import send_password_reset_email
    send_password_reset_email(email, code)
