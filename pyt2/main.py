import json
import uuid
import numpy as np
import cv2
from paddleocr import PaddleOCR
from fastapi import FastAPI, HTTPException, Response
from pydantic import BaseModel
from typing import List
import base64
import requests
import logging
import uvicorn

logging.basicConfig(
    level=logging.INFO
)  # You can change the level to DEBUG for more detailed logs
logger = logging.getLogger("uvicorn")

app = FastAPI()
ocr = PaddleOCR(use_angle_cls=True, lang="tr")


# Pydantic models for request validation
class Point(BaseModel):
    x: int
    y: int


class ScanRequest(BaseModel):
    image: str
    points: List[Point]


class LllmRequest(BaseModel):
    receiptContent: str
    points: List[Point]


def load_config(file_path):
    with open(file_path) as config_file:
        return json.load(config_file)


def generate_content(api_key, user_input, sys_instruction):
    url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key={api_key}"

    headers = {"Content-Type": "application/json"}

    data = {
        "contents": [{"role": "user", "parts": [{"text": user_input}]}],
        "systemInstruction": {"role": "user", "parts": [{"text": sys_instruction}]},
        "generationConfig": {
            "temperature": 1,
            "topK": 40,
            "topP": 0.95,
            "maxOutputTokens": 8192,
            "responseMimeType": "text/plain",
        },
    }

    response = requests.post(url, headers=headers, data=json.dumps(data))

    if response.status_code == 200:
        return response.text
    else:
        return {"error": response.status_code, "message": response.text}


# Load configuration
config = load_config("config.json")
API_KEY = config[0]["api_key"]
config2 = load_config("config2.json")
config3 = load_config("config3.json")


system_instruction = config[1]["System Instruction"]
system_instruction2 = config2[1]["System Instruction"]
system_instruction3 = config3[1]["System Instruction"]


def check_image_quality(image):

    gray = image
    quality_issues = 0
    issues_detected = []

    # 1. Check brightness
    mean_brightness = np.mean(gray)
    if mean_brightness < 25 or mean_brightness > 230:
        quality_issues += 1
        issues_detected.append(f"Brightness issue: {mean_brightness}")

    # 2. Check contrast
    contrast = gray.std()
    if contrast < 15:
        quality_issues += 1
        issues_detected.append(f"Contrast issue: {contrast}")

    # 3. Check blur level
    laplacian_var = cv2.Laplacian(gray, cv2.CV_64F).var()
    if laplacian_var < 50:
        quality_issues += 1
        issues_detected.append(f"Blur issue: {laplacian_var}")

    # 4. Check noise level
    noise_level = np.std(gray)
    if noise_level > 85:
        quality_issues += 1
        issues_detected.append(f"Noise issue: {noise_level}")

    # 5. Check for extreme dark or light regions
    dark_pixels = np.sum(gray < 30) / gray.size
    light_pixels = np.sum(gray > 225) / gray.size
    if dark_pixels > 0.4 or light_pixels > 0.4:
        quality_issues += 1
        issues_detected.append(
            f"Extreme dark/light regions: Dark={dark_pixels:.2f}, Light={light_pixels:.2f}"
        )

    # Print detected issues
    if quality_issues >= 2:
        print("Multiple quality issues detected:")
        for issue in issues_detected:
            print(f"- {issue}")

    # Return True only if at least 2 quality issues are detected
    return quality_issues >= 2


def preprocess_image(image):
    """Adjusted preprocessing steps for less aggressive image enhancement."""

    # Adjust contrast using CLAHE with less aggressive parameters
    clahe = cv2.createCLAHE(clipLimit=1.5, tileGridSize=(8, 8))
    contrast_enhanced = clahe.apply(image)

    denoised = cv2.fastNlMeansDenoising(contrast_enhanced, None, h=5)

    thresh = cv2.adaptiveThreshold(
        denoised,
        255,
        cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
        cv2.THRESH_BINARY,
        15,  # Smaller block size for more localized thresholding
        7,  # Lower constant for less aggressive adjustment
    )

    # Use smaller kernel for dilation and erosion
    kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (1, 1))
    dilated = cv2.dilate(thresh, kernel, iterations=1)

    kernel_erode = cv2.getStructuringElement(cv2.MORPH_RECT, (1, 1))
    cleaned = cv2.erode(dilated, kernel_erode, iterations=1)

    # Skip skew correction if angle adjustment is unnecessary
    return cleaned


def normalize_ocr_output(result):
    """Clean and normalize OCR output for better usability."""
    normalized_result = []
    for line in result:
        for text, _ in line:  # line is a tuple where the first element is text
            # Remove unnecessary whitespace and special characters
            if isinstance(text, str):  # Ensure text is a string
                cleaned_text = text.strip()
                cleaned_text = "".join(
                    e for e in cleaned_text if e.isalnum() or e.isspace()
                )
                normalized_result.append(cleaned_text)
    return "\n".join(normalized_result)


