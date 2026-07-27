"""Test all 4 roles login + push notification pipeline."""
from django.test import TestCase, Client
from apps.accounts.models import User, UserRole
from apps.students.models import StudentProfile
from apps.wardens.models import WardenProfile
from apps.watchmen.models import WatchmanProfile, GateScan
from apps.outpass.models import Outpass
from apps.notifications.models import Notification
from apps.common.models import MovementLog


class AllRolesLoginTest(TestCase):
    """Verify all 4 roles can log in."""

    def setUp(self):
        self.client = Client()

        # Student
        self.student = User.objects.create_user(
            email='student@srishakthi.ac.in', password='pass123',
            role=UserRole.STUDENT, is_verified=True
        )
        sp = StudentProfile.objects.get(user=self.student)
        sp.register_number = '21BS001'
        sp.department = 'CSE'
        sp.year = 1
        sp.hostel_block = 'A'
        sp.save()

        # Warden
        self.warden = User.objects.create_user(
            email='warden@srishakthi.ac.in', password='pass123',
            role=UserRole.WARDEN, is_verified=True
        )
        wp = WardenProfile.objects.get(user=self.warden)
        wp.employee_id = 'W001'
        wp.hostel_name = 'A'
        wp.save()

        # Watchman (phone login)
        self.watchman = User.objects.create_user(
            email='9876543210@watchman.internal', password='pass123',
            role=UserRole.WATCHMAN, phone_number='9876543210', is_verified=True
        )
        WatchmanProfile.objects.create(
            user=self.watchman, employee_id='WM001', assigned_gate='Main Gate'
        )

        # Admin
        self.admin = User.objects.create_user(
            email='admin@srishakthi.ac.in', password='pass123',
            role=UserRole.ADMIN, is_verified=True
        )

    def _login(self, email, role):
        res = self.client.post('/api/v1/auth/login/', {
            'email': email, 'password': 'pass123', 'role': role
        })
        return res

    def test_student_login(self):
        res = self._login('student@srishakthi.ac.in', 'student')
        self.assertEqual(res.status_code, 200, res.content)
        self.assertIn('tokens', res.json())

    def test_warden_login(self):
        res = self._login('warden@srishakthi.ac.in', 'warden')
        self.assertEqual(res.status_code, 200, res.content)
        self.assertIn('tokens', res.json())

    def test_watchman_login_by_phone(self):
        res = self._login('9876543210', 'watchman')
        self.assertEqual(res.status_code, 200, res.content)
        self.assertIn('tokens', res.json())

    def test_watchman_login_by_email(self):
        res = self._login('9876543210@watchman.internal', 'watchman')
        self.assertEqual(res.status_code, 200, res.content)
        self.assertIn('tokens', res.json())

    def test_admin_login(self):
        res = self._login('admin@srishakthi.ac.in', 'admin')
        self.assertEqual(res.status_code, 200, res.content)
        self.assertIn('tokens', res.json())


