# Google ML Digital Ink Recognition

A Flutter application that demonstrates Google ML Kit's Digital Ink Recognition capabilities. This app allows users to draw on the screen and converts their handwriting into digital text in real-time.

## Features

- Real-time handwriting recognition using Google ML Kit
- Two drawing modes:
  - Text Mode: Draw and convert handwriting to text
  - Normal Mode: Free-form drawing
- Automatic text placement based on drawing position
- Clear canvas functionality
- Material Design 3 UI

## Getting Started

### Prerequisites

- Flutter SDK (>=3.2.3)
- Dart SDK (>=3.2.3)
- Android Studio / Xcode (for running on respective platforms)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/google_ml_digital_ink.git
```

2. Navigate to the project directory:
```bash
cd google_ml_digital_ink
```

3. Install dependencies:
```bash
flutter pub get
```

4. Run the app:
```bash
flutter run
```

## Usage

1. Launch the app
2. Use the floating action buttons to switch between modes:
   - Text Mode (ABC icon): Draw text that will be recognized
   - Normal Mode (Pencil icon): Free-form drawing
   - Clear Canvas (Trash icon): Erase all drawings
3. Draw on the screen:
   - In Text Mode: Draw letters or words, and they will be automatically recognized and converted to text
   - In Normal Mode: Draw freely without recognition

## Dependencies

- `google_mlkit_digital_ink_recognition: ^0.14.1`: For handwriting recognition
- `flutter`: The Flutter framework
- `cupertino_icons: ^1.0.2`: For iOS-style icons

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Google ML Kit for providing the Digital Ink Recognition API
- Flutter team for the amazing framework
