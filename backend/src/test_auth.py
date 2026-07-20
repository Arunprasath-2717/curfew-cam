import os
import django
import requests

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from apps.accounts.models import User
# Let's find the OTP model
from django.apps import apps
OTPModel = None
for model in apps.get_models():
    if 'otp' in model.__name__.lower():
        OTPModel = model
        break

BASE = 'http://127.0.0.1:8000/api/v1/auth'

print("Trying to register a user...")
res = requests.post(f"{BASE}/register/", json={
    "email": "test_reset@example.com",
    "password": "Password123!",
    "password2": "Password123!",
    "first_name": "Test",
    "last_name": "Reset",
    "role": "student"
})
print("Register:", res.status_code, res.text)

print("\n1. Forgot Password")
res = requests.post(f"{BASE}/forgot-password/", json={"email": "test_reset@example.com"})
print("Forgot Password:", res.status_code, res.text)

if OTPModel:
    otp_obj = OTPModel.objects.filter(email='test_reset@example.com').order_by('-created_at').first()
    if otp_obj:
        otp = otp_obj.otp
        print(f"\nExtracted OTP from DB: {otp}")
        
        print("\n2. Verify OTP")
        res = requests.post(f"{BASE}/verify-otp/", json={
            "email": "test_reset@example.com",
            "otp": otp,
            "purpose": "password_reset"
        })
        print("Verify OTP:", res.status_code, res.text)
        
        print("\n3. Reset Password")
        res = requests.post(f"{BASE}/reset-password/", json={
            "email": "test_reset@example.com",
            "otp": otp,
            "new_password": "NewPassword123!",
            "new_password2": "NewPassword123!"
        })
        print("Reset Password:", res.status_code, res.text)

        print("\n4. Login with new password")
        res = requests.post(f"{BASE}/login/", json={
            "email": "test_reset@example.com",
            "password": "NewPassword123!"
        })
        print("Login:", res.status_code, res.text)
    else:
        print("Failed to find OTP in DB")
else:
    print("Could not find OTP model")

