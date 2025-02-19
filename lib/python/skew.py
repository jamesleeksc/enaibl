import cv2
import numpy as np
import math
import sys

def compute_skew(filename):
    # Load image in binary
    src = cv2.imread(filename, 0)

    if src is None:
        raise Exception(f"Failed to load image {filename}")

    # Invert the colors (black text on white background)
    src = cv2.bitwise_not(src)

    # Detect lines using the Probabilistic Hough Transform
    lines = cv2.HoughLinesP(src, 1, np.pi / 180, 100, minLineLength=src.shape[1] // 2, maxLineGap=20)

    if lines is None:
        raise Exception("No lines detected")

    # Prepare to display the detected lines
    disp_lines = np.zeros_like(src)
    angle = 0.0
    num_lines = len(lines)

    # Draw lines and calculate the angle for each line
    for line in lines:
        x1, y1, x2, y2 = line[0]
        cv2.line(disp_lines, (x1, y1), (x2, y2), (255, 0, 0), 1)
        angle += math.atan2(y2 - y1, x2 - x1)

    # Compute the average angle
    angle /= num_lines

    # Output the skew angle in degrees
    skew_angle = angle * 180 / np.pi
    return skew_angle

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python skew.py <image_path>")
        sys.exit(1)

    image_path = sys.argv[1]
    skew_angle = compute_skew(image_path)
    print(skew_angle)
