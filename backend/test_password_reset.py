import os
import django
import sys

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'src.config.settings')
django.setup()

from apps.accounts.models import StudentWhitelist, User
from rest_framework.test import APIClient
from django.core.cache import cache

def run_test():
    StudentWhitelist.objects.filter(register_number="EXPAND2026").delete()
    User.objects.filter(email="expand@srishakthi.ac.in").delete()

    StudentWhitelist.objects.create(
        name="Expand Student",
        register_number="EXPAND2026",
        block="C-Block",
        room_number="302"
    )

    client = APIClient()

    # 1. Test Expanded Registration (wrong block)
    print("Testing expanded registration (wrong block)...")
    res1 = client.post('/api/v1/auth/register/student/', {
        'name': 'Expand Student',
        'register_number': 'EXPAND2026',
        'block': 'D-Block',
        'email': 'expand@srishakthi.ac.in',
        'password': 'password123'
    })
    print(f"Status: {res1.status_code}")
    assert res1.status_code == 400
    assert "not recognized" in res1.json()['error']

    # 2. Test Expanded Registration (wrong email domain)
    print("\nTesting expanded registration (wrong domain)...")
    res2 = client.post('/api/v1/auth/register/student/', {
        'name': 'Expand Student',
        'register_number': 'EXPAND2026',
        'block': 'C-Block',
        'email': 'expand@gmail.com',
        'password': 'password123'
    })
    print(f"Status: {res2.status_code}")
    assert res2.status_code == 400
    assert "srishakthi.ac.in" in res2.json()['error']

    # 3. Test Valid Registration
    print("\nTesting expanded registration (valid)...")
    res3 = client.post('/api/v1/auth/register/student/', {
        'name': 'Expand Student',
        'register_number': 'EXPAND2026',
        'block': 'C-Block',
        'email': 'expand@srishakthi.ac.in',
        'password': 'password123'
    })
    print(f"Status: {res3.status_code}")
    assert res3.status_code == 201

    # 4. Test Forgot Password (enumeration protection)
    print("\nTesting forgot password enumeration (fake email)...")
    res4 = client.post('/api/v1/auth/password-reset/request/', {
        'email': 'doesnotexist@srishakthi.ac.in'
    })
    print(f"Status: {res4.status_code}")
    assert res4.status_code == 200
    fake_token = res4.json()['data']['reset_session']

    print("\nTesting forgot password enumeration (real email)...")
    res5 = client.post('/api/v1/auth/password-reset/request/', {
        'email': 'expand@srishakthi.ac.in'
    })
    print(f"Status: {res5.status_code}")
    assert res5.status_code == 200
    real_token = res5.json()['data']['reset_session']
    
    # Get the code from cache directly
    user = User.objects.get(email='expand@srishakthi.ac.in')
    code = cache.get(f'reset_code:{user.id}')
    assert code is not None, "Code not saved to cache"

    # 5. Confirm password reset
    print("\nTesting password reset confirm...")
    res6 = client.post('/api/v1/auth/password-reset/confirm/', {
        'session_token': real_token,
        'code': code,
        'new_password': 'newpassword123',
        'new_password2': 'newpassword123'
    })
    print(f"Status: {res6.status_code}")
    assert res6.status_code == 200

    print("\nAll tests passed successfully!")

if __name__ == '__main__':
    run_test()
