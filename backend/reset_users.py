import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'src.config.settings')
django.setup()

from apps.accounts.models import User, UserRole

try:
    from apps.watchmen.models import WatchmanProfile
except ImportError:
    WatchmanProfile = None

try:
    from apps.students.models import StudentProfile
except ImportError:
    StudentProfile = None

try:
    from apps.wardens.models import WardenProfile
except ImportError:
    WardenProfile = None

User.objects.all().delete()

# Create Admin Warden
admin = User.objects.create_superuser(
    email='admin@test.com',
    password='Password123',
    first_name='Admin',
    last_name='Warden'
)
admin.role = UserRole.ADMIN_WARDEN
admin.save()
if WardenProfile:
    WardenProfile.objects.get_or_create(user=admin)
print(f"Created Admin Warden: {admin.email}")

# Create Watchman
watchman = User.objects.create_user(
    email='watchman1@test.com',
    password='Password123',
    role=UserRole.WATCHMAN,
    first_name='Watchman',
    last_name='One',
    phone_number='9998887770',
    is_verified=True
)
if WatchmanProfile:
    WatchmanProfile.objects.get_or_create(user=watchman)
print(f"Created Watchman: {watchman.phone_number} / {watchman.email}")

# Create Wardens
for i in range(1, 3):
    warden = User.objects.create_user(
        email=f'warden{i}@test.com',
        password='Password123',
        role=UserRole.WARDEN,
        first_name='Warden',
        last_name=str(i),
        is_verified=True
    )
    if WardenProfile:
        WardenProfile.objects.get_or_create(user=warden)
    print(f"Created Warden: {warden.email}")

# Create Students
for i in range(1, 4):
    student = User.objects.create_user(
        email=f'student{i}@test.com',
        password='Password123',
        role=UserRole.STUDENT,
        first_name='Student',
        last_name=str(i),
        is_verified=True
    )
    if StudentProfile:
        StudentProfile.objects.get_or_create(user=student)
    print(f"Created Student: {student.email}")

print("Done resetting users.")