def process_image(base64_image, points):
    image_id = uuid.uuid4()
    image_data = base64.b64decode(base64_image)
    image_array = np.frombuffer(image_data, np.uint8)
    image = cv2.imdecode(image_array, cv2.IMREAD_COLOR)
    # cv2.imwrite(f"base64img/{image_id}.png", image)
    image = np.array(image)

    src_points = np.array(points, dtype="float32")
    height, width = image.shape[:2]
    dst_points = np.array(
        [[0, 0], [width, 0], [width, height], [0, height]], dtype="float32"
    )

    matrix = cv2.getPerspectiveTransform(src_points, dst_points)
    transformed_image = cv2.warpPerspective(image, matrix, (width, height))

    processed_img = cv2.cvtColor(transformed_image, cv2.COLOR_BGR2GRAY)

    if check_image_quality(processed_img):
        logger.info("-------------------")
        logger.info("Ek ön işleme yapıldı")
        logger.info("-------------------")

        processed_img = preprocess_image(processed_img)

    # cv2.imwrite(f"transformed/{image_id}.png", processed_img)
    # cv2.imwrite(f"static/{image_id}.png", processed_img)
    result = ocr.ocr(processed_img, cls=False)

    result = generate_content(API_KEY, str(result), system_instruction)

    try:
        llm_data = json.loads(result)
        result = llm_data["candidates"][0]["content"]["parts"][0]["text"]

        jsresult = result[result.find("{") : result.rfind("}") + 1]

        # logger.info("-------------------")
        # logger.info(jsresult)
        # logger.info("-------------------")

        # logger.info(f"Result from full: 1111{result}111")  # Log the result

        return jsresult

    except (json.JSONDecodeError, KeyError, IndexError) as e:
        print(f"Error parsing LLM response: {e}")
        result = "Error"


def cleanJson(llm_result):
    try:
        llm_data = json.loads(llm_result)
        result = llm_data["candidates"][0]["content"]["parts"][0]["text"]

        return result[result.find("{") : result.rfind("}") + 1]

    except (json.JSONDecodeError, KeyError, IndexError) as e:
        print(f"Error parsing LLM response: {e}")
        return "Error"


@app.post("/api/v1/scan")
async def scan_paddleocr(request: ScanRequest):
    try:
        base64_image = request.image
        points = np.array(
            [[point.x, point.y] for point in request.points], dtype=np.int32
        )
        points = points.reshape((4, 2))

        result = process_image(base64_image, points)

        # Yanıtı yazdır
        response_content = result.encode("utf-8").decode("utf-8")
        logger.info("-------------------")
        logger.info(response_content)
        logger.info("-------------------")
        # logger.info(f"Result from processing: {result}")  # Log the result
        # print(f"Response content: {response_content.decode('utf-8')}")

        return Response(
            content=response_content, media_type="text/plain", status_code=200
        )

    except Exception as e:
        print(f"Error: {e}")
        raise HTTPException(status_code=400, detail="Failed to process the request")


@app.post("/api/v2/scan")
async def scan_mlkit(request: LllmRequest):
    try:
        content_text = request.receiptContent
        points = np.array(
            [[point.x, point.y] for point in request.points], dtype=np.int32
        )
        points = points.reshape((4, 2))

        print(content_text)

        llm_result = generate_content(API_KEY, content_text, system_instruction2)

        print("--------------------d")
        print(llm_result)

        result = cleanJson(llm_result)

        return Response(
            content=result.encode("utf-8"), media_type="text/plain", status_code=200
        )

    except Exception as e:
        print(f"Error: {e}")
        raise HTTPException(status_code=400, detail="Failed to process the request")


def generate_content_with_image(api_key, base64_image, sys_instruction):
    url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key={api_key}"

    headers = {"Content-Type": "application/json"}

    # Prepare the image data
    image_data = {"mime_type": "image/png", "data": base64_image}

    # Prepare the request payload
    data = {
        "contents": [
            {
                "role": "user",
                "parts": [{"text": sys_instruction}, {"inline_data": image_data}],
            }
        ],
        "generationConfig": {
            "temperature": 0.4,
            "topK": 32,
            "topP": 1,
            "maxOutputTokens": 4096,
        },
    }

    response = requests.post(url, headers=headers, json=data)

    if response.status_code == 200:
        response_json = response.json()
        # Gemini API'den gelen yanıtı uygun formata dönüştür
        formatted_response = {
            "candidates": [
                {
                    "content": {
                        "parts": [
                            {
                                "text": response_json["candidates"][0]["content"][
                                    "parts"
                                ][0]["text"]
                            }
                        ]
                    }
                }
            ]
        }
        return json.dumps(formatted_response)
    else:
        raise Exception(f"API Error: {response.status_code} - {response.text}")


@app.post("/api/v3/scan")
async def scan_gemini_with_image(request: ScanRequest):
    try:
        base64_image = request.image
        points = np.array(
            [[point.x, point.y] for point in request.points], dtype=np.int32
        )
        points = points.reshape((4, 2))

        try:
            # Get the response from Gemini
            llm_result = generate_content_with_image(
                API_KEY, base64_image, system_instruction3
            )

            # Use the existing cleanJson function to process the response
            result = cleanJson(llm_result)

            if result == "Error":
                raise HTTPException(
                    status_code=500, detail="Error processing the image"
                )

            return Response(
                content=result.encode("utf-8"), media_type="text/plain", status_code=200
            )

        except Exception as e:
            logger.error(f"Processing error: {str(e)}")
            raise HTTPException(status_code=500, detail=str(e))

    except Exception as e:
        logger.error(f"Request error: {str(e)}")
        raise HTTPException(status_code=400, detail="Failed to process the request")


if __name__ == "__main__":

    uvicorn.run(app, host="0.0.0.0", port=8000)
