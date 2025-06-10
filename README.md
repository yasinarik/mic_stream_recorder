# mic_stream_recorder

[![pub package](https://img.shields.io/pub/v/mic_stream_recorder.svg)](https://pub.dev/packages/mic_stream_recorder)
[![Platform](https://img.shields.io/badge/platform-flutter-blue.svg)](https://flutter.dev)

A Flutter plugin for real-time microphone audio stream recording on iOS and Android platforms with amplitude monitoring and configurable settings.

## Features

- 🎤 **Real-time microphone recording** with M4A/AAC format
- 📊 **Live amplitude monitoring** for audio visualization
- 📱 **Cross-platform support** (iOS & Android)
- ⚙️ **Configurable settings** (sample rate, channels, quality, buffer size)
- 🎵 **Playback controls** (play, pause, stop)
- 🛡️ **Automatic permission handling** for microphone access
- ⚡ **Low latency** real-time audio processing
- 🎯 **Simple API** with comprehensive error handling

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  mic_stream_recorder: ^1.0.0
```

Then run:

```bash
flutter pub get
```

## Quick Start

```dart
import 'package:mic_stream_recorder/mic_stream_recorder.dart';

final recorder = MicStreamRecorder();

// Start recording
await recorder.startRecording();

// Listen to real-time amplitude
recorder.amplitudeStream.listen((amplitude) {
  print('Amplitude: ${(amplitude * 100).toInt()}%');
});

// Stop recording and get file path
final filePath = await recorder.stopRecording();
print('Recording saved: $filePath');

// Play the recording
await recorder.playRecording();
```

## Detailed Usage

### Configuration

Configure recording settings before starting:

```dart
// Configure with individual parameters
await recorder.configureRecording(
  sampleRate: 44100,     // 8000, 16000, 22050, 44100, 48000
  channels: 1,           // 1 (mono) or 2 (stereo)
  audioQuality: AudioQuality.high,  // min, low, medium, high, max
  bufferSize: 1024,      // 128, 256, 512, 1024, 2048, 4096
);

// Or use RecordingConfig object
const config = RecordingConfig(
  sampleRate: 44100,
  channels: 1,
  audioQuality: AudioQuality.high,
  bufferSize: 512,
);
await recorder.configureRecordingWithConfig(config);
```

### Recording Control

```dart
// Start recording (requests permission automatically)
await recorder.startRecording();

// Stop recording and get file path
String? filePath = await recorder.stopRecording();

// Check platform version
String? version = await recorder.getPlatformVersion();
```

### Real-time Amplitude Monitoring

Perfect for creating audio visualizations:

```dart
StreamSubscription? subscription;

subscription = recorder.amplitudeStream.listen(
  (double amplitude) {
    // amplitude is normalized between 0.0 and 1.0
    setState(() {
      _currentAmplitude = amplitude;
    });
  },
  onError: (error) => print('Amplitude error: $error'),
);

// Don't forget to cancel the subscription
subscription?.cancel();
```

### Playback Control

```dart
// Play the most recent recording
await recorder.playRecording();

// Play a specific file
await recorder.playRecording('/path/to/audio/file.m4a');

// Pause playback
await recorder.pausePlayback();

// Stop playback
await recorder.stopPlayback();

// Check if currently playing
bool isPlaying = await recorder.isPlaying();
```

### Complete Example

```dart
class RecordingWidget extends StatefulWidget {
  @override
  _RecordingWidgetState createState() => _RecordingWidgetState();
}

class _RecordingWidgetState extends State<RecordingWidget> {
  final _recorder = MicStreamRecorder();
  bool _isRecording = false;
  double _amplitude = 0.0;
  String? _recordingPath;
  StreamSubscription<double>? _amplitudeSubscription;

  @override
  void dispose() {
    _amplitudeSubscription?.cancel();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      await _recorder.configureRecording(
        sampleRate: 44100,
        audioQuality: AudioQuality.high,
      );
      
      await _recorder.startRecording();
      
      _amplitudeSubscription = _recorder.amplitudeStream.listen(
        (amplitude) => setState(() => _amplitude = amplitude),
      );
      
      setState(() => _isRecording = true);
    } catch (e) {
      print('Recording failed: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _recorder.stopRecording();
      _amplitudeSubscription?.cancel();
      
      setState(() {
        _isRecording = false;
        _amplitude = 0.0;
        _recordingPath = path;
      });
    } catch (e) {
      print('Stop recording failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Amplitude visualization
        if (_isRecording)
          LinearProgressIndicator(
            value: _amplitude,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              _amplitude > 0.7 ? Colors.red :
              _amplitude > 0.3 ? Colors.orange : Colors.green,
            ),
          ),
        
        // Recording button
        ElevatedButton(
          onPressed: _isRecording ? _stopRecording : _startRecording,
          child: Text(_isRecording ? 'Stop Recording' : 'Start Recording'),
        ),
        
        // Playback button
        if (_recordingPath != null)
          ElevatedButton(
            onPressed: () => _recorder.playRecording(_recordingPath),
            child: Text('Play Recording'),
          ),
      ],
    );
  }
}
```

## Permissions

### Android

Add the following permission to your `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

### iOS

Add the following to your `ios/Runner/Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>This app needs access to microphone to record audio.</string>
```

## API Reference

### MicStreamRecorder

| Method | Description | Returns |
|--------|-------------|---------|
| `startRecording()` | Start microphone recording | `Future<void>` |
| `stopRecording()` | Stop recording and return file path | `Future<String?>` |
| `playRecording([filePath])` | Play recorded audio | `Future<void>` |
| `pausePlayback()` | Pause audio playback | `Future<void>` |
| `stopPlayback()` | Stop audio playback | `Future<void>` |
| `isPlaying()` | Check if audio is playing | `Future<bool>` |
| `configureRecording({...})` | Configure recording settings | `Future<void>` |
| `getPlatformVersion()` | Get platform version | `Future<String?>` |

| Property | Description | Type |
|----------|-------------|------|
| `amplitudeStream` | Real-time amplitude data | `Stream<double>` |

### AudioQuality

- `AudioQuality.min` - 32 kbps
- `AudioQuality.low` - 64 kbps  
- `AudioQuality.medium` - 96 kbps
- `AudioQuality.high` - 128 kbps
- `AudioQuality.max` - 192 kbps

## Platform Support

| Platform | Recording | Playback | Amplitude | Format |
|----------|-----------|----------|-----------|---------|
| Android  | ✅        | ✅       | ✅        | M4A/AAC |
| iOS      | ✅        | ✅       | ✅        | M4A/AAC |

## Technical Implementation

- **iOS**: Uses `AVAudioEngine` for real-time processing and `AVAudioRecorder` for file recording
- **Android**: Uses `MediaRecorder` for recording and `AudioRecord` for amplitude monitoring
- **Format**: M4A containers with AAC encoding for optimal quality and file size
- **Threading**: Background processing for amplitude calculation with main thread updates
- **Memory**: Efficient buffer management and automatic resource cleanup

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
