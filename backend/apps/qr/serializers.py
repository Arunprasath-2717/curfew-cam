"""QR serializers."""
from rest_framework import serializers
from .models import QRPass


class QRPassSerializer(serializers.ModelSerializer):
    is_expired = serializers.BooleanField(read_only=True)
    is_valid = serializers.BooleanField(read_only=True)
    student_name = serializers.SerializerMethodField()

    class Meta:
        model = QRPass
        fields = (
            'id', 'outpass', 'token', 'qr_image', 'expires_at',
            'is_used', 'is_expired', 'is_valid', 'scan_count',
            'max_scans', 'student_name', 'created_at',
        )
        read_only_fields = ('id', 'token', 'hmac_signature', 'created_at')

    def get_student_name(self, obj):
        try:
            return obj.outpass.student.user.full_name
        except Exception:
            return None


class QRValidateSerializer(serializers.Serializer):
    token = serializers.CharField()
