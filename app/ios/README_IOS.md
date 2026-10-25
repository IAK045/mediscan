# iOS setup note

## Requirements
- macOS with a current stable Xcode
- Flutter stable SDK
- Xcode command-line tools and CocoaPods as required by Flutter
- Apple Developer signing for installing/distributing on a physical iPhone

The shared Flutter source uses `image_picker`, Google ML Kit text recognition, Dio, Riverpod, GoRouter, and `flutter_tts`. These have iOS platform support, but the native iOS project must be generated and built on macOS.

## Generate the iOS project
From the `app` directory on macOS:
```bash
flutter create --platforms=android,ios .
flutter pub get
cd ios
pod install
cd ..
```

Open `ios/Runner.xcworkspace` in Xcode to set the bundle identifier and signing team.

## Add permission descriptions
In `ios/Runner/Info.plist`, inside the root `<dict>`, ensure these keys exist. Add them only once; do not replace the entire plist:

```xml
<key>NSCameraUsageDescription</key>
<string>MediScan uses the camera to scan medicine packaging.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>MediScan lets you choose a medicine label image from your photo library.</string>
<key>NSMicrophoneUsageDescription</key>
<string>MediScan does not record audio; this description is only needed if an enabled plugin feature requests microphone access.</string>
<key>NSLocalNetworkUsageDescription</key>
<string>MediScan connects to your development computer's backend on the local network.</string>
```

Remove the microphone description if no installed feature requests microphone access. `flutter_tts` speaks output and does not itself require recording audio. The local network description is for local development if connecting to a computer-hosted backend.

## Backend URL
- iOS Simulator can usually reach a backend on the same Mac at `http://127.0.0.1:8000`.
- A physical iPhone must use the Mac/PC's LAN IP for a local backend, with both devices on the same network.
- For production, use HTTPS. iOS App Transport Security may block plain HTTP; do not globally disable ATS in a production app.

Example:
```bash
flutter run --dart-define=API_BASE_URL=https://your-backend.example.com
```

## Build
```bash
flutter build ios --release --dart-define=API_BASE_URL=https://your-backend.example.com
```

iOS builds cannot be compiled, signed, or launched from Windows. The Flutter Dart code is shared, but final iOS validation must be done on macOS/Xcode.
