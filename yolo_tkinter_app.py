import tkinter as tk
from tkinter import filedialog, messagebox
import cv2
from PIL import Image, ImageTk
from ultralytics import YOLO
import threading

class YoloApp:
    def __init__(self, root, window_title="YOLO Video Inference"):
        self.root = root
        self.root.title(window_title)
        
        # Load YOLO model
        self.model_path = '/home/techpark-6/Music/curfewcam/backend/models/yolov8n_best.pt'
        try:
            self.model = YOLO(self.model_path)
            print(f"Loaded model from {self.model_path}")
        except Exception as e:
            messagebox.showerror("Model Error", f"Failed to load YOLO model: {e}")
            self.root.destroy()
            return
            
        self.video_source = None
        self.vid = None
        self.is_playing = False
        
        # Create UI elements
        self.top_frame = tk.Frame(root)
        self.top_frame.pack(pady=10)
        
        self.btn_upload = tk.Button(self.top_frame, text="Upload Video", width=15, command=self.upload_video)
        self.btn_upload.pack(side=tk.LEFT, padx=5)
        
        self.btn_stop = tk.Button(self.top_frame, text="Stop", width=10, command=self.stop_video, state=tk.DISABLED)
        self.btn_stop.pack(side=tk.LEFT, padx=5)
        
        self.canvas = tk.Canvas(root, width=640, height=480, bg='black')
        self.canvas.pack(pady=10)
        
        self.delay = 15 # ms delay for updating video frames

    def upload_video(self):
        file_path = filedialog.askopenfilename(
            title="Select Video File",
            filetypes=(("MP4 files", "*.mp4"), ("AVI files", "*.avi"), ("All files", "*.*"))
        )
        if file_path:
            self.video_source = file_path
            self.start_video()

    def start_video(self):
        if self.vid is not None:
            self.vid.release()
            
        self.vid = cv2.VideoCapture(self.video_source)
        if not self.vid.isOpened():
            messagebox.showerror("Error", "Could not open video file.")
            return
            
        self.is_playing = True
        self.btn_upload.config(state=tk.DISABLED)
        self.btn_stop.config(state=tk.NORMAL)
        
        # Start a thread to process and update frames to avoid freezing the GUI
        self.thread = threading.Thread(target=self.update, daemon=True)
        self.thread.start()

    def update(self):
        while self.is_playing and self.vid.isOpened():
            ret, frame = self.vid.read()
            if ret:
                # Run YOLO inference
                results = self.model(frame, verbose=False)
                
                # Annotate the frame with bounding boxes
                annotated_frame = results[0].plot()
                
                # Resize frame to fit canvas if necessary
                canvas_width = 640
                canvas_height = 480
                annotated_frame = cv2.resize(annotated_frame, (canvas_width, canvas_height))
                
                # Convert frame for Tkinter
                annotated_frame = cv2.cvtColor(annotated_frame, cv2.COLOR_BGR2RGB)
                self.photo = ImageTk.PhotoImage(image=Image.fromarray(annotated_frame))
                
                # Update canvas in the main thread
                self.root.after(0, self._update_canvas, self.photo)
                
                # Sleep a bit to match normal playback speed (approximate)
                cv2.waitKey(self.delay)
            else:
                self.is_playing = False
                break
                
        # Clean up when done
        self.root.after(0, self.stop_video)
        
    def _update_canvas(self, photo):
        self.canvas.create_image(0, 0, image=photo, anchor=tk.NW)

    def stop_video(self):
        self.is_playing = False
        if self.vid is not None:
            self.vid.release()
        self.canvas.delete("all")
        self.btn_upload.config(state=tk.NORMAL)
        self.btn_stop.config(state=tk.DISABLED)

    def on_closing(self):
        self.is_playing = False
        if self.vid is not None:
            self.vid.release()
        self.root.destroy()

if __name__ == '__main__':
    root = tk.Tk()
    app = YoloApp(root)
    root.protocol("WM_DELETE_WINDOW", app.on_closing)
    root.mainloop()
