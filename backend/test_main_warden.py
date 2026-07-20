import os
import django
import sys

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'src.config.settings')
django.setup()

from apps.accounts.models import User
from apps.wardens.models import WardenProfile
from rest_framework.test import APIClient
from django.core.management import call_command

def run_test():
    # Cleanup previous tests
    User.objects.filter(email__in=['mainwarden@srishakthi.ac.in', 'regwarden@srishakthi.ac.in', 'targetwarden@srishakthi.ac.in']).delete()

    # Create main warden
    main_user = User.objects.create_user(
        email='mainwarden@srishakthi.ac.in',
        password='password123',
        role='warden'
    )
    main_profile = main_user.warden_profile
    main_profile.employee_id = 'MW1'
    main_profile.hostel_name = 'H1'
    main_profile.save()

    # Create reg warden
    reg_user = User.objects.create_user(
        email='regwarden@srishakthi.ac.in',
        password='password123',
        role='warden'
    )
    reg_profile = reg_user.warden_profile
    reg_profile.employee_id = 'RW1'
    reg_profile.hostel_name = 'H1'
    reg_profile.save()

    # Use management command to set main warden
    call_command('set_main_warden', 'mainwarden@srishakthi.ac.in')

    client = APIClient()

    # 1. Reg warden tries to create a warden (should fail 403)
    client.force_authenticate(user=reg_user)
    res1 = client.post('/api/v1/wardens/manage/wardens/', {
        'first_name': 'Target',
        'email': 'targetwarden@srishakthi.ac.in',
        'password': 'password123',
        'employee_id': 'TW1',
        'hostel_name': 'H1'
    })
    print(f"Reg warden create status: {res1.status_code}")
    assert res1.status_code == 403

    # 2. Main warden tries to create a warden (should succeed 200)
    main_user = User.objects.get(email='mainwarden@srishakthi.ac.in')
    client.force_authenticate(user=main_user)
    res2 = client.post('/api/v1/wardens/manage/wardens/', {
        'first_name': 'Target',
        'email': 'targetwarden@srishakthi.ac.in',
        'password': 'password123',
        'employee_id': 'TW1',
        'hostel_name': 'H1'
    })
    print(f"Main warden create status: {res2.status_code}")
    assert res2.status_code == 200
    target_warden = WardenProfile.objects.get(employee_id='TW1')

    # 3. Reg warden tries to delete warden (should fail 403)
    client.force_authenticate(user=reg_user)
    res3 = client.delete(f'/api/v1/wardens/manage/wardens/{target_warden.id}/')
    print(f"Reg warden delete status: {res3.status_code}")
    assert res3.status_code == 403

    # 4. Main warden tries to delete warden (should succeed 200)
    client.force_authenticate(user=main_user)
    res4 = client.delete(f'/api/v1/wardens/manage/wardens/{target_warden.id}/')
    print(f"Main warden delete status: {res4.status_code}")
    assert res4.status_code == 200

    print("All tests passed successfully!")

if __name__ == '__main__':
    run_test()
