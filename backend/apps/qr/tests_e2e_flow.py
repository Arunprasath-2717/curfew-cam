from django.test import TestCase, Client
from apps.accounts.models import User, UserRole
from apps.students.models import StudentProfile
from apps.wardens.models import WardenProfile
from apps.watchmen.models import WatchmanProfile, GateScan
from apps.outpass.models import Outpass
from apps.common.models import MovementLog
from apps.qr.models import QRPass


class QRFlowE2ETest(TestCase):
    def setUp(self):
        self.client = Client()

        self.student_user = User.objects.create_user(
            email='student@srishakthi.ac.in',
            password='testpassword123',
            role=UserRole.STUDENT,
            is_verified=True
        )
        self.student_profile = StudentProfile.objects.get(user=self.student_user)
        self.student_profile.register_number = '21BS001'
        self.student_profile.department = 'CSE'
        self.student_profile.year = 1
        self.student_profile.hostel_block = 'A'
        self.student_profile.save()

        self.warden_user = User.objects.create_user(
            email='warden@srishakthi.ac.in',
            password='testpassword123',
            role=UserRole.WARDEN,
            is_verified=True
        )
        self.warden_profile = WardenProfile.objects.get(user=self.warden_user)
        self.warden_profile.employee_id = 'W001'
        self.warden_profile.hostel_name = 'A'
        self.warden_profile.save()

        self.watchman_user = User.objects.create_user(
            email='9876543210@watchman.internal',
            password='testpassword123',
            role=UserRole.WATCHMAN,
            phone_number='9876543210',
            is_verified=True
        )
        self.watchman_profile = WatchmanProfile.objects.create(
            user=self.watchman_user,
            employee_id='WM001',
            assigned_gate='Main Gate'
        )

    def test_e2e_qr_flow(self):
        res = self.client.post('/api/v1/auth/login/', {
            'email': 'student@srishakthi.ac.in',
            'password': 'testpassword123',
            'role': 'student'
        })
        self.assertEqual(res.status_code, 200, res.content)
        student_token = res.json()['tokens']['access']

        res = self.client.post('/api/v1/outpass/request/', {
            'destination': 'City Center',
            'reason': 'Shopping',
            'exit_date': '2027-10-10',
            'exit_time': '10:00:00',
            'expected_return_date': '2027-10-10',
            'expected_return_time': '20:00:00'
        }, HTTP_AUTHORIZATION=f'Bearer {student_token}')
        self.assertEqual(res.status_code, 201, res.content)
        outpass_id = res.json()['data']['id']

        res = self.client.post('/api/v1/auth/login/', {
            'email': 'warden@srishakthi.ac.in',
            'password': 'testpassword123',
            'role': 'warden'
        })
        self.assertEqual(res.status_code, 200, res.content)
        warden_token = res.json()['tokens']['access']

        res = self.client.post(f'/api/v1/wardens/outpass/{outpass_id}/approve/', {
            'action': 'approve'
        }, HTTP_AUTHORIZATION=f'Bearer {warden_token}')
        self.assertEqual(res.status_code, 200, res.content)

        outpass = Outpass.objects.get(id=outpass_id)
        self.assertEqual(outpass.status, Outpass.Status.APPROVED)

        res = self.client.post(f'/api/v1/qr/generate/{outpass_id}/', {},
                                HTTP_AUTHORIZATION=f'Bearer {student_token}')
        self.assertEqual(res.status_code, 200, res.content)
        qr_token = res.json()['data']['token']

        res = self.client.post('/api/v1/auth/login/', {
            'email': '9876543210',
            'password': 'testpassword123',
            'role': 'watchman'
        })
        self.assertEqual(res.status_code, 200, res.content)
        watchman_token = res.json()['tokens']['access']

        res = self.client.post('/api/v1/watchmen/scan/', {
            'qr_token': qr_token,
            'scan_type': 'EXIT',
            'gate': 'Main Gate'
        }, HTTP_AUTHORIZATION=f'Bearer {watchman_token}')
        self.assertEqual(res.status_code, 200, res.content)

        self.assertEqual(GateScan.objects.count(), 1)
        gs_exit = GateScan.objects.first()
        self.assertEqual(gs_exit.scan_type, 'EXIT')

        self.assertEqual(MovementLog.objects.count(), 1)
        ml = MovementLog.objects.first()
        self.assertEqual(ml.action, 'EXIT')

        outpass.refresh_from_db()
        self.assertEqual(outpass.status, Outpass.Status.ACTIVE)

        res = self.client.post(f'/api/v1/qr/regenerate/{outpass_id}/', {},
                                HTTP_AUTHORIZATION=f'Bearer {student_token}')
        self.assertEqual(res.status_code, 200, res.content)
        qr_token_return = res.json()['data']['token']

        res = self.client.post('/api/v1/watchmen/scan/', {
            'qr_token': qr_token_return,
            'scan_type': 'RETURN',
            'gate': 'Main Gate'
        }, HTTP_AUTHORIZATION=f'Bearer {watchman_token}')
        self.assertEqual(res.status_code, 200, res.content)

        self.assertEqual(GateScan.objects.count(), 2)
        gs_return = GateScan.objects.order_by('created_at').last()
        self.assertEqual(gs_return.scan_type, 'RETURN')

        self.assertEqual(MovementLog.objects.count(), 2)
        ml_return = MovementLog.objects.order_by('created_at').last()
        self.assertEqual(ml_return.action, 'RETURN')

        outpass.refresh_from_db()
        self.assertEqual(outpass.status, Outpass.Status.RETURNED)

        print("TEST PASSED: E2E QR Flow works!")
