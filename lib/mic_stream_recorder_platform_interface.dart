import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'mic_stream_recorder_method_channel.dart';

abstract class MicStreamRecorderPlatform extends PlatformInterface {
  /// Constructs a MicStreamRecorderPlatform.
  MicStreamRecorderPlatform() : super(token: _token);

  static final Object _token = Object();

  static MicStreamRecorderPlatform _instance = MethodChannelMicStreamRecorder();

  /// The default instance of [MicStreamRecorderPlatform] to use.
  ///
  /// Defaults to [MethodChannelMicStreamRecorder].
  static MicStreamRecorderPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [MicStreamRecorderPlatform] when
  /// they register themselves.
  static set instance(MicStreamRecorderPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  /// Start recording audio
  Future<void> startRecording([String? filePath]) {
    throw UnimplementedError('startRecording() has not been implemented.');
  }

  /// Stop recording audio and return the file path
  Future<String?> stopRecording() {
    throw UnimplementedError('stopRecording() has not been implemented.');
  }

  /// Play the specified audio file
  Future<void> playRecording(String filePath) {
    throw UnimplementedError('playRecording() has not been implemented.');
  }

  /// Pause audio playback
  Future<void> pausePlayback() {
    throw UnimplementedError('pausePlayback() has not been implemented.');
  }

  /// Stop audio playback
  Future<void> stopPlayback() {
    throw UnimplementedError('stopPlayback() has not been implemented.');
  }

  /// Check if audio is currently playing
  Future<bool> isPlaying() {
    throw UnimplementedError('isPlaying() has not been implemented.');
  }

  /// Configure recording settings
  Future<void> configureRecording({
    double? sampleRate,
    int? channels,
    int? bufferSize,
    int? audioQuality,
    double? amplitudeMin,
    double? amplitudeMax,
  }) {
    throw UnimplementedError('configureRecording() has not been implemented.');
  }

  /// Get amplitude stream for real-time audio level monitoring
  Stream<double> getAmplitudeStream() {
    throw UnimplementedError('getAmplitudeStream() has not been implemented.');
  }
}
