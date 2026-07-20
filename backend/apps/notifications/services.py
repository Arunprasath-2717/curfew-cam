"""Notification services."""
import logging
from django.utils import timezone
from .models import Notification
from apps.accounts.emails import send_outpass_notification

logger = logging.getLogger(__name__)


def notify_admins_of_alert(alert):
    """Notify all admins of a critical system alert."""
    from apps.accounts.models import User, UserRole
    admins = User.objects.filter(role=UserRole.ADMIN, is_active=True)
    
    for admin in admins:
        NotificationService.create(
            user=admin,
            title=f"SYSTEM ALERT: {alert.title}",
            message=alert.message,
            event_name="SYSTEM_ALERT_CREATED",
            category=Notification.NotificationCategory.SYSTEM,
            priority=Notification.NotificationPriority.CRITICAL,
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
