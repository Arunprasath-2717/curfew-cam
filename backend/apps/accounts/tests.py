from django.test import TestCase
from rest_framework.test import APIClient
from rest_framework import status
from apps.accounts.models import User, UserRole


class AccountsAPITestCase(TestCase):
    def setUp(self):
        self.client = APIClient()

        # Create Student
        self.student = User.objects.create_user(
            email='student_login@test.com',
            password='StudentPassword123!',
            role=UserRole.STUDENT
        )

        # Create Warden
        self.warden = User.objects.create_user(
            email='warden_login@test.com',
            password='WardenPassword123!',
            role=UserRole.WARDEN
        )

    def test_student_login_success(self):
        res = self.client.post('/api/v1/auth/login/', {
            'email': 'student_login@test.com',
            'password': 'StudentPassword123!',
            'role': 'student',
        }, format='json')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertTrue(res.data['success'])
        self.assertIn('tokens', res.data)
        self.assertEqual(res.data['role'], 'student')

    def test_warden_login_success(self):
        res = self.client.post('/api/v1/auth/login/', {
            'email': 'warden_login@test.com',
            'password': 'WardenPassword123!',
            'role': 'warden',
        }, format='json')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertTrue(res.data['success'])
        self.assertIn('tokens', res.data)
        self.assertEqual(res.data['role'], 'warden')

    def test_login_invalid_password(self):
        res = self.client.post('/api/v1/auth/login/', {
            'email': 'student_login@test.com',
            'password': 'WrongPassword123!',
            'role': 'student',
        }, format='json')
        self.assertEqual(res.status_code, status.HTTP_401_UNAUTHORIZED)
        self.assertFalse(res.data['success'])
