"""Celery tasks for outpass."""
from celery import shared_task
from django.utils import timezone
import logging

logger = logging.getLogger(__name__)


@shared_task
def check_late_returns():
    """Check for late returns and create alerts."""
    from .models import Outpass
    from apps.notifications.services import NotificationService
    from apps.notifications.models import Notification

    now = timezone.now()
    active_outpasses = Outpass.objects.filter(status=Outpass.Status.ACTIVE)

    for outpass in active_outpasses:
        expected = timezone.make_aware(
            timezone.datetime.combine(outpass.expected_return_date, outpass.expected_return_time)
        )
        if now > expected:
            # Mark as late and notify
            NotificationService.create(
                user=outpass.student.user,
                title='Late Return Alert',
                message=f'You are past your expected return time ({outpass.expected_return_time}). Please return immediately.',
                event_name='LATE_RETURN',
                category=Notification.NotificationCategory.ALERT,
                notification_type=Notification.NotificationType.SYSTEM_ALERT,
                priority=Notification.NotificationPriority.HIGH,
                related_outpass=outpass,
            )
            if outpass.approved_by:
                NotificationService.create(
                    user=outpass.approved_by.user,
                    title=f'Late Return: {outpass.student.user.full_name}',
                    message=f'{outpass.student.user.full_name} ({outpass.student.register_number}) has not returned. Expected: {outpass.expected_return_time}',
                    event_name='LATE_RETURN_WARDEN',
                    category=Notification.NotificationCategory.ALERT,
                    notification_type=Notification.NotificationType.SYSTEM_ALERT,
                    priority=Notification.NotificationPriority.HIGH,
                    related_outpass=outpass,
                )
            logger.warning('Late return detected: %s', outpass)


@shared_task
def expire_old_pending_outpasses():
    """Auto-expire pending outpasses older than 48 hours."""
    from .models import Outpass
    from apps.notifications.services import NotificationService
    from apps.notifications.models import Notification

    cutoff = timezone.now() - timezone.timedelta(hours=48)
    expired_qs = Outpass.objects.filter(
        status=Outpass.Status.PENDING,
        created_at__lt=cutoff,
    )
    
    count = 0
    for op in expired_qs:
        op.status = Outpass.Status.EXPIRED
        op.save()
        count += 1
        NotificationService.create(
            user=op.student.user,
            title='Outpass Expired',
            message='Your pending outpass request has expired.',
            event_name='OUTPASS_EXPIRED',
            category=Notification.NotificationCategory.OUTPASS,
            notification_type=Notification.NotificationType.OUTPASS_STATUS,
            related_outpass=op,
        )
        
    if count:
        logger.info('Expired %d old pending outpasses', count)

