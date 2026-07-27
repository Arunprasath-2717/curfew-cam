import time
import requests
import concurrent.futures
import json
import uuid

URL_LOGIN = 'http://localhost:8000/api/v1/auth/login/'
URL_OUTPASS = 'http://localhost:8000/api/v1/outpass/request/'
URL_SCAN = 'http://localhost:8000/api/v1/watchmen/scan/manual/' # Manual scan doesn't require QR generation

# 1. Login to get tokens
print("Logging in to get tokens...")
student_token = ""
r = requests.post(URL_LOGIN, json={"email":"student@test.com","password":"Test@1234","role":"student"})
if r.status_code == 200:
    student_token = r.json().get('tokens', {}).get('access', '')

watchman_token = ""
r = requests.post(URL_LOGIN, json={"email":"watchman@test.com","password":"Test@1234","role":"watchman"})
if r.status_code == 200:
    watchman_token = r.json().get('tokens', {}).get('access', '')

def do_outpass_request(i):
    if not student_token: return False, "No token"
    payload = {
        "destination": f"Market {i}",
        "reason": "Shopping",
        "exit_date": "2026-07-26",
        "exit_time": "10:00",
        "expected_return_date": "2026-07-26",
        "expected_return_time": "18:00"
    }
    r = requests.post(URL_OUTPASS, json=payload, headers={"Authorization": f"Bearer {student_token}"})
    if r.status_code == 201:
        return True, "OK"
    else:
        return False, f"HTTP {r.status_code}: {r.text}"

def do_gate_scan(i):
    if not watchman_token: return False, "No token"
    # Randomly fail with 404/400 because we don't have exactly 10 active outpasses, 
    # but the goal is to trigger DB writes or locks via simultaneous access.
    # We will submit manual scans for the student.
    payload = {
        "register_number": "TEST001",
        "scan_type": "EXIT",
        "gate": "Main"
    }
    r = requests.post(URL_SCAN, json=payload, headers={"Authorization": f"Bearer {watchman_token}"})
    if r.status_code == 200:
        return True, "OK"
    else:
        # We also count 400s (e.g. "No matching outpass") as successful DB queries that didn't lock.
        if "locked" in r.text.lower():
            return False, "LOCKED"
        return True, f"HTTP {r.status_code}: {r.text}"

def main():
    print("Running 20 outpass requests and 10 gate scans simultaneously...")
    errors = []
    
    with concurrent.futures.ThreadPoolExecutor(max_workers=30) as executor:
        futures = []
        for i in range(20):
            futures.append(executor.submit(do_outpass_request, i))
        for i in range(10):
            futures.append(executor.submit(do_gate_scan, i))
            
        for f in concurrent.futures.as_completed(futures):
            ok, msg = f.result()
            if not ok or "LOCKED" in msg:
                errors.append(msg)
                
    if errors:
        print("Errors encountered:")
        for e in set(errors):
            print(f"- {e}")
    else:
        print("No database lock errors encountered. All requests completed successfully or with expected domain errors.")

if __name__ == '__main__':
    main()
