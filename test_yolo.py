from ultralytics import YOLO

def test_model():
    model_path = '/home/techpark-6/Music/curfewcam/backend/models/yolov8n_best.pt'
    image_path = '/home/techpark-6/Music/Dataset/Image2/132.png'
    
    print(f"Loading model from {model_path}...")
    model = YOLO(model_path)
    
    print(f"Running inference on {image_path}...")
    results = model(image_path)
    
    print("\n--- Detection Results ---")
    for r in results:
        boxes = r.boxes
        print(f"Found {len(boxes)} object(s).")
        for box in boxes:
            # get box coordinates in (top, left, bottom, right) format
            b = box.xyxy[0].tolist()
            c = box.cls.item()
            conf = box.conf.item()
            name = model.names[int(c)]
            print(f"Class: {name}, Confidence: {conf:.2f}, Box: [x1: {b[0]:.1f}, y1: {b[1]:.1f}, x2: {b[2]:.1f}, y2: {b[3]:.1f}]")
    
if __name__ == '__main__':
    test_model()
