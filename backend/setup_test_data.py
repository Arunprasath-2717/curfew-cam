import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'src.config.settings.base')
django.setup()

from apps.accounts.models import User
from apps.students.models import StudentProfile
from apps.wardens.models import WardenProfile

def setup_test_data():
    print("Setting up test data...")
    
    # Ensure users exist (created with test_unified_login.py initially)
    student_user, _ = User.objects.get_or_create(email='student@test.com', defaults={'role': 'student'})
    warden_user, _ = User.objects.get_or_create(email='warden@test.com', defaults={'role': 'warden'})
    watchman_user, _ = User.objects.get_or_create(email='watchman@test.com', defaults={'role': 'watchman'})

    student_user.set_password('Test@1234')
    student_user.role = 'student'
    student_user.save()

    warden_user.set_password('Test@1234')
    warden_user.role = 'warden'
    warden_user.save()

    watchman_user.set_password('Test@1234')
    watchman_user.role = 'watchman'
    watchman_user.save()

    # Ensure StudentProfile matches WardenProfile's hostel_block
    student_prof, _ = StudentProfile.objects.get_or_create(
        user=student_user,
        defaults={
            'register_number': 'REG-TEST-1',
            'department': 'Computer Science',
            'year': 2,
            'hostel_block': 'A-Block',
            'room_number': '101'
        }
    )
    student_prof.hostel_block = 'A-Block'
    student_prof.save()

    warden_prof, _ = WardenProfile.objects.get_or_create(
        user=warden_user,
        defaults={
            'employee_id': 'EMP-TEST-1',
            'hostel_name': 'A-Block'
        }
    )
    warden_prof.hostel_name = 'A-Block'
    warden_prof.save()

    print("Test data setup complete.")
    print("Student and Warden both linked to 'A-Block'.")

if __name__ == '__main__':
    setup_test_data()
