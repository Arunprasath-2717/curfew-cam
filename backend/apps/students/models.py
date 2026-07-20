"""Student models."""
from django.db import models
from apps.common.models import TimeStampedModel


class StudentProfile(TimeStampedModel):
    """Student profile linked to User."""
    user = models.OneToOneField(
        'accounts.User', on_delete=models.CASCADE,
        related_name='student_profile',
    )
    register_number = models.CharField(max_length=30, unique=True)
    department = models.CharField(max_length=100)
    year = models.PositiveSmallIntegerField()
    semester = models.PositiveSmallIntegerField(default=1)
    hostel_block = models.CharField(max_length=50)
    room_number = models.CharField(max_length=20)
    face_image = models.ImageField(upload_to='faces/', blank=True, null=True)
    is_in_hostel = models.BooleanField(default=True)
    is_on_campus = models.BooleanField(default=True)

    class Meta(TimeStampedModel.Meta):
        verbose_name = 'Student Profile'

    def __str__(self):
        return f'{self.user.full_name} ({self.register_number})'


class Guardian(TimeStampedModel):
    """Guardian / parent of student."""
    student = models.ForeignKey(
        StudentProfile, on_delete=models.CASCADE, related_name='guardians'
    )
    name = models.CharField(max_length=150)
    relationship = models.CharField(max_length=50)
    phone = models.CharField(max_length=15)
    email = models.EmailField(blank=True)
    is_primary = models.BooleanField(default=False)

    def __str__(self):
        return f'{self.name} ({self.relationship}) for {self.student}'