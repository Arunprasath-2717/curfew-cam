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

import math

def haversine(lat1, lon1, lat2, lon2):
    """Calculate the great circle distance between two points on the earth."""
    R = 6371000  # radius of Earth in meters
    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    delta_phi = math.radians(lat2 - lat1)
    delta_lambda = math.radians(lon2 - lon1)

    a = math.sin(delta_phi / 2.0) ** 2 + \
        math.cos(phi1) * math.cos(phi2) * \
        math.sin(delta_lambda / 2.0) ** 2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return R * c

class VerifyLocationView(APIView):
    """Verify if student is on campus based on WiFi SSID or GPS."""
    permission_classes = (permissions.IsAuthenticated, IsStudent)

    def post(self, request):
        from apps.common.models import Campus
        try:
            profile = request.user.student_profile
        except StudentProfile.DoesNotExist:
            return error_response('Student profile not found', status_code=404)

        wifi_ssid = request.data.get('wifi_ssid', '').strip('\"\'')
        latitude = request.data.get('latitude')
        longitude = request.data.get('longitude')

        campus = Campus.objects.first()
        if not campus:
            return error_response('Campus configuration not found', status_code=500)

        on_campus = False
        method = 'none'

        if campus.campus_wifi_ssid and wifi_ssid == campus.campus_wifi_ssid:
            on_campus = True
            method = 'wifi'
        elif latitude is not None and longitude is not None and campus.campus_latitude and campus.campus_longitude:
            try:
                distance = haversine(
                    float(latitude), float(longitude),
                    campus.campus_latitude, campus.campus_longitude
                )
                if distance <= campus.geofence_radius_meters:
                    on_campus = True
                    method = 'gps'
            except (ValueError, TypeError):
                pass

        if not on_campus:
            method = 'both_failed'

        profile.is_on_campus = on_campus
        profile.save()

        return success_response(
            data={'on_campus': on_campus, 'method': method},
            message='Location verified on campus' if on_campus else 'Not on campus'
        )