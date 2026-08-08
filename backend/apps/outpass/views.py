"""Outpass views."""
from rest_framework import generics, permissions, status
from rest_framework.views import APIView
from django.utils import timezone
from django_filters.rest_framework import DjangoFilterBackend
from django.db import transaction
from django.db.models import Q

from apps.common.responses import success_response, created_response, error_response
from apps.accounts.permissions import IsStudent, IsAdminOrWarden
from apps.accounts.models import UserRole
from .models import Outpass
from .serializers import OutpassCreateSerializer, OutpassSerializer


class OutpassRequestView(APIView):
    """Student requests a new outpass."""
    permission_classes = (permissions.IsAuthenticated, IsStudent)

    def post(self, request):
        if not hasattr(request.user, 'student_profile'):
            return error_response('Create student profile first', status_code=status.HTTP_400_BAD_REQUEST)

        # Check for existing active/pending outpass
        existing = Outpass.objects.filter(
            student=request.user.student_profile,
            status__in=[Outpass.Status.PENDING, Outpass.Status.APPROVED, Outpass.Status.ACTIVE],
        ).exists()
        if existing:
            return error_response('You already have an active or pending outpass')

        serializer = OutpassCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        outpass = serializer.save(student=request.user.student_profile)

        # Notify relevant warden(s) — wrapped in try/except so a notification
        # failure never breaks outpass creation.
        try:
            from apps.notifications.services import NotificationService
            from apps.notifications.models import Notification
            from apps.accounts.models import User, UserRole

            wardens = User.objects.filter(
                role=UserRole.WARDEN,
                is_active=True,
                warden_profile__hostel_name=outpass.student.hostel_block,
            )

            if not wardens.exists():
                # Hostel block string didn't match any warden's hostel_name exactly;
                # fall back to ALL active wardens so the request is never missed.
                wardens = User.objects.filter(role=UserRole.WARDEN, is_active=True)
                import logging
                logger = logging.getLogger(__name__)
                logger.warning(f"No exact hostel match found for {outpass.student.hostel_block}. Falling back to all active wardens.")

            for warden in wardens:
                NotificationService.create(
                    user=warden,
                    title='New Outpass Request',
                    message=f'{outpass.student.user.full_name} has requested an outpass to {outpass.destination}.',
                    event_name='NEW_OUTPASS_REQUEST',
                    category=Notification.NotificationCategory.OUTPASS,
                    notification_type=Notification.NotificationType.OUTPASS_STATUS,
                    related_outpass=outpass
                )
        except Exception:
            # Don't let notification failure break outpass creation
            pass

        return created_response(data=OutpassSerializer(outpass).data, message='Outpass requested')


class OutpassHistoryView(generics.ListAPIView):
    """Student: list own outpass history."""
    permission_classes = (permissions.IsAuthenticated, IsStudent)
    serializer_class = OutpassSerializer
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['status', 'outpass_type']

    def get_queryset(self):
        if hasattr(self.request.user, 'student_profile'):
            qs = Outpass.objects.filter(
                student=self.request.user.student_profile
            ).order_by('-created_at')
            Outpass.mark_overdue_outpasses(qs)
            return qs
        return Outpass.objects.none()


class OutpassCurrentView(APIView):
    """Get student's current active outpass."""
    permission_classes = (permissions.IsAuthenticated, IsStudent)

    def get(self, request):
        if not hasattr(request.user, 'student_profile'):
            return error_response('No student profile', status_code=status.HTTP_404_NOT_FOUND)
        qs = Outpass.objects.filter(
            student=request.user.student_profile,
            status__in=[Outpass.Status.PENDING, Outpass.Status.APPROVED, Outpass.Status.ACTIVE],
        )
        Outpass.mark_overdue_outpasses(qs)
        outpass = qs.first()
        if not outpass:
            return success_response(data=None, message='No active outpass')
        return success_response(data=OutpassSerializer(outpass).data)


class OutpassCancelView(APIView):
    """Student cancels pending outpass."""
    permission_classes = (permissions.IsAuthenticated, IsStudent)

    def post(self, request, pk):
        try:
            outpass = Outpass.objects.get(pk=pk, student=request.user.student_profile)
        except Outpass.DoesNotExist:
            return error_response('Outpass not found', status_code=status.HTTP_404_NOT_FOUND)
        if outpass.status != Outpass.Status.PENDING:
            return error_response('Only pending outpasses can be cancelled')
        outpass.status = Outpass.Status.CANCELLED
        outpass.save()
        return success_response(data=OutpassSerializer(outpass).data, message='Outpass cancelled')


