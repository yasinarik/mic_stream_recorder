# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.1] - 2024-12-29

### Added
- **Configurable Amplitude Normalization**
  - Added `amplitudeMin` and `amplitudeMax` parameters to `configureRecording()`
  - Custom amplitude ranges for real-time monitoring (default: 0.0 to 1.0)
  - Support for percentage ranges (0-100), symmetric ranges (-1.0 to 1.0), decibel-like ranges (-80 to 0)
  - Updated both iOS and Android implementations with custom normalization
  - Enhanced documentation with amplitude normalization examples

### Enhanced API
- `configureRecording()` now accepts `amplitudeMin` and `amplitudeMax` parameters
- `RecordingConfig` class updated with amplitude normalization properties
- Amplitude stream now respects configured normalization range

## [1.0.0] - 2024-12-29

### Added
- **Core Recording Features**
  - Real-time microphone recording with M4A/AAC format
  - Configurable recording settings (sample rate: 8000-48000 Hz, channels: 1-2, buffer size, audio quality)
  - Automatic microphone permission handling on both platforms

- **Enhanced File Management**
  - **Optional custom file path for recording** - specify where to save recordings or use default location
  - **Required file path for playback** - validate file existence before attempting playback
  - **File validation** - automatic checking of file existence with proper error handling
  - Support for custom recording locations using `startRecording([String? filePath])`

- **Real-time Audio Monitoring**
  - Live amplitude stream with normalized values (0.0 to 1.0)
  - Real-time audio level visualization support
  - Background amplitude processing with main thread UI updates

- **Comprehensive Playback Controls**
  - Play, pause, and stop audio playback with file path validation
  - Playback status monitoring with `isPlaying()` method
  - Automatic resource cleanup on playback completion

- **Cross-Platform Implementation**
  - **iOS**: AVAudioEngine + AVAudioRecorder + AVAudioPlayer with hardware-optimized processing
  - **Android**: MediaRecorder + AudioRecord + MediaPlayer with runtime permission handling
  - Consistent API across both platforms with platform-specific optimizations

- **Developer Experience**
  - Comprehensive error handling with specific exception types
  - Detailed API documentation with usage examples
  - Enhanced example app with custom file naming and file list management
  - Full test coverage with updated test cases

### Enhanced API
- `startRecording([String? filePath])` - Start recording with optional custom file path
- `playRecording(String filePath)` - Play audio file with required path validation
- Throws `FileSystemException` for missing files and `ArgumentError` for invalid paths
- Improved error messages and debugging information

### Technical Improvements
- Efficient file path management with fallback to default locations
- Enhanced native implementations for both iOS and Android
- Better resource management and cleanup
- Optimized amplitude calculation and streaming
