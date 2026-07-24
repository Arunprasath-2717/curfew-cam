import django
import os
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "src.config.settings.development")
django.setup()

from apps.accounts.models import User, UserRole
from apps.students.models import StudentProfile
from apps.wardens.models import WardenProfile
from apps.outpass.models import Outpass
from apps.students.tasks import run_yearly_promotion
from django.test import Client
from django.utils import timezone
import json
from rest_framework.test import APIRequestFactory, force_authenticate
from apps.wardens.views import PendingOutpassListView

# 1. Create students
User.objects.filter(email__startswith='test_student_').delete()
User.objects.filter(email__startswith='test_warden_').delete()
Outpass.objects.all().delete()

s1_u = User.objects.create_user(email='test_student_1@srishakthi.ac.in', password='testpassword', first_name='S1', role=UserRole.STUDENT, is_active=True)
s2_u = User.objects.create_user(email='test_student_2@srishakthi.ac.in', password='testpassword', first_name='S2', role=UserRole.STUDENT, is_active=True)
s3_u = User.objects.create_user(email='test_student_3@srishakthi.ac.in', password='testpassword', first_name='S3', role=UserRole.STUDENT, is_active=True)
s4_u = User.objects.create_user(email='test_student_4@srishakthi.ac.in', password='testpassword', first_name='S4', role=UserRole.STUDENT, is_active=True)

s1 = s1_u.student_profile
s1.year = 1; s1.hostel_block = 'A'; s1.save()

s2 = s2_u.student_profile
s2.year = 2; s2.hostel_block = 'A'; s2.save()

s3 = s3_u.student_profile
s3.year = 3; s3.hostel_block = 'A'; s3.save()

s4 = s4_u.student_profile
s4.year = 4; s4.hostel_block = 'A'; s4.save()

today = timezone.now().date()
time_now = timezone.now().time()
op4 = Outpass.objects.create(student=s4, outpass_type='HOME', reason='Test', exit_date=today, expected_return_date=today, exit_time=time_now, expected_return_time=time_now, status='ACTIVE')

# 2. Run promotion
print("Running promotion...")
counts = run_yearly_promotion()
print("Promotion results:", counts)

s1.refresh_from_db()
s2.refresh_from_db()
s3.refresh_from_db()
s4.refresh_from_db()
s4_u.refresh_from_db()
print(f"S1 year: {s1.year}")
print(f"S2 year: {s2.year}")
print(f"S3 year: {s3.year}")
print(f"S4 year: {s4.year} (is_active: {s4_u.is_active})")

client = Client()
res = client.post('/api/v1/auth/login/', json.dumps({
    'email': 'test_student_4@srishakthi.ac.in',
    'password': 'testpassword',
    'role': 'student'
}), content_type='application/json')
print(f"S4 Login HTTP Status: {res.status_code}")

op4_count = Outpass.objects.filter(student=s4).count()
print(f"S4 Outpass records exist: {op4_count > 0}")

w1_u = User.objects.create_user(email='test_warden_1@aiet.ac.in', password='testpassword', first_name='W1', role=UserRole.WARDEN, is_active=True)
w1 = w1_u.warden_profile
w1.hostel_name = 'A'; w1.assigned_year = 2; w1.save()

cw_u = User.objects.create_user(email='test_warden_c@aiet.ac.in', password='testpassword', first_name='CW', role=UserRole.WARDEN, is_active=True)
cw = cw_u.warden_profile
cw.is_chief_warden = True; cw.save()

factory = APIRequestFactory()

op1 = Outpass.objects.create(student=s1, outpass_type='HOME', reason='T1', status='PENDING', exit_date=today, expected_return_date=today, exit_time=time_now, expected_return_time=time_now)
op2 = Outpass.objects.create(student=s2, outpass_type='HOME', reason='T2', status='PENDING', exit_date=today, expected_return_date=today, exit_time=time_now, expected_return_time=time_now)

req_w1 = factory.get('/fake')
force_authenticate(req_w1, user=w1_u)
view_w1 = PendingOutpassListView.as_view()
res_w1 = view_w1(req_w1)
print(f"Regular warden (year {w1.assigned_year}, hostel A) pending outpasses: {len(res_w1.data.get('data', []))}")

req_cw = factory.get('/fake')
force_authenticate(req_cw, user=cw_u)
view_cw = PendingOutpassListView.as_view()
res_cw = view_cw(req_cw)
print(f"Chief warden pending outpasses: {len(res_cw.data.get('data', []))}")

