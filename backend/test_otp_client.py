from django.test import Client
import json
import time

c = Client(HTTP_HOST='localhost')
email = f"test.otp.reset.{int(time.time())}@srishakthi.ac.in"

from apps.accounts.models import User
user, created = User.objects.get_or_create(email=email, defaults={
    "first_name": "Reset",
    "role": "student",
    "is_verified": True
})
if created:
    user.set_password("Password123!")
    user.save()

print("--- TESTING PASSWORD RESET OTP VIA DJANGO TEST CLIENT ---")

resp = c.post('/api/v1/auth/password-reset/request/', json.dumps({"email": email}), content_type="application/json")
if resp.status_code != 200:
    print(f"Failed to request reset. Status: {resp.status_code}")
    print(resp.json())
    import sys; sys.exit(1)

resp_data = resp.json()
session_token = resp_data['data']['reset_session']
print(f"Got session_token: {session_token}")

from django.core.cache import cache
from django.core.signing import TimestampSigner

signer = TimestampSigner(salt='password-reset')
user_id_str = signer.unsign(session_token, max_age=600)
cache_key = f'reset_code:{user_id_str}'

otp_val = cache.get(cache_key)
print(f"OTP from cache: {otp_val!r} (type: {type(otp_val)})")

# Let's verify!
verify_resp = c.post('/api/v1/auth/password-reset/verify-otp/', json.dumps({
    "session_token": session_token,
    "code": otp_val
}), content_type="application/json")

print(f"Verify status with string code: {verify_resp.status_code}")
print(verify_resp.json())

# Wait! The bug could be type mismatch! Let's also check what happens if it's sent as int?
if otp_val.isdigit():
    verify_resp_int = c.post('/api/v1/auth/password-reset/verify-otp/', json.dumps({
        "session_token": session_token,
        "code": int(otp_val)
    }), content_type="application/json")
    print(f"Verify status with int code: {verify_resp_int.status_code}")
    print(verify_resp_int.json())
