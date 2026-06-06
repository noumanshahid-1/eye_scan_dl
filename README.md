# Eye Scan DL

![Flutter](https://img.shields.io/badge/Flutter-Mobile%20App-02569B?style=for-the-badge&logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart)
![TensorFlow Lite](https://img.shields.io/badge/TensorFlow%20Lite-On--Device%20AI-FF6F00?style=for-the-badge&logo=tensorflow)
![Medical AI](https://img.shields.io/badge/Medical%20AI-Retinal%20Screening-0ea5e9?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-Research%20Prototype-facc15?style=for-the-badge)

An AI-powered Flutter application for **retinal disease screening** from fundus eye images.

The application accepts a retinal image, performs on-device TensorFlow Lite classification, maps the model output to disease labels, applies confidence-based validation for invalid retinal inputs, and presents the predicted label with a confidence score inside a clean portfolio-ready mobile interface.

> **Research Use Only:** This project is intended for educational and research screening demonstrations. It is not intended for clinical diagnosis, treatment planning, or replacement of expert ophthalmological review.

---

## Preview

| Welcome | Image Upload | Detection Result |
| --- | --- | --- |
| ![Eye Scan welcome screen](screenshots/UI.png) | ![Eye Scan upload screen](screenshots/media.png) | ![Eye Scan result screen](screenshots/result.png) |

## Project Highlights

- Built a complete Flutter flow for retinal image selection, preview, inference, and results.
- Integrated local TensorFlow Lite inference so predictions run on device without a server.
- Added confidence-based validation to reject images that are unlikely to be valid retinal fundus scans.
- Structured labels and model assets for repeatable multi-class disease prediction.
- Kept the repository clean by excluding generated build artifacts and the large model file.

## Tech Stack

- Flutter and Dart
- TensorFlow Lite via `tflite_flutter`
- `image_picker` for gallery-based image input
- `image` for preprocessing
- Android, iOS, web, and desktop Flutter project targets

## Repository Structure

- `lib/` - application screens, navigation, upload flow, and inference logic
- `assets/class_labels.json` - output label mapping for model classes
- `assets/model.tflite` - local model file, excluded from Git because of size
- `screenshots/` - portfolio screenshots used in this README

## Run Locally

1. Install Flutter and confirm the environment with `flutter doctor`.
2. Install dependencies with `flutter pub get`.
3. Place the trained TensorFlow Lite model at `assets/model.tflite`.
4. Start the app with `flutter run`.

## Model Note

The trained `.tflite` model is about 83 MB, so it is intentionally excluded from the repository. Restore it locally at `assets/model.tflite` before running inference.

## Input Note

The portfolio flow is centered on gallery image selection. Camera capture depends on device sensor availability and may not be applicable in all target environments.
