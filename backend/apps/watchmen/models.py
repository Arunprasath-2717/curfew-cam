"""Watchman models."""
from django.db import models
from apps.common.models import TimeStampedModel


class WatchmanProfile(TimeStampedModel):
    """Watchman profile."""
    user = models.OneToOneField(
        'accounts.User', on_delete=models.CASCADE,
        related_name='watchman_profile',
    )
    employee_id = models.CharField(max_length=30, unique=True)
    assigned_gate = models.CharField(max_length=100)
    is_on_duty = models.BooleanField(default=False)

    def __str__(self):
        return f'{self.user.full_name} — Gate: {self.assigned_gate}'


class ShiftLog(TimeStampedModel):
    """Shift start/end log for watchman."""
    watchman = models.ForeignKey(WatchmanProfile, on_delete=models.CASCADE, related_name='shifts')
    shift_start = models.DateTimeField()
    shift_end = models.DateTimeField(null=True, blank=True)
    gate = models.CharField(max_length=100)
    notes = models.TextField(blank=True)

    def __str__(self):
        return f'{self.watchman} — {self.shift_start}'


class GateScan(TimeStampedModel):
    """Record of QR scan at gate."""

    class ScanType(models.TextChoices):
        EXIT = 'EXIT', 'Exit'
        RETURN = 'RETURN', 'Return'

    qr_pass = models.ForeignKey('qr.QRPass', on_delete=models.CASCADE, related_name='scans')
    watchman = models.ForeignKey(WatchmanProfile, on_delete=models.SET_NULL, null=True, related_name='scans')
    scan_type = models.CharField(max_length=10, choices=ScanType.choices)
    gate = models.CharField(max_length=100, blank=True)
    notes = models.TextField(blank=True)

    def __str__(self):
        return f'{self.scan_type} — {self.qr_pass}'