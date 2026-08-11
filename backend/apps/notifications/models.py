"""Notification models."""
from django.db import models
from apps.common.models import TimeStampedModel


class Notification(TimeStampedModel):
    """System notification for users."""

    class NotificationType(models.TextChoices):
        EMAIL = 'EMAIL', 'Email'
        IN_APP = 'IN_APP', 'In-App'
        PUSH = 'PUSH', 'Push Notification'
        LATE_ALERT = 'LATE_ALERT', 'Late Return Alert'
        OUTPASS_STATUS = 'OUTPASS_STATUS', 'Outpass Status'
        SYSTEM_ALERT = 'SYSTEM_ALERT', 'System Alert'

    class NotificationCategory(models.TextChoices):
        OUTPASS = 'OUTPASS', 'Outpass'
        QR = 'QR', 'QR Code'
        SECURITY = 'SECURITY', 'Security'
        CAMERA = 'CAMERA', 'Camera'
        SYSTEM = 'SYSTEM', 'System'
        SHIFT = 'SHIFT', 'Shift'
        MOVEMENT = 'MOVEMENT', 'Movement'
        DETECTION = 'DETECTION', 'Detection'

    class NotificationPriority(models.TextChoices):
        LOW = 'LOW', 'Low'
        NORMAL = 'NORMAL', 'Normal'
        HIGH = 'HIGH', 'High'
        CRITICAL = 'CRITICAL', 'Critical'

    class DeliveryStatus(models.TextChoices):
        PENDING = 'PENDING', 'Pending'
        SENT = 'SENT', 'Sent'
        FAILED = 'FAILED', 'Failed'
        READ = 'READ', 'Read'

    user = models.ForeignKey('accounts.User', on_delete=models.CASCADE, related_name='notifications')
    title = models.CharField(max_length=200)
    message = models.TextField()
    notification_type = models.CharField(max_length=20, choices=NotificationType.choices, default=NotificationType.IN_APP)
    category = models.CharField(max_length=20, choices=NotificationCategory.choices, default=NotificationCategory.SYSTEM)
    priority = models.CharField(max_length=20, choices=NotificationPriority.choices, default=NotificationPriority.NORMAL)
    delivery_status = models.CharField(max_length=20, choices=DeliveryStatus.choices, default=DeliveryStatus.PENDING)
    metadata = models.JSONField(default=dict, blank=True)
    is_read = models.BooleanField(default=False)
    related_outpass = models.ForeignKey('outpass.Outpass', on_delete=models.SET_NULL, null=True, blank=True)
    sent_at = models.DateTimeField(null=True, blank=True)

    class Meta(TimeStampedModel.Meta):
        verbose_name = 'Notification'

    def __str__(self):
        return f'{self.title} - {self.user.email}'

class Announcement(TimeStampedModel):
    """Global announcements for all users (notices)."""
    warden = models.ForeignKey('accounts.User', on_delete=models.CASCADE, related_name='announcements')
    title = models.CharField(max_length=200)
    message = models.TextField()
    is_active = models.BooleanField(default=True)
    expires_at = models.DateTimeField(null=True, blank=True)

    class Meta(TimeStampedModel.Meta):
        verbose_name = 'Announcement'
        ordering = ['-created_at']

    def __str__(self):
        return self.title