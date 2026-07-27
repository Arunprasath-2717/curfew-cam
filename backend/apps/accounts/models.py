"""Custom User model with UUID, email login, and role-based permissions."""
import uuid
from django.contrib.auth.models import AbstractUser, BaseUserManager
from django.db import models


class UserRole(models.TextChoices):
    STUDENT = 'student', 'Student'
    WARDEN = 'warden', 'Warden'
    WATCHMAN = 'watchman', 'Watchman'
    ADMIN = 'admin', 'Admin'
    ADMIN_WARDEN = 'admin_warden', 'Admin Warden'


class CustomUserManager(BaseUserManager):
    """Custom manager for User model with email as the unique identifier."""

    def create_user(self, email, password=None, **extra_fields):
        if not email:
            raise ValueError('Email is required')
        email = self.normalize_email(email)
        extra_fields.setdefault('is_active', True)
        user = self.model(email=email, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, email, password=None, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        extra_fields.setdefault('role', UserRole.ADMIN)
        extra_fields.setdefault('is_verified', True)
        if not extra_fields.get('is_staff'):
            raise ValueError('Superuser must have is_staff=True.')
        if not extra_fields.get('is_superuser'):
            raise ValueError('Superuser must have is_superuser=True.')
        return self.create_user(email, password, **extra_fields)


class User(AbstractUser):
    """Custom user: UUID PK, email login, role-based."""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    email = models.EmailField(unique=True)
    username = models.CharField(max_length=150, unique=True, blank=True, null=True)
    role = models.CharField(max_length=20, choices=UserRole.choices, default=UserRole.STUDENT)
    phone_number = models.CharField(max_length=15, blank=True)
    date_of_birth = models.DateField(blank=True, null=True)
    avatar = models.ImageField(upload_to='avatars/', blank=True, null=True)
    is_verified = models.BooleanField(default=False)
    current_session_id = models.UUIDField(null=True, blank=True)
    fcm_token = models.CharField(max_length=255, blank=True, null=True, help_text="Firebase Cloud Messaging token for push notifications.")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    objects = CustomUserManager()

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = []

    class Meta:
        verbose_name = 'User'
        verbose_name_plural = 'Users'
        ordering = ['-created_at']

    def __str__(self):
        return self.email

    def save(self, *args, **kwargs):
        if not self.username:
            self.username = self.email.split('@')[0]
        super().save(*args, **kwargs)

    @property
    def full_name(self):
        return f'{self.first_name} {self.last_name}'.strip() or self.email


class StudentWhitelist(models.Model):
    """Whitelist of valid students allowed to register."""
    name = models.CharField(max_length=150)
    register_number = models.CharField(max_length=30, unique=True)
    block = models.CharField(max_length=50, default='Unknown')
    room_number = models.CharField(max_length=20)
    is_claimed = models.BooleanField(default=False)
    claimed_by = models.ForeignKey(
        'User', on_delete=models.SET_NULL, null=True, blank=True,
        related_name='claimed_whitelist'
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = 'Student Whitelist'
        verbose_name_plural = 'Student Whitelists'
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.name} ({self.register_number})"
