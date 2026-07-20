"""Detection serializers."""
from rest_framework import serializers
from .models import Detection, Alert


class DetectionSerializer(serializers.ModelSerializer):
    camera_name = serializers.CharField(source='camera.name', read_only=True)
    matched_student_name = serializers.SerializerMethodField()

    class Meta:
        model = Detection
        fields = (
            'id', 'camera', 'camera_name', 'detection_type', 'image',
            'confidence', 'bounding_box', 'matched_student',
            'matched_student_name', 'metadata', 'created_at',
        )
        read_only_fields = ('id', 'created_at')

    def get_matched_student_name(self, obj):
        if obj.matched_student:
            return obj.matched_student.user.full_name
        return None


class DetectionCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Detection
        fields = ('camera', 'detection_type', 'image', 'confidence', 'bounding_box', 'metadata')


class AlertSerializer(serializers.ModelSerializer):
    class Meta:
        model = Alert
        fields = (
            'id', 'detection', 'title', 'message', 'level', 'status',
            'acknowledged_by', 'acknowledged_at', 'created_at',
        )
        read_only_fields = ('id', 'created_at')
