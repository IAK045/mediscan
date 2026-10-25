# Android + iOS support

The application logic lives in `app/lib/` and is shared between Android and iOS.

Important distinction:
- Shared Flutter/Dart source: included.
- Native Android/iOS platform project scaffolding: generate with `flutter create --platforms=android,ios .` from `app/`.
- Android build: can be done on Windows, macOS, or Linux with Android tooling.
- iOS build/signing: requires macOS and Xcode.
- Backend: must be reachable by the phone/simulator and should use HTTPS in production.

Read `app/android/README_ANDROID.md`, `app/ios/README_IOS.md`, and the root `README.md`.
