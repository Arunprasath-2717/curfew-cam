from django.test import Client
import json
import time

c = Client(HTTP_HOST='localhost')
email = f"test.otp.verify.{int(time.time())}@srishakthi.ac.in"

from apps.accounts.models import User
from apps.accounts.otp import generate_otp, _otp_key

user = User.objects.create(email=email, first_name="Verify", role="student", is_verified=False)
user.set_password("Password123!")
user.save()

# Generate OTP manually
otp_str = generate_otp(email, purpose='email_verification')
print(f"Generated OTP: {otp_str!r} (type: {type(otp_str)})")

# Fetch it directly from cache to ensure it's there
from django.core.cache import cache
cache_key = _otp_key(email, 'email_verification')
stored_val = cache.get(cache_key)
print(f"OTP from cache: {stored_val!r} (type: {type(stored_val)})")

print("--- TESTING VERIFY OTP VIA DJANGO TEST CLIENT ---")

# Let's verify with exact string code!
verify_resp = c.post('/api/v1/auth/verify-otp/', json.dumps({
    "email": email,
    "otp": otp_str,
    "purpose": "email_verification"
}), content_type="application/json")

print(f"Verify status with string code: {verify_resp.status_code}")
print(verify_resp.json())

# Wait! Let's check what happens if it's sent as int?
if otp_str.isdigit():
    verify_resp_int = c.post('/api/v1/auth/verify-otp/', json.dumps({
        "email": email,
        "otp": int(otp_str),
        "purpose": "email_verification"
    }), content_type="application/json")
    print(f"Verify status with int code: {verify_resp_int.status_code}")
    print(verify_resp_int.json())
