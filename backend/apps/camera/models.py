"""Camera models."""
from django.db import models
from apps.common.models import TimeStampedModel


class Camera(TimeStampedModel):
    """Camera device for surveillance."""

    class CameraStatus(models.TextChoices):
        ONLINE = 'ONLINE', 'Online'
        OFFLINE = 'OFFLINE', 'Offline'
        MAINTENANCE = 'MAINTENANCE', 'Maintenance'

    name = models.CharField(max_length=100)
    location = models.CharField(max_length=200)
    ip_address = models.GenericIPAddressField()
    rtsp_url = models.URLField(max_length=500, blank=True)
    status = models.CharField(max_length=20, choices=CameraStatus.choices, default=CameraStatus.OFFLINE)
    is_active = models.BooleanField(default=True)
    assigned_gate = models.CharField(max_length=100, blank=True)
    assigned_hostel = models.CharField(max_length=100, blank=True)
    last_health_check = models.DateTimeField(null=True, blank=True)
    resolution = models.CharField(max_length=20, default='1920x1080')
    notes = models.TextField(blank=True)

    class Meta(TimeStampedModel.Meta):
        verbose_name = 'Camera'

    def __str__(self):
        return f'{self.name} ({self.location}) — {self.status}'