import os
import requests
import json
import argparse

# Configuration
API_URL = "http://127.0.0.1:8000/api/v1/detection/analyze/"
# Use a known test image from the dataset for testing
DEFAULT_IMAGE = "/home/techpark-6/Music/Dataset/Image2/frame_0000005.jpg" 

def test_analyze_endpoint(image_path, camera_id):
    """Test the dual-YOLO detection endpoint."""
    
    if not os.path.exists(image_path):
        print(f"❌ Error: Image not found at {image_path}")
        print("Please provide a valid image path.")
        return

    print(f"📸 Testing image: {image_path}")
    print(f"📷 Camera ID: {camera_id}")
    print(f"🚀 Sending request to: {API_URL}")
    print("-" * 50)

    try:
        # Prepare the payload
        with open(image_path, 'rb') as img_file:
            files = {'image': img_file}
            data = {'camera_id': camera_id}
            
            # Send POST request
            # Note: Assuming no authentication is required for this specific test,
            # or you might need to add a Bearer token in headers if IsAuthenticated is enforced.
            # headers = {'Authorization': f'Bearer {YOUR_TOKEN}'}
            
            response = requests.post(API_URL, files=files, data=data)
            
        # Parse and display the results
        if response.status_code == 200:
            print("✅ Success! Response (200 OK):")
            result = response.json()
            print(json.dumps(result, indent=2))
            
            if 'data' in result and len(result['data']) > 0:
                print(f"\n🎯 Found {len(result['data'])} person(s)!")
            else:
                print("\n👻 No persons detected in the image.")
                
        elif response.status_code == 401:
            print("❌ Error 401: Unauthorized.")
            print("The endpoint requires a valid JWT token. You may need to modify this script to include an authorization header.")
            
        elif response.status_code == 404:
            print(f"❌ Error 404: Camera ID '{camera_id}' not found.")
            print("Make sure you provide a valid Camera UUID from your database.")
            
        else:
            print(f"❌ Error {response.status_code}:")
            print(response.text)

    except requests.exceptions.ConnectionError:
        print("❌ Connection Error: Could not connect to the Django server.")
        print("Is the server running? Start it with: python manage.py runserver")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Test CurfewCam Detection API")
    parser.add_argument("--image", type=str, default=DEFAULT_IMAGE, help="Path to the test image")
    parser.add_argument("--camera", type=str, required=True, help="UUID of a camera in your database")
    
    args = parser.parse_args()
    
    test_analyze_endpoint(args.image, args.camera)
