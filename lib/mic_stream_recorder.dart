import 'dart:io';
import 'mic_stream_recorder_platform_interface.dart';

/// Audio quality options for recording
enum AudioQuality {
  min,
  low,
  medium,
  high,
  max,
}

/// Configuration class for recording settings
class RecordingConfig {
  final double sampleRate;
  final int channels;
  final int bufferSize;
  final AudioQuality audioQuality;

  const RecordingConfig({
    this.sampleRate = 44100,
    this.channels = 1,
    this.bufferSize = 128,
    this.audioQuality = AudioQuality.high,
  });

  Map<String, dynamic> toMap() {
    return {
      'sampleRate': sampleRate,
      'channels': channels,
      'bufferSize': bufferSize,
      'audioQuality': audioQuality.index,
    };
  }
}

/// Main class for microphone stream recording functionality
class MicStreamRecorder {
  /// Get the platform version
  Future<String?> getPlatformVersion() {
    return MicStreamRecorderPlatform.instance.getPlatformVersion();
  }

  /// Start recording audio from the microphone
  ///
  /// Optionally provide a [filePath] to specify where to save the recording.
  /// If no [filePath] is provided, a default location will be used.
  /// Audio will be recorded in M4A format with AAC encoding.
  ///
  /// Example:
  /// ```dart
  /// // Record to default location
  /// await recorder.startRecording();
  ///
  /// // Record to specific file
  /// await recorder.startRecording('/path/to/my_recording.m4a');
  /// ```
  Future<void> startRecording([String? filePath]) {
    return MicStreamRecorderPlatform.instance.startRecording(filePath);
  }

  /// Stop recording audio
  ///
  /// Returns the file path of the recorded M4A audio file.
  Future<String?> stopRecording() {
    return MicStreamRecorderPlatform.instance.stopRecording();
  }

  /// Play the specified audio file
  ///
  /// [filePath] is required and must point to a valid audio file.
  /// The file will be validated before attempting playback.
  ///
  /// Example:
  /// ```dart
  /// await recorder.playRecording('/path/to/recording.m4a');
  /// ```
  ///
  /// Throws [FileSystemException] if the file doesn't exist.
  /// Throws [ArgumentError] if the file path is invalid.
  Future<void> playRecording(String filePath) async {
    if (filePath.isEmpty) {
      throw ArgumentError('File path cannot be empty');
    }

    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException('Audio file not found', filePath);
    }

    return MicStreamRecorderPlatform.instance.playRecording(filePath);
  }

  /// Pause audio playback
  Future<void> pausePlayback() {
    return MicStreamRecorderPlatform.instance.pausePlayback();
  }

  /// Stop audio playback completely
  Future<void> stopPlayback() {
    return MicStreamRecorderPlatform.instance.stopPlayback();
  }

  /// Check if audio is currently playing
  Future<bool> isPlaying() {
    return MicStreamRecorderPlatform.instance.isPlaying();
  }

  /// Configure recording settings
  ///
  /// This should be called before starting recording to apply the settings.
  /// All recordings will be in M4A format with AAC encoding.
  ///
  /// Example:
  /// ```dart
  /// await recorder.configureRecording(
  ///   sampleRate: 44100,
  ///   channels: 1,
  ///   audioQuality: AudioQuality.high,
  /// );
  /// ```
  Future<void> configureRecording({
    double? sampleRate,
    int? channels,
    int? bufferSize,
    AudioQuality? audioQuality,
  }) {
    return MicStreamRecorderPlatform.instance.configureRecording(
      sampleRate: sampleRate,
      channels: channels,
      bufferSize: bufferSize,
      audioQuality: audioQuality?.index,
    );
  }

  /// Configure recording using a [RecordingConfig] object
  Future<void> configureRecordingWithConfig(RecordingConfig config) {
    final configMap = config.toMap();
    return MicStreamRecorderPlatform.instance.configureRecording(
      sampleRate: configMap['sampleRate'],
      channels: configMap['channels'],
      bufferSize: configMap['bufferSize'],
      audioQuality: configMap['audioQuality'],
    );
  }

  /// Get real-time amplitude stream for audio level monitoring
  ///
  /// Returns a stream of normalized amplitude values between 0.0 and 1.0.
  /// This can be used to create visualizations like amplitude meters.
  ///
  /// Example:
  /// ```dart
  /// recorder.amplitudeStream.listen((amplitude) {
  ///   print('Current amplitude: $amplitude');
  ///   // Update UI with amplitude value
  /// });
  /// ```
  Stream<double> get amplitudeStream {
    return MicStreamRecorderPlatform.instance.getAmplitudeStream();
  }
}
