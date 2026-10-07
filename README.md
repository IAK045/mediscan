# MediScan: AI Medicine Assistant

MediScan makes prescriptions and medicine information easier to understand. Scan a prescription, and the app extracts the text with OCR, looks up medicine details through APIs, and reads them back to you with voice interaction.

![MediScan demo](assets/demo.gif)

## Features
- **Prescription scanning:** capture or upload an image and extract medicine names with OCR
- **Medicine information:** fetches details through [name of API you used]
- **Voice interaction:** [reads results aloud / accepts voice commands, keep what's true]
- **Cross-platform app:** built with Flutter

## Tech Stack
| Area | Tools |
|---|---|
| Mobile app | Flutter, Dart |
| Backend / processing | Python, [Flask / FastAPI / none] |
| OCR | [Tesseract / Google ML Kit / Google Vision / other] |
| Data | [Medicine API name], REST APIs |
| Voice | [flutter_tts / speech_to_text / other] |

## How It Works
1. User captures or uploads a prescription image
2. OCR extracts the text
3. Medicine names are identified and sent to the medicine-information API
4. Results appear in the app and can be read aloud

## Screenshots
| Scan | Results | Voice |
|---|---|---|
| ![](assets/scan.png) | ![](assets/results.png) | ![](assets/voice.png) |

## Getting Started

### Prerequisites
- Flutter SDK ([install guide](https://docs.flutter.dev/get-started/install))
- Python 3.x (if the backend is included)
- API key for [medicine API name]

### Setup
```bash
git clone https://github.com/IAK045/mediscan.git
cd mediscan

# Flutter app
flutter pub get

# Backend (if applicable)
pip install -r requirements.txt
```

Create a `.env` file (never commit it):
```
MEDICINE_API_KEY=your_key_here
```

### Run
```bash
flutter run
```

## Limitations
- OCR accuracy depends on image quality and handwriting clarity
- Not a substitute for professional medical advice. Always confirm with a doctor or pharmacist

## Roadmap
- [ ] [Something real you plan to add, e.g. multi-language support]
- [ ] [e.g. medicine reminders]

## Author
**Isteyaque Ahmad Khan**: [Portfolio](https://iakdev.vercel.app) · [LinkedIn](https://www.linkedin.com/in/isteyaque)
