import os
import django
import sys

# Setup django
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'src.config.settings')
django.setup()

from apps.accounts.models import StudentWhitelist, User
from rest_framework.test import APIClient
from django.urls import reverse

def run_test():
    # 1. Clear existing for test
    StudentWhitelist.objects.filter(register_number="TEST2026").delete()
    User.objects.filter(email="teststudent@example.com").delete()

    # 2. Add whitelist entry
    whitelist = StudentWhitelist.objects.create(
        name="Test Student",
        register_number="TEST2026",
        room_number="101"
    )

    client = APIClient()

    # 3. Test un-whitelisted registration
    print("Testing un-whitelisted user...")
    res1 = client.post('/api/v1/auth/register/student/', {
        'name': 'Unknown Student',
        'register_number': 'FAKE999',
        'email': 'fake@example.com',
        'password': 'password123'
    })
    print(f"Status: {res1.status_code}")
    print(res1.json())
    assert res1.status_code == 400
    assert "not recognized" in res1.json()['error']

    # 4. Test valid registration
    print("\nTesting valid user...")
    res2 = client.post('/api/v1/auth/register/student/', {
        'name': 'Test Student',
        'register_number': 'TEST2026',
        'email': 'teststudent@example.com',
        'password': 'password123'
    })
    print(f"Status: {res2.status_code}")
    print(res2.json())
    assert res2.status_code == 201

    # 5. Test already claimed
    print("\nTesting already claimed user...")
    res3 = client.post('/api/v1/auth/register/student/', {
        'name': 'Test Student',
        'register_number': 'TEST2026',
        'email': 'another@example.com',
        'password': 'password123'
    })
    print(f"Status: {res3.status_code}")
    print(res3.json())
    assert res3.status_code == 400
    assert "already registered" in res3.json()['error']

    print("\nAll tests passed successfully!")

if __name__ == '__main__':
    run_test()
