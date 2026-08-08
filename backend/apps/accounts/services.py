"""Auth service layer."""
import logging
from rest_framework_simplejwt.tokens import RefreshToken
from .models import User
from .otp import generate_otp
from .emails import send_otp_email

logger = logging.getLogger(__name__)


def get_tokens_for_user(user):
    """Generate JWT access + refresh tokens for user."""
    import uuid
    user.current_session_id = uuid.uuid4()
    user.save(update_fields=['current_session_id'])
    
    refresh = RefreshToken.for_user(user)
    refresh['session_id'] = str(user.current_session_id)
    return {
        'refresh': str(refresh),
        'access': str(refresh.access_token),
    }


def register_user(validated_data):
    """Create user account and send verification OTP."""
    password = validated_data.pop('password')
    validated_data.pop('password2', None)
    user = User(**validated_data)
    user.set_password(password)
    user.is_verified = False
    user.save()

    # Generate and send verification OTP
    otp = generate_otp(user.email, purpose='email_verification')
    send_otp_email(user.email, otp, purpose='email_verification')

    tokens = get_tokens_for_user(user)
    return user, tokens


def register_user_with_domain_check(validated_data):
    """Register user based on email domain check instead of whitelist."""
    from django.db import transaction
    from rest_framework.exceptions import ValidationError
    from .models import UserRole
    from apps.students.models import StudentProfile
    from apps.wardens.models import WardenProfile

    name = validated_data.get('name', '').strip()
    email = validated_data['email'].lower()
    password = validated_data['password']
    phone_number = validated_data.get('phone_number', '').strip()

    if email.endswith('@srishakthi.ac.in'):
        role = UserRole.STUDENT
        register_number = validated_data.get('register_number', '').strip()
        if not register_number:
            raise ValidationError({'register_number': ["Register number is required for students."]})
            
        from apps.accounts.models import StudentWhitelist
        try:
            whitelist_entry = StudentWhitelist.objects.get(register_number=register_number)
        except StudentWhitelist.DoesNotExist:
            raise ValidationError({'register_number': ["Register number not found in the approved student roster."]})
            
        if whitelist_entry.is_claimed:
            raise ValidationError({'register_number': ["This register number has already been claimed."]})
    else:
        raise ValidationError({'email': ["Only @srishakthi.ac.in domains are allowed for students."]})

    if User.objects.filter(email__iexact=email).exists():
        raise ValidationError({'email': ["This email is already in use"]})

    with transaction.atomic():
        parts = name.split(' ', 1)
        first_name = parts[0]
        last_name = parts[1] if len(parts) > 1 else ''
        
        user = User(
            email=email,
            role=role,
            is_verified=False,
            first_name=first_name,
            last_name=last_name,
            phone_number=phone_number
        )
        user.set_password(password)
        user.save()

        if role == UserRole.STUDENT:
            # Update student profile (created by signal)
            profile = StudentProfile.objects.get(user=user)
            profile.register_number = whitelist_entry.register_number
            profile.department = whitelist_entry.department
            profile.year = whitelist_entry.year or 1
            profile.hostel_block = whitelist_entry.hostel_block
            profile.room_number = whitelist_entry.room_number
            profile.save()
            
            whitelist_entry.is_claimed = True
            whitelist_entry.claimed_by = user
            whitelist_entry.save()

    # Generate and send verification OTP
    otp = generate_otp(user.email, purpose='email_verification')
    send_otp_email(user.email, otp, purpose='email_verification')

    tokens = get_tokens_for_user(user)
    return user, tokens


def request_password_reset(email):
    """Generate a short 6-digit code and store it in cache for the user, sending it via email."""
    import random
    from django.core.cache import cache
    from django.core.signing import TimestampSigner
    from .emails import send_password_reset_email

    try:
        user = User.objects.get(email__iexact=email)
    except User.DoesNotExist:
        # Prevent enumeration
        signer = TimestampSigner(salt='password-reset')
        dummy_session = signer.sign(email)
        return dummy_session

    code = ''.join(str(random.randint(0, 9)) for _ in range(6))
    cache_key = f'reset_code:{user.id}'
    cache.set(cache_key, code, timeout=600)  # 10 minutes expiry

    # Sign the user id to pass back to the frontend
    signer = TimestampSigner(salt='password-reset')
    session_token = signer.sign(str(user.id))

    # Send only the 6-digit code via email using Celery
    from .tasks import send_password_reset_email_task
    send_password_reset_email_task.delay(user.email, code)
    
    return session_token


def check_password_reset_otp(session_token, code):
    """Just verify the OTP is correct for the session_token without deleting it."""
    from django.core.cache import cache
    from django.core.signing import TimestampSigner, BadSignature, SignatureExpired
    
    signer = TimestampSigner(salt='password-reset')
    try:
        user_id_str = signer.unsign(session_token, max_age=600)
    except (BadSignature, SignatureExpired):
        return False, "Reset link expired or invalid — request a new one"

    cache_key = f'reset_code:{user_id_str}'
    stored_code = cache.get(cache_key)
    
    if stored_code is None or stored_code != str(code):
        return False, "Invalid or expired reset code"
        
    return True, "Valid code"


def confirm_password_reset(session_token, code, new_password):
    """Verify session_token signature, check cache for the 6-digit code, and reset password."""
    import uuid
    from django.core.cache import cache
    from django.core.signing import TimestampSigner, BadSignature, SignatureExpired
    
    signer = TimestampSigner(salt='password-reset')
    try:
        # Check if the session token is valid and not older than 10 minutes
        user_id_str = signer.unsign(session_token, max_age=600)
    except (BadSignature, SignatureExpired):
        return False, "Reset link expired or invalid — request a new one"

    cache_key = f'reset_code:{user_id_str}'
    stored_code = cache.get(cache_key)
    
    if stored_code is None or stored_code != str(code):
        return False, "Reset link expired or invalid — request a new one"

    try:
        user = User.objects.get(id=user_id_str)
        user.set_password(new_password)
        # Invalidate all active sessions
        user.current_session_id = uuid.uuid4()
        user.save()
        
        # Clear the reset code to make it single-use
        cache.delete(cache_key)
        return True, "Password reset successful"
    except User.DoesNotExist:
        return False, "Reset link expired or invalid — request a new one"
