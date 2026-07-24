from django.test import Client
import json
import time

c = Client(HTTP_HOST='localhost')
email = f"test.otp.verify2.{int(time.time())}@srishakthi.ac.in"

from apps.accounts.models import User
from apps.accounts.otp import generate_otp

user = User.objects.create(email=email, first_name="Verify", role="student", is_verified=False)
user.set_password("Password123!")
user.save()

print("--- TESTING INT VS STRING OTP ---")

# 1. String code test
otp_str = generate_otp(email, purpose='email_verification')
resp_str = c.post('/api/v1/auth/verify-otp/', json.dumps({
    "email": email,
    "otp": otp_str,
    "purpose": "email_verification"
}), content_type="application/json")
print(f"Verify status with string code: {resp_str.status_code}")
print(resp_str.json())

# 2. Int code test
otp_str2 = generate_otp(email, purpose='email_verification')
resp_int = c.post('/api/v1/auth/verify-otp/', json.dumps({
    "email": email,
    "otp": int(otp_str2),
    "purpose": "email_verification"
}), content_type="application/json")
print(f"Verify status with int code: {resp_int.status_code}")
print(resp_int.json())
