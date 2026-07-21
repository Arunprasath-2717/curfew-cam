"""Watchman views — shift, dashboard, QR scan, logs."""
from rest_framework import generics, permissions
from rest_framework.views import APIView
from django.utils import timezone
from django.db.models import Count

from apps.common.responses import success_response, error_response, created_response
from apps.accounts.permissions import IsWatchman, IsWardenOrWatchman
from apps.qr.models import QRPass
from apps.qr.services import validate_qr_token, generate_qr_for_outpass
from apps.outpass.models import Outpass
from apps.outpass.serializers import OutpassSerializer
from apps.students.models import StudentProfile
from apps.common.models import MovementLog
from .models import WatchmanProfile, ShiftLog, GateScan
from .serializers import (
    WatchmanProfileSerializer, ShiftLogSerializer,
    GateScanSerializer, QRScanRequestSerializer,
)


class WatchmanDashboardView(APIView):
    """Watchman dashboard — today's stats."""
    permission_classes = (permissions.IsAuthenticated, IsWardenOrWatchman)

    def get(self, request):
        today = timezone.now().date()
        profile = getattr(request.user, 'watchman_profile', None)
        scans_today = GateScan.objects.filter(created_at__date=today)
        if profile:
            scans_today = scans_today.filter(watchman=profile)

        stats = {
            'total_scans_today': scans_today.count(),
            'exits_today': scans_today.filter(scan_type='EXIT').count(),
            'returns_today': scans_today.filter(scan_type='RETURN').count(),
            'active_outpasses': Outpass.objects.filter(status=Outpass.Status.ACTIVE).count(),
            'is_on_duty': profile.is_on_duty if profile else False,
        }
        return success_response(data=stats)


class ShiftStartView(APIView):
    """Start a new shift."""
    permission_classes = (permissions.IsAuthenticated, IsWatchman)

    def post(self, request):
        profile = request.user.watchman_profile
        if profile.is_on_duty:
            return error_response('Already on duty. End current shift first.')
        shift = ShiftLog.objects.create(
            watchman=profile,
            shift_start=timezone.now(),
            gate=request.data.get('gate', profile.assigned_gate),
        )
        profile.is_on_duty = True
        profile.save()
        return created_response(data=ShiftLogSerializer(shift).data, message='Shift started')


class ShiftEndView(APIView):
    """End current shift."""
    permission_classes = (permissions.IsAuthenticated, IsWatchman)

    def post(self, request):
        profile = request.user.watchman_profile
        if not profile.is_on_duty:
            return error_response('Not currently on duty')
        shift = ShiftLog.objects.filter(
            watchman=profile, shift_end__isnull=True
        ).order_by('-shift_start').first()
        if shift:
            shift.shift_end = timezone.now()
            shift.notes = request.data.get('notes', '')
            shift.save()
        profile.is_on_duty = False
        profile.save()
        return success_response(message='Shift ended')


class QRScanView(APIView):
    """Scan QR code at gate (exit or return)."""
    permission_classes = (permissions.IsAuthenticated, IsWatchman)

    def post(self, request):
        serializer = QRScanRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        token = serializer.validated_data['qr_token']
        scan_type = serializer.validated_data['scan_type']
        gate = serializer.validated_data.get('gate', '')
        profile = request.user.watchman_profile

        # Validate QR
        valid, result = validate_qr_token(token)
        if not valid:
            return error_response(result)

        qr_pass = result  # On success, result is the QRPass object
        outpass = qr_pass.outpass

        # Business logic
        if scan_type == 'EXIT':
            if outpass.status != Outpass.Status.APPROVED:
                return error_response('Outpass is not approved for exit')
            outpass.status = Outpass.Status.ACTIVE
            outpass.actual_exit_time = timezone.now()
            outpass.save()
            outpass.student.is_in_hostel = False
            outpass.student.save()
            qr_pass.is_used = True
            qr_pass.save()
        elif scan_type == 'RETURN':
            if outpass.status != Outpass.Status.ACTIVE:
                return error_response('Outpass is not active for return')
            outpass.status = Outpass.Status.RETURNED
            outpass.actual_return_time = timezone.now()
            outpass.auto_detect_method = 'manual_scan'
            outpass.save()
            outpass.student.is_in_hostel = True
            outpass.student.save()
            qr_pass.is_used = True
            qr_pass.save()

        # Record scan
        scan = GateScan.objects.create(
            qr_pass=qr_pass,
            watchman=profile,
            scan_type=scan_type,
            gate=gate or profile.assigned_gate,
        )

        # Movement log
        MovementLog.objects.create(
            student=outpass.student,
            action=scan_type,
            gate=gate or profile.assigned_gate,
            recorded_by=request.user,
        )

        return success_response(
            data=GateScanSerializer(scan).data,
            message=f'{scan_type} recorded for {outpass.student.user.full_name}',
        )


class ScanLogsView(generics.ListAPIView):
    """List scan logs."""
    permission_classes = (permissions.IsAuthenticated, IsWardenOrWatchman)
    serializer_class = GateScanSerializer

    def get_queryset(self):
        qs = GateScan.objects.select_related('qr_pass__outpass__student__user', 'watchman__user')
        profile = getattr(self.request.user, 'watchman_profile', None)
        if profile:
            qs = qs.filter(watchman=profile)
        return qs.order_by('-created_at')[:200]


class ScanStatsView(APIView):
    """Scan statistics."""
    permission_classes = (permissions.IsAuthenticated, IsWardenOrWatchman)

    def get(self, request):
        today = timezone.now().date()
        week_ago = today - timezone.timedelta(days=7)
        scans = GateScan.objects.filter(created_at__date__gte=week_ago)
        daily = scans.values('created_at__date').annotate(
            count=Count('id')
        ).order_by('created_at__date')
        return success_response(data={
            'daily_scans': list(daily),
            'total_week': scans.count(),
        })