class OutpassReturnView(APIView):
    """Mark outpass as returned."""
    permission_classes = (permissions.IsAuthenticated,)

    def post(self, request, pk):
        try:
            outpass = Outpass.objects.get(pk=pk)
        except Outpass.DoesNotExist:
            return error_response('Outpass not found', status_code=status.HTTP_404_NOT_FOUND)

        user = request.user
        if getattr(user, 'role', '') == UserRole.STUDENT:
            if not hasattr(user, 'student_profile') or outpass.student != user.student_profile:
                return error_response('Permission denied', status_code=status.HTTP_403_FORBIDDEN)
        elif getattr(user, 'role', '') != 'watchman':
            return error_response('Only the student or a watchman can return an outpass', status_code=status.HTTP_403_FORBIDDEN)

        if outpass.status != Outpass.Status.ACTIVE:
            return error_response('Outpass is not active')
            
        method = request.data.get('auto_detect_method', 'manual_scan')
        outpass.status = Outpass.Status.RETURNED
        outpass.actual_return_time = timezone.now()
        outpass.auto_detect_method = method
        outpass.save()
        
        # Update student hostel status
        outpass.student.is_in_hostel = True
        outpass.student.save()
        
        import logging
        logger = logging.getLogger(__name__)
        logger.info(f"Outpass {outpass.id} returned via {method}.")
        
        return success_response(data=OutpassSerializer(outpass).data, message='Return recorded')


class OutpassDetailView(APIView):
    """Get outpass detail by ID."""
    permission_classes = (permissions.IsAuthenticated,)

    def get(self, request, pk):
        try:
            qs = Outpass.objects.select_related(
                'student__user', 'approved_by__user'
            ).filter(pk=pk)
            Outpass.mark_overdue_outpasses(qs)
            outpass = qs.get()
        except Outpass.DoesNotExist:
            return error_response('Outpass not found', status_code=404)

        user = request.user
        student_profile = getattr(user, 'student_profile', None)
        warden_profile = getattr(user, 'warden_profile', None)

        if user.role == 'admin' or user.role == UserRole.ADMIN_WARDEN:
            return success_response(data=OutpassSerializer(outpass).data)

        if student_profile:
            if outpass.student_id != student_profile.id:
                return error_response('Permission denied', status_code=403)
            return success_response(data=OutpassSerializer(outpass).data)

        if warden_profile:
            if outpass.student.hostel_block != warden_profile.hostel_name:
                return error_response('Outpass not in your hostel block', status_code=403)
            return success_response(data=OutpassSerializer(outpass).data)

        return error_response('Permission denied', status_code=403)


class BulkApproveView(APIView):
    """Bulk approve pending outpasses."""
    permission_classes = (permissions.IsAuthenticated, IsAdminOrWarden)

    def post(self, request):
        outpass_ids = request.data.get('outpass_ids', [])
        if not outpass_ids:
            return error_response('outpass_ids list is required')

        warden_profile = getattr(request.user, 'warden_profile', None)
        approved = []
        failed = []

        with transaction.atomic():
            for oid in outpass_ids:
                try:
                    outpass = Outpass.objects.select_for_update().get(pk=oid)
                    if outpass.status != Outpass.Status.PENDING:
                        failed.append({'id': str(oid), 'reason': 'Not pending'})
                        continue
                    if warden_profile and request.user.role != UserRole.ADMIN_WARDEN:
                        if outpass.student.hostel_block != warden_profile.hostel_name:
                            failed.append({'id': str(oid), 'reason': 'Wrong hostel block'})
                            continue
                    outpass.status = Outpass.Status.APPROVED
                    outpass.approved_by = warden_profile
                    outpass.save()
                    approved.append(str(oid))
                except Outpass.DoesNotExist:
                    failed.append({'id': str(oid), 'reason': 'Not found'})

        return success_response(
            data={'approved': approved, 'failed': failed},
            message=f'{len(approved)} approved, {len(failed)} failed',
        )


class OutsideStudentsView(APIView):
    """List all active (outside) outpasses."""
    permission_classes = (permissions.IsAuthenticated, IsAdminOrWarden)

    def get(self, request):
        qs = Outpass.objects.filter(
            status=Outpass.Status.ACTIVE
        ).select_related('student__user', 'approved_by__user').order_by('-actual_exit_time')
        warden_profile = getattr(request.user, 'warden_profile', None)
        if warden_profile and request.user.role != UserRole.ADMIN_WARDEN:
            qs = qs.filter(student__hostel_block=warden_profile.hostel_name)
        serializer = OutpassSerializer(qs, many=True)
        return success_response(data=serializer.data)
