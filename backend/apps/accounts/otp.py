"""OTP generation, storage (cache), and verification."""
import random
import logging
from django.core.cache import cache

logger = logging.getLogger(__name__)

OTP_EXPIRY = 600  # 10 minutes
OTP_LENGTH = 6


def _otp_key(email, purpose='default'):
    return f'otp:{purpose}:{email}'


def generate_otp(email, purpose='email_verification'):
    """Generate a 6-digit OTP and store in cache."""
    otp = ''.join(str(random.randint(0, 9)) for _ in range(OTP_LENGTH))
    key = _otp_key(email, purpose)
    cache.set(key, otp, timeout=OTP_EXPIRY)
    logger.info('OTP generated for %s (%s)', email, purpose)
    return otp


def verify_otp(email, otp, purpose='email_verification'):
    """Verify OTP from cache. Returns True and deletes key on success."""
    key = _otp_key(email, purpose)
    stored = cache.get(key)
    if stored is None:
        return False, 'OTP expired or not found'
    if stored != str(otp):
        return False, 'Invalid OTP'
    cache.delete(key)
    return True, 'OTP verified'


def invalidate_otp(email, purpose='email_verification'):
    """Delete stored OTP."""
    cache.delete(_otp_key(email, purpose))
