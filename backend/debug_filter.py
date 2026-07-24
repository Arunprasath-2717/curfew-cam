import django
import os
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "src.config.settings.development")
django.setup()
from apps.wardens.models import WardenProfile
from apps.outpass.models import Outpass

w1 = WardenProfile.objects.get(user__email='test_warden_1@aiet.ac.in')
print(f"w1 year: {w1.assigned_year}, hostel: {w1.hostel_name}")

qs = Outpass.objects.filter(status='PENDING').select_related('student__user')
print(f"Total pending outpasses: {qs.count()}")
for op in qs:
    print(f"OP {op.id} - Student {op.student.user.email} - Year {op.student.year} - Hostel {op.student.hostel_block}")

qs = qs.filter(student__hostel_block=w1.hostel_name)
print(f"After hostel filter: {qs.count()}")

qs = qs.filter(student__year=w1.assigned_year)
print(f"After year filter: {qs.count()}")

