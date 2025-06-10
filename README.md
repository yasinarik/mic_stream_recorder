# mic_stream_recorder

[![pub package](https://img.shields.io/pub/v/mic_stream_recorder.svg)](https://pub.dev/packages/mic_stream_recorder)
[![Platform](https://img.shields.io/badge/platform-flutter-blue.svg)](https://flutter.dev)

A Flutter plugin for real-time microphone audio stream recording on iOS and Android platforms with amplitude monitoring and configurable settings.

## Features

- 🎤 **High-quality audio recording** in M4A format with AAC encoding
- 📊 **Real-time amplitude monitoring** with normalized output (0.0-1.0)
- 🔧 **Configurable recording settings** (sample rate, channels, buffer size, quality)
- ▶️ **Audio playback controls** (play, pause, stop)
- 📁 **Flexible file management** with custom file paths
- 🔒 **Automatic permission handling** for microphone access
- 🎯 **Cross-platform support** for iOS and Android

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

## Platform Setup

### iOS

Add the following key to your `ios/Runner/Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>This app needs access to the microphone to record audio</string>
```

### Android

Add the following permission to your `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

## Quick Start

```dart
import 'package:mic_stream_recorder/mic_stream_recorder.dart';

class MyRecorder {
  final _recorder = MicStreamRecorder();

  Future<void> startRecording() async {
    // Start recording to default location
    await _recorder.startRecording();
    
    // Or start recording to custom location
    await _recorder.startRecording('/path/to/my_recording.m4a');
  }

  Future<void> stopRecording() async {
    final recordingPath = await _recorder.stopRecording();
    print('Recording saved: $recordingPath');
  }

  Future<void> playRecording(String filePath) async {
    await _recorder.playRecording(filePath);
  }
}
```

## API Reference

### Recording Methods

#### `startRecording([String? filePath])`
Starts audio recording from the microphone.

**Parameters:**
- `filePath` (optional): Custom file path for the recording. If not provided, uses default location.

**Example:**
```dart
// Record to default location
await recorder.startRecording();

// Record to custom location
await recorder.startRecording('/path/to/my_recording.m4a');
```

#### `stopRecording()`
Stops the current recording and returns the file path.

**Returns:** `Future<String?>` - Path to the recorded file

**Example:**
```dart
final recordingPath = await recorder.stopRecording();
```

### Playback Methods

#### `playRecording(String filePath)`
Plays the specified audio file. The file path is required and validated before playback.

**Parameters:**
- `filePath`: Path to the audio file to play

**Throws:**
- `ArgumentError`: If the file path is empty
- `FileSystemException`: If the file doesn't exist

**Example:**
```dart
try {
  await recorder.playRecording('/path/to/recording.m4a');
} catch (e) {
  print('Playback failed: $e');
}
```

#### `pausePlayback()`
Pauses the current audio playback.

#### `stopPlayback()`
Stops the current audio playback.

#### `isPlaying()`
Returns whether audio is currently playing.

**Returns:** `Future<bool>`

### Configuration Methods

#### `configureRecording({...})`
Configure recording settings before starting recording.

**Parameters:**
- `sampleRate` (double?): Audio sample rate (8000, 16000, 22050, 44100, 48000 Hz)
- `channels` (int?): Number of audio channels (1 or 2)
- `bufferSize` (int?): Audio buffer size (128, 256, 512, 1024)
- `audioQuality` (AudioQuality?): Recording quality (min, low, medium, high, max)
- `amplitudeMin` (double?): Minimum value for amplitude normalization (default: 0.0)
- `amplitudeMax` (double?): Maximum value for amplitude normalization (default: 1.0)

**Example:**
```dart
await recorder.configureRecording(
  sampleRate: 44100,
  channels: 1,
  audioQuality: AudioQuality.high,
  amplitudeMin: -1.0,  // Custom range from -1.0 to 1.0
  amplitudeMax: 1.0,
);
```

### Real-time Monitoring

#### `amplitudeStream`
Stream of real-time amplitude values during recording. The range is configurable 
through `amplitudeMin` and `amplitudeMax` parameters (default: 0.0 to 1.0).

**Example:**
```dart
// Configure custom amplitude range
await recorder.configureRecording(
  amplitudeMin: -100.0,
  amplitudeMax: 100.0,
);

recorder.amplitudeStream.listen((amplitude) {
  print('Current amplitude: ${amplitude.toStringAsFixed(1)}'); // Range: -100.0 to 100.0
  // Update UI amplitude meter
});
```

## Complete Example

```dart
import 'package:flutter/material.dart';
import 'package:mic_stream_recorder/mic_stream_recorder.dart';
import 'package:path_provider/path_provider.dart';

class RecordingPage extends StatefulWidget {
  @override
  _RecordingPageState createState() => _RecordingPageState();
}

class _RecordingPageState extends State<RecordingPage> {
  final _recorder = MicStreamRecorder();
  bool _isRecording = false;
  bool _isPlaying = false;
  double _amplitude = 0.0;
  String? _lastRecordingPath;

  @override
  void initState() {
    super.initState();
    
    // Listen to amplitude changes
    _recorder.amplitudeStream.listen((amplitude) {
      setState(() => _amplitude = amplitude);
    });
  }

  Future<void> _startRecording() async {
    try {
      // Optional: Configure recording settings
      await _recorder.configureRecording(
        sampleRate: 44100,
        channels: 1,
        audioQuality: AudioQuality.high,
        amplitudeMin: 0.0,   // Custom amplitude range
        amplitudeMax: 1.0,
      );

      // Start recording with custom filename
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/my_recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
      
      await _recorder.startRecording(filePath);
      setState(() => _isRecording = true);
    } catch (e) {
      print('Failed to start recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _recorder.stopRecording();
      setState(() {
        _isRecording = false;
        _lastRecordingPath = path;
        _amplitude = 0.0;
      });
      print('Recording saved: $path');
    } catch (e) {
      print('Failed to stop recording: $e');
    }
  }

  Future<void> _playRecording() async {
    if (_lastRecordingPath == null) return;
    
    try {
      await _recorder.playRecording(_lastRecordingPath!);
      setState(() => _isPlaying = true);
      
      // Check if playback is still active
      _checkPlaybackStatus();
    } catch (e) {
      print('Failed to play recording: $e');
    }
  }

  void _checkPlaybackStatus() async {
    while (_isPlaying) {
      await Future.delayed(Duration(milliseconds: 500));
      final isPlaying = await _recorder.isPlaying();
      if (!isPlaying) {
        setState(() => _isPlaying = false);
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Mic Stream Recorder')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Amplitude meter
            if (_isRecording) ...[
              Text('Recording... ${(_amplitude * 100).toStringAsFixed(1)}%'),
              LinearProgressIndicator(value: _amplitude),
              SizedBox(height: 20),
            ],
            
            // Recording controls
            ElevatedButton.icon(
              onPressed: _isRecording ? _stopRecording : _startRecording,
              icon: Icon(_isRecording ? Icons.stop : Icons.mic),
              label: Text(_isRecording ? 'Stop Recording' : 'Start Recording'),
            ),
            
            SizedBox(height: 20),
            
            // Playback controls
            if (_lastRecordingPath != null) ...[
              ElevatedButton.icon(
                onPressed: _isPlaying ? null : _playRecording,
                icon: Icon(Icons.play_arrow),
                label: Text('Play Recording'),
              ),
              if (_isPlaying) ...[
                SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () async {
                    await _recorder.pausePlayback();
                    setState(() => _isPlaying = false);
                  },
                  icon: Icon(Icons.pause),
                  label: Text('Pause'),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
```

## Configuration Options

### AudioQuality Enum
- `AudioQuality.min` - Minimum quality (64 kbps)
- `AudioQuality.low` - Low quality (96 kbps)
- `AudioQuality.medium` - Medium quality (128 kbps)
- `AudioQuality.high` - High quality (256 kbps)
- `AudioQuality.max` - Maximum quality (320 kbps)

### Sample Rates
Supported sample rates: 8000, 16000, 22050, 44100, 48000 Hz

### Buffer Sizes
Supported buffer sizes: 128, 256, 512, 1024 samples

### Amplitude Normalization
Configure custom amplitude ranges for real-time monitoring:

```dart
// Default range (0.0 to 1.0)
await recorder.configureRecording();

// Custom percentage range (0 to 100)
await recorder.configureRecording(
  amplitudeMin: 0.0,
  amplitudeMax: 100.0,
);

// Symmetric range (-1.0 to 1.0)
await recorder.configureRecording(
  amplitudeMin: -1.0,
  amplitudeMax: 1.0,
);

// Decibel-like range (-80 to 0)
await recorder.configureRecording(
  amplitudeMin: -80.0,
  amplitudeMax: 0.0,
);
```

## Technical Implementation

### Audio Format
- **Container**: M4A (MPEG-4 Audio)
- **Codec**: AAC (Advanced Audio Coding)
- **Quality**: Configurable bitrate encoding

### Platform-Specific Details

#### iOS Implementation
- Uses `AVAudioEngine` for real-time amplitude monitoring
- Uses `AVAudioRecorder` for high-quality file recording
- Uses `AVAudioPlayer` for audio playback
- Automatic microphone permission handling

#### Android Implementation
- Uses `MediaRecorder` for audio recording
- Uses `AudioRecord` for real-time amplitude monitoring
- Uses `MediaPlayer` for audio playback
- Runtime permission handling with activity lifecycle integration

## Error Handling

The plugin provides comprehensive error handling:

```dart
try {
  await recorder.startRecording('/custom/path/recording.m4a');
} catch (e) {
  if (e is PlatformException) {
    switch (e.code) {
      case 'PERMISSION_DENIED':
        print('Microphone permission denied');
        break;
      case 'ALREADY_RECORDING':
        print('Recording is already in progress');
        break;
      default:
        print('Recording error: ${e.message}');
    }
  }
}

try {
  await recorder.playRecording('/path/to/recording.m4a');
} catch (e) {
  if (e is FileSystemException) {
    print('Audio file not found: ${e.path}');
  } else if (e is ArgumentError) {
    print('Invalid file path: ${e.message}');
  }
}
```

## File Management Best Practices

### Recording File Paths
```dart
import 'package:path_provider/path_provider.dart';

// Use app documents directory
final directory = await getApplicationDocumentsDirectory();
final filePath = '${directory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
await recorder.startRecording(filePath);

// Use temporary directory
final tempDir = await getTemporaryDirectory();
final tempPath = '${tempDir.path}/temp_recording.m4a';
await recorder.startRecording(tempPath);
```

### File Validation
```dart
Future<void> playRecordingIfExists(String filePath) async {
  final file = File(filePath);
  if (await file.exists()) {
    await recorder.playRecording(filePath);
  } else {
    print('Recording file does not exist');
  }
}
```

## Contributing

Contributions are welcome! Please read our contributing guidelines and submit pull requests to our repository.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For issues, feature requests, or questions, please visit our [GitHub repository](https://github.com/yasinarik/mic_stream_recorder).

## Author

**Yasin Arik**

- GitHub: [@yasinarik](https://github.com/yasinarik)
- Email: yasin.ariky@gmail.com
