# CurfewCam Backend

Backend service for the CurfewCam Hostel Security and Outpass Management System.

## Tech Stack

- Python
- Django
- Django REST Framework
- PostgreSQL
- JWT Authentication
- Docker
- Redis (Later)
- Celery (Later)

## Project Structure

backend/
├── apps/
├── src/
├── requirements/
├── media/
├── static/
├── tests/

## Developer

Person 4 — Backend

## AI Detection Pipeline (YOLO Dual-Model)

The system uses a fast and accurate dual-model YOLO architecture for person detection:

1. **Stage 1 (Screening): YOLOv8n (Nano)**
   - Runs on every frame in real-time (~0.8ms per frame).
   - If a person is flagged, the frame is passed to the next stage.
2. **Stage 2 (Verification): YOLOv8x (Extra Large)**
   - Only processes frames flagged by Stage 1.
   - Confirms the detection with high accuracy (~5ms) to filter out false positives.

### Configuration
Models are stored in `backend/models/`:
- `yolov8n_best.pt` - 3 Million parameters
- `yolov8x_best.pt` - 68 Million parameters (Currently training/fine-tuning)

Settings inside `src/config/settings/base.py`:
- `YOLO_V8N_MODEL_PATH`
- `YOLO_V8X_MODEL_PATH`
- `YOLO_CONFIDENCE_THRESHOLD` (default: 0.5)

To run detection on an uploaded image, send a POST request to `/api/v1/detection/analyze/` with `image` and `camera_id`.