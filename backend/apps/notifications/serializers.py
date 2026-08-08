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

    class Meta:
        model = Announcement
        fields = ('id', 'warden', 'warden_name', 'title', 'message', 'is_active', 'created_at')
        read_only_fields = ('id', 'warden', 'created_at')
