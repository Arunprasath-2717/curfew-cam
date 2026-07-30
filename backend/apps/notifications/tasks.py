"""Notification Celery tasks."""
from celery import shared_task
import logging

logger = logging.getLogger(__name__)


@shared_task
def send_notification_email_async(notification_id):
    """Send an email for a notification in the background."""
    from .models import Notification
    from apps.accounts.emails import send_outpass_notification
    from django.core.mail import send_mail
    from django.conf import settings
    
    try:
        notification = Notification.objects.get(id=notification_id)
        
        if notification.notification_type == Notification.NotificationType.OUTPASS_STATUS and notification.related_outpass:
            outpass = notification.related_outpass
            send_outpass_notification(
                email=notification.user.email,
                outpass_status=outpass.status,
                student_name=notification.user.full_name
            )
        else:
            send_mail(
                subject=notification.title,
                message=notification.message,
                from_email=settings.DEFAULT_FROM_EMAIL,
                recipient_list=[notification.user.email],
                fail_silently=True
            )
        logger.info(f"Sent email notification for {notification_id}")
    except Notification.DoesNotExist:
        logger.error(f"Notification {notification_id} not found")
        

@shared_task
def send_notification_digest():
    """Send daily digest of unread notifications to users."""
    # Implementation depends on business requirements
    logger.info("Executing daily notification digest task")
    pass


@shared_task
def broadcast_notification(notification_id, event_name):
    """Broadcast notification payload to websocket clients."""
    from .models import Notification
    from channels.layers import get_channel_layer
    from asgiref.sync import async_to_sync
    
    try:
        notification = Notification.objects.get(id=notification_id)
        channel_layer = get_channel_layer()
        if not channel_layer:
            return
            
        unread_count = Notification.objects.filter(user=notification.user, is_read=False).count()
        
        payload = {
            "event": event_name,
            "event_id": str(notification.id),
            "timestamp": notification.created_at.isoformat(),
            "priority": notification.priority,
            "category": notification.category,
            "delivery_status": notification.delivery_status,
            "unread_count": unread_count,
            "metadata": notification.metadata,
            "data": {
                "title": notification.title,
                "message": notification.message
            }
        }
        
        async_to_sync(channel_layer.group_send)(
            f"user_{notification.user.id}",
            {
                "type": "send_notification",
                "payload": payload
            }
        )
        
        if notification.delivery_status == Notification.DeliveryStatus.PENDING:
            notification.delivery_status = Notification.DeliveryStatus.SENT
            notification.save(update_fields=['delivery_status'])
            
    except Exception as e:
        logger.exception(f"Failed to broadcast real-time notification {notification_id}: {e}")

@shared_task
def send_fcm_notification_async(notification_id):
    """Send push notification via Firebase Cloud Messaging."""
    from .models import Notification
    import firebase_admin
    from firebase_admin import messaging
    
    if not firebase_admin._apps:
        logger.warning("Firebase Admin not initialized, skipping FCM dispatch.")
        return

    try:
        notification = Notification.objects.get(id=notification_id)
        token = notification.user.fcm_token
        
        if not token:
            logger.info(f"User {notification.user.id} has no FCM token. Skipping push notification.")
            return

        message = messaging.Message(
            notification=messaging.Notification(
                title=notification.title,
                body=notification.message,
            ),
            android=messaging.AndroidConfig(
                priority='high',
                notification=messaging.AndroidNotification(
                    channel_id='high_importance_channel',
                    priority='max',
                    default_sound=True,
                    default_vibrate_timings=True,
                    visibility='public',
                ),
            ),
            apns=messaging.APNSConfig(
                payload=messaging.APNSPayload(
                    aps=messaging.Aps(
                        alert=messaging.ApsAlert(
                            title=notification.title,
                            body=notification.message,
                        ),
                        sound='default',
                        badge=1,
                    )
                )
            ),
            data={
                "event_id": str(notification.id),
                "category": str(notification.category),
                "title": str(notification.title),
                "message": str(notification.message),
                "priority": str(notification.priority),
            },
            token=token,
        )
        
        response = messaging.send(message)
        logger.info(f"Successfully sent FCM message: {response}")
        
    except Notification.DoesNotExist:
        logger.error(f"Notification {notification_id} not found")
    except Exception as e:
        logger.error(f"Failed to send FCM notification for {notification_id}: {e}")
