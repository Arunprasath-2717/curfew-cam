"""Base models shared across apps."""
import uuid
from django.db import models


class TimeStampedModel(models.Model):
    """Abstract base model with UUID pk and timestamps."""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        abstract = True
        ordering = ['-created_at']


class MovementLog(TimeStampedModel):
    """Log of student movements through gates."""
    student = models.ForeignKey(
        'students.StudentProfile', on_delete=models.CASCADE,
        related_name='movement_logs'
    )
    action = models.CharField(max_length=50)
    gate = models.CharField(max_length=100, blank=True)
    recorded_by = models.ForeignKey(
        'accounts.User', on_delete=models.SET_NULL,
        null=True, blank=True, related_name='recorded_movements'
    )
    notes = models.TextField(blank=True)

    def __str__(self):
        return f'{self.student} - {self.action} at {self.created_at}'


class Campus(TimeStampedModel):
    """Campus location and wifi settings."""
    name = models.CharField(max_length=100, default='Main Campus')
    campus_wifi_ssid = models.CharField(max_length=100, blank=True)
    campus_latitude = models.FloatField(null=True, blank=True)
    campus_longitude = models.FloatField(null=True, blank=True)
    geofence_radius_meters = models.FloatField(default=100.0)

    class Meta(TimeStampedModel.Meta):
        verbose_name = 'Campus Settings'
        verbose_name_plural = 'Campus Settings'

    def __str__(self):
        return self.name