"""Student serializers."""
from rest_framework import serializers
from .models import StudentProfile, Guardian
from apps.accounts.serializers import UserSerializer


class GuardianSerializer(serializers.ModelSerializer):
    class Meta:
        model = Guardian
        fields = ('id', 'name', 'relationship', 'phone', 'email', 'is_primary')
        read_only_fields = ('id',)


class StudentProfileSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    guardians = GuardianSerializer(many=True, read_only=True)
    outpass_stats = serializers.SerializerMethodField()

    class Meta:
        model = StudentProfile
        fields = (
            'id', 'user', 'register_number', 'department', 'year',
            'semester', 'hostel_block', 'room_number', 'face_image',
            'is_in_hostel', 'guardians', 'created_at', 'outpass_stats',
        )
        read_only_fields = ('id', 'created_at', 'is_in_hostel')

    def get_outpass_stats(self, obj):
        from apps.outpass.models import Outpass
        qs = obj.outpasses.all()
        return {
            'total': qs.count(),
            'approved': qs.filter(status=Outpass.Status.APPROVED).count(),
            'rejected': qs.filter(status=Outpass.Status.REJECTED).count(),
            'returned': qs.filter(status=Outpass.Status.RETURNED).count(),
        }


class StudentProfileCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = StudentProfile
        fields = (
            'register_number', 'department', 'year', 'semester',
            'hostel_block', 'room_number', 'face_image',
        )


class StudentProfileUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = StudentProfile
        fields = ('department', 'year', 'semester', 'hostel_block', 'room_number', 'face_image')