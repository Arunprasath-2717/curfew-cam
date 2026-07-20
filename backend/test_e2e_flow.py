import os
import django
import sys
import json

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "src.config.settings")
django.setup()

from rest_framework.test import APIClient
from apps.outpass.models import Outpass

def run_walkthrough():
    Outpass.objects.all().delete()
    client = APIClient()
    
    print("\n[Step 1 & 2] Logging in as student (student@test.com)...")
    res = client.post('/api/v1/auth/login/', {'email': 'student@test.com', 'password': 'Test@1234', 'role': 'student'}, format='json')
    if res.status_code != 200:
        print(f"Failed to login student: {res.data}")
        return
    student_token = res.data.get('tokens', {}).get('access')
    if not student_token:
        print(f"Could not find token in: {res.data}")
        return
    print("✓ Student login successful.")
    
    print("\n[Step 3] Submitting a fresh outpass request...")
    client.credentials(HTTP_AUTHORIZATION='Bearer ' + student_token)
    data = {
        "outpass_type": "REGULAR",
        "reason": "Buying groceries",
        "destination": "Supermarket",
        "exit_date": "2026-07-15",
        "exit_time": "12:00",
        "expected_return_date": "2026-07-15",
        "expected_return_time": "18:00"
    }
    res = client.post('/api/v1/outpass/request/', data, format='json')
    if res.status_code != 201:
        print(f"Failed to create outpass: {res.data}")
        return
    outpass_id = res.data['data']['id']
    print(f"✓ Outpass created successfully (ID: {outpass_id})")

    print("\n[Step 4] Logging in as warden (warden@test.com)...")
    client = APIClient()
    res = client.post('/api/v1/auth/login/', {'email': 'warden@test.com', 'password': 'Test@1234', 'role': 'warden'}, format='json')
    if res.status_code != 200:
        print(f"Failed to login warden: {res.data}")
        return
    warden_token = res.data.get('tokens', {}).get('access')
    client.credentials(HTTP_AUTHORIZATION='Bearer ' + warden_token)
    print("✓ Warden login successful.")
    
    res = client.get('/api/v1/wardens/pending/')
    if res.status_code != 200:
        print("Failed to get pending requests")
        return
    
    found = any(str(req.get('id')) == str(outpass_id) for req in res.data.get('data', []))
    print(f"✓ Does the new request appear on the warden dashboard? {found}")
    
    print("\n[Step 5] Warden approving the outpass...")
    res = client.post(f'/api/v1/wardens/outpass/{outpass_id}/approve/', {'action': 'approve'}, format='json')
    if res.status_code == 200:
        print("✓ Outpass approved by warden.")
    else:
        print(f"Failed to approve: {res.data}")
        return
    
    print("\n[Step 6] Logging back in as student to check status & QR screen...")
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION='Bearer ' + student_token)
    res = client.get('/api/v1/outpass/current/')
    if res.status_code != 200:
        print("Failed to get current outpass")
        return
    status = res.data['data']['status']
    print(f"✓ Is it approved? Status is: {status}")
    
    res = client.post(f'/api/v1/qr/regenerate/{outpass_id}/', format='json')
    if res.status_code != 200:
        print(f"Failed to get QR token: {res.data}")
        return
    qr_token = res.data['data']['token']
    print("✓ QR token generated successfully.")
    
    print("\n[Step 7] Logging in as watchman (watchman@test.com) & Scanning EXIT...")
    client = APIClient()
    res = client.post('/api/v1/auth/login/', {'email': 'watchman@test.com', 'password': 'Test@1234', 'role': 'watchman'}, format='json')
    if res.status_code != 200:
        print(f"Failed to login watchman: {res.data}")
        return
    watchman_token = res.data.get('tokens', {}).get('access')
    client.credentials(HTTP_AUTHORIZATION='Bearer ' + watchman_token)
    
    res = client.post('/api/v1/watchmen/scan/', {'qr_token': qr_token, 'scan_type': 'EXIT'}, format='json')
    if res.status_code == 200:
        print(f"✓ Scan EXIT successful. Data: {res.data['data']}")
    else:
        print(f"Scan EXIT failed: {res.data}")
        return
        
    print("\n[Step 8] Watchman Scanning RETURN...")
    client.credentials(HTTP_AUTHORIZATION='Bearer ' + student_token)
    res = client.post(f'/api/v1/qr/regenerate/{outpass_id}/', format='json')
    if res.status_code != 200:
        print(f"Failed to get new QR token for return: {res.data}")
        return
    qr_token_return = res.data['data']['token']
    
    client.credentials(HTTP_AUTHORIZATION='Bearer ' + watchman_token)
    res = client.post('/api/v1/watchmen/scan/', {'qr_token': qr_token_return, 'scan_type': 'RETURN'}, format='json')
    if res.status_code == 200:
        print(f"✓ Scan RETURN successful. Data: {res.data['data']}")
    else:
        print(f"Scan RETURN failed: {res.data}")
        return
        
    print("\n==================================")
    print("WALKTHROUGH COMPLETED SUCCESSFULLY!")
    print("==================================")

if __name__ == '__main__':
    run_walkthrough()
