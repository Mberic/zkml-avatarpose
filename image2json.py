import numpy as np
from PIL import Image

def create_ezkl_input(image_path, output_json_path, img_size=192):
    try:
        # Open and convert image to grayscale
        with Image.open(image_path) as img:
            img = img.convert('L')  # Convert to grayscale
            
            # Resize
            img = img.resize((img_size, img_size))
            
            # Convert to numpy array
            img_array = np.array(img, dtype=np.float32) / 255.0
            
            # Duplicate grayscale values for RGB channels
            img_rgb = np.stack([img_array] * 3, axis=-1)
            
            # Create single array of numbers
            flattened = img_rgb.reshape(-1).tolist()
            
            # Create the input structure EZKL expects
            input_data = {
                "input_data": [flattened]  # Single flat array of numbers
            }
            
            print(f"Input length: {len(flattened)}")  # Should be 192*192*3
            
            # Save to file with proper formatting
            import json
            with open(output_json_path, 'w') as f:
                json.dump(input_data, f)
            
            print(f"Created input JSON at {output_json_path}")
            
            # Verify first few values
            print(f"First few values: {flattened[:5]}")
            
    except Exception as e:
        print(f"Error: {str(e)}")
        raise

if __name__ == "__main__":
    image_path = "edges.jpeg"
    output_json_path = "input.json"
    create_ezkl_input(image_path, output_json_path)
