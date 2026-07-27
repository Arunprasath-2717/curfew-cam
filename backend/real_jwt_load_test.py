import time
import requests
import concurrent.futures

URL = 'http://localhost:8000/api/v1/auth/login/'
PAYLOAD = {"email":"student@test.com","password":"Test@1234","role":"student"}

def do_login(i):
    start = time.time()
    try:
        r = requests.post(URL, json=PAYLOAD, timeout=5)
        elapsed = time.time() - start
        if r.status_code == 200:
            return True, elapsed
        else:
            return False, elapsed
    except Exception as e:
        return False, time.time() - start

def main():
    print("Running 50 concurrent real logins...")
    start_total = time.time()
    successes = 0
    failures = 0
    times = []
    
    with concurrent.futures.ThreadPoolExecutor(max_workers=50) as executor:
        futures = [executor.submit(do_login, i) for i in range(50)]
        for f in concurrent.futures.as_completed(futures):
            ok, t = f.result()
            times.append(t)
            if ok:
                successes += 1
            else:
                failures += 1
                
    total_time = time.time() - start_total
    avg_time = sum(times) / len(times) if times else 0
    max_time = max(times) if times else 0
    min_time = min(times) if times else 0
    
    print(f"Total time for 50 logins: {total_time:.2f}s")
    print(f"Success: {successes}, Failures: {failures}")
    print(f"Avg response: {avg_time:.3f}s")
    print(f"Min response: {min_time:.3f}s")
    print(f"Max response: {max_time:.3f}s")

if __name__ == '__main__':
    main()
