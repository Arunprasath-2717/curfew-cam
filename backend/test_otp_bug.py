import sys
import datetime
from django.core.cache import cache
from apps.accounts.otp import generate_otp, _otp_key, verify_otp
from django.utils.timezone import now

email = "test@example.com"
purpose = "email_verification"

print(f"--- TESTING OTP BUG ---")
# 1. Generate OTP
otp_str = generate_otp(email, purpose)
print(f"Generated OTP: {otp_str!r} (type: {type(otp_str)})")

# 2. Get directly from cache
key = _otp_key(email, purpose)
stored_val = cache.get(key)
print(f"Stored OTP directly from cache: {stored_val!r} (type: {type(stored_val)})")

# Let's also check if it's stored differently, like string vs int
if stored_val == otp_str:
    print("Direct equality check: PASS (stored_val == otp_str)")
else:
    print(f"Direct equality check: FAIL (stored_val != otp_str). Types: {type(stored_val)} vs {type(otp_str)}")

# 3. Call verify_otp function
success, msg = verify_otp(email, otp_str, purpose)
print(f"verify_otp result with exact string generated: {success}, {msg}")

if stored_val:
    success2, msg2 = verify_otp(email, str(stored_val), purpose)
    print(f"verify_otp result with str(stored_val): {success2}, {msg2}")
