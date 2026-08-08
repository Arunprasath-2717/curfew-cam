"""Warden serializers."""
from rest_framework import serializers
from .models import WardenProfile, AuditLog
from apps.accounts.serializers import UserSerializer


class WardenProfileSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)

    class Meta:
        model = WardenProfile
        fields = ('id', 'user', 'employee_id', 'hostel_name', 'designation', 'is_chief_warden', 'created_at')
        read_only_fields = ('id', 'created_at')


class DashboardStatsSerializer(serializers.Serializer):
    total_students = serializers.IntegerField()
    students_in_hostel = serializers.IntegerField()
    students_outside = serializers.IntegerField()
    pending_requests = serializers.IntegerField()
    approved_today = serializers.IntegerField()
    late_returns = serializers.IntegerField()
    active_outpasses = serializers.IntegerField()

class AuditLogSerializer(serializers.ModelSerializer):
    performed_by_name = serializers.CharField(source='performed_by.full_name', read_only=True)
    
    class Meta:
        model = AuditLog
        fields = ('id', 'action', 'performed_by', 'performed_by_name', 'target_email', 'timestamp')
        read_only_fields = fields

class ManageStudentSerializer(serializers.Serializer):
    email = serializers.EmailField()
    first_name = serializers.CharField(max_length=150)
    last_name = serializers.CharField(max_length=150, required=False, allow_blank=True)
    password = serializers.CharField(write_only=True, min_length=8)
    register_number = serializers.CharField(max_length=30)
    department = serializers.CharField(max_length=100)
    year = serializers.IntegerField(min_value=1, max_value=5)
    hostel_block = serializers.CharField(max_length=100)
    room_number = serializers.CharField(max_length=100, required=False, allow_blank=True, default='TBD')

class ManageWardenSerializer(serializers.Serializer):
    email = serializers.EmailField()
    first_name = serializers.CharField(max_length=150)
    last_name = serializers.CharField(max_length=150, required=False, allow_blank=True)
    password = serializers.CharField(write_only=True, min_length=8)
    employee_id = serializers.CharField(max_length=30)
    hostel_name = serializers.CharField(max_length=100, required=False, allow_blank=True)
    phone_number = serializers.CharField(max_length=15, required=False, allow_blank=True)
    assigned_year = serializers.IntegerField(required=False, allow_null=True)
    is_chief_warden = serializers.BooleanField(required=False, default=False)


