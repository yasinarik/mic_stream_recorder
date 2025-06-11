# Mic Stream Recorder

A Flutter plugin for recording audio from the microphone with real-time amplitude monitoring. Supports both iOS and Android platforms with configurable recording settings and built-in playback functionality.

## Features

- 🎤 **Real-time microphone recording** with M4A/AAC format output
- 📊 **Live amplitude monitoring** with 0.0-1.0 normalized values
- ⚙️ **Configurable recording settings** (sample rate, channels, buffer size, audio quality)
- 🎵 **Built-in audio playback** with pause/resume/stop controls
- 📱 **Cross-platform support** for iOS and Android
- 🎛️ **Example app** demonstrating advanced features like amplitude post-processing

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  mic_stream_recorder: ^1.1.1
```

## Permissions

### Android
Add to your `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

### iOS
Add to your `ios/Runner/Info.plist`:
```xml
<key>NSMicrophoneUsageDescription</key>
<string>This app needs access to the microphone to record audio.</string>
```

## Basic Usage

```dart
import 'package:mic_stream_recorder/mic_stream_recorder.dart';

class AudioRecorderExample extends StatefulWidget {
  @override
  _AudioRecorderExampleState createState() => _AudioRecorderExampleState();
}

class _AudioRecorderExampleState extends State<AudioRecorderExample> {
  final MicStreamRecorder _recorder = MicStreamRecorder();
  bool _isRecording = false;
  double _currentAmplitude = 0.0;

  @override
  void initState() {
    super.initState();
    
    // Listen to real-time amplitude values (0.0 - 1.0)
    _recorder.amplitudeStream.listen((amplitude) {
      setState(() => _currentAmplitude = amplitude);
    });
  }

  Future<void> _startRecording() async {
    try {
      await _recorder.startRecording();
      setState(() => _isRecording = true);
    } catch (e) {
      print('Failed to start recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final recordingPath = await _recorder.stopRecording();
      setState(() => _isRecording = false);
      print('Recording saved to: $recordingPath');
    } catch (e) {
      print('Failed to stop recording: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Amplitude: ${_currentAmplitude.toStringAsFixed(2)}'),
          LinearProgressIndicator(value: _currentAmplitude),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isRecording ? _stopRecording : _startRecording,
            child: Text(_isRecording ? 'Stop Recording' : 'Start Recording'),
          ),
        ],
      ),
    );
  }
}
```

## Advanced Configuration

Configure recording settings before starting:

```dart
await _recorder.configureRecording(
  sampleRate: 44100,
  channels: 1,
  bufferSize: 1024,
  audioQuality: AudioQuality.high,
);
```

### Audio Quality Options
- `AudioQuality.min` (32 kbps)
- `AudioQuality.low` (64 kbps)  
- `AudioQuality.medium` (96 kbps)
- `AudioQuality.high` (128 kbps)
- `AudioQuality.max` (192 kbps)

## Amplitude Monitoring

The plugin provides raw amplitude values between 0.0 and 1.0:

```dart
_recorder.amplitudeStream.listen((amplitude) {
  // amplitude is between 0.0 (silence) and 1.0 (maximum)
  print('Current amplitude: $amplitude');
  
  // Example: Convert to percentage
  int percentage = (amplitude * 100).round();
  print('Amplitude: $percentage%');
  
  // Example: Apply custom range (see example app for full implementation)
  double customMin = 0.2; // 20%
  double customMax = 0.8; // 80%
  double normalizedAmplitude = customMin + (amplitude * (customMax - customMin));
});
```

## Audio Playback

Play recorded audio files:

```dart
// Play a recording
await _recorder.playRecording('/path/to/recording.m4a');

// Pause playback
await _recorder.pausePlayback();

// Stop playback
await _recorder.stopPlayback();

// Check if playing
bool isPlaying = await _recorder.isPlaying();
```

## Custom File Paths

Specify custom recording locations:

```dart
// Record to specific path
await _recorder.startRecording('/custom/path/my_recording.m4a');

// Use app documents directory
final directory = await getApplicationDocumentsDirectory();
final filePath = '${directory.path}/custom_recording.m4a';
await _recorder.startRecording(filePath);
```

## Example App Features

The included example app demonstrates:

- ✅ **Basic recording and playback**
- ✅ **Real-time amplitude visualization**
- ✅ **Custom amplitude range post-processing** (how to map 0.0-1.0 to custom ranges)
- ✅ **File management** (list and play recordings)
- ✅ **Modern UI components** with reusable widgets
- ✅ **Best practices** for error handling and state management

### Post-Processing Example

The example app shows how to implement custom amplitude normalization:

```dart
double normalizeAmplitude(double rawAmplitude, double minPercent, double maxPercent) {
  return minPercent + (rawAmplitude * (maxPercent - minPercent));
}

// Usage
_recorder.amplitudeStream.listen((rawAmplitude) {
  // Apply custom range (e.g., 20% to 80%)
  double customAmplitude = normalizeAmplitude(rawAmplitude, 0.2, 0.8);
  setState(() => _currentAmplitude = customAmplitude);
});
```

## Platform Support

| Platform | Minimum Version | Audio Format |
|----------|----------------|--------------|
| iOS      | 12.0+          | M4A (AAC)    |
| Android  | API 21+        | M4A (AAC)    |

## Technical Details

- **Audio Format**: M4A with AAC encoding
- **Sample Rates**: 8000, 16000, 22050, 44100, 48000 Hz
- **Channels**: Mono (1) or Stereo (2)
- **Buffer Sizes**: 128, 256, 512, 1024 samples
- **Amplitude Values**: Normalized 0.0-1.0 range (raw values, no post-processing)

## API Reference

### Core Methods

| Method | Description | Returns |
|--------|-------------|---------|
| `startRecording([filePath])` | Start recording audio | `Future<void>` |
| `stopRecording()` | Stop recording and get file path | `Future<String?>` |
| `playRecording(filePath)` | Play an audio file | `Future<void>` |
| `pausePlayback()` | Pause current playback | `Future<void>` |
| `stopPlayback()` | Stop current playback | `Future<void>` |
| `isPlaying()` | Check if audio is playing | `Future<bool>` |
| `configureRecording({...})` | Configure recording settings | `Future<void>` |

### Streams

| Stream | Description | Type |
|--------|-------------|------|
| `amplitudeStream` | Real-time amplitude values | `Stream<double>` |

## Troubleshooting

### Common Issues

1. **Permission Denied**: Ensure microphone permissions are granted
2. **Recording Failed**: Check available storage space
3. **Playback Issues**: Verify file exists and is valid M4A format
4. **Low Amplitude Values**: Raw values are normalized; apply post-processing for custom ranges

### Debug Tips

```dart
// Enable verbose logging
await _recorder.configureRecording(
  sampleRate: 44100,
  channels: 1,
  bufferSize: 1024, // Smaller buffer = more frequent amplitude updates
);

// Monitor amplitude stream
_recorder.amplitudeStream.listen((amplitude) {
  print('Raw amplitude: $amplitude'); // Should be 0.0-1.0
});
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For issues, feature requests, or questions, please visit our [GitHub repository](https://github.com/yasinarik/mic_stream_recorder).

## Author

**Yasin Arik**

- GitHub: [@yasinarik](https://github.com/yasinarik)
- Email: yasin.ariky@gmail.com
