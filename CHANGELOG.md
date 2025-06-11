# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.1] - 2024-12-28

### Changed
- **BREAKING**: Removed amplitude normalization from core plugin functionality
- Amplitude stream now returns clean 0.0-1.0 values directly from audio processing
- Moved amplitude range normalization to example app as a post-processing demonstration
- Simplified plugin API by removing `amplitudeMin` and `amplitudeMax` parameters from `configureRecording()`
- Updated example app to show how to implement custom amplitude normalization as a UI feature

### Improved
- Cleaner, more focused plugin architecture
- Better separation of concerns between core functionality and UI examples
- Enhanced example app with clear post-processing demonstration
- More intuitive API for developers who want raw amplitude values

## [1.1.0] - 2024-12-28

### Enhanced
- Improved example app UI with component-based architecture
- Refactored example app into smaller, reusable widget components
- Enhanced code organization and maintainability
- Better error handling and user feedback
- Optimized amplitude range controls with preset buttons
- Added volume controls UI (recording gain and playback volume sliders)
- Improved responsive layout with SingleChildScrollView

### Fixed
- Type consistency improvements in iOS implementation
- Better file validation and error messages
- Enhanced amplitude meter visualization with color-coded progress
- Improved recording file list management

### Technical
- Split UI components into separate widget classes for better maintainability
- Consistent use of CardWrapper component throughout the example app
- Enhanced state management for better performance
- All analyzer checks passing with zero issues

## [1.0.1] - 2024-12-27

### Added
- Amplitude normalization with configurable min/max ranges
- Enhanced amplitude stream processing with custom range mapping
- Improved example app with amplitude range controls
- Range slider for configuring amplitude normalization (0-100%)
- Preset buttons for common amplitude ranges (Full, Mid, Focus)
- Dead zone elimination for amplitude values outside configured range

### Enhanced
- Better amplitude calculation and normalization
- Real-time amplitude meter with color-coded visualization
- Improved example app layout and user experience
- Enhanced documentation with amplitude configuration examples

### Fixed
- Proper amplitude range clamping and linear mapping
- Improved cross-platform amplitude processing consistency

## [1.0.0] - 2024-12-26

### Added
- Initial release of mic_stream_recorder plugin
- Real-time microphone audio recording on iOS and Android
- M4A format with AAC encoding for high-quality audio
- Custom file path support for recordings
- File validation for playback with proper error handling
- Real-time amplitude stream for audio level monitoring
- Comprehensive example app with file management
- Cross-platform audio playback controls (play, pause, stop)
- Recording state management and proper cleanup
- Permission handling for microphone access

### Features
- **Recording**: Start/stop recording with optional custom file paths
- **Playback**: Play, pause, and stop recorded audio files
- **Amplitude Monitoring**: Real-time audio level stream
- **File Management**: Automatic file organization and validation
- **Cross-Platform**: Full iOS and Android support
- **Error Handling**: Comprehensive error reporting and validation

### Platform Support
- iOS: AVAudioEngine + AVAudioRecorder + AVAudioPlayer
- Android: MediaRecorder + AudioRecord + MediaPlayer
- Flutter: Dart 3.5.4+, Flutter 3.3.0+
