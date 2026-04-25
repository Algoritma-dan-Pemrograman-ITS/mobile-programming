# 13 YOLO in Flutter

## Content Outline

- [What is YOLO?](#what-is-yolo)
- [What is TFLite?](#what-is-tflite)
- [How YOLO Works on Phone](#how-yolo-works-on-phone)
- [Setup Dependencies](#setup-dependencies)
- [Android Permissions](#android-permissions)
- [Download Model](#download-model)
- [Code Implementation](#code-implementation)

In this module we will try how to run a real-time object detection AI (YOLO) directly on a mobile device using Flutter.

---

### What is YOLO?

**YOLO (You Only Look Once)** is a real-time object detection algorithm based on convolutional neural networks. Unlike older approaches that scan an image multiple times at different regions, YOLO processes the entire image in a **single forward pass** — making it significantly faster.

YOLO has gone through many versions (v1 → v26). In this module we use **YOLO11**, trained on the **COCO dataset** which contains 80 common object classes.

### What is TFLite?

Training a YOLO model produces a large file (hundreds of MB) optimized for GPU servers. To run it on Android, we convert it to **TensorFlow Lite (TFLite)** — a lightweight format designed for mobile and embedded devices.

### How YOLO Works on Phone

The [`ultralytics_yolo`](https://pub.dev/packages/ultralytics_yolo) plugin — the official Flutter package from [Ultralytics](https://github.com/ultralytics/yolo-flutter-app) — bridges Flutter with native platform code:

You only need to provide the model file and handle the results. The plugin supports five tasks:

| Task | Description |
|------|-------------|
| Detection | Detect objects and their locations (bounding box) |
| Segmentation | Pixel-level object masking |
| Classification | Categorize the whole image |
| Pose Estimation | Detect human body keypoints |
| OBB Detection | Oriented bounding box for rotated objects |

In this module we focus on **Detection** using the back camera.

---

## Setup Dependencies

Add the [`ultralytics_yolo`](https://pub.dev/packages/ultralytics_yolo) package to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  ultralytics_yolo: ^0.3.0
```

Then run:

```
flutter pub get
```

---

## Android Permissions

Add camera permission to `android/app/src/main/AndroidManifest.xml` (inside `<manifest>` tag, before `<application>`):

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Add this two line -->
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-feature android:name="android.hardware.camera" android:required="true" />

    <application ...>
    </application>
</manifest>
```

---

## Download Model

The YOLO model file must be bundled inside the app as an asset.

1. Create the folder `assets/models/` in your project root
2. Register the folder in `pubspec.yaml`:
    ```yaml
    assets:
        - assets/models/
    ```
3. Download [yolo11n_int8.tflite](https://github.com/ultralytics/yolo-flutter-app/releases/download/v0.2.0/yolo11n_int8.tflite) and save it to `assets/models/yolo11n_int8.tflite`


> `yolo11n` is the nano variant of YOLO11, trained on the COCO dataset (80 classes: person, car, dog, bottle, etc.). The `_int8` suffix means it is quantized for faster inference on mobile.

---

## Code Implementation

### `lib/main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YOLO Realtime Detection',
      theme: ThemeData.dark(),
      home: const YOLODetection(),
    );
  }
}

class YOLODetection extends StatefulWidget {
  const YOLODetection({super.key});

  @override
  State<YOLODetection> createState() => _YOLODetectionState();
}

class _YOLODetectionState extends State<YOLODetection> {
  List<YOLOResult> _detections = [];
  double _fps = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black54,
        title: Text('${_detections.length} objects'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                '${_fps.toStringAsFixed(1)} FPS',
                style: const TextStyle(color: Colors.greenAccent),
              ),
            ),
          ),
        ],
      ),
      body: YOLOView(
        modelPath: 'assets/models/yolo11n_int8.tflite',
        confidenceThreshold: 0.5,
        iouThreshold: 0.45,
        lensFacing: LensFacing.back,
        showOverlays: true,
        onResult: (results) {
          setState(() => _detections = results);
        },
        onPerformanceMetrics: (metrics) {
          setState(() => _fps = metrics.fps);
        },
      ),
    );
  }
}
```

### Key Parameters

| Parameter | Description |
|-----------|-------------|
| `modelPath` | Path to the `.tflite` model file in assets |
| `confidenceThreshold` | Minimum confidence to show a detection (0.0–1.0) |
| `iouThreshold` | IoU threshold for removing duplicate boxes (0.0–1.0) |
| `lensFacing` | `LensFacing.back` or `LensFacing.front` |
| `showOverlays` | Draw bounding boxes directly on the camera feed |
| `onResult` | Callback with list of detected objects each frame |
| `onPerformanceMetrics` | Callback with FPS and inference time |

