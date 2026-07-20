"""Notification views."""
from rest_framework import generics, permissions, status
from rest_framework.views import APIView
from django_filters.rest_framework import DjangoFilterBackend
from django.utils import timezone

from apps.common.responses import success_response, error_response
from apps.accounts.permissions import IsAdminOrWarden
from apps.students.models import StudentProfile
from .models import Notification
from .serializers import NotificationSerializer, NotificationMarkReadSerializer


class NotificationListView(generics.ListAPIView):
    """List current user's notifications."""
    permission_classes = (permissions.IsAuthenticated,)
    serializer_class = NotificationSerializer
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['is_read', 'notification_type']

    def get_queryset(self):
        return Notification.objects.filter(user=self.request.user).order_by('-created_at')


class NotificationUnreadCountView(APIView):
    """Get count of unread notifications."""
    permission_classes = (permissions.IsAuthenticated,)

    def get(self, request):
        count = Notification.objects.filter(user=request.user, is_read=False).count()
        return success_response(data={'unread_count': count})


class NotificationMarkReadView(APIView):
    """Mark specific notifications as read."""
    permission_classes = (permissions.IsAuthenticated,)

    def post(self, request):
        serializer = NotificationMarkReadSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        notification_ids = serializer.validated_data['notification_ids']
        updated = Notification.objects.filter(
            id__in=notification_ids, 
            user=request.user
        ).update(is_read=True)
        
        return success_response(message=f'Marked {updated} notifications as read')


class NotificationMarkAllReadView(APIView):
    """Mark all notifications as read for current user."""
    permission_classes = (permissions.IsAuthenticated,)

    def post(self, request):
        updated = Notification.objects.filter(
            user=request.user, 
            is_read=False
        ).update(is_read=True)
        
        return success_response(message=f'Marked {updated} notifications as read')


class EmergencyNotificationView(APIView):
    """Broadcast emergency alert to all students in warden's hostel block."""
    permission_classes = (permissions.IsAuthenticated, IsAdminOrWarden)

    def post(self, request):
        title = request.data.get('title', '').strip()
        message = request.data.get('message', '').strip()
        if not title or not message:
            return error_response('title and message are required')

        warden_profile = getattr(request.user, 'warden_profile', None)
        students = StudentProfile.objects.select_related('user')
        if warden_profile:
            students = students.filter(hostel_block=warden_profile.hostel_name)

        notifications = [
            Notification(
                user=s.user,
                title=title,
                message=message,
                notification_type=Notification.NotificationType.SYSTEM_ALERT,
                category=Notification.NotificationCategory.SYSTEM,
                priority=Notification.NotificationPriority.CRITICAL,
            )
            for s in students
        ]
        Notification.objects.bulk_create(notifications)
        return success_response(
            data={'sent_count': len(notifications)},
            message=f'Emergency alert sent to {len(notifications)} students',
        )
