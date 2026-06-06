# Eye Scan DL

Portfolio-ready Flutter app for retinal disease screening. The app accepts a fundus image, runs an on-device TensorFlow Lite classifier, and presents the predicted disease label with a confidence score.

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
