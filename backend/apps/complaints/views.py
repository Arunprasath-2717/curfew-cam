from rest_framework import generics, permissions, status
from rest_framework.views import APIView
from rest_framework.response import Response
from django.db.models import Count
from apps.common.responses import success_response, error_response, paginated_response
from .models import Complaint, ComplaintStatus, ComplaintCategory
from .serializers import (
    ComplaintSerializer,
    ComplaintCreateSerializer,
    ComplaintStatusUpdateSerializer
)


class IsWardenUser(permissions.BasePermission):
    """Permission class for Wardens and Admins."""
    def has_permission(self, request, view):
        return (
            request.user.is_authenticated and
            request.user.role in ['warden', 'admin_warden', 'admin']
        )


class ComplaintListCreateView(generics.ListCreateAPIView):
    """List complaints (filtered by role/queries) and allow students to create complaints."""
    permission_classes = (permissions.IsAuthenticated,)

    def get_serializer_class(self):
        if self.request.method == 'POST':
            return ComplaintCreateSerializer
        return ComplaintSerializer

    def get_queryset(self):
        user = self.request.user
        queryset = Complaint.objects.select_related('student', 'student__student_profile', 'assigned_warden').all()

        if user.role == 'student':
            queryset = queryset.filter(student=user)
        elif getattr(user, 'role', '') != 'admin_warden':
            warden_profile = getattr(user, 'warden_profile', None)
            if warden_profile and not warden_profile.is_chief_warden:
                queryset = queryset.filter(student__student_profile__hostel_block=warden_profile.hostel_name)

        # Filters for wardens
        status_param = self.request.query_params.get('status')
        category_param = self.request.query_params.get('category')
        priority_param = self.request.query_params.get('priority')
        search_param = self.request.query_params.get('search')

        if status_param:
            queryset = queryset.filter(status=status_param)
        if category_param:
            queryset = queryset.filter(category=category_param)
        if priority_param:
            queryset = queryset.filter(priority=priority_param)
        if search_param:
            queryset = queryset.filter(title__icontains=search_param) | queryset.filter(description__icontains=search_param)

        return queryset

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        complaint = serializer.save(student=request.user)
        return success_response(
            data=ComplaintSerializer(complaint).data,
            message="Complaint logged successfully.",
            status_code=status.HTTP_201_CREATED
        )

    def list(self, request, *args, **kwargs):
        queryset = self.filter_queryset(self.get_queryset())
        if self.paginator:
            return paginated_response(self.paginator, ComplaintSerializer, queryset, request)
        serializer = ComplaintSerializer(queryset, many=True)
        return success_response(data=serializer.data)


class ComplaintDetailView(generics.RetrieveAPIView):
    """Get single complaint detail."""
    permission_classes = (permissions.IsAuthenticated,)
    serializer_class = ComplaintSerializer
    queryset = Complaint.objects.all()

    def retrieve(self, request, *args, **kwargs):
        instance = self.get_object()
        # Ensure student can only view their own complaint unless user is warden
        if request.user.role == 'student' and instance.student != request.user:
            return error_response("You do not have permission to view this complaint.", status_code=403)
        elif getattr(request.user, 'role', '') != 'admin_warden' and request.user.role != 'student':
            warden_profile = getattr(request.user, 'warden_profile', None)
            if warden_profile and not warden_profile.is_chief_warden:
                if not hasattr(instance.student, 'student_profile') or instance.student.student_profile.hostel_block != warden_profile.hostel_name:
                    return error_response("Complaint is not from your hostel block.", status_code=403)

        serializer = self.get_serializer(instance)
        return success_response(data=serializer.data)


class ComplaintStatusUpdateView(generics.UpdateAPIView):
    """Warden updates complaint status & adds response/feedback."""
    permission_classes = (IsWardenUser,)
    serializer_class = ComplaintStatusUpdateSerializer
    queryset = Complaint.objects.all()

    def update(self, request, *args, **kwargs):
        partial = kwargs.pop('partial', True)
        instance = self.get_object()

        user = request.user
        if getattr(user, 'role', '') != 'admin_warden':
            warden_profile = getattr(user, 'warden_profile', None)
            if warden_profile and not warden_profile.is_chief_warden:
                if not hasattr(instance.student, 'student_profile') or instance.student.student_profile.hostel_block != warden_profile.hostel_name:
                    return error_response("Complaint is not from your hostel block.", status_code=403)

        serializer = self.get_serializer(instance, data=request.data, partial=partial, context={'request': request})
        serializer.is_valid(raise_exception=True)
        updated = serializer.save()
        return success_response(
            data=ComplaintSerializer(updated).data,
            message="Complaint status updated successfully."
        )


class ComplaintStatsView(APIView):
    """Logged data statistics overview for Warden."""
    permission_classes = (IsWardenUser,)

    def get(self, request):
        qs = Complaint.objects.all()
        user = request.user
        if getattr(user, 'role', '') != 'admin_warden':
            warden_profile = getattr(user, 'warden_profile', None)
            if warden_profile and not warden_profile.is_chief_warden:
                qs = qs.filter(student__student_profile__hostel_block=warden_profile.hostel_name)
                
        total = qs.count()
        pending = qs.filter(status=ComplaintStatus.PENDING).count()
        in_progress = qs.filter(status=ComplaintStatus.IN_PROGRESS).count()
        resolved = qs.filter(status=ComplaintStatus.RESOLVED).count()
        rejected = qs.filter(status=ComplaintStatus.REJECTED).count()

        category_counts = {}
        category_data = qs.values('category').annotate(count=Count('category'))
        for item in category_data:
            cat_key = item['category']
            category_counts[cat_key] = item['count']

        data = {
            'total_complaints': total,
            'pending_count': pending,
            'in_progress_count': in_progress,
            'resolved_count': resolved,
            'rejected_count': rejected,
            'category_breakdown': category_counts,
        }
        return success_response(data=data)
