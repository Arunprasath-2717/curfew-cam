"""Warden models."""
from django.db import models
from apps.common.models import TimeStampedModel


class WardenProfile(TimeStampedModel):
    """Warden profile."""
    user = models.OneToOneField(
        'accounts.User', on_delete=models.CASCADE,
        related_name='warden_profile',
    )
    employee_id = models.CharField(max_length=30, unique=True)
    hostel_name = models.CharField(max_length=100, null=True, blank=True)
    designation = models.CharField(max_length=100, default='Warden')
    is_chief_warden = models.BooleanField(default=False)
    is_main_warden = models.BooleanField(default=False)
    assigned_year = models.PositiveSmallIntegerField(null=True, blank=True)

    def __str__(self):
        return f'{self.user.full_name} — {self.hostel_name}'

class AuditLog(models.Model):
    """Audit log for warden actions (e.g., add/remove accounts)."""
    ACTION_CHOICES = (
        ('create_student', 'Create Student'),
        ('delete_student', 'Delete Student'),
        ('create_warden', 'Create Warden'),
        ('delete_warden', 'Delete Warden'),
    )
    action = models.CharField(max_length=50, choices=ACTION_CHOICES)
    performed_by = models.ForeignKey(
        'accounts.User', on_delete=models.SET_NULL, null=True,
        related_name='performed_audit_logs',
    )
    target_email = models.EmailField()
    timestamp = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-timestamp']

    def __str__(self):
        return f'{self.action} by {self.performed_by} at {self.timestamp}'