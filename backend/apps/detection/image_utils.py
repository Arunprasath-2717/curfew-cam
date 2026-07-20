import cv2
import numpy as np

# MOG2 Motion Gate
_mog2 = cv2.createBackgroundSubtractorMOG2(
    history=200, varThreshold=50, detectShadows=False
)

def has_motion(frame: np.ndarray, threshold: int = 800) -> bool:
    """
    Returns True if enough foreground pixels are detected.
    Used to skip running heavy YOLO inference on static frames.
    """
    if threshold <= 0:
        return True
    mask = _mog2.apply(frame)
    return int(np.sum(mask > 200)) >= threshold

# CLAHE Night Enhancement
# Clip limit 3.0 and TileGrid 8x8 are good defaults for night enhancement
_clahe = cv2.createCLAHE(clipLimit=3.0, tileGridSize=(8, 8))

def enhance_night(frame: np.ndarray) -> np.ndarray:
    """
    Converts BGR → LAB, applies CLAHE to the L (luminance) channel,
    and converts back. This lifts dark/night frames without blowing out highlights.
    """
    lab = cv2.cvtColor(frame, cv2.COLOR_BGR2LAB)
    l, a, b = cv2.split(lab)
    l_eq = _clahe.apply(l)
    return cv2.cvtColor(cv2.merge([l_eq, a, b]), cv2.COLOR_LAB2BGR)
