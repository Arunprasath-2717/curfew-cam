import urllib.request
import json
import time

base_url = "http://localhost:8000/api/v1/auth"
email = "test.otp.reset@srishakthi.ac.in"

import sys
sys.path.append("/app")
from apps.accounts.models import User

# Ensure user exists
user, created = User.objects.get_or_create(email=email, defaults={
    "first_name": "Reset",
    "role": "student",
    "is_verified": True
})
if created:
    user.set_password("Password123!")
    user.save()

print("--- TESTING PASSWORD RESET OTP VIA REAL HTTP SERVER ---")

data = json.dumps({"email": email}).encode('utf-8')
req = urllib.request.Request(f"{base_url}/password-reset/request/", data=data, headers={'Content-Type': 'application/json'})

try:
    with urllib.request.urlopen(req) as response:
        resp_data = json.loads(response.read())
        print(f"Request status: {response.status}")
        session_token = resp_data['data']['reset_session']
except urllib.error.HTTPError as e:
    print(f"Failed to request reset. Status: {e.code}")
    print(e.read().decode('utf-8'))
    import sys; sys.exit(1)

print(f"Got session_token: {session_token}")

from django.core.cache import cache
from django.core.signing import TimestampSigner

signer = TimestampSigner(salt='password-reset')
user_id_str = signer.unsign(session_token, max_age=600)
cache_key = f'reset_code:{user_id_str}'

otp_val = cache.get(cache_key)

print(f"OTP from cache: {otp_val!r} (type: {type(otp_val)})")

if not otp_val:
    print("OTP not found in cache!")
    sys.exit(1)

print("Attempting to verify OTP via API...")

verify_data = json.dumps({
    "session_token": session_token,
    "code": otp_val
}).encode('utf-8')

verify_req = urllib.request.Request(f"{base_url}/password-reset/verify-otp/", data=verify_data, headers={'Content-Type': 'application/json'})

try:
    with urllib.request.urlopen(verify_req) as response:
        print(f"Verify status: {response.status}")
        print(response.read().decode('utf-8'))
except urllib.error.HTTPError as e:
    print(f"Verify failed. Status: {e.code}")
    print(e.read().decode('utf-8'))
