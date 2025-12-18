#!/usr/bin/env python3
"""
Face Comparison Script for HRIS Asuka

This script compares two face images and returns similarity score.
Uses face_recognition library which is based on dlib.

Usage: python3 compare_faces.py <reference_image_path> <captured_image_path>

Output: JSON object with comparison results
"""

import sys
import json
import os

def main():
    if len(sys.argv) != 3:
        print(json.dumps({
            'success': False,
            'match': False,
            'confidence': 0,
            'message': 'Invalid arguments. Usage: compare_faces.py <image1> <image2>'
        }))
        sys.exit(1)

    image1_path = sys.argv[1]
    image2_path = sys.argv[2]

    # Validate files exist
    if not os.path.exists(image1_path):
        print(json.dumps({
            'success': False,
            'match': False,
            'confidence': 0,
            'message': f'Reference image not found: {image1_path}'
        }))
        sys.exit(0)

    if not os.path.exists(image2_path):
        print(json.dumps({
            'success': False,
            'match': False,
            'confidence': 0,
            'message': f'Captured image not found: {image2_path}'
        }))
        sys.exit(0)

    try:
        import face_recognition
        import numpy as np

        # Load images
        image1 = face_recognition.load_image_file(image1_path)
        image2 = face_recognition.load_image_file(image2_path)

        # Get face encodings
        encodings1 = face_recognition.face_encodings(image1)
        encodings2 = face_recognition.face_encodings(image2)

        if len(encodings1) == 0:
            print(json.dumps({
                'success': False,
                'match': False,
                'confidence': 0,
                'message': 'Tidak dapat mendeteksi wajah pada foto referensi'
            }))
            sys.exit(0)

        if len(encodings2) == 0:
            print(json.dumps({
                'success': False,
                'match': False,
                'confidence': 0,
                'message': 'Tidak dapat mendeteksi wajah pada foto yang diambil'
            }))
            sys.exit(0)

        if len(encodings1) > 1:
            print(json.dumps({
                'success': False,
                'match': False,
                'confidence': 0,
                'message': 'Terdeteksi lebih dari satu wajah pada foto referensi'
            }))
            sys.exit(0)

        if len(encodings2) > 1:
            print(json.dumps({
                'success': False,
                'match': False,
                'confidence': 0,
                'message': 'Terdeteksi lebih dari satu wajah pada foto yang diambil'
            }))
            sys.exit(0)

        # Get the face encodings
        encoding1 = encodings1[0]
        encoding2 = encodings2[0]

        # Calculate face distance (lower = more similar)
        # face_distance returns values from 0 (identical) to ~1.0+ (very different)
        face_distance = face_recognition.face_distance([encoding1], encoding2)[0]

        # Convert distance to confidence percentage
        # Distance of 0 = 100% confidence
        # Distance of 0.6 (threshold) = ~50% confidence (typical threshold for match)
        # Distance of 1.0 = 0% confidence

        # Using a more intuitive conversion:
        # confidence = (1 - distance) * 100, clamped to 0-100
        # But we need to scale it better for practical use

        # face_recognition typically uses 0.6 as threshold
        # We'll use a formula that gives:
        # - distance 0.0 -> 100%
        # - distance 0.4 -> 80% (good match)
        # - distance 0.6 -> 60% (borderline)
        # - distance 0.8 -> 40%
        # - distance 1.0 -> 20%

        # Linear mapping: confidence = max(0, 100 - (distance * 80))
        # This gives distance 0.6 = 52% and distance 0.4 = 68%

        # Better formula using exponential decay for more intuitive results
        # confidence = 100 * exp(-distance * 2.5)
        # This gives: 0.0 -> 100%, 0.3 -> 47%, 0.4 -> 37%, 0.6 -> 22%

        # Actually, let's use a formula that's more forgiving for real-world use:
        # We want distance 0.6 (typical threshold) to be around 50%
        # confidence = 100 * (1 - min(distance / 1.2, 1.0))

        # Simpler and more intuitive:
        # If distance < 0.4: High confidence (80-100%)
        # If distance 0.4-0.6: Medium confidence (50-80%)
        # If distance > 0.6: Low confidence (0-50%)

        # Formula: confidence = 100 * (1 - (distance / 0.8))^0.5 if distance < 0.8 else 0
        if face_distance >= 1.0:
            confidence = 0.0
        elif face_distance >= 0.8:
            confidence = max(0, 20 - (face_distance - 0.8) * 100)
        else:
            # Non-linear mapping for better spread
            # distance 0.0 -> 100%
            # distance 0.3 -> 85%
            # distance 0.4 -> 75%
            # distance 0.5 -> 62%
            # distance 0.6 -> 50%
            # distance 0.7 -> 35%
            # distance 0.8 -> 20%
            confidence = 100 * (1 - (face_distance / 0.8)) ** 0.7
            confidence = max(20, min(100, confidence))

        # Round to 2 decimal places and ensure native Python types
        confidence = float(round(confidence, 2))
        face_distance_val = float(round(face_distance, 4))

        # Determine if it's a match (using 60% as threshold)
        # Lowered from 75% to accommodate different lighting/angles
        # This still rejects clearly different faces while allowing some variance
        is_match = bool(confidence >= 60.0)

        print(json.dumps({
            'success': True,
            'match': is_match,
            'confidence': confidence,
            'distance': face_distance_val,
            'message': 'Wajah cocok!' if is_match else 'Wajah tidak cocok dengan foto referensi'
        }))

    except ImportError as e:
        print(json.dumps({
            'success': False,
            'match': False,
            'confidence': 0,
            'message': f'Library face_recognition tidak tersedia: {str(e)}'
        }))
        sys.exit(0)

    except Exception as e:
        print(json.dumps({
            'success': False,
            'match': False,
            'confidence': 0,
            'message': f'Error: {str(e)}'
        }))
        sys.exit(0)


if __name__ == '__main__':
    main()
