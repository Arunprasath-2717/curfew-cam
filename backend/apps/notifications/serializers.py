"""Notification serializers."""
from rest_framework import serializers
from .models import Notification, Announcement


class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = (
            'id', 'title', 'message', 'notification_type', 
            'category', 'priority', 'delivery_status', 
            'metadata', 'is_read', 'related_outpass', 
            'sent_at', 'created_at'
        )
        read_only_fields = ('id', 'created_at', 'sent_at')


class NotificationMarkReadSerializer(serializers.Serializer):
    notification_ids = serializers.ListField(
        child=serializers.UUIDField(),
        allow_empty=False
    )

class AnnouncementSerializer(serializers.ModelSerializer):
    warden_name = serializers.CharField(source='warden.get_full_name', read_only=True)
    duration_hours = serializers.IntegerField(write_only=True, required=False, allow_null=True)

    class Meta:
        model = Announcement
        fields = ('id', 'warden', 'warden_name', 'title', 'message', 'is_active', 'expires_at', 'duration_hours', 'created_at')
        read_only_fields = ('id', 'warden', 'created_at', 'expires_at')

    def create(self, validated_data):
        duration_hours = validated_data.pop('duration_hours', None)
        instance = super().create(validated_data)
        if duration_hours:
            from django.utils import timezone
            from datetime import timedelta
            instance.expires_at = timezone.now() + timedelta(hours=duration_hours)
            instance.save(update_fields=['expires_at'])
        return instance
