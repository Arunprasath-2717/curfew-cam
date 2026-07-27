"""Outpass models."""
from django.db import models
from django.utils import timezone
from apps.common.models import TimeStampedModel


class Outpass(TimeStampedModel):
    """Outpass request from student."""

    class Status(models.TextChoices):
        PENDING = 'PENDING', 'Pending'
        APPROVED = 'APPROVED', 'Approved'
        REJECTED = 'REJECTED', 'Rejected'
        CANCELLED = 'CANCELLED', 'Cancelled'
        ACTIVE = 'ACTIVE', 'Active (Exited)'
        RETURNED = 'RETURNED', 'Returned'
        EXPIRED = 'EXPIRED', 'Expired'
        OVERDUE = 'OVERDUE', 'Overdue'

    class OutpassType(models.TextChoices):
        REGULAR = 'REGULAR', 'Regular'
        EMERGENCY = 'EMERGENCY', 'Emergency'
        WEEKEND = 'WEEKEND', 'Weekend'

    student = models.ForeignKey(
        'students.StudentProfile', on_delete=models.CASCADE,
        related_name='outpasses',
    )
    approved_by = models.ForeignKey(
        'wardens.WardenProfile', on_delete=models.SET_NULL,
        null=True, blank=True, related_name='approved_outpasses',
    )
    class AutoDetectMethod(models.TextChoices):
        WIFI = "wifi", "WiFi"
        GEOFENCE = "geofence", "Geofence"
        MANUAL_SCAN = "manual_scan", "Manual Scan"

    outpass_type = models.CharField(max_length=20, choices=OutpassType.choices, default=OutpassType.REGULAR)
    reason = models.TextField()
    destination = models.CharField(max_length=255, blank=True)

    exit_date = models.DateField()
    exit_time = models.TimeField()
    expected_return_date = models.DateField()
    expected_return_time = models.TimeField()

    actual_exit_time = models.DateTimeField(null=True, blank=True)
    actual_return_time = models.DateTimeField(null=True, blank=True)
    reviewed_at = models.DateTimeField(null=True, blank=True)

    status = models.CharField(max_length=20, choices=Status.choices, default=Status.PENDING)
    rejection_reason = models.TextField(blank=True)
    warden_notes = models.TextField(blank=True)
    auto_detect_method = models.CharField(
        max_length=20, choices=AutoDetectMethod.choices, null=True, blank=True
    )

    class Meta(TimeStampedModel.Meta):
        verbose_name = 'Outpass'
        verbose_name_plural = 'Outpasses'

    def __str__(self):
        return f'{self.student} — {self.status}'

    @property
    def expected_return_at(self):
        return timezone.make_aware(
            timezone.datetime.combine(self.expected_return_date, self.expected_return_time)
        )

    @classmethod
    def mark_overdue_outpasses(cls, queryset=None):
        qs = queryset if queryset is not None else cls.objects.all()
        now = timezone.now()
        
        # 1. Mark APPROVED passes overdue if expected return date/time has passed without exit or return
        overdue_ids = [
            op.id for op in qs.filter(status=cls.Status.APPROVED)
            if now > op.expected_return_at
        ]
        if overdue_ids:
            cls.objects.filter(id__in=overdue_ids).update(status=cls.Status.OVERDUE)

        # 2. Auto-expire PENDING passes whose expected return time has already passed
        expired_pending_ids = [
            op.id for op in qs.filter(status=cls.Status.PENDING)
            if now > op.expected_return_at
        ]
        if expired_pending_ids:
            cls.objects.filter(id__in=expired_pending_ids).update(status=cls.Status.EXPIRED)

        return len(overdue_ids) + len(expired_pending_ids)

    @property
    def is_late(self):
        """Check if student returned late or hasn't returned yet."""
        if self.status == self.Status.RETURNED and self.actual_return_time:
            return self.actual_return_time > self.expected_return_at
        if self.status == self.Status.ACTIVE:
            return timezone.now() > self.expected_return_at
        return False
