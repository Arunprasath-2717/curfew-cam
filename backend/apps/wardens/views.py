"""Warden views — dashboard, approval workflow."""
from rest_framework import generics, permissions
from rest_framework.views import APIView
from django.utils import timezone
from django.db.models import Q, Count
from datetime import timedelta

from apps.common.responses import success_response, error_response
from apps.accounts.permissions import IsWarden, IsAdminOrWarden
from apps.accounts.models import UserRole
from apps.outpass.models import Outpass
from apps.outpass.serializers import OutpassSerializer, OutpassApprovalSerializer
from apps.students.models import StudentProfile
from apps.students.serializers import StudentProfileSerializer
from apps.common.models import MovementLog
from .models import WardenProfile


class WardenDashboardView(APIView):
    """Warden dashboard with statistics."""
    permission_classes = (permissions.IsAuthenticated, IsAdminOrWarden)

    def get(self, request):
        Outpass.mark_overdue_outpasses()

        warden_profile = getattr(request.user, 'warden_profile', None)
        hostel = warden_profile.hostel_name if warden_profile else None

        students_qs = StudentProfile.objects.all()
        outpass_qs = Outpass.objects.all()
        if warden_profile and not warden_profile.is_chief_warden and request.user.role != UserRole.ADMIN_WARDEN:
            if hostel:
                students_qs = students_qs.filter(hostel_block=hostel)
                outpass_qs = outpass_qs.filter(student__hostel_block=hostel)
            if warden_profile.assigned_year:
                students_qs = students_qs.filter(year=warden_profile.assigned_year)
                outpass_qs = outpass_qs.filter(student__year=warden_profile.assigned_year)

        today = timezone.now().date()
        total = students_qs.count()
        in_hostel = students_qs.filter(is_in_hostel=True).count()

        stats = {
            'total_students': total,
            'students_in_hostel': in_hostel,
            'students_outside': total - in_hostel,
            'pending_requests': outpass_qs.filter(status=Outpass.Status.PENDING).count(),
            'approved_today': outpass_qs.filter(status=Outpass.Status.APPROVED, updated_at__date=today).count(),
            'active_outpasses': outpass_qs.filter(status=Outpass.Status.ACTIVE).count(),
            'late_returns': sum(1 for op in outpass_qs.filter(status=Outpass.Status.ACTIVE) if op.is_late),
        }
        return success_response(data=stats)


class PendingOutpassListView(generics.ListAPIView):
    """List pending outpass requests for warden's hostel."""
    permission_classes = (permissions.IsAuthenticated, IsAdminOrWarden)
    serializer_class = OutpassSerializer

    def get_queryset(self):
        Outpass.mark_overdue_outpasses()

        qs = Outpass.objects.filter(status=Outpass.Status.PENDING).select_related(
            'student__user', 'approved_by__user'
        ).order_by('created_at')
        warden_profile = getattr(self.request.user, 'warden_profile', None)
        if warden_profile and not warden_profile.is_chief_warden and self.request.user.role != UserRole.ADMIN_WARDEN:
            if warden_profile.hostel_name:
                qs = qs.filter(student__hostel_block=warden_profile.hostel_name)
            if warden_profile.assigned_year:
                qs = qs.filter(student__year=warden_profile.assigned_year)
        return qs

    def list(self, request, *args, **kwargs):
        qs = self.filter_queryset(self.get_queryset())
        serializer = self.get_serializer(qs, many=True)
        return success_response(data=serializer.data, message='Pending outpasses retrieved')


