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

    class Meta:
        model = GateScan
        fields = ('id', 'qr_pass', 'watchman', 'scan_type', 'gate', 'student_name', 'notes', 'created_at')
        read_only_fields = ('id', 'created_at')

    def get_student_name(self, obj):
        try:
            return obj.qr_pass.outpass.student.user.full_name
        except Exception:
            return None


class QRScanRequestSerializer(serializers.Serializer):
    qr_token = serializers.CharField()
    scan_type = serializers.ChoiceField(choices=['EXIT', 'RETURN'])
    gate = serializers.CharField(required=False, allow_blank=True)
