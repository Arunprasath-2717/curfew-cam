"""Outpass serializers."""
from rest_framework import serializers
from .models import Outpass
from apps.students.serializers import StudentProfileSerializer


class OutpassCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Outpass
        fields = (
            'outpass_type', 'reason', 'destination',
            'exit_date', 'exit_time',
            'expected_return_date', 'expected_return_time',
        )


class OutpassSerializer(serializers.ModelSerializer):
    student_name = serializers.CharField(source='student.user.full_name', read_only=True)
    student_register = serializers.CharField(source='student.register_number', read_only=True)
    student_on_campus = serializers.BooleanField(source='student.is_on_campus', read_only=True)
    is_late = serializers.BooleanField(read_only=True)
    approved_by_name = serializers.SerializerMethodField()

    class Meta:
        model = Outpass
        fields = (
            'id', 'student', 'student_name', 'student_register', 'student_on_campus',
            'outpass_type', 'reason', 'destination',
            'exit_date', 'exit_time',
            'expected_return_date', 'expected_return_time',
            'actual_exit_time', 'actual_return_time',
            'status', 'rejection_reason', 'warden_notes',
            'approved_by', 'approved_by_name',
            'is_late', 'created_at',
        )
        read_only_fields = (
            'id', 'student', 'actual_exit_time', 'actual_return_time',
            'status', 'rejection_reason', 'approved_by', 'created_at',
        )

    def get_approved_by_name(self, obj):
        if obj.approved_by:
            return obj.approved_by.user.full_name
        return None


class OutpassApprovalSerializer(serializers.Serializer):
    action = serializers.ChoiceField(choices=['approve', 'reject'])
    rejection_reason = serializers.CharField(required=False, allow_blank=True)
    warden_notes = serializers.CharField(required=False, allow_blank=True)
