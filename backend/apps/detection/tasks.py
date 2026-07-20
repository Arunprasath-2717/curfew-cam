"""Detection background tasks."""
from celery import shared_task
import logging

logger = logging.getLogger(__name__)

@shared_task
def process_detection_async(detection_id):
    """Process a detection in the background."""
    from .models import Detection
    from .services import process_detection
    
    try:
        detection = Detection.objects.get(id=detection_id)
        process_detection(detection)
    except Detection.DoesNotExist:
        logger.error(f"Detection {detection_id} not found for processing")

@shared_task
def run_yolo_detection_async(image_path, camera_id):
    """Run dual-YOLO inference in the background."""
    from apps.camera.models import Camera
    from .services import run_yolo_detection
    
    try:
        camera = Camera.objects.get(id=camera_id)
        # We don't save the image_file directly here since it's just a path string
        # A more robust system would save the image to media first, then pass the relative path
        run_yolo_detection(image_path, camera)
    except Camera.DoesNotExist:
        logger.error(f"Camera {camera_id} not found")
    except Exception as e:
        logger.error(f"YOLO task failed: {e}")