def _apply_scan(outpass, qr_pass, scan_type, profile, gate, user):
    """Shared exit/return logic for QR and manual verification."""
    if scan_type == 'EXIT':
        if outpass.status != Outpass.Status.APPROVED:
            return False, 'Outpass is not approved for exit'
        outpass.status = Outpass.Status.ACTIVE
        outpass.actual_exit_time = timezone.now()
        outpass.save()
        outpass.student.is_in_hostel = False
        outpass.student.save()
        qr_pass.is_used = True
        qr_pass.save()
    elif scan_type == 'RETURN':
        if outpass.status != Outpass.Status.ACTIVE:
            return False, 'Outpass is not active for return'
        outpass.status = Outpass.Status.RETURNED
        outpass.actual_return_time = timezone.now()
        outpass.auto_detect_method = 'manual_scan'
        outpass.save()
        outpass.student.is_in_hostel = True
        outpass.student.save()
        qr_pass.is_used = True
        qr_pass.save()

    scan = GateScan.objects.create(
        qr_pass=qr_pass,
        watchman=profile,
        scan_type=scan_type,
        gate=gate or profile.assigned_gate,
    )
    MovementLog.objects.create(
        student=outpass.student,
        action=scan_type,
        gate=gate or profile.assigned_gate,
        recorded_by=user,
    )
    return True, scan


class ManualVerifyView(APIView):
    """Manual verification by register number."""
    permission_classes = (permissions.IsAuthenticated, IsWatchman)

    def post(self, request):
        register_number = request.data.get('register_number', '').strip()
        scan_type = request.data.get('scan_type', 'EXIT')
        if not register_number:
            return error_response('register_number is required')
        if scan_type not in ('EXIT', 'RETURN'):
            return error_response('scan_type must be EXIT or RETURN')

        profile = request.user.watchman_profile
        try:
            student = StudentProfile.objects.select_related('user').get(
                register_number=register_number
            )
        except StudentProfile.DoesNotExist:
            return error_response('Student not found', status_code=404)

        if scan_type == 'EXIT':
            outpass = Outpass.objects.filter(
                student=student, status=Outpass.Status.APPROVED
            ).order_by('-created_at').first()
        else:
            outpass = Outpass.objects.filter(
                student=student, status=Outpass.Status.ACTIVE
            ).order_by('-created_at').first()

        if not outpass:
            return error_response(f'No matching outpass for {scan_type}')

        if hasattr(outpass, 'qr_pass'):
            qr_pass = outpass.qr_pass
        else:
            qr_pass = generate_qr_for_outpass(outpass)

        ok, result = _apply_scan(
            outpass, qr_pass, scan_type, profile,
            request.data.get('gate', ''), request.user,
        )
        if not ok:
            return error_response(result)

        return success_response(
            data={
                'scan': GateScanSerializer(result).data,
                'student_name': student.user.full_name,
                'outpass': str(outpass.id),
                'scan_type': scan_type,
            },
            message=f'{scan_type} recorded for {student.user.full_name}',
        )


class ActivePassesView(APIView):
    """Active outpasses — reuses same data as OutsideStudentsView."""
    permission_classes = (permissions.IsAuthenticated, IsWardenOrWatchman)

    def get(self, request):
        qs = Outpass.objects.filter(
            status=Outpass.Status.ACTIVE
        ).select_related('student__user').order_by('-actual_exit_time')
        
        from apps.accounts.models import UserRole
        warden_profile = getattr(request.user, 'warden_profile', None)
        if warden_profile and not warden_profile.is_chief_warden and request.user.role != UserRole.ADMIN_WARDEN:
            if warden_profile.hostel_name:
                qs = qs.filter(student__hostel_block=warden_profile.hostel_name)
            if warden_profile.assigned_year:
                qs = qs.filter(student__year=warden_profile.assigned_year)
                
        return success_response(data=OutpassSerializer(qs, many=True).data)


class OverdueStudentsView(APIView):
    """Active outpasses where student is late."""
    permission_classes = (permissions.IsAuthenticated, IsWardenOrWatchman)

    def get(self, request):
        qs = Outpass.objects.filter(
            status=Outpass.Status.ACTIVE
        ).select_related('student__user')
        
        from apps.accounts.models import UserRole
        warden_profile = getattr(request.user, 'warden_profile', None)
        if warden_profile and not warden_profile.is_chief_warden and request.user.role != UserRole.ADMIN_WARDEN:
            if warden_profile.hostel_name:
                qs = qs.filter(student__hostel_block=warden_profile.hostel_name)
            if warden_profile.assigned_year:
                qs = qs.filter(student__year=warden_profile.assigned_year)
                
        late = [op for op in qs if op.is_late]
        return success_response(data=OutpassSerializer(late, many=True).data)


class ShiftSummaryView(APIView):
    """Current watchman's open shift summary."""
    permission_classes = (permissions.IsAuthenticated, IsWatchman)

    def get(self, request):
        profile = request.user.watchman_profile
        shift = ShiftLog.objects.filter(
            watchman=profile, shift_end__isnull=True
        ).order_by('-shift_start').first()

        if not shift:
            return success_response(data={
                'on_duty': False,
                'shift_start': None,
                'total_scans': 0,
                'exits': 0,
                'returns': 0,
            })

        scans = GateScan.objects.filter(
            watchman=profile, created_at__gte=shift.shift_start
        )
        return success_response(data={
            'on_duty': True,
            'shift_start': shift.shift_start,
            'gate': shift.gate,
            'total_scans': scans.count(),
            'exits': scans.filter(scan_type='EXIT').count(),
            'returns': scans.filter(scan_type='RETURN').count(),
        })
