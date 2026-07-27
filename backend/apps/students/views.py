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
    """Verify if student is on campus based strictly on GPS geofencing."""
    permission_classes = (permissions.IsAuthenticated, IsStudent)

    def post(self, request):
        from apps.common.models import Campus
        import math
        try:
            profile = request.user.student_profile
        except StudentProfile.DoesNotExist:
            return error_response('Student profile not found', status_code=404)

        lat = request.data.get('latitude')
        lng = request.data.get('longitude')
        
        if lat is None or lng is None:
            return error_response('Latitude and longitude required', status_code=400)
            
        try:
            lat = float(lat)
            lng = float(lng)
        except ValueError:
            return error_response('Invalid coordinates', status_code=400)

        campus = Campus.objects.first()
        if not campus:
            return error_response('Campus configuration not found', status_code=500)
            
        if campus.campus_latitude is None or campus.campus_longitude is None:
            return error_response('Campus GPS verification not yet configured, contact admin', status_code=400)

        # Haversine distance
        R = 6371000 # Earth radius in meters
        dlat = math.radians(campus.campus_latitude - lat)
        dlng = math.radians(campus.campus_longitude - lng)
        a = (math.sin(dlat / 2) * math.sin(dlat / 2) +
             math.cos(math.radians(lat)) * math.cos(math.radians(campus.campus_latitude)) *
             math.sin(dlng / 2) * math.sin(dlng / 2))
        c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
        distance = R * c

        on_campus = False
        method = 'none'

        if distance <= campus.geofence_radius_meters:
            on_campus = True
            method = 'gps'
        else:
            method = 'gps_failed'

        profile.is_on_campus = on_campus
        profile.save()
        
        # If successfully on campus, we should mark their active outpass as returned
        # and trigger a silent notification to the warden. (Task 5)
        if on_campus:
            from apps.outpass.models import Outpass
            from apps.notifications.services import NotificationService
            from apps.notifications.models import Notification
            from django.utils import timezone
            
            active_outpass = Outpass.objects.filter(student=profile, status=Outpass.Status.ACTIVE).first()
            if active_outpass:
                active_outpass.status = Outpass.Status.RETURNED
                active_outpass.actual_return_time = timezone.now()
                active_outpass.auto_detect_method = Outpass.AutoDetectMethod.GPS
                active_outpass.save(update_fields=['status', 'actual_return_time', 'auto_detect_method'])
                
                # Notify warden (Task 5)
                # Find wardens for this student
                from apps.wardens.models import WardenProfile
                from django.db.models import Q
                
                wardens = WardenProfile.objects.filter(
                    Q(is_chief_warden=True) |
                    (Q(hostel_name=profile.hostel_block) &
                     (Q(assigned_year__isnull=True) | Q(assigned_year=profile.year)))
                )
                
                for warden in wardens:
                    NotificationService.create(
                        user=warden.user,
                        title=f'Student Returned (GPS): {profile.user.full_name}',
                        message=f'{profile.user.full_name} ({profile.register_number}) has checked in on campus via GPS verification.',
                        event_name='OUTPASS_RETURNED_WARDEN',
                        category=Notification.NotificationCategory.OUTPASS,
                        notification_type=Notification.NotificationType.OUTPASS_STATUS,
                        priority=Notification.NotificationPriority.NORMAL,
                        related_outpass=active_outpass,
                    )

        return success_response(
            data={'on_campus': on_campus, 'method': method, 'distance_meters': distance},
            message='Location verified on campus' if on_campus else f'Not on campus (Distance: {distance:.0f}m)'
        )