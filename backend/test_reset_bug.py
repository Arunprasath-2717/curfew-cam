from django.test import Client
import json
import time

c = Client(HTTP_HOST='localhost')
email = f"test.otp.reset.verify.{int(time.time())}@srishakthi.ac.in"

from apps.accounts.models import User
from apps.accounts.services import request_password_reset

user = User.objects.create(email=email, first_name="Reset", role="student", is_verified=True)
user.set_password("Password123!")
user.save()

# Generate session_token and code via request_password_reset
session_token = request_password_reset(email)

# Get the code from cache
from django.core.signing import TimestampSigner
from django.core.cache import cache
signer = TimestampSigner(salt='password-reset')
user_id_str = signer.unsign(session_token, max_age=600)
cache_key = f'reset_code:{user_id_str}'
code_str = cache.get(cache_key)

print(f"Generated password reset code: {code_str!r} (type: {type(code_str)})")

print("--- TESTING PASSWORD RESET VERIFY OTP ---")

# 1. String code test
resp_str = c.post('/api/v1/auth/password-reset/verify-otp/', json.dumps({
    "session_token": session_token,
    "code": code_str
}), content_type="application/json")
print(f"Verify status with string code: {resp_str.status_code}")
print(resp_str.json())

# 2. Int code test
resp_int = c.post('/api/v1/auth/password-reset/verify-otp/', json.dumps({
    "session_token": session_token,
    "code": int(code_str)
}), content_type="application/json")
print(f"Verify status with int code: {resp_int.status_code}")
print(resp_int.json())
