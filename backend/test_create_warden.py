from apps.accounts.models import User, UserRole
from apps.wardens.models import WardenProfile
from apps.wardens.serializers import ManageWardenSerializer
from rest_framework.test import APIRequestFactory, force_authenticate
from apps.wardens.management_views import ManageWardensView
from apps.accounts.views import LoginView
import json

User.objects.filter(email='new_warden@test.com').delete()

# 1. Create a dummy chief warden to authenticate
chief, _ = User.objects.get_or_create(email='test_chief_warden@test.com')
chief.set_password('Admin@1234')
chief.role = UserRole.ADMIN_WARDEN
chief.is_verified = True
chief.save()
profile, _ = WardenProfile.objects.get_or_create(user=chief)
profile.is_chief_warden = True
profile.save()

# 2. Call the manage/create endpoint
factory = APIRequestFactory()
data = {
    'email': 'new_warden@test.com',
    'first_name': 'New',
    'last_name': 'Warden',
    'password': 'NewPassword123!',
    'employee_id': 'EMP999',
    'hostel_name': 'A-Block',
    'assigned_year': 1,
    'is_chief_warden': False,
    'phone_number': '9998887770'
}

request = factory.post('/api/wardens/manage/create/', data, format='json')
force_authenticate(request, user=chief)
view = ManageWardensView.as_view()
response = view(request)

print(f"Create Warden Status: {response.status_code}")
print(f"Create Warden Data: {response.data}")

# 3. Test login endpoint with the new credentials
login_data = {
    'email': 'new_warden@test.com',
    'password': 'NewPassword123!',
    'role': 'warden'
}
login_request = factory.post('/api/auth/login/', login_data, format='json')
login_view = LoginView.as_view()
login_response = login_view(login_request)

print(f"Login Status: {login_response.status_code}")
if login_response.status_code == 200:
    print("Login succeeded on the first try. Tokens received.")
else:
    print(f"Login failed: {login_response.data}")
