import django
import os
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "src.config.settings.development")
django.setup()

from apps.accounts.models import User
from rest_framework.test import APIRequestFactory
from apps.wardens.views import PendingOutpassListView
factory = APIRequestFactory()
w1_u = User.objects.get(email='test_warden_1@aiet.ac.in')
req = factory.get('/fake')
req.user = w1_u
view = PendingOutpassListView.as_view()
res = view(req)
print(res.data)
