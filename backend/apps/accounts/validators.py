"""Custom validators."""
import re
from django.core.exceptions import ValidationError


def validate_phone_number(value):
    """Validate phone number format."""
    pattern = r'^\+?[1-9]\d{7,14}$'
    if not re.match(pattern, value):
        raise ValidationError('Enter a valid phone number (e.g., +919876543210)')


def validate_password_strength(value):
    """Enforce password strength."""
    if len(value) < 8:
        raise ValidationError('Password must be at least 8 characters.')
    if not re.search(r'[A-Z]', value):
        raise ValidationError('Password must contain at least one uppercase letter.')
    if not re.search(r'[a-z]', value):
        raise ValidationError('Password must contain at least one lowercase letter.')
    if not re.search(r'\d', value):
        raise ValidationError('Password must contain at least one digit.')
    if not re.search(r'[!@#$%^&*(),.?":{}|<>]', value):
        raise ValidationError('Password must contain at least one special character.')
