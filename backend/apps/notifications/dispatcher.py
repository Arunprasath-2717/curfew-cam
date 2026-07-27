import logging
from .models import Notification

logger = logging.getLogger(__name__)


class NotificationDispatcher:
    """
    Coordinates the delivery of a Notification across different channels
    (WebSocket, Email, FCM, SMS).

    Each channel is dispatched independently so a failure in one (e.g.
    Redis unavailable) never prevents others or the calling view from
    succeeding. The notification record is always already saved to the DB
    by NotificationService.create() before dispatch is called.
    """

    @classmethod
    def dispatch(cls, notification: Notification, event_name: str):
        # Mark pending
        try:
            if notification.delivery_status != Notification.DeliveryStatus.PENDING:
                notification.delivery_status = Notification.DeliveryStatus.PENDING
                notification.save(update_fields=['delivery_status'])
        except Exception as e:
            logger.warning(f"Could not set PENDING for notification {notification.id}: {e}")

        # WebSocket broadcast via Celery (requires Redis)
        try:
            from .tasks import broadcast_notification
            broadcast_notification.delay(notification.id, event_name)
        except Exception as e:
            logger.warning(
                f"WebSocket dispatch skipped for notification {notification.id} "
                f"(Celery/Redis unavailable): {e}"
            )

        # Email dispatch via Celery
        if notification.notification_type in [
            Notification.NotificationType.EMAIL,
            Notification.NotificationType.OUTPASS_STATUS,
        ]:
            try:
                from .tasks import send_notification_email_async
                send_notification_email_async.delay(notification.id)
            except Exception as e:
                logger.warning(
                    f"Email dispatch skipped for notification {notification.id}: {e}"
                )

        # FCM dispatch via Celery
        try:
            from .tasks import send_fcm_notification_async
            send_fcm_notification_async.delay(notification.id)
        except Exception as e:
            logger.warning(
                f"FCM dispatch skipped for notification {notification.id}: {e}"
            )
