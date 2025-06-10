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
}