class NotificationFlowTest(TestCase):
    """Verify notifications are created for both student AND warden at each step."""

    def setUp(self):
        self.client = Client()

        self.student = User.objects.create_user(
            email='student@srishakthi.ac.in', password='pass123',
            role=UserRole.STUDENT, is_verified=True
        )
        sp = StudentProfile.objects.get(user=self.student)
        sp.register_number = '21BS001'
        sp.department = 'CSE'
        sp.year = 1
        sp.hostel_block = 'A'
        sp.save()

        self.warden_user = User.objects.create_user(
            email='warden@srishakthi.ac.in', password='pass123',
            role=UserRole.WARDEN, is_verified=True
        )
        wp = WardenProfile.objects.get(user=self.warden_user)
        wp.employee_id = 'W001'
        wp.hostel_name = 'A'
        wp.save()

        self.watchman_user = User.objects.create_user(
            email='9876543210@watchman.internal', password='pass123',
            role=UserRole.WATCHMAN, phone_number='9876543210', is_verified=True
        )
        WatchmanProfile.objects.create(
            user=self.watchman_user, employee_id='WM001', assigned_gate='Main Gate'
        )

    def test_notifications_at_each_step(self):
        # Login
        res = self.client.post('/api/v1/auth/login/', {
            'email': 'student@srishakthi.ac.in', 'password': 'pass123', 'role': 'student'
        })
        student_token = res.json()['tokens']['access']

        # 1. Student requests outpass → warden gets notified
        before = Notification.objects.count()
        res = self.client.post('/api/v1/outpass/request/', {
            'destination': 'City Center', 'reason': 'Shopping',
            'exit_date': '2027-10-10', 'exit_time': '10:00:00',
            'expected_return_date': '2027-10-10', 'expected_return_time': '20:00:00'
        }, HTTP_AUTHORIZATION=f'Bearer {student_token}')
        self.assertEqual(res.status_code, 201, res.content)
        outpass_id = res.json()['data']['id']

        warden_notifs = Notification.objects.filter(user=self.warden_user)
        self.assertGreaterEqual(warden_notifs.count(), 1,
            "Warden should be notified of new outpass request")
        self.assertEqual(warden_notifs.first().title, 'New Outpass Request')

        # 2. Warden approves → student gets notified
        res = self.client.post('/api/v1/auth/login/', {
            'email': 'warden@srishakthi.ac.in', 'password': 'pass123', 'role': 'warden'
        })
        warden_token = res.json()['tokens']['access']

        student_notif_before = Notification.objects.filter(user=self.student).count()
        res = self.client.post(f'/api/v1/wardens/outpass/{outpass_id}/approve/', {
            'action': 'approve'
        }, HTTP_AUTHORIZATION=f'Bearer {warden_token}')
        self.assertEqual(res.status_code, 200, res.content)

        student_notifs = Notification.objects.filter(user=self.student)
        self.assertGreater(student_notifs.count(), student_notif_before,
            "Student should be notified of outpass approval")
        self.assertTrue(
            student_notifs.filter(title='Outpass Approved').exists(),
            "Student should receive 'Outpass Approved' notification"
        )

        # 3. Generate QR
        res = self.client.post(f'/api/v1/qr/generate/{outpass_id}/', {},
            HTTP_AUTHORIZATION=f'Bearer {student_token}')
        self.assertEqual(res.status_code, 200, res.content)
        qr_token = res.json()['data']['token']

        # 4. Watchman scans EXIT → student AND warden notified
        res = self.client.post('/api/v1/auth/login/', {
            'email': '9876543210', 'password': 'pass123', 'role': 'watchman'
        })
        watchman_token = res.json()['tokens']['access']

        student_before = Notification.objects.filter(user=self.student).count()
        warden_before = Notification.objects.filter(user=self.warden_user).count()

        res = self.client.post('/api/v1/watchmen/scan/', {
            'qr_token': qr_token, 'scan_type': 'EXIT', 'gate': 'Main Gate'
        }, HTTP_AUTHORIZATION=f'Bearer {watchman_token}')
        self.assertEqual(res.status_code, 200, res.content)

        self.assertGreater(
            Notification.objects.filter(user=self.student).count(), student_before,
            "Student should be notified of EXIT scan"
        )
        self.assertGreater(
            Notification.objects.filter(user=self.warden_user).count(), warden_before,
            "Warden should be notified of EXIT scan"
        )

        # 5. Watchman scans RETURN → student AND warden notified
        student_before = Notification.objects.filter(user=self.student).count()
        warden_before = Notification.objects.filter(user=self.warden_user).count()

        res = self.client.post('/api/v1/watchmen/scan/', {
            'qr_token': qr_token, 'scan_type': 'RETURN', 'gate': 'Main Gate'
        }, HTTP_AUTHORIZATION=f'Bearer {watchman_token}')
        self.assertEqual(res.status_code, 200, res.content)

        self.assertGreater(
            Notification.objects.filter(user=self.student).count(), student_before,
            "Student should be notified of RETURN scan"
        )
        self.assertGreater(
            Notification.objects.filter(user=self.warden_user).count(), warden_before,
            "Warden should be notified of RETURN scan"
        )

        # Final summary
        total = Notification.objects.count()
        student_total = Notification.objects.filter(user=self.student).count()
        warden_total = Notification.objects.filter(user=self.warden_user).count()
        print(f"\nTOTAL NOTIFICATIONS: {total}")
        print(f"  Student received: {student_total}")
        print(f"  Warden received: {warden_total}")
        for n in Notification.objects.order_by('created_at'):
            print(f"  [{n.user.role}] {n.title} → {n.user.email}")
