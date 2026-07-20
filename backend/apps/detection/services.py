"""Detection services."""
import logging
from django.core.files import File
from .models import Detection, Alert

logger = logging.getLogger(__name__)

def run_yolo_detection(image_path, camera, image_file=None):
    """
    Run YOLO on an image and create detection records.
    """
    # YOLO is an optional, heavyweight runtime dependency. Import it only for
    # image-analysis requests so its absence cannot prevent unrelated API
    # endpoints (including login) from starting.
    from .yolo_engine import engine

    detections = engine.detect(image_path)
    
    created_detections = []
    for det in detections:
        # Create a Detection record for each person found
        detection_obj = Detection.objects.create(
            camera=camera,
            detection_type=Detection.DetectionType.PERSON,
            confidence=det['confidence'],
            bounding_box=det['bbox'],
            metadata={'source': 'yolo_dual_pipeline'}
        )
        
        # Save image file to detection if provided
        if image_file:
            # We assume image_file is a Django File object
            detection_obj.image = image_file
            detection_obj.save()
            
        created_detections.append(detection_obj)
        
        # Process curfew checks, alerts, etc.
        process_detection(detection_obj)
        
    return created_detections


def process_detection(detection):
    """Business logic to handle a new detection."""
    # Placeholder for actual processing logic
    
    # E.g. Check for suspicious activity and generate alert
    if detection.detection_type == Detection.DetectionType.SUSPICIOUS:
        create_alert_from_detection(
            detection, 
            title="Suspicious Activity Detected", 
            message=f"Camera {detection.camera.name} detected suspicious activity with {detection.confidence*100:.1f}% confidence.",
            level=Alert.AlertLevel.CRITICAL
        )
    
    # E.g. Person detected at gate out of hours
    elif detection.detection_type == Detection.DetectionType.PERSON:
        # Check current time against curfew hours
        import datetime
        from django.utils import timezone
        
        now = timezone.localtime(timezone.now()).time()
        curfew_start = datetime.time(22, 0) # 10 PM
        curfew_end = datetime.time(5, 0)   # 5 AM
        
        is_curfew = False
        if curfew_start <= now or now <= curfew_end:
            is_curfew = True
            
        if is_curfew:
            create_alert_from_detection(
                detection,
                title="Curfew Violation",
                message=f"Person detected at {detection.camera.name} during curfew hours.",
                level=Alert.AlertLevel.WARNING
            )
            
    return True


def create_alert_from_detection(detection, title, message, level=Alert.AlertLevel.WARNING):
    """Create an alert from a detection."""
    alert = Alert.objects.create(
        detection=detection,
        title=title,
        message=message,
        level=level
    )
    logger.info("Alert created: %s", alert.title)
    
    # Trigger notification
    from apps.notifications.services import notify_admins_of_alert
    notify_admins_of_alert(alert)
    
    return alert