class OutpassApprovalView(APIView):
    """Approve or reject an outpass."""
    permission_classes = (permissions.IsAuthenticated, IsAdminOrWarden)

    def post(self, request, pk):
        try:
            outpass = Outpass.objects.get(pk=pk)
        except Outpass.DoesNotExist:
            return error_response('Outpass not found', status_code=404)

        if outpass.status != Outpass.Status.PENDING:
            return error_response('Outpass is not pending')

        serializer = OutpassApprovalSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        action = serializer.validated_data['action']

        warden_profile = getattr(request.user, 'warden_profile', None)

        from apps.notifications.services import NotificationService
        from apps.notifications.models import Notification

        if action == 'approve':
            outpass.status = Outpass.Status.APPROVED
            outpass.approved_by = warden_profile
            outpass.warden_notes = serializer.validated_data.get('warden_notes', '')
            NotificationService.create(
                user=outpass.student.user,
                title='Outpass Approved',
                message='Your outpass request has been approved.',
                event_name='OUTPASS_APPROVED',
                category=Notification.NotificationCategory.OUTPASS,
                notification_type=Notification.NotificationType.OUTPASS_STATUS,
                related_outpass=outpass
            )
        else:
            outpass.status = Outpass.Status.REJECTED
            outpass.approved_by = warden_profile
            outpass.rejection_reason = serializer.validated_data.get('rejection_reason', 'Rejected by warden')
            outpass.warden_notes = serializer.validated_data.get('warden_notes', '')
            NotificationService.create(
                user=outpass.student.user,
                title='Outpass Rejected',
                message=f'Your outpass request was rejected. Reason: {outpass.rejection_reason}',
                event_name='OUTPASS_REJECTED',
                category=Notification.NotificationCategory.OUTPASS,
                notification_type=Notification.NotificationType.OUTPASS_STATUS,
                priority=Notification.NotificationPriority.HIGH,
                related_outpass=outpass
            )

        outpass.save()
        return success_response(
            data=OutpassSerializer(outpass).data,
            message=f'Outpass {action}d successfully',
        )


class OutpassOverrideView(APIView):
    """Force approve/reject (chief warden)."""
    permission_classes = (permissions.IsAuthenticated, IsAdminOrWarden)

    def post(self, request, pk):
        try:
            outpass = Outpass.objects.get(pk=pk)
        except Outpass.DoesNotExist:
            return error_response('Outpass not found', status_code=404)

        serializer = OutpassApprovalSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        action = serializer.validated_data['action']

        warden_profile = getattr(request.user, 'warden_profile', None)
        if action == 'approve':
            outpass.status = Outpass.Status.APPROVED
        else:
            outpass.status = Outpass.Status.REJECTED
            outpass.rejection_reason = serializer.validated_data.get('rejection_reason', 'Override')
        outpass.approved_by = warden_profile
        outpass.warden_notes = f'[OVERRIDE] {serializer.validated_data.get("warden_notes", "")}'
        outpass.save()
        return success_response(data=OutpassSerializer(outpass).data, message=f'Outpass {action}d (override)')


class LateStudentsView(generics.ListAPIView):
    """List students with late returns."""
    permission_classes = (permissions.IsAuthenticated, IsAdminOrWarden)
    serializer_class = OutpassSerializer

    def get_queryset(self):
        Outpass.mark_overdue_outpasses()

        qs = Outpass.objects.filter(status=Outpass.Status.ACTIVE).select_related('student__user')
        warden_profile = getattr(self.request.user, 'warden_profile', None)
        if warden_profile and not warden_profile.is_chief_warden and self.request.user.role != UserRole.ADMIN_WARDEN:
            if warden_profile.hostel_name:
                qs = qs.filter(student__hostel_block=warden_profile.hostel_name)
            if warden_profile.assigned_year:
                qs = qs.filter(student__year=warden_profile.assigned_year)
        # Filter in Python since is_late is a property
        return [op for op in qs if op.is_late]

    def list(self, request, *args, **kwargs):
        late = self.get_queryset()
        serializer = OutpassSerializer(late, many=True)
        return success_response(data=serializer.data, message=f'{len(late)} late student(s)')


