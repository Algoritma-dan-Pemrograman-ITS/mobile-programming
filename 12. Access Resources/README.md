# 12 Access Resources

## Content Outline

- [Camera](#camera)
- [GPS](#gps)
- [File Manager](#file-manager)
- [Gallery / Image Picker](#gallery--image-picker)

In this module we will try how to access and use some of the resources in Flutter.

---

## Camera

We can access the camera using the [`camera`](https://pub.dev/packages/camera) plugin. It shows a live camera preview and allows users to take a picture. In this version, captured images are saved to the device Gallery in an album named `flutter_access_device_app` using the [`gal`](https://pub.dev/packages/gal) package.

First you must set your dependencies in `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  camera: ^0.11.0
  gal: ^2.3.0
```

After that you have to add this to your `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="...">

    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.RECORD_AUDIO" />
    <uses-permission
        android:name="android.permission.WRITE_EXTERNAL_STORAGE"
        android:maxSdkVersion="28" />

    <application
        ...>
    </application>
</manifest>
```

For iOS, add these keys to `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to take photos.</string>
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access for video recording.</string>
```

After that you can make your own kind of app or implement this simple code in `main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:gal/gal.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final firstCamera = cameras.first;

  runApp(MyApp(camera: firstCamera));
}

class MyApp extends StatelessWidget {
  final CameraDescription camera;

  const MyApp({super.key, required this.camera});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: CameraPreviewScreen(camera: camera),
    );
  }
}

class CameraPreviewScreen extends StatefulWidget {
  final CameraDescription camera;

  const CameraPreviewScreen({super.key, required this.camera});

  @override
  State<CameraPreviewScreen> createState() => _CameraPreviewScreenState();
}

class _CameraPreviewScreenState extends State<CameraPreviewScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> takePicture() async {
    try {
      await _initializeControllerFuture;
      final image = await _controller.takePicture();

      await Gal.putImage(image.path, album: 'flutter_access_device_app');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Picture saved to Gallery/flutter_access_device_app')),
      );
    } catch (e) {
      print('Error taking picture: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Camera Access')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return CameraPreview(_controller);
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: takePicture,
        child: const Icon(Icons.camera),
      ),
    );
  }
}
```

---

## GPS

We can access location using [`google_maps_flutter`](https://pub.dev/packages/google_maps_flutter) and [`location`](https://pub.dev/packages/location) plugins.

First you must set up your dependencies. Run this line in terminal,

```
flutter pub add flutter_map latlong2 location
```

or add these lines in `pubspec.yaml` in the `dependencies` section:

```yaml
dependencies:
  google_maps_flutter: ^2.17.0
  location: ^8.0.1
```

### Google Cloud Console Setup (Android & iOS)

To use Google Maps, you need to obtain an API key from Google Cloud Console:

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project
3. Enable "Maps SDK for Android" and "Maps SDK for iOS"
4. Create an API key

<img width="1408" height="522" alt="image" src="https://github.com/user-attachments/assets/d8fd19e2-39b5-4713-93a5-68638cab2714" />

<img width="720" height="180" alt="image" src="https://github.com/user-attachments/assets/2106560e-159b-4d01-9fa7-e3a2fb41d560" />

### Android Setup

**Step 1: Add permissions**

Add your setup at `android/app/src/main/AndroidManifest.xml` (inside `<manifest>` tag):

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
  <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
  <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
  <uses-permission android:name="android.permission.INTERNET" />
  ...
```

**Step 2: Add API key**

Add to `android/app/src/main/AndroidManifest.xml` (inside `<application>` tag):

```xml
<application
  <meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_API_KEY_HERE"
  />
  ...
>
```

### iOS Setup

**Step 1: Add permissions**

Add to `ios/Runner/Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs your location to show it on the map</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>This app needs your location to track and display on the map</string>
```

**Step 2: Update Podfile**

Open `ios/Podfile` and add to the `post_install` section:

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        'PERMISSION_LOCATION=1',
      ]
    end
  end
end
```

**Step 3: Update Capabilities (Xcode)**

1. Open `Runner.xcworkspace` in Xcode
2. Select Runner project → Target: Runner
3. Go to "Signing & Capabilities" tab
4. Click "+ Capability"
5. Search and add "Location Services"

### Code Implementation

After that make your own app or implement simple code like this:

```dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Location Tracking Map',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MapWithLocation(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MapWithLocation extends StatefulWidget {
  const MapWithLocation({super.key});

  @override
  State<MapWithLocation> createState() => _MapWithLocationState();
}

class _MapWithLocationState extends State<MapWithLocation> {
  final Location _location = Location();
  LocationData? _currentLocation;
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    final hasPermission = await _checkPermission();
    if (!hasPermission) return;

    final loc = await _location.getLocation();
    setState(() => _currentLocation = loc);

    _location.onLocationChanged.listen((newLoc) {
      setState(() => _currentLocation = newLoc);
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(LatLng(newLoc.latitude!, newLoc.longitude!)),
        );
        _updateMarker();
      }
    });
  }

  Future<bool> _checkPermission() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return false;
    }

    PermissionStatus permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Track My Location')),
      body: _currentLocation == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  _currentLocation!.latitude!,
                  _currentLocation!.longitude!,
                ),
                zoom: 16,
              ),
              markers: _markers,
              onMapCreated: (controller) {
                _mapController = controller;
                _updateMarker();
              },
            ),
    );
  }

  void _updateMarker() {
    if (_currentLocation == null) return;

    setState(() {
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(
            _currentLocation!.latitude!,
            _currentLocation!.longitude!,
          ),
          infoWindow: const InfoWindow(title: 'My Location'),
        ),
      );
    });
  }
}
```

<img width="360" height="800" alt="image" src="https://github.com/user-attachments/assets/e13f3a60-535e-47df-b7de-c512319f491a" />

---

## File Manager

We can access the device file system using the [`file_picker`](https://pub.dev/packages/file_picker) plugin. It lets users browse and pick files of any type from their device.

First you must set your dependencies in `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  file_picker: ^8.0.0
```

After that add this to your `app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
<uses-permission android:name="android.permission.READ_MEDIA_AUDIO" />
```

After that you can make your own app or implement this simple code in `main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: FilePickerScreen());
  }
}

class FilePickerScreen extends StatefulWidget {
  const FilePickerScreen({super.key});

  @override
  State<FilePickerScreen> createState() => _FilePickerScreenState();
}

class _FilePickerScreenState extends State<FilePickerScreen> {
  String _result = 'No file selected';

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'txt'],
    );

    setState(() {
      _result = result != null
          ? 'Selected: ${result.files.single.name}'
          : 'No file selected';
    });
  }

  Future<void> pickDirectory() async {
    final path = await FilePicker.platform.getDirectoryPath();
    setState(() {
      _result = path != null ? 'Directory: $path' : 'No directory selected';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('File Manager')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_result, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: pickFile,
              child: const Text('Pick a File'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: pickDirectory,
              child: const Text('Pick a Directory'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## Gallery / Image Picker

We can access the photo gallery using the [`image_picker`](https://pub.dev/packages/image_picker) plugin.

First you must set your dependencies in `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  image_picker: ^1.1.0
```

For iOS, add to `ios/Runner/Info.plist`:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs access to your photo library.</string>
```

After that you can make your own app or implement this simple code in `main.dart`:

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: GalleryScreen());
  }
}

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;

  Future<void> pickFromGallery() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() => _selectedImage = File(file.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gallery Picker')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _selectedImage != null
                ? Image.file(_selectedImage!, height: 300)
                : const Text('No image selected'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: pickFromGallery,
              child: const Text('Pick from Gallery'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---
