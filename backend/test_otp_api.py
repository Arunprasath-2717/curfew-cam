import sys
from django.test import Client
from apps.accounts.models import User
import json

c = Client()

print("--- TESTING OTP VIA API ---")

# First create a test user
email = "test.otp@srishakthi.ac.in"
# Register endpoint generates OTP
resp = c.post('/api/accounts/student-register/', {
    "name": "Test Student",
    "email": email,
    "password": "Password123!",
    "register_number": "12345678"
})

print(f"Register status: {resp.status_code}")
if resp.status_code != 201:
    print(resp.json())
    sys.exit(1)

# Get the OTP directly from cache to simulate what user gets in email
from django.core.cache import cache
from apps.accounts.otp import _otp_key
cache_key = _otp_key(email, 'email_verification')
otp_val = cache.get(cache_key)
print(f"OTP from cache (what is emailed): {otp_val!r} (type: {type(otp_val)})")

# Try to verify it
resp_verify = c.post('/api/accounts/verify-otp/', {
    "email": email,
    "otp": otp_val,
    "purpose": "email_verification"
})

print(f"Verify OTP status: {resp_verify.status_code}")
print(resp_verify.json())
