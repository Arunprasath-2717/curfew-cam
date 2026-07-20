"""Camera views — CRUD, health, status."""
from rest_framework import generics, permissions
from rest_framework.views import APIView
from django.utils import timezone

from apps.common.responses import success_response, error_response, created_response
from apps.accounts.permissions import IsAdmin, IsAdminOrWarden
from .models import Camera
from .serializers import CameraSerializer, CameraCreateSerializer


class CameraListCreateView(generics.ListCreateAPIView):
    """List/Create cameras (admin)."""
    permission_classes = (permissions.IsAuthenticated, IsAdminOrWarden)
    queryset = Camera.objects.all()

    def get_serializer_class(self):
        if self.request.method == 'POST':
            return CameraCreateSerializer
        return CameraSerializer

    def create(self, request, *args, **kwargs):
        serializer = CameraCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        camera = serializer.save()
        return created_response(data=CameraSerializer(camera).data, message='Camera added')


class CameraDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Get/Update/Delete camera."""
    permission_classes = (permissions.IsAuthenticated, IsAdminOrWarden)
    queryset = Camera.objects.all()
    serializer_class = CameraSerializer
    lookup_field = 'pk'


class CameraHealthCheckView(APIView):
    """Check camera health / update status."""
    permission_classes = (permissions.IsAuthenticated, IsAdminOrWarden)

    def post(self, request, pk):
        try:
            camera = Camera.objects.get(pk=pk)
        except Camera.DoesNotExist:
            return error_response('Camera not found', status_code=404)

        # In production, you'd ping the RTSP URL or IP here
        new_status = request.data.get('status', Camera.CameraStatus.ONLINE)
        camera.status = new_status
        camera.last_health_check = timezone.now()
        camera.save()
        return success_response(data=CameraSerializer(camera).data, message='Health check updated')


class CameraStatusView(APIView):
    """Get all camera statuses."""
    permission_classes = (permissions.IsAuthenticated, IsAdminOrWarden)

    def get(self, request):
        cameras = Camera.objects.values('id', 'name', 'location', 'status', 'is_active', 'last_health_check')
        return success_response(data=list(cameras))
