"""Student views."""
from rest_framework import generics, permissions, status
from rest_framework.views import APIView
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework.filters import SearchFilter, OrderingFilter
from django.db.models import Q

from apps.common.responses import success_response, created_response, error_response
from apps.accounts.permissions import IsStudent, IsAdminOrWarden, IsOwnerOrAdmin
from apps.outpass.models import Outpass
from .models import StudentProfile, Guardian
from .serializers import (
    StudentProfileSerializer, StudentProfileCreateSerializer,
    StudentProfileUpdateSerializer, GuardianSerializer,
)


class StudentProfileCreateView(APIView):
    """Create student profile (student only, once)."""
    permission_classes = (permissions.IsAuthenticated, IsStudent)

    def post(self, request):
        if hasattr(request.user, 'student_profile'):
            return error_response('Profile already exists', status_code=status.HTTP_409_CONFLICT)
        serializer = StudentProfileCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        profile = serializer.save(user=request.user)
        return created_response(
            data=StudentProfileSerializer(profile).data,
            message='Student profile created',
        )


class StudentProfileDetailView(APIView):
    """Get / update own student profile."""
    permission_classes = (permissions.IsAuthenticated,)

    def get(self, request):
        try:
            profile = request.user.student_profile
        except StudentProfile.DoesNotExist:
            return error_response('Profile not found', status_code=status.HTTP_404_NOT_FOUND)
        return success_response(data=StudentProfileSerializer(profile).data)

    def patch(self, request):
        try:
            profile = request.user.student_profile
        except StudentProfile.DoesNotExist:
            return error_response('Profile not found', status_code=status.HTTP_404_NOT_FOUND)
        serializer = StudentProfileUpdateSerializer(profile, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return success_response(data=StudentProfileSerializer(profile).data, message='Profile updated')


class StudentListView(generics.ListAPIView):
    """List students (warden/admin only)."""
    permission_classes = (permissions.IsAuthenticated, IsAdminOrWarden)
    serializer_class = StudentProfileSerializer
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_fields = ['department', 'year', 'hostel_block', 'is_in_hostel']
    search_fields = ['user__first_name', 'user__last_name', 'register_number']
    ordering_fields = ['created_at', 'register_number']

    def get_queryset(self):
        qs = StudentProfile.objects.select_related('user').prefetch_related('guardians')
        if self.request.user.role == 'warden' and hasattr(self.request.user, 'warden_profile'):
            qs = qs.filter(hostel_block=self.request.user.warden_profile.hostel_name)
        return qs


class StudentDetailByIdView(generics.RetrieveAPIView):
    """Get a student by ID (warden/admin)."""
    permission_classes = (permissions.IsAuthenticated, IsAdminOrWarden)
    serializer_class = StudentProfileSerializer
    queryset = StudentProfile.objects.select_related('user').prefetch_related('guardians')
    lookup_field = 'pk'


class GuardianCreateView(APIView):
    """Add guardian to student profile."""
    permission_classes = (permissions.IsAuthenticated, IsStudent)

    def post(self, request):
        try:
            profile = request.user.student_profile
        except StudentProfile.DoesNotExist:
            return error_response('Create student profile first', status_code=status.HTTP_404_NOT_FOUND)
        serializer = GuardianSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        serializer.save(student=profile)
        return created_response(data=serializer.data, message='Guardian added')


class GuardianListView(APIView):
    """List guardians of current student."""
    permission_classes = (permissions.IsAuthenticated,)

    def get(self, request):
        try:
            profile = request.user.student_profile
        except StudentProfile.DoesNotExist:
            return error_response('Profile not found', status_code=status.HTTP_404_NOT_FOUND)
        guardians = profile.guardians.all()
        return success_response(data=GuardianSerializer(guardians, many=True).data)


class StudentSearchView(APIView):
    """Search students by name or register number."""
    permission_classes = (permissions.IsAuthenticated, IsAdminOrWarden)

    def get(self, request):
        q = request.query_params.get('q', '').strip()
        if not q:
            return success_response(data=[])

        qs = StudentProfile.objects.select_related('user').filter(
            Q(user__first_name__icontains=q)
            | Q(user__last_name__icontains=q)
            | Q(register_number__icontains=q)
        )
        if request.user.role == 'warden' and hasattr(request.user, 'warden_profile'):
            qs = qs.filter(hostel_block=request.user.warden_profile.hostel_name)
        qs = qs[:20]
        return success_response(data=StudentProfileSerializer(qs, many=True).data)


class StudentViolationsView(APIView):
    """Student violation records (rejected + late returns)."""
    permission_classes = (permissions.IsAuthenticated, IsAdminOrWarden)

    def get(self, request, pk):
        try:
            student = StudentProfile.objects.select_related('user').get(pk=pk)
        except StudentProfile.DoesNotExist:
            return error_response('Student not found', status_code=404)

        warden_profile = getattr(request.user, 'warden_profile', None)
        if warden_profile and student.hostel_block != warden_profile.hostel_name:
            return error_response('Student not in your hostel block', status_code=403)

        rejected = Outpass.objects.filter(student=student, status=Outpass.Status.REJECTED)
        late = [
            op for op in Outpass.objects.filter(
                student=student,
                status__in=[Outpass.Status.RETURNED, Outpass.Status.ACTIVE],
            ) if op.is_late
        ]
        from apps.outpass.serializers import OutpassSerializer
        violations = list(rejected) + late
        return success_response(data=OutpassSerializer(violations, many=True).data)


class VerifyLocationView(APIView):
    """Verify if student is on campus based strictly on WiFi SSID."""
    permission_classes = (permissions.IsAuthenticated, IsStudent)

    def post(self, request):
        from apps.common.models import Campus
        try:
            profile = request.user.student_profile
        except StudentProfile.DoesNotExist:
            return error_response('Student profile not found', status_code=404)

        wifi_ssid = request.data.get('wifi_ssid', '').strip('\"\'')

        campus = Campus.objects.first()
        if not campus:
            return error_response('Campus configuration not found', status_code=500)
            
        if not campus.campus_wifi_ssid:
            return error_response('WiFi verification not yet configured, contact admin', status_code=400)

        on_campus = False
        method = 'none'

        if wifi_ssid == campus.campus_wifi_ssid:
            on_campus = True
            method = 'wifi'
        else:
            method = 'wifi_failed'

        profile.is_on_campus = on_campus
        profile.save()
        
        # If successfully on campus, we should mark their active outpass as returned
        # and trigger a silent notification to the warden. (Task 2)
        if on_campus:
            from apps.outpass.models import Outpass
            from apps.notifications.services import NotificationService
            from apps.notifications.models import Notification
            from django.utils import timezone
            
            active_outpass = Outpass.objects.filter(student=profile, status=Outpass.Status.ACTIVE).first()
            if active_outpass:
                active_outpass.status = Outpass.Status.RETURNED
                active_outpass.actual_return_time = timezone.now()
                active_outpass.auto_detect_method = Outpass.AutoDetectMethod.WIFI
                active_outpass.save(update_fields=['status', 'actual_return_time', 'auto_detect_method'])
                
                # Notify warden
                if active_outpass.approved_by:
                    NotificationService.create(
                        user=active_outpass.approved_by.user,
                        title=f'Student Returned: {profile.user.full_name}',
                        message=f'{profile.user.full_name} ({profile.register_number}) has checked in on campus via WiFi verification.',
                        event_name='OUTPASS_RETURNED_WARDEN',
                        category=Notification.NotificationCategory.OUTPASS,
                        notification_type=Notification.NotificationType.OUTPASS_STATUS,
                        priority=Notification.NotificationPriority.NORMAL,
                        related_outpass=active_outpass,
                    )

        return success_response(
            data={'on_campus': on_campus, 'method': method},
            message='Location verified on campus' if on_campus else 'Not on campus'
        )