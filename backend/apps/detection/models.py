"""Detection models."""
from django.db import models
from apps.common.models import TimeStampedModel


class Detection(TimeStampedModel):
    """AI detection event."""

    class DetectionType(models.TextChoices):
        PERSON = 'PERSON', 'Person'
        FACE = 'FACE', 'Face'
        SUSPICIOUS = 'SUSPICIOUS', 'Suspicious Activity'

    camera = models.ForeignKey('camera.Camera', on_delete=models.CASCADE, related_name='detections')
    detection_type = models.CharField(max_length=20, choices=DetectionType.choices, default=DetectionType.PERSON)
    image = models.ImageField(upload_to='detections/')
    confidence = models.FloatField()
    bounding_box = models.JSONField(default=dict, blank=True)
    matched_student = models.ForeignKey(
        'students.StudentProfile', on_delete=models.SET_NULL,
        null=True, blank=True, related_name='detections',
    )
    metadata = models.JSONField(default=dict, blank=True)

    class Meta(TimeStampedModel.Meta):
        verbose_name = 'Detection'

    def __str__(self):
        return f'{self.detection_type} on {self.camera.name} ({self.confidence:.2f})'


class Alert(TimeStampedModel):
    """Alert triggered by detection."""

    class AlertLevel(models.TextChoices):
        INFO = 'INFO', 'Info'
        WARNING = 'WARNING', 'Warning'
        CRITICAL = 'CRITICAL', 'Critical'

    class AlertStatus(models.TextChoices):
        ACTIVE = 'ACTIVE', 'Active'
        ACKNOWLEDGED = 'ACKNOWLEDGED', 'Acknowledged'
        RESOLVED = 'RESOLVED', 'Resolved'

    detection = models.ForeignKey(Detection, on_delete=models.CASCADE, related_name='alerts', null=True, blank=True)
    title = models.CharField(max_length=200)
    message = models.TextField()
    level = models.CharField(max_length=20, choices=AlertLevel.choices, default=AlertLevel.WARNING)
    status = models.CharField(max_length=20, choices=AlertStatus.choices, default=AlertStatus.ACTIVE)
    acknowledged_by = models.ForeignKey(
        'accounts.User', on_delete=models.SET_NULL, null=True, blank=True,
    )
    acknowledged_at = models.DateTimeField(null=True, blank=True)

    class Meta(TimeStampedModel.Meta):
        verbose_name = 'Alert'

    def __str__(self):
        return f'[{self.level}] {self.title}'