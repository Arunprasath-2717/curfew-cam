#!/bin/bash
set -e

BASE_URL="http://localhost:8000/api/v1/auth"
EMAIL="test.otp.curl2@srishakthi.ac.in"

docker compose exec -T web python manage.py shell -c "
from apps.accounts.models import User
User.objects.get_or_create(email='$EMAIL', defaults={'first_name': 'Curl', 'role': 'student', 'is_verified': True})
" > /dev/null 2>&1

echo "--- TEST 1: Generate & Validate Valid OTP ---"
REQ_RESP=$(curl -s -X POST $BASE_URL/password-reset/request/ \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\"}")

SESSION_TOKEN=$(echo $REQ_RESP | grep -o '"reset_session":"[^"]*' | cut -d'"' -f4)

# Get code from cache via django shell, grep only the digits
OTP_CODE=$(docker compose exec -T web python manage.py shell -c "
from django.core.signing import TimestampSigner
from django.core.cache import cache
signer = TimestampSigner(salt='password-reset')
user_id = signer.unsign('$SESSION_TOKEN', max_age=600)
print(cache.get(f'reset_code:{user_id}'))
" | grep -Eo '^[0-9]{6}')

echo "Generated OTP: $OTP_CODE"

echo "Sending code as integer via curl..."
VERIFY_RESP=$(curl -s -X POST $BASE_URL/password-reset/verify-otp/ \
  -H "Content-Type: application/json" \
  -d "{\"session_token\":\"$SESSION_TOKEN\", \"code\":$OTP_CODE}")
echo "Response: $VERIFY_RESP"

echo ""
echo "--- TEST 2: Validate with WRONG code ---"
WRONG_RESP=$(curl -s -X POST $BASE_URL/password-reset/verify-otp/ \
  -H "Content-Type: application/json" \
  -d "{\"session_token\":\"$SESSION_TOKEN\", \"code\":999999}")
echo "Response: $WRONG_RESP"

echo ""
echo "--- TEST 3: Validate past expiry (force delete cache) ---"
docker compose exec -T web python manage.py shell -c "
from django.core.signing import TimestampSigner
from django.core.cache import cache
signer = TimestampSigner(salt='password-reset')
user_id = signer.unsign('$SESSION_TOKEN', max_age=600)
cache.delete(f'reset_code:{user_id}')
" > /dev/null 2>&1

EXPIRED_RESP=$(curl -s -X POST $BASE_URL/password-reset/verify-otp/ \
  -H "Content-Type: application/json" \
  -d "{\"session_token\":\"$SESSION_TOKEN\", \"code\":$OTP_CODE}")
echo "Response: $EXPIRED_RESP"

echo ""
echo "All curl tests finished!"
