"""Notification services."""
import logging
from django.utils import timezone
from .models import Notification
from apps.accounts.emails import send_outpass_notification

logger = logging.getLogger(__name__)


def notify_admins_of_alert(alert):
    """Notify all admins and wardens of a critical system/security alert."""
    from apps.accounts.models import User, UserRole
    recipients = User.objects.filter(role__in=[UserRole.ADMIN, UserRole.WARDEN, UserRole.ADMIN_WARDEN], is_active=True)
    
    for user in recipients:
        NotificationService.create(
            user=user,
            title=f"ALERT: {alert.title}",
            message=alert.message,
            event_name="SYSTEM_ALERT_CREATED",
            category=Notification.NotificationCategory.SECURITY,
            priority=Notification.NotificationPriority.CRITICAL if alert.level == 'CRITICAL' else Notification.NotificationPriority.HIGH,
            notification_type=Notification.NotificationType.SYSTEM_ALERT
        )

class NotificationService:
    """
    Service for creating and routing notifications.
    """

    @classmethod
    def create(cls, user, title, message, event_name, category, 
               notification_type=Notification.NotificationType.IN_APP, 
               priority=Notification.NotificationPriority.NORMAL, 
               metadata=None, related_outpass=None):
        """
        Creates a notification in the database and dispatches it.
        """
        if metadata is None:
            metadata = {}

        notification = Notification.objects.create(
            user=user,
            title=title,
            message=message,
            notification_type=notification_type,
            category=category,
            priority=priority,
            metadata=metadata,
            related_outpass=related_outpass,
            sent_at=timezone.now()
        )
        
        # Dispatch the notification
        try:
            from .dispatcher import NotificationDispatcher
            NotificationDispatcher.dispatch(notification, event_name)
        except Exception as e:
            logger.warning(f"Failed to dispatch notification {notification.id}: {e}")
        
        return notification
