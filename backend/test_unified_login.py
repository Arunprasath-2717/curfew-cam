from __future__ import annotations

import json
import os
from dataclasses import dataclass
from typing import Any

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'src.config.settings.base')
os.environ.setdefault('POSTGRES_HOST', 'localhost')
os.environ.setdefault('POSTGRES_PORT', '5432')
os.environ.setdefault('POSTGRES_DB', 'curfewcam')
os.environ.setdefault('POSTGRES_USER', 'curfewcam')
os.environ.setdefault('POSTGRES_PASSWORD', 'secretpassword')

import django
import requests
from django.core.management import call_command

django.setup()

from apps.accounts.models import User  # noqa: E402

BASE_URL = os.environ.get('CURFEWCAM_API_BASE_URL', 'http://localhost:8000/api/v1')
LOGIN_URL = f'{BASE_URL}/auth/login/'
REQUEST_TIMEOUT = 10


@dataclass(frozen=True)
class TestCase:
    name: str
    payload: dict[str, Any]
    expected_status: int
    expect_success: bool


CASES = [
    TestCase('student success', {'email': 'student@test.com', 'password': 'Student@1234', 'role': 'student'}, 200, True),
    TestCase('student wrong password', {'email': 'student@test.com', 'password': 'Wrong@1234', 'role': 'student'}, 401, False),
    TestCase('student wrong role', {'email': 'student@test.com', 'password': 'Student@1234', 'role': 'warden'}, 401, False),
    TestCase('warden success', {'email': 'warden@test.com', 'password': 'Warden@1234', 'role': 'warden'}, 200, True),
    TestCase('warden wrong password', {'email': 'warden@test.com', 'password': 'Wrong@1234', 'role': 'warden'}, 401, False),
    TestCase('warden wrong role', {'email': 'warden@test.com', 'password': 'Warden@1234', 'role': 'watchman'}, 401, False),
    TestCase('watchman success', {'email': 'watchman@test.com', 'password': 'Watchman@1234', 'role': 'watchman'}, 200, True),
    TestCase('watchman wrong password', {'email': 'watchman@test.com', 'password': 'Wrong@1234', 'role': 'watchman'}, 401, False),
    TestCase('watchman wrong role', {'email': 'watchman@test.com', 'password': 'Watchman@1234', 'role': 'student'}, 401, False),
    TestCase('missing field', {'email': 'student@test.com', 'password': 'Student@1234'}, 400, False),
]


def seed_users() -> None:
    call_command('migrate', verbosity=0)
    for email, role, password in [
        ('student@test.com', 'student', 'Student@1234'),
        ('warden@test.com', 'warden', 'Warden@1234'),
        ('watchman@test.com', 'watchman', 'Watchman@1234'),
    ]:
        user, _ = User.objects.get_or_create(email=email, defaults={'role': role})
        user.role = role
        user.set_password(password)
        user.save()


def parse_json(response: requests.Response) -> Any:
    try:
        return response.json()
    except ValueError:
        return response.text


def validate_response(case: TestCase, response: requests.Response, body: Any) -> list[str]:
    failures: list[str] = []

    if response.status_code != case.expected_status:
        failures.append(f'status={response.status_code} expected={case.expected_status}')

    if 'application/json' not in response.headers.get('Content-Type', ''):
        failures.append(f'content_type={response.headers.get("Content-Type", "")}')

    if not isinstance(body, dict):
        failures.append('response was not JSON object')
        return failures

    if case.expect_success:
        if body.get('success') is not True:
            failures.append('success flag was not true')
        if body.get('role') not in {'student', 'warden', 'watchman'}:
            failures.append('missing or invalid role')
        if not isinstance(body.get('user'), dict):
            failures.append('missing user payload')
        tokens = body.get('tokens')
        if not isinstance(tokens, dict):
            failures.append('missing tokens payload')
        else:
            if not tokens.get('access') or not tokens.get('refresh'):
                failures.append('missing access or refresh token')
    else:
        if body.get('success') is not False:
            failures.append('success flag was not false')
        if not body.get('error'):
            failures.append('missing error message')

    return failures


def main() -> int:
    seed_users()

    session = requests.Session()
    rows: list[tuple[str, int, int, str]] = []
    failures: list[str] = []

    for case in CASES:
        try:
            response = session.post(LOGIN_URL, json=case.payload, timeout=REQUEST_TIMEOUT)
            body = parse_json(response)
            case_failures = validate_response(case, response, body)
        except Exception as exc:  # noqa: BLE001
            response = None
            body = {'error': str(exc)}
            case_failures = [f'request failed: {exc}']

        status = response.status_code if response is not None else 0
        rows.append((case.name, status, case.expected_status, 'PASS' if not case_failures else 'FAIL'))
        if case_failures:
            failures.append(f'{case.name}: {"; ".join(case_failures)}')
        print(f'{case.name}: status={status} expected={case.expected_status} -> {"PASS" if not case_failures else "FAIL"}')
        print(body)
        print('---')

    print('RESULTS')
    print('case | status | expected | result')
    for name, status, expected, result in rows:
        print(f'{name} | {status} | {expected} | {result}')

    if failures:
        print('FAILURES')
        for failure in failures:
            print(failure)
        return 1

    print('All unified login cases passed.')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
