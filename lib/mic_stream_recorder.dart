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
  /// This will request microphone permissions if not already granted
  /// and start recording audio with the current configuration.
  /// Audio will be recorded in M4A format with AAC encoding.
  Future<void> startRecording() {
    return MicStreamRecorderPlatform.instance.startRecording();
  }

  /// Stop recording audio
  ///
  /// Returns the file path of the recorded M4A audio file.
  Future<String?> stopRecording() {
    return MicStreamRecorderPlatform.instance.stopRecording();
  }

  /// Play the recorded audio file
  ///
  /// If [filePath] is provided, plays that specific file.
  /// Otherwise, plays the most recently recorded file.
  Future<void> playRecording([String? filePath]) {
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
