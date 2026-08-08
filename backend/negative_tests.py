import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'src.config.settings.base')
django.setup()

from django.core.management import call_command
call_command('migrate', verbosity=0)

from apps.accounts.models import User, UserRole
from apps.students.models import StudentProfile
from apps.wardens.models import WardenProfile
from apps.outpass.models import Outpass
from apps.complaints.models import Complaint
from rest_framework_simplejwt.tokens import RefreshToken
from django.test import Client

def get_token(user):
    return str(RefreshToken.for_user(user).access_token)

def run_tests():
    print("=== Setting up test data ===")
    
    # Create Student A
    student_a_user, _ = User.objects.get_or_create(email='student_a@test.com', defaults={'role': UserRole.STUDENT, 'first_name': 'A'})
    student_a_user.set_password('testpass')
    student_a_user.save()
    student_a, _ = StudentProfile.objects.get_or_create(user=student_a_user, defaults={'register_number': 'A1', 'hostel_block': 'Hostel A', 'department': 'CS', 'year': 1})

    # Create Student B
    student_b_user, _ = User.objects.get_or_create(email='student_b@test.com', defaults={'role': UserRole.STUDENT, 'first_name': 'B'})
    student_b_user.set_password('testpass')
    student_b_user.save()
    student_b, _ = StudentProfile.objects.get_or_create(user=student_b_user, defaults={'register_number': 'B1', 'hostel_block': 'Hostel B', 'department': 'CS', 'year': 1})

    # Create Warden for Hostel B (Not Chief)
    warden_b_user, _ = User.objects.get_or_create(email='warden_b@test.com', defaults={'role': UserRole.WARDEN, 'first_name': 'W'})
    warden_b_user.set_password('testpass')
    warden_b_user.save()
    warden_b, _ = WardenProfile.objects.get_or_create(user=warden_b_user, defaults={'hostel_name': 'Hostel B', 'is_chief_warden': False, 'employee_id': 'W1'})

    # Create Outpass for Student A
    import datetime
    today = datetime.date.today()
    now = datetime.datetime.now().time()
    outpass_a, _ = Outpass.objects.get_or_create(
        student=student_a, destination='Home', reason='Test', status=Outpass.Status.PENDING,
        exit_date=today, exit_time=now, expected_return_date=today, expected_return_time=now
    )
    
    from django.utils import timezone
    from apps.qr.models import QRPass
    qr_a, _ = QRPass.objects.get_or_create(outpass=outpass_a, defaults={'token': 'test_token', 'hmac_signature': 'test_sig', 'expires_at': timezone.now()})

    # Create Complaint for Student A
    complaint_a, _ = Complaint.objects.get_or_create(student=student_a_user, title='Test Complaint', description='...')

    print(f"DEBUG: Student A Hostel: {student_a.hostel_block}")
    print(f"DEBUG: Warden B Hostel: {warden_b.hostel_name}")

    token_a = get_token(student_a_user)
    token_b = get_token(student_b_user)
    token_warden_b = get_token(warden_b_user)

    client = Client()

    print("\n=== A1. QR Ownership ===")
    res = client.get(f"/api/v1/qr/detail/{outpass_a.id}/", headers={'Authorization': f'Bearer {token_b}'})
    print(f"Req: GET /api/v1/qr/detail/{outpass_a.id}/ (Student B)")
    print(f"Res: {res.status_code} {res.content.decode()[:100]}")

    print("\n=== A2. Outpass Ownership (Return) ===")
    res = client.post(f"/api/v1/outpass/{outpass_a.id}/return/", headers={'Authorization': f'Bearer {token_b}'}, content_type='application/json', data={})
    print(f"Req: POST /api/v1/outpass/{outpass_a.id}/return/ (Student B)")
    print(f"Res: {res.status_code} {res.content.decode()[:100]}")

    print("\n=== A2. Warden Scope Approval ===")
    res = client.post(f"/api/v1/wardens/outpass/{outpass_a.id}/approve/", headers={'Authorization': f'Bearer {token_warden_b}'}, content_type='application/json', data={'action': 'approve'})
    print(f"Req: POST /api/v1/wardens/outpass/{outpass_a.id}/approve/ (Warden B)")
    print(f"Res: {res.status_code} {res.content.decode()[:100]}")

    print("\n=== A3. Destructive Warden Endpoints (Chief check) ===")
    res = client.post(f"/api/v1/wardens/manage/students/delete-passed-out/", headers={'Authorization': f'Bearer {token_warden_b}'})
    print(f"Req: POST /api/v1/wardens/manage/students/delete-passed-out/ (Warden B)")
    print(f"Res: {res.status_code} {res.content.decode()[:100]}")

    print("\n=== A4. Complaint Endpoints Scope ===")
    res = client.get(f"/api/v1/complaints/{complaint_a.id}/", headers={'Authorization': f'Bearer {token_warden_b}'})
    print(f"Req: GET /api/v1/complaints/{complaint_a.id}/ (Warden B)")
    print(f"Res: {res.status_code} {res.content.decode()[:100]}")

    print("\n=== A6. Detection Edge Token Auth ===")
    res = client.post(f"/api/v1/detection/analyze/", headers={'Authorization': f'Bearer {token_a}'}, data={'camera_id': 1})
    print(f"Req: POST /api/v1/detection/analyze/ (Student A without Edge Token)")
    print(f"Res: {res.status_code} {res.content.decode()[:100]}")

if __name__ == '__main__':
    run_tests()
