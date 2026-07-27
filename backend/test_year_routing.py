import os
import django
import sys
from datetime import datetime

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'src.config.settings')
django.setup()

from django.test import RequestFactory
from django.contrib.auth import get_user_model
from rest_framework.test import force_authenticate
from apps.accounts.models import UserRole
from apps.wardens.models import WardenProfile
from apps.students.models import StudentProfile
from apps.outpass.views import OutpassRequestView
from apps.outpass.models import Outpass
from apps.notifications.models import Notification

User = get_user_model()

def run_tests():
    print("Setting up test data...")
    # Clear existing
    Notification.objects.all().delete()
    Outpass.objects.all().delete()
    User.objects.filter(email__startswith='test_').delete()

    # Create wardens in A-Block
    w_year1 = User.objects.create_user(email='test_w_y1@example.com', password='pw', role=UserRole.WARDEN, is_verified=True, first_name='Warden Y1')
    WardenProfile.objects.filter(user=w_year1).update(hostel_name='A-Block', assigned_year=1)

    w_year2 = User.objects.create_user(email='test_w_y2@example.com', password='pw', role=UserRole.WARDEN, is_verified=True, first_name='Warden Y2')
    WardenProfile.objects.filter(user=w_year2).update(hostel_name='A-Block', assigned_year=2)

    w_all = User.objects.create_user(email='test_w_all@example.com', password='pw', role=UserRole.WARDEN, is_verified=True, first_name='Warden All')
    WardenProfile.objects.filter(user=w_all).update(hostel_name='A-Block', assigned_year=None)

    # Create warden in B-Block
    w_b = User.objects.create_user(email='test_w_b@example.com', password='pw', role=UserRole.WARDEN, is_verified=True, first_name='Warden B')
    WardenProfile.objects.filter(user=w_b).update(hostel_name='B-Block', assigned_year=None)

    # Create students
    s_y1 = User.objects.create_user(email='test_s_y1@example.com', password='pw', role=UserRole.STUDENT, is_verified=True, first_name='Student Y1')
    p_y1 = s_y1.student_profile
    p_y1.hostel_block = 'A-Block'
    p_y1.year = 1
    p_y1.save()

    s_null = User.objects.create_user(email='test_s_null@example.com', password='pw', role=UserRole.STUDENT, is_verified=True, first_name='Student Null')
    p_null = s_null.student_profile
    p_null.hostel_block = 'A-Block'
    p_null.year = None
    p_null.save()

    s_y3 = User.objects.create_user(email='test_s_y3@example.com', password='pw', role=UserRole.STUDENT, is_verified=True, first_name='Student Y3')
    p_y3 = s_y3.student_profile
    p_y3.hostel_block = 'A-Block'
    p_y3.year = 3
    p_y3.save()
    
    s_c = User.objects.create_user(email='test_s_c@example.com', password='pw', role=UserRole.STUDENT, is_verified=True, first_name='Student C Block')
    p_c = s_c.student_profile
    p_c.hostel_block = 'C-Block' # No wardens exist for this block
    p_c.year = 1
    p_c.save()

    factory = RequestFactory()
    view = OutpassRequestView.as_view()

    def request_outpass(student_user, dest="Home"):
        req = factory.post('/api/v1/outpass/request/', {
            'destination': dest, 
            'reason': 'Test', 
            'outpass_type': 'REGULAR',
            'exit_date': '2027-01-01',
            'exit_time': '10:00:00',
            'expected_return_date': '2027-01-01',
            'expected_return_time': '18:00:00'
        }, format='json')
        force_authenticate(req, user=student_user)
        return view(req)

    print("Test 1: Normal Year 1 request")
    res = request_outpass(s_y1, "Test 1")
    print(res.data)
    assert res.status_code == 201
    nots = Notification.objects.filter(related_outpass__destination="Test 1")
    notified_wardens = [n.user.email for n in nots]
    # Should notify w_year1 and w_all
    assert 'test_w_y1@example.com' in notified_wardens
    assert 'test_w_all@example.com' in notified_wardens
    assert 'test_w_y2@example.com' not in notified_wardens
    assert 'test_w_b@example.com' not in notified_wardens
    print("PASS: Normal Year 1 request notified the right wardens.")

    print("Test 2: Student with null year")
    res = request_outpass(s_null, "Test 2")
    assert res.status_code == 201
    nots = Notification.objects.filter(related_outpass__destination="Test 2")
    notified_wardens = [n.user.email for n in nots]
    # Should notify ALL wardens in A-Block because year is null, so year filter is skipped.
    assert 'test_w_y1@example.com' in notified_wardens
    assert 'test_w_y2@example.com' in notified_wardens
    assert 'test_w_all@example.com' in notified_wardens
    assert 'test_w_b@example.com' not in notified_wardens
    print("PASS: Student with null year notified all wardens in the hostel.")

    print("Test 3: Mismatched year but correct hostel (Student Y3 in A-Block)")
    res = request_outpass(s_y3, "Test 3")
    assert res.status_code == 201
    nots = Notification.objects.filter(related_outpass__destination="Test 3")
    notified_wardens = [n.user.email for n in nots]
    # Should notify w_all because w_all has assigned_year=None. It shouldn't notify Y1 or Y2.
    assert 'test_w_all@example.com' in notified_wardens
    assert 'test_w_y1@example.com' not in notified_wardens
    assert 'test_w_y2@example.com' not in notified_wardens
    print("PASS: Mismatched year fell back to warden with assigned_year=None in that hostel.")
    
    print("Test 4: Mismatched year AND no warden with assigned_year=null in hostel (Student Y1 in C-Block)")
    # Since C-Block has no wardens at all, it should fallback to all active wardens.
    res = request_outpass(s_c, "Test 4")
    assert res.status_code == 201
    nots = Notification.objects.filter(related_outpass__destination="Test 4")
    notified_wardens = [n.user.email for n in nots]
    # Should fallback to all wardens
    assert 'test_w_y1@example.com' in notified_wardens
    assert 'test_w_b@example.com' in notified_wardens
    print("PASS: No matching wardens at all falls back to all active wardens.")

    print("All tests passed!")

if __name__ == '__main__':
    run_tests()
