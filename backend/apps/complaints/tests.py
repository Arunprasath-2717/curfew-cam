from django.test import TestCase
from rest_framework.test import APIClient
from rest_framework import status
from apps.accounts.models import User, UserRole
from .models import Complaint, ComplaintCategory, ComplaintPriority, ComplaintStatus


class ComplaintsAPITestCase(TestCase):
    def setUp(self):
        self.client = APIClient()

        # Create Student
        self.student = User.objects.create_user(
            email='student@test.com',
            password='StudentPassword123!',
            role=UserRole.STUDENT,
            first_name='John',
            last_name='Doe'
        )

        # Create Warden
        self.warden = User.objects.create_user(
            email='warden@test.com',
            password='WardenPassword123!',
            role=UserRole.WARDEN,
            first_name='Jane',
            last_name='Smith'
        )

    def test_student_create_complaint(self):
        self.client.force_authenticate(user=self.student)
        payload = {
            'title': 'Leaking Water Pipe',
            'category': ComplaintCategory.MAINTENANCE,
            'priority': ComplaintPriority.HIGH,
            'description': 'Pipe leaking in room 204 near the bathroom.',
            'is_anonymous': False,
        }
        response = self.client.post('/api/v1/complaints/', payload, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertTrue(response.data['success'])
        self.assertEqual(response.data['data']['title'], 'Leaking Water Pipe')

        # Check DB
        complaint = Complaint.objects.get(id=response.data['data']['id'])
        self.assertEqual(complaint.student, self.student)
        self.assertEqual(complaint.status, ComplaintStatus.PENDING)

    def test_warden_list_and_stats(self):
        # Create complaints
        Complaint.objects.create(
            student=self.student,
            title='Noisy Party in Hallway',
            category=ComplaintCategory.NOISE_DISCIPLINE,
            priority=ComplaintPriority.MEDIUM,
            description='Loud music after 10 PM.',
            status=ComplaintStatus.PENDING
        )

        self.client.force_authenticate(user=self.warden)

        # Test stats endpoint
        stats_res = self.client.get('/api/v1/complaints/stats/')
        self.assertEqual(stats_res.status_code, status.HTTP_200_OK)
        self.assertEqual(stats_res.data['data']['total_complaints'], 1)
        self.assertEqual(stats_res.data['data']['pending_count'], 1)

        # Test list endpoint
        list_res = self.client.get('/api/v1/complaints/')
        self.assertEqual(list_res.status_code, status.HTTP_200_OK)
        results = list_res.data['data']['results'] if 'results' in list_res.data['data'] else list_res.data['data']
        self.assertEqual(len(results), 1)

    def test_warden_update_status(self):
        complaint = Complaint.objects.create(
            student=self.student,
            title='Broken Chair',
            category=ComplaintCategory.MAINTENANCE,
            priority=ComplaintPriority.LOW,
            description='Study chair broken leg.',
            status=ComplaintStatus.PENDING
        )

        self.client.force_authenticate(user=self.warden)
        patch_payload = {
            'status': ComplaintStatus.RESOLVED,
            'warden_response': 'Replaced with a new chair from inventory.',
        }
        res = self.client.patch(f'/api/v1/complaints/{complaint.id}/status/', patch_payload, format='json')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertTrue(res.data['success'])

        complaint.refresh_from_db()
        self.assertEqual(complaint.status, ComplaintStatus.RESOLVED)
        self.assertEqual(complaint.warden_response, 'Replaced with a new chair from inventory.')
        self.assertEqual(complaint.assigned_warden, self.warden)
        self.assertIsNotNone(complaint.resolved_at)

    def test_anonymous_complaint(self):
        complaint = Complaint.objects.create(
            student=self.student,
            title='Anonymous Feedback',
            category=ComplaintCategory.FOOD_MESS,
            priority=ComplaintPriority.MEDIUM,
            description='Food quality needs improvement.',
            is_anonymous=True
        )

        self.client.force_authenticate(user=self.warden)
        res = self.client.get(f'/api/v1/complaints/{complaint.id}/')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data['data']['student_name'], 'Anonymous Student')
