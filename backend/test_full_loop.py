import os
import django
import requests

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'src.config.settings.base')
django.setup()

from apps.accounts.models import User
from apps.outpass.models import Outpass

BASE_URL = 'http://localhost:8000/api/v1'

def run_loop_test():
    print("--- Starting Full Loop Test ---")

    # 1. Login as Student
    print("1. Logging in as Student...")
    res = requests.post(f"{BASE_URL}/auth/login/", json={
        "email": "student@test.com",
        "password": "Test@1234",
        "role": "student"
    })
    assert res.status_code == 200, "Student login failed"
    student_token = res.json()['tokens']['access']
    print("   ✓ Student logged in.")

    # 2. Student Submits Outpass
    print("2. Student submitting outpass request...")
    res = requests.post(
        f"{BASE_URL}/outpass/request/",
        json={
            "outpass_type": "REGULAR",
            "reason": "Family Function",
            "destination": "Home",
            "exit_date": "2026-10-10",
            "exit_time": "10:00",
            "expected_return_date": "2026-10-12",
            "expected_return_time": "18:00"
        },
        headers={"Authorization": f"Bearer {student_token}"}
    )
    assert res.status_code == 201, f"Failed to submit outpass: {res.text}"
    outpass_id = res.json()['data']['id']
    print(f"   ✓ Outpass {outpass_id} submitted.")

    # 3. Student sees it as PENDING
    print("3. Checking Student Dashboard (Current Outpass)...")
    res = requests.get(f"{BASE_URL}/outpass/current/", headers={"Authorization": f"Bearer {student_token}"})
    assert res.status_code == 200
    assert res.json()['data']['status'] == 'PENDING', "Status is not PENDING"
    print("   ✓ Student Dashboard shows PENDING.")

    # 4. Login as Warden
    print("4. Logging in as Warden...")
    res = requests.post(f"{BASE_URL}/auth/login/", json={
        "email": "warden@test.com",
        "password": "Test@1234",
        "role": "warden"
    })
    assert res.status_code == 200, "Warden login failed"
    warden_token = res.json()['tokens']['access']
    print("   ✓ Warden logged in.")

    # 5. Warden sees Pending Requests
    print("5. Warden fetching Pending Requests...")
    res = requests.get(f"{BASE_URL}/wardens/pending/", headers={"Authorization": f"Bearer {warden_token}"})
    assert res.status_code == 200
    pending = res.json()['results']
    assert len(pending) > 0, "No pending requests found for warden!"
    assert any(p['id'] == outpass_id for p in pending), "Student's request not in pending list!"
    print(f"   ✓ Warden sees the request in pending list.")

    # 6. Warden Approves Request
    print("6. Warden approving the request...")
    res = requests.post(
        f"{BASE_URL}/wardens/outpass/{outpass_id}/approve/",
        json={"action": "approve", "warden_notes": "Approved, be safe."},
        headers={"Authorization": f"Bearer {warden_token}"}
    )
    assert res.status_code == 200, f"Failed to approve outpass: {res.text}"
    print("   ✓ Request approved.")

    # 7. Student sees updated status
    print("7. Checking Student Dashboard again...")
    res = requests.get(f"{BASE_URL}/outpass/current/", headers={"Authorization": f"Bearer {student_token}"})
    assert res.status_code == 200
    assert res.json()['data']['status'] == 'APPROVED', "Status is not APPROVED"
    print("   ✓ Student Dashboard shows APPROVED.")

    print("--- Full Loop Test PASSED! ---")

if __name__ == "__main__":
    # Clean up previous outpasses to ensure a clean state
    Outpass.objects.all().delete()
    run_loop_test()
