# mic_stream_recorder

[![pub package](https://img.shields.io/pub/v/mic_stream_recorder.svg)](https://pub.dev/packages/mic_stream_recorder)
[![Platform](https://img.shields.io/badge/platform-flutter-blue.svg)](https://flutter.dev)

A Flutter plugin for real-time microphone audio stream recording on iOS and Android platforms.

## Features

- 🎤 Real-time microphone audio stream recording
- 📱 Cross-platform support (iOS & Android)
- 🔄 Stream-based audio data capture
- ⚡ Low latency audio processing
- 🛡️ Permission handling for microphone access

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  mic_stream_recorder: ^0.0.1
```

Then run:

```bash
flutter pub get
```

## Usage

### Basic Example

```dart
import 'package:mic_stream_recorder/mic_stream_recorder.dart';

// Initialize the recorder
final micRecorder = MicStreamRecorder();

// Start recording
await micRecorder.startRecording();

// Listen to audio stream
micRecorder.audioStream.listen((audioData) {
  // Process audio data
  print('Received audio data: ${audioData.length} bytes');
});

// Stop recording
await micRecorder.stopRecording();
```

### Permissions

Make sure to add the necessary permissions to your app:

#### Android

Add the following permission to your `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

#### iOS

Add the following to your `ios/Runner/Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>This app needs access to microphone to record audio.</string>
```

## API Reference

### MicStreamRecorder

#### Methods

- `startRecording()` - Start recording audio from microphone
- `stopRecording()` - Stop recording audio
- `isRecording` - Check if currently recording

#### Properties

- `audioStream` - Stream of audio data bytes

## Platform Support

| Android | iOS |
| ------- | --- |
| ✅      | ✅  |

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Issues

Please file any issues, bugs, or feature requests in the [GitHub repository](https://github.com/yasinarik/mic_stream_recorder/issues).

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

**Yasin Arik**

- GitHub: [@yasinarik](https://github.com/yasinarik)
- Email: yasin.ariky@gmail.com
