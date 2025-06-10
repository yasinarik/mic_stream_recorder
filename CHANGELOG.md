# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-12-29

### Added
- **Initial stable release** of mic_stream_recorder plugin
- **Real-time microphone recording** with amplitude monitoring for iOS and Android
- **Cross-platform support** with comprehensive implementations for both platforms
- **M4A/AAC audio format** recording for optimal quality and compression
- **Real-time amplitude streaming** for audio visualization (0.0 - 1.0 normalized values)
- **Configurable recording settings**: sample rate, channels, buffer size, audio quality
- **Complete playback functionality**: play, pause, stop controls
- **Automatic permission handling** for microphone access on both platforms
- **Event channel streaming** for real-time audio amplitude data
- **Comprehensive example app** with visual amplitude meter and recording controls
- **Full API documentation** with usage examples
- **Cross-platform API consistency** between iOS and Android implementations

### Features
- **iOS Implementation**: AVAudioEngine + AVAudioRecorder with real-time processing
- **Android Implementation**: MediaRecorder + AudioRecord for recording and monitoring
- **Sample Rate Support**: 8000, 16000, 22050, 44100, 48000 Hz
- **Audio Quality Levels**: Min, Low, Medium, High, Max (32k-192k bitrate)
- **Buffer Size Options**: 128, 256, 512, 1024+ samples
- **Automatic file management** in platform-appropriate cache directories
- **Error handling and validation** for all recording parameters
- **Permission flow integration** with Flutter's activity lifecycle

### Technical Details
- Uses Method Channels for cross-platform communication
- Event Channels for real-time amplitude streaming
- Platform-specific optimizations for audio processing
- Memory-efficient buffer management
- Thread-safe amplitude calculations
- Proper resource cleanup and lifecycle management
