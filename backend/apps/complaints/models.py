import uuid
from django.db import models
from django.conf import settings


class ComplaintCategory(models.TextChoices):
    MAINTENANCE = 'maintenance', 'Maintenance / Repair'
    FOOD_MESS = 'food_mess', 'Food & Mess'
    NOISE_DISCIPLINE = 'noise_discipline', 'Noise & Discipline'
    SECURITY = 'security', 'Security & Safety'
    FACILITIES = 'facilities', 'Facilities & Amenities'
    OTHER = 'other', 'Other Issues'


class ComplaintPriority(models.TextChoices):
    LOW = 'low', 'Low'
    MEDIUM = 'medium', 'Medium'
    HIGH = 'high', 'High'
    URGENT = 'urgent', 'Urgent'


class ComplaintStatus(models.TextChoices):
    PENDING = 'pending', 'Pending'
    IN_PROGRESS = 'in_progress', 'In Progress'
    RESOLVED = 'resolved', 'Resolved'
    REJECTED = 'rejected', 'Rejected'


class Complaint(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    student = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='complaints'
    )
    title = models.CharField(max_length=200)
    category = models.CharField(
        max_length=30,
        choices=ComplaintCategory.choices,
        default=ComplaintCategory.OTHER
    )
    priority = models.CharField(
        max_length=20,
        choices=ComplaintPriority.choices,
        default=ComplaintPriority.MEDIUM
    )
    description = models.TextField()
    status = models.CharField(
        max_length=20,
        choices=ComplaintStatus.choices,
        default=ComplaintStatus.PENDING
    )
    is_anonymous = models.BooleanField(
        default=False,
        help_text="If true, student identity is hidden from public logs"
    )
    warden_response = models.TextField(blank=True, default='')
    assigned_warden = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='handled_complaints'
    )
    resolved_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        app_label = 'complaints'
        verbose_name = 'Complaint'
        verbose_name_plural = 'Complaints'
        ordering = ['-created_at']

    def __str__(self):
        return f"[{self.get_priority_display()}] {self.title} ({self.get_status_display()})"
