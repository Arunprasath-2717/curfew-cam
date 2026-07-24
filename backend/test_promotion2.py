import django
import os
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "src.config.settings.development")
django.setup()

from apps.accounts.models import User
from django.test import Client

w1_u = User.objects.get(email='test_warden_1@aiet.ac.in')
print("w1_u.warden_profile.assigned_year:", w1_u.warden_profile.assigned_year)
