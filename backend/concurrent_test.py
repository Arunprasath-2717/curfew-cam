import requests
import concurrent.futures
import time
import os
import django
import sys
from collections import Counter

# Set up Django to interact directly with the DB to create test data
sys.path.append('/home/techpark-6/Music/curfewcam/backend/src')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from apps.accounts.models import User
from apps.outpass.models import Outpass
from apps.students.models import StudentProfile
from django.utils import timezone

# 1. Prepare 10 active outpasses
student = StudentProfile.objects.filter(user__email='test1@srishakthi.ac.in').first()
if not student:
    u = User.objects.get(email='test1@srishakthi.ac.in')
    student = StudentProfile.objects.create(user=u, register_number='R1', hostel_block='A-Block', room_number='101')

# Create 10 active outpasses manually to simulate existing ones to be scanned
active_outpasses = []
for i in range(10):
    op = Outpass.objects.create(
        student=student,
        destination=f"Scan Test {i}",
        reason="Testing",
        departure_time=timezone.now(),
        return_time=timezone.now() + timezone.timedelta(hours=2),
        status=Outpass.Status.ACTIVE,
        actual_exit_time=timezone.now()
    )
    active_outpasses.append(str(op.id))

print(f"Prepared {len(active_outpasses)} active outpasses for scanning.")

# 2. Get tokens
BASE_URL = "http://localhost:8000/api/v1"

def get_token(email, role):
    r = requests.post(f"{BASE_URL}/auth/login/", json={"email": email, "password": "Curfew@123", "role": role})
    return r.json().get("access")

student_token = get_token("test1@srishakthi.ac.in", "student")
watchman_token = get_token("watchman@test.com", "watchman")

print("Got tokens. Starting concurrent test...")

# 3. Concurrent requests definitions
def submit_outpass(req_id):
    start = time.time()
    try:
        r = requests.post(
            f"{BASE_URL}/outpass/request/",
            headers={"Authorization": f"Bearer {student_token}"},
            json={
                "destination": f"Concurrent {req_id}",
                "reason": "Stress test",
                "departure_time": (timezone.now() + timezone.timedelta(hours=1)).isoformat(),
                "return_time": (timezone.now() + timezone.timedelta(hours=5)).isoformat()
            }
        )
        return {"type": "submit", "status": r.status_code, "text": r.text, "time": time.time() - start}
    except Exception as e:
        return {"type": "submit", "status": "ERROR", "text": str(e), "time": time.time() - start}

def scan_outpass(op_id):
    start = time.time()
    try:
        r = requests.post(
            f"{BASE_URL}/outpass/{op_id}/return/",
            headers={"Authorization": f"Bearer {watchman_token}"},
            json={"auto_detect_method": "qr_scan"}
        )
        return {"type": "scan", "status": r.status_code, "text": r.text, "time": time.time() - start}
    except Exception as e:
        return {"type": "scan", "status": "ERROR", "text": str(e), "time": time.time() - start}

# 4. Run them simultaneously
results = []
overall_start = time.time()

with concurrent.futures.ThreadPoolExecutor(max_workers=30) as executor:
    futures = []
    # 20 submissions
    for i in range(20):
        futures.append(executor.submit(submit_outpass, i))
    # 10 scans
    for op_id in active_outpasses:
        futures.append(executor.submit(scan_outpass, op_id))
    
    for f in concurrent.futures.as_completed(futures):
        results.append(f.result())

overall_end = time.time()

print("\n--- Concurrent Write Test Results ---")
print(f"Total Time: {overall_end - overall_start:.2f}s")
submit_statuses = Counter([r['status'] for r in results if r['type'] == 'submit'])
scan_statuses = Counter([r['status'] for r in results if r['type'] == 'scan'])
errors = [r['text'] for r in results if r['status'] == 500 or "locked" in r['text'].lower()]

print("\nSubmissions (Expected 1 success, 19 failures due to 'already pending' logic):")
for s, c in submit_statuses.items():
    print(f"  HTTP {s}: {c}")

print("\nScans (Expected 10 successes):")
for s, c in scan_statuses.items():
    print(f"  HTTP {s}: {c}")

if errors:
    print("\nERRORS DETECTED:")
    for e in errors:
        print(f"  - {e}")
else:
    print("\nNo database locks or 500 errors detected!")
