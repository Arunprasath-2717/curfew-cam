import requests

BASE = 'http://127.0.0.1:8000/api/v1/auth'

# We need a user to test this on. Let's create one first.
print("Trying to register a user...")
res = requests.post(f"{BASE}/register/", json={
    "email": "test_reset@example.com",
    "password": "Password123!",
    "password2": "Password123!",
    "first_name": "Test",
    "last_name": "Reset",
    "role": "STUDENT"
})
print("Register:", res.status_code, res.text)

print("\n1. Forgot Password")
res = requests.post(f"{BASE}/forgot-password/", json={"email": "test_reset@example.com"})
print("Forgot Password:", res.status_code, res.text)

# We need the OTP. In dev, it might be logged or we can pull it from the DB.
import sqlite3
import json

conn = sqlite3.connect('db.sqlite3')
c = conn.cursor()
c.execute("SELECT otp FROM accounts_otp WHERE email='test_reset@example.com' ORDER BY created_at DESC LIMIT 1")
row = c.fetchone()
if row:
    otp = row[0]
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

