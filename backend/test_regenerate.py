
import json
from django.contrib.auth import get_user_model
from apps.outpass.models import Outpass
from apps.qr.models import QRPass
from rest_framework.test import APIClient

User = get_user_model()
client = APIClient()

student = User.objects.filter(role='STUDENT').first()
if student:
    client.force_authenticate(user=student)
    outpass = Outpass.objects.filter(student=student).first()
    if outpass:
        print('Testing /api/v1/qr/regenerate/{}/'.format(outpass.id))
        res = client.post('/api/v1/qr/regenerate/{}/'.format(outpass.id))
        print('Response status:', res.status_code)
        print('Response body:', res.content.decode())
    else:
        print('No outpass found to test')
else:
    print('No student found')

