"""Notification views."""
from rest_framework import generics, permissions, status
from rest_framework.views import APIView
from django_filters.rest_framework import DjangoFilterBackend
from django.utils import timezone

from apps.common.responses import success_response, error_response
from apps.accounts.permissions import IsAdminOrWarden
from apps.students.models import StudentProfile
from .models import Notification, Announcement
from .serializers import NotificationSerializer, NotificationMarkReadSerializer, AnnouncementSerializer


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

        user = request.user
        warden_profile = getattr(user, 'warden_profile', None)
        students = StudentProfile.objects.select_related('user')
        
        if getattr(user, 'role', '') != 'admin_warden':
            if warden_profile and not warden_profile.is_chief_warden:
                students = students.filter(hostel_block=warden_profile.hostel_name)

        from .services import NotificationService
        count = 0
        for s in students:
            NotificationService.create(
                user=s.user,
                title=title,
                message=message,
                event_name='EMERGENCY_ALERT',
                category=Notification.NotificationCategory.SYSTEM,
                notification_type=Notification.NotificationType.SYSTEM_ALERT,
                priority=Notification.NotificationPriority.CRITICAL,
            )
            count += 1

        return success_response(
            data={'sent_count': count},
            message=f'Emergency alert sent to {count} students',
        )

class AnnouncementListCreateView(generics.ListCreateAPIView):
    """List and create announcements."""
    permission_classes = (permissions.IsAuthenticated,)
    serializer_class = AnnouncementSerializer

    def get_queryset(self):
        from django.db.models import Q
        return Announcement.objects.filter(
            Q(is_active=True) & (Q(expires_at__isnull=True) | Q(expires_at__gt=timezone.now()))
        )

    def perform_create(self, serializer):
        from rest_framework.exceptions import PermissionDenied
        if getattr(self.request.user, 'role', '') not in ['warden', 'admin_warden']:
            raise PermissionDenied("Only wardens can post announcements.")
        serializer.save(warden=self.request.user)


class AnnouncementDeleteView(generics.DestroyAPIView):
    """Delete (deactivate) an announcement."""
    permission_classes = (permissions.IsAuthenticated,)
    queryset = Announcement.objects.all()

    def perform_destroy(self, instance):
        from rest_framework.exceptions import PermissionDenied
        if getattr(self.request.user, 'role', '') not in ['warden', 'admin_warden']:
            raise PermissionDenied("Only wardens can delete announcements.")
        instance.is_active = False
        instance.save()
