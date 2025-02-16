import cv2

def detect_edges(input_path, output_path, low_threshold=50, high_threshold=150):
    # Load the image in grayscale
    image = cv2.imread(input_path, cv2.IMREAD_GRAYSCALE)

    if image is None:
        print(f"Error: Could not load image {input_path}")
        return
    
    # Apply Canny edge detection
    edges = cv2.Canny(image, low_threshold, high_threshold)

    # Save the output image
    cv2.imwrite(output_path, edges)
    print(f"Edge-detected image saved as {output_path}")

if __name__ == "__main__":
    input_path = "resized.jpeg"
    output_path = "edges.jpeg"
    detect_edges(input_path, output_path)