class MovementLogListView(generics.ListAPIView):
    """List movement logs."""
    permission_classes = (permissions.IsAuthenticated, IsAdminOrWarden)

    def get(self, request):
        from apps.common.models import MovementLog
        logs = MovementLog.objects.select_related('student__user', 'recorded_by').order_by('-created_at')[:100]
        data = [{
            'id': str(log.id),
            'student': log.student.user.full_name,
            'register_number': log.student.register_number,
            'action': log.action,
            'gate': log.gate,
            'recorded_by': log.recorded_by.full_name if log.recorded_by else None,
            'timestamp': log.created_at,
            'notes': log.notes,
        } for log in logs]
        return success_response(data=data)


class WardenReportsView(APIView):
    """Reports with period=daily|weekly|trend."""
    permission_classes = (permissions.IsAuthenticated, IsAdminOrWarden)

    def get(self, request):
        Outpass.mark_overdue_outpasses()

        period = request.query_params.get('period', 'daily')
        warden_profile = getattr(request.user, 'warden_profile', None)
        today = timezone.now().date()

        outpass_qs = Outpass.objects.all()
        if warden_profile and not warden_profile.is_chief_warden and request.user.role != UserRole.ADMIN_WARDEN:
            if warden_profile.hostel_name:
                outpass_qs = outpass_qs.filter(student__hostel_block=warden_profile.hostel_name)
            if warden_profile.assigned_year:
                outpass_qs = outpass_qs.filter(student__year=warden_profile.assigned_year)

        if period == 'daily':
            filtered = outpass_qs.filter(created_at__date=today)
        elif period == 'weekly':
            week_start = today - timedelta(days=today.weekday())
            filtered = outpass_qs.filter(created_at__date__gte=week_start)
        else:
            filtered = outpass_qs.filter(created_at__date__gte=today - timedelta(days=7))

        status_counts = {}
        for status_val, _ in Outpass.Status.choices:
            status_counts[status_val] = filtered.filter(status=status_val).count()

        late_outpasses = [op for op in filtered if op.is_late]
        late_count = len(late_outpasses)

        approved = status_counts.get('APPROVED', 0) + status_counts.get('ACTIVE', 0) + status_counts.get('RETURNED', 0)
        rejected = status_counts.get('REJECTED', 0)
        decided = approved + rejected
        approval_rate = round((approved / decided * 100), 1) if decided else 0.0

        trend = []
        for i in range(6, -1, -1):
            day = today - timedelta(days=i)
            count = outpass_qs.filter(created_at__date=day).count()
            trend.append({
                'date': str(day),
                'label': day.strftime('%a'),
                'count': count,
            })

        return success_response(data={
            'period': period,
            'status_counts': status_counts,
            'late_count': late_count,
            'approval_rate': approval_rate,
            'trend': trend,
            'total': filtered.count(),
        })


class WardenOutpassHistoryView(generics.ListAPIView):
    """List all outpasses for warden's hostel (history)."""
    permission_classes = (permissions.IsAuthenticated, IsAdminOrWarden)
    serializer_class = OutpassSerializer

    def get_queryset(self):
        Outpass.mark_overdue_outpasses()

        qs = Outpass.objects.select_related(
            'student__user', 'approved_by__user'
        ).order_by('-created_at')
        warden_profile = getattr(self.request.user, 'warden_profile', None)
        if warden_profile and not warden_profile.is_chief_warden and self.request.user.role != UserRole.ADMIN_WARDEN:
            if warden_profile.hostel_name:
                qs = qs.filter(student__hostel_block=warden_profile.hostel_name)
            if warden_profile.assigned_year:
                qs = qs.filter(student__year=warden_profile.assigned_year)
        return qs

    def list(self, request, *args, **kwargs):
        qs = self.filter_queryset(self.get_queryset())
        page = self.paginate_queryset(qs)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        serializer = self.get_serializer(qs, many=True)
        return success_response(data=serializer.data, message='Outpass history retrieved')
