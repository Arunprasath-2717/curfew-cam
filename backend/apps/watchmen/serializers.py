"""Watchman serializers."""
from rest_framework import serializers
from .models import WatchmanProfile, ShiftLog, GateScan


class WatchmanProfileSerializer(serializers.ModelSerializer):
    user_name = serializers.CharField(source='user.full_name', read_only=True)

    class Meta:
        model = WatchmanProfile
        fields = ('id', 'user', 'user_name', 'employee_id', 'assigned_gate', 'is_on_duty', 'created_at')
        read_only_fields = ('id', 'user', 'created_at')


class ShiftLogSerializer(serializers.ModelSerializer):
    class Meta:
        model = ShiftLog
        fields = ('id', 'watchman', 'shift_start', 'shift_end', 'gate', 'notes', 'created_at')
        read_only_fields = ('id', 'created_at')


class GateScanSerializer(serializers.ModelSerializer):
    student_name = serializers.SerializerMethodField()
    register_number = serializers.SerializerMethodField()
    room_number = serializers.SerializerMethodField()
    hostel_block = serializers.SerializerMethodField()
    department = serializers.SerializerMethodField()
    destination = serializers.SerializerMethodField()
    expected_return_date = serializers.SerializerMethodField()
    expected_return_time = serializers.SerializerMethodField()
    approved_by_name = serializers.SerializerMethodField()
    outpass_id = serializers.SerializerMethodField()

    class Meta:
        model = GateScan
        fields = (
            'id', 'qr_pass', 'watchman', 'scan_type', 'gate', 'student_name',
            'register_number', 'room_number', 'hostel_block', 'department',
            'destination', 'expected_return_date', 'expected_return_time',
            'approved_by_name', 'outpass_id', 'notes', 'created_at'
        )
        read_only_fields = ('id', 'created_at')

    def get_student_name(self, obj):
        try:
            return obj.qr_pass.outpass.student.user.full_name
        except Exception:
            return None

    def get_register_number(self, obj):
        try:
            return obj.qr_pass.outpass.student.register_number
        except Exception:
            return None

    def get_room_number(self, obj):
        try:
            return obj.qr_pass.outpass.student.room_number
        except Exception:
            return None

    def get_hostel_block(self, obj):
        try:
            return obj.qr_pass.outpass.student.hostel_block
        except Exception:
            return None

    def get_department(self, obj):
        try:
            return obj.qr_pass.outpass.student.department
        except Exception:
            return None

    def get_destination(self, obj):
        try:
            return obj.qr_pass.outpass.destination or obj.qr_pass.outpass.reason
        except Exception:
            return None

    def get_expected_return_date(self, obj):
        try:
            return str(obj.qr_pass.outpass.expected_return_date)
        except Exception:
            return None

    def get_expected_return_time(self, obj):
        try:
            return str(obj.qr_pass.outpass.expected_return_time)
        except Exception:
            return None

    def get_approved_by_name(self, obj):
        try:
            if obj.qr_pass.outpass.approved_by:
                return obj.qr_pass.outpass.approved_by.user.full_name
            return 'Warden'
        except Exception:
            return None

    def get_outpass_id(self, obj):
        try:
            return str(obj.qr_pass.outpass.id)
        except Exception:
            return None


class QRScanRequestSerializer(serializers.Serializer):
    qr_token = serializers.CharField()
    scan_type = serializers.ChoiceField(choices=['EXIT', 'RETURN'], required=False, allow_null=True, allow_blank=True)
    gate = serializers.CharField(required=False, allow_blank=True)
