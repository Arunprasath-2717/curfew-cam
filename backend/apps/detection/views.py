"""Detection views."""
from rest_framework import generics, permissions
from rest_framework.views import APIView
from django_filters.rest_framework import DjangoFilterBackend
from django.utils import timezone

from apps.common.responses import success_response, created_response, error_response
from apps.accounts.permissions import IsAdminOrWarden
from .models import Detection, Alert
from .serializers import DetectionSerializer, DetectionCreateSerializer, AlertSerializer
from .services import process_detection, run_yolo_detection
import tempfile
from apps.camera.models import Camera


from django.conf import settings

class IsEdgeDevice(permissions.BasePermission):
    def has_permission(self, request, view):
        token = request.headers.get('X-Edge-Token')
        expected_token = getattr(settings, 'EDGE_DEVICE_TOKEN', 'fallback-edge-secret-123')
        return bool(token and token == expected_token)

class DetectionWebhookView(APIView):
    """Receive detection results from edge device / YOLO script."""
    permission_classes = (IsEdgeDevice,)

    def post(self, request):
        serializer = DetectionCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        # We can save it here, or process it first
        detection = serializer.save()
        
        # Trigger background task or synchronous processing
        process_detection(detection)
        
        return created_response(data=DetectionSerializer(detection).data, message='Detection recorded')


class DetectionListView(generics.ListAPIView):
    """List detections (admin/warden)."""
    permission_classes = (permissions.IsAuthenticated, IsAdminOrWarden)
    serializer_class = DetectionSerializer
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['detection_type', 'camera']
    queryset = Detection.objects.all().select_related('camera', 'matched_student__user')


class AlertListView(generics.ListAPIView):
    """List alerts."""
    permission_classes = (permissions.IsAuthenticated, IsAdminOrWarden)
    serializer_class = AlertSerializer
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['level', 'status']
    queryset = Alert.objects.all().order_by('-created_at')


class AlertAcknowledgeView(APIView):
    """Acknowledge an alert."""
    permission_classes = (permissions.IsAuthenticated, IsAdminOrWarden)

    def post(self, request, pk):
        try:
            alert = Alert.objects.get(pk=pk)
        except Alert.DoesNotExist:
            return error_response('Alert not found', status_code=404)

        if alert.status == Alert.AlertStatus.ACKNOWLEDGED:
            return error_response('Alert already acknowledged')

        alert.status = Alert.AlertStatus.ACKNOWLEDGED
        alert.acknowledged_by = request.user
        alert.acknowledged_at = timezone.now()
        alert.save()

        return success_response(data=AlertSerializer(alert).data, message='Alert acknowledged')

class DetectionAnalyzeView(APIView):
    """Upload an image to run YOLO inference and record detections."""
    permission_classes = (IsEdgeDevice,)

    def post(self, request):
        if 'image' not in request.FILES:
            return error_response('No image provided', status_code=400)
            
        camera_id = request.data.get('camera_id')
        if not camera_id:
            return error_response('camera_id is required', status_code=400)
            
        try:
            camera = Camera.objects.get(id=camera_id)
        except Camera.DoesNotExist:
            return error_response('Camera not found', status_code=404)
            
        image_file = request.FILES['image']
        
        # Save uploaded file temporarily to pass to YOLO
        with tempfile.NamedTemporaryFile(delete=False, suffix='.jpg') as tmp:
            for chunk in image_file.chunks():
                tmp.write(chunk)
            tmp_path = tmp.name
            
        try:
            # Re-read file pointer for django models
            image_file.seek(0)
            detections = run_yolo_detection(tmp_path, camera, image_file)
            
            return success_response(
                data=DetectionSerializer(detections, many=True).data,
                message=f'Found {len(detections)} persons'
            )
        finally:
            import os
            if os.path.exists(tmp_path):
                os.remove(tmp_path)


class DetectionStreamControlView(APIView):
    """Start or stop the backend YOLO stream."""
    permission_classes = (permissions.IsAuthenticated, IsAdminOrWarden)

    def post(self, request, action):
        from .yolo_engine import engine
        
        if action == 'start':
            engine.start_stream()
            return success_response(message='Detection stream started.')
        elif action == 'stop':
            engine.stop_stream()
            return success_response(message='Detection stream stopped.')
        else:
            return error_response('Invalid action. Use start or stop.', status_code=400)

