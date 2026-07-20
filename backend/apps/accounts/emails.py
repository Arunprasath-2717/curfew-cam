"""Email service for sending templated emails."""
import logging
from django.core.mail import send_mail
from django.conf import settings

logger = logging.getLogger(__name__)


def send_otp_email(email, otp, purpose='email_verification'):
    """Send OTP via email."""
    subject_map = {
        'email_verification': 'Verify your CurfewCam account',
        'password_reset': 'CurfewCam Password Reset OTP',
    }
    body_map = {
        'email_verification': (
            f'Welcome to CurfewCam!\n\n'
            f'Your verification OTP is: {otp}\n\n'
            f'This OTP expires in 10 minutes.\n'
            f'If you did not create an account, please ignore this email.'
        )
    }
    try:
        resend_key = getattr(settings, 'RESEND_API_KEY', '')
        subject = subject_map.get(purpose, 'CurfewCam OTP')
        message = body_map.get(purpose, f'Your OTP is: {otp}')
        
        if resend_key:
            import resend
            resend.api_key = resend_key
            r = resend.Emails.send({
                "from": settings.DEFAULT_FROM_EMAIL,
                "to": [email],
                "subject": subject,
                "text": message
            })
            logger.info('OTP email sent via Resend to %s: %s', email, r)
        else:
            send_mail(
                subject=subject,
                message=message,
                from_email=settings.DEFAULT_FROM_EMAIL,
                recipient_list=[email],
                fail_silently=False,
            )
            logger.info('OTP email sent via console to %s for %s', email, purpose)
    except Exception as e:
        logger.error('Failed to send OTP email to %s: %s', email, e)


def send_password_reset_email(email, code):
    """Send 6-digit password reset code via email."""
    subject = 'CurfewCam Password Reset Code'
    message = (
        f'Password Reset Request\n\n'
        f'Your secure reset code is: {code}\n\n'
        f'This code expires in 10 minutes.\n'
        f'If you did not request a password reset, please ignore this email.'
    )
    try:
        resend_key = getattr(settings, 'RESEND_API_KEY', '')
        if resend_key:
            import resend
            resend.api_key = resend_key
            r = resend.Emails.send({
                "from": settings.DEFAULT_FROM_EMAIL,
                "to": [email],
                "subject": subject,
                "text": message
            })
            logger.info('Password reset email sent via Resend to %s: %s', email, r)
        else:
            send_mail(
                subject=subject,
                message=message,
                from_email=settings.DEFAULT_FROM_EMAIL,
                recipient_list=[email],
                fail_silently=False,
            )
            logger.info('Password reset email sent via console to %s', email)
    except Exception as e:
        logger.error('Failed to send password reset email to %s: %s', email, e)


def send_outpass_notification(email, outpass_status, student_name):
    """Notify student about outpass status change."""
    subject = f'CurfewCam: Outpass {outpass_status}'
    message = (
        f'Dear {student_name},\n\n'
        f'Your outpass request has been {outpass_status.lower()}.\n\n'
        f'Please check your CurfewCam app for details.\n\n'
        f'— CurfewCam Team'
    )
    try:
        send_mail(
            subject=subject,
            message=message,
            from_email=settings.DEFAULT_FROM_EMAIL,
            recipient_list=[email],
            fail_silently=False,
        )
    except Exception as e:
        logger.error('Failed to send outpass notification: %s', e)


def send_late_return_alert(warden_email, student_name, expected_time):
    """Alert warden about late return."""
    send_mail(
        subject=f'ALERT: Late Return — {student_name}',
        message=(
            f'{student_name} has not returned by the expected time '
            f'({expected_time}).\n\nPlease check the CurfewCam dashboard.'
        ),
        from_email=settings.DEFAULT_FROM_EMAIL,
        recipient_list=[warden_email],
        fail_silently=True,
    )
