import os
import django
import sys
import json

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "src.config.settings")
django.setup()

from rest_framework.test import APIClient

from apps.accounts.models import User

def run_test():
    User.objects.get_or_create(email='a62341327@gmail.com', defaults={'role': 'student', 'is_verified': True})
    client = APIClient()
    
    print("\n[Step 1] Requesting OTP for a62341327@gmail.com...")
    res = client.post('/api/v1/auth/forgot-password/', {'email': 'a62341327@gmail.com'}, format='json')
    if res.status_code == 200:
        print(f"✓ Forgot password requested successfully: {res.data}")
    else:
        print(f"Failed: {res.data}")

if __name__ == '__main__':
    run_test()
