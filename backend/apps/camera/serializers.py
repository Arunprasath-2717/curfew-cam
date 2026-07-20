"""Camera serializers."""
from rest_framework import serializers
from .models import Camera


class CameraSerializer(serializers.ModelSerializer):
    class Meta:
        model = Camera
        fields = (
            'id', 'name', 'location', 'ip_address', 'rtsp_url',
            'status', 'is_active', 'assigned_gate', 'assigned_hostel',
            'last_health_check', 'resolution', 'notes', 'created_at',
        )
        read_only_fields = ('id', 'created_at', 'last_health_check')


class CameraCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Camera
        fields = (
            'name', 'location', 'ip_address', 'rtsp_url',
            'assigned_gate', 'assigned_hostel', 'resolution', 'notes',
        )
