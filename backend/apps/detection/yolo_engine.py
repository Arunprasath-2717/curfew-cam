"""YOLO dual-model batched inference engine for CurfewCam."""
import os
import logging
import time
import threading
from django.conf import settings

logger = logging.getLogger(__name__)

class YoloEngine:
    """Singleton engine for batched YOLO inference to avoid reloading models."""
    _instance = None
    
    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(YoloEngine, cls).__new__(cls)
            cls._instance.model_n = None
            cls._instance.model_x = None
            cls._instance.is_running = False
        return cls._instance

    def initialize(self):
        """Load the YOLO models."""
        from ultralytics import YOLO
        
        if self.model_n is None and hasattr(settings, 'YOLO_V8N_MODEL_PATH') and os.path.exists(settings.YOLO_V8N_MODEL_PATH):
            logger.info(f"Loading YOLOv8n from {settings.YOLO_V8N_MODEL_PATH}")
            self.model_n = YOLO(settings.YOLO_V8N_MODEL_PATH)
        
        if self.model_x is None and hasattr(settings, 'YOLO_V8X_MODEL_PATH') and os.path.exists(settings.YOLO_V8X_MODEL_PATH):
            logger.info(f"Loading YOLOv8x from {settings.YOLO_V8X_MODEL_PATH}")
            self.model_x = YOLO(settings.YOLO_V8X_MODEL_PATH)

    def detect_batch(self, frames, frame_ids=None):
        """
        Run two-stage batched inference on a list of frames.
        Returns a list of dicts: {frame_id, detected, confidence, bbox}
        """
        if not frames:
            return []
            
        if self.model_n is None:
            self.initialize()
            
        if self.model_n is None:
            logger.error("YOLOv8n model could not be loaded.")
            return []

        if frame_ids is None:
            frame_ids = list(range(len(frames)))

        device = getattr(settings, 'YOLO_DEVICE', 0)
        
        # Apply night enhancement
        from .image_utils import enhance_night
        processed_frames = [enhance_night(f) for f in frames]
        
        start_time = time.time()
        
        # Stage 1: YOLOv8n screening (low conf, wide net)
        results_n = self.model_n.predict(
            source=processed_frames,
            conf=0.25,
            device=device,
            verbose=False,
            classes=[0] # person
        )
        
        stage2_frames = []
        stage2_indices = []
        final_results = []
        
        # Initialize output
        for frame_id in frame_ids:
            final_results.append({
                'frame_id': frame_id,
                'detected': False,
                'confidence': 0.0,
                'bbox': None
            })
            
        # Collect frames flagged in Stage 1
        for i, r in enumerate(results_n):
            if len(r.boxes) > 0:
                stage2_frames.append(processed_frames[i])
                stage2_indices.append(i)
                
        flagged_count = len(stage2_frames)
        
        # Stage 2: YOLOv8x verification (higher conf)
        if stage2_frames and self.model_x is not None:
            results_x = self.model_x.predict(
                source=stage2_frames,
                conf=0.5,
                device=device,
                verbose=False,
                classes=[0]
            )
            
            for j, r in enumerate(results_x):
                original_idx = stage2_indices[j]
                
                best_conf = 0.0
                best_bbox = None
                has_detection = False
                
                for box in r.boxes:
                    cls_id = int(box.cls[0].item())
                    if cls_id == 0:
                        conf = float(box.conf[0].item())
                        if conf > best_conf:
                            best_conf = conf
                            best_bbox = box.xywh.tolist()[0]
                            has_detection = True
                            
                if has_detection:
                    final_results[original_idx]['detected'] = True
                    final_results[original_idx]['confidence'] = best_conf
                    final_results[original_idx]['bbox'] = best_bbox

        inference_time = time.time() - start_time
        logger.info(f"Batch processed: {len(frames)} frames. Flagged by Stage1: {flagged_count}. Time: {inference_time:.2f}s")
        
        return final_results

    def start_stream(self, video_source=None):
        if self.is_running:
            logger.info("Detection stream is already running.")
            return
        
        self.is_running = True
        logger.info("Starting YOLO detection pipeline in background...")
        threading.Thread(target=self.process_stream, args=(video_source,), daemon=True).start()
        
    def stop_stream(self):
        if not self.is_running:
            logger.info("Detection stream is already stopped.")
            return
            
        logger.info("Stopping YOLO detection pipeline...")
        self.is_running = False

    def process_stream(self, video_source=None):
        """
        Process a live video stream in batches, buffering frames and running inference 
        without blocking the capture loop.
        """
        import cv2
        
        # Use settings if available, fallback to video_source
        stream_url = getattr(settings, 'DETECTION_CAMERA_URL', video_source)
        
        cap = cv2.VideoCapture(stream_url)
        if not cap.isOpened():
            logger.error(f"Could not connect to camera stream at {stream_url}")
            self.is_running = False
            return

        batch_size = getattr(settings, 'YOLO_BATCH_SIZE', 8)
        
        frame_buffer = []
        frame_id_buffer = []
        frame_count = 0
        
        try:
            while self.is_running:
                ret, frame = cap.read()
                if not ret:
                    break
                    
                frame_buffer.append(frame)
                frame_id_buffer.append(frame_count)
                frame_count += 1
                
                if len(frame_buffer) >= batch_size:
                    # Dispatch to a thread so we don't block capture
                    batch = list(frame_buffer)
                    ids = list(frame_id_buffer)
                    threading.Thread(target=self.detect_batch, args=(batch, ids)).start()
                    
                    frame_buffer.clear()
                    frame_id_buffer.clear()
                    
            if frame_buffer:
                self.detect_batch(frame_buffer, frame_id_buffer)
                
        finally:
            cap.release()
            logger.info("Detection stream stopped and camera released.")

    def detect(self, image_path, conf_threshold=None):
        """
        Legacy single-image compatibility.
        """
        import cv2
        frame = cv2.imread(image_path)
        if frame is None:
            logger.error(f"Could not read image at {image_path}")
            return []
            
        results = self.detect_batch([frame], [image_path])
        
        legacy_results = []
        if results and results[0]['detected']:
            legacy_results.append({
                'class_name': 'person',
                'confidence': results[0]['confidence'],
                'bbox': results[0]['bbox']
            })
            
        return legacy_results

engine = YoloEngine()
