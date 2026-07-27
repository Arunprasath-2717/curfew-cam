"""QR code generation and validation services."""
import hashlib
import hmac
import json
import base64
import io
import logging
from datetime import timedelta

import qrcode
from django.conf import settings
from django.core.files.base import ContentFile
from django.utils import timezone

from .models import QRPass
from apps.outpass.models import Outpass

logger = logging.getLogger(__name__)


def _generate_hmac(payload_str):
    """Generate HMAC-SHA256 signature."""
    secret = settings.QR_HMAC_SECRET.encode()
    return hmac.new(secret, payload_str.encode(), hashlib.sha256).hexdigest()


def _encode_payload(data):
    """Base64 encode payload data."""
    json_str = json.dumps(data, sort_keys=True, default=str)
    return base64.urlsafe_b64encode(json_str.encode()).decode()


def _decode_payload(encoded):
    """Decode base64 payload."""
    try:
        decoded = base64.urlsafe_b64decode(encoded.encode())
        return json.loads(decoded)
    except Exception:
        return None


def generate_qr_for_outpass(outpass):
    """Generate a secure QR pass for an approved outpass."""
    # Build payload
    payload = {
        'outpass_id': str(outpass.id),
        'student_id': str(outpass.student.id),
        'student_register': outpass.student.register_number,
        'exit_date': str(outpass.exit_date),
        'return_date': str(outpass.expected_return_date),
        'issued_at': str(timezone.now()),
    }

    encoded_payload = _encode_payload(payload)
    signature = _generate_hmac(encoded_payload)
    token = f'{encoded_payload}.{signature}'

    expiry = timezone.now() + timedelta(hours=settings.QR_EXPIRY_HOURS)

    # Generate QR image
    qr = qrcode.QRCode(version=1, box_size=10, border=4)
    qr.add_data(token)
    qr.make(fit=True)
    img = qr.make_image(fill_color='black', back_color='white')

    buffer = io.BytesIO()
    img.save(buffer, format='PNG')
    buffer.seek(0)

    # Create QRPass
    qr_pass = QRPass.objects.create(
        outpass=outpass,
        token=token,
        hmac_signature=signature,
        encrypted_payload=encoded_payload,
        expires_at=expiry,
        max_scans=2,
    )
    qr_pass.qr_image.save(
        f'qr_{outpass.student.register_number}_{outpass.id}.png',
        ContentFile(buffer.read()),
        save=True,
    )

    logger.info('QR generated for outpass %s', outpass.id)
    return qr_pass


def regenerate_qr_for_outpass(outpass):
    """Force new token/hmac on the same QRPass row."""
    payload = {
        'outpass_id': str(outpass.id),
        'student_id': str(outpass.student.id),
        'student_register': outpass.student.register_number,
        'exit_date': str(outpass.exit_date),
        'return_date': str(outpass.expected_return_date),
        'issued_at': str(timezone.now()),
    }

    encoded_payload = _encode_payload(payload)
    signature = _generate_hmac(encoded_payload)
    token = f'{encoded_payload}.{signature}'
    expiry = timezone.now() + timedelta(hours=settings.QR_EXPIRY_HOURS)

    qr = qrcode.QRCode(version=1, box_size=10, border=4)
    qr.add_data(token)
    qr.make(fit=True)
    img = qr.make_image(fill_color='black', back_color='white')

    buffer = io.BytesIO()
    img.save(buffer, format='PNG')
    buffer.seek(0)

    if hasattr(outpass, 'qr_pass'):
        qr_pass = outpass.qr_pass
        qr_pass.token = token
        qr_pass.hmac_signature = signature
        qr_pass.encrypted_payload = encoded_payload
        qr_pass.expires_at = expiry
        qr_pass.is_used = False
        qr_pass.scan_count = 0
        qr_pass.qr_image.save(
            f'qr_{outpass.student.register_number}_{outpass.id}.png',
            ContentFile(buffer.read()),
            save=False,
        )
        qr_pass.save()
    else:
        qr_pass = generate_qr_for_outpass(outpass)

    logger.info('QR regenerated for outpass %s', outpass.id)
    return qr_pass


def validate_qr_token(token):
    """Validate a QR token. Returns (is_valid, result_or_error)."""
    try:
        parts = token.rsplit('.', 1)
        if len(parts) != 2:
            return False, 'Invalid QR format'

        encoded_payload, provided_sig = parts
        expected_sig = _generate_hmac(encoded_payload)

        if not hmac.compare_digest(provided_sig, expected_sig):
            return False, 'QR signature verification failed'

        # Look up pass
        try:
            qr_pass = QRPass.objects.select_related('outpass__student__user').get(token=token)
        except QRPass.DoesNotExist:
            return False, 'QR pass not found'

        if qr_pass.is_expired:
            return False, 'QR pass has expired'

        if qr_pass.is_used:
            return False, 'QR pass already used'

        if qr_pass.scan_count >= qr_pass.max_scans:
            return False, 'Maximum scans exceeded'

        # Check outpass status (real enum values are uppercase — was previously
        # comparing against lowercase strings that could never match)
        if qr_pass.outpass.status in [
            Outpass.Status.CANCELLED, Outpass.Status.REJECTED, Outpass.Status.OVERDUE
        ]:
            return False, f'Outpass is {qr_pass.outpass.status}'

        # Check if the current time is valid for the outpass window.
        # expected_return_date is a plain date — comparing it directly to an
        # aware datetime raises TypeError. Use the expected_return_at property,
        # which combines date+time into a proper aware datetime.
        now = timezone.now()
        if now > qr_pass.outpass.expected_return_at:
            return False, 'Outpass return time has passed'

        # Increment scan count
        qr_pass.scan_count += 1
        qr_pass.save()

        return True, qr_pass

    except Exception as e:
        logger.error('QR validation error: %s', e)
        return False, 'QR validation error'
