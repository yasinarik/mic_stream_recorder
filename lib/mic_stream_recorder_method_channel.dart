import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'mic_stream_recorder_platform_interface.dart';

/// An implementation of [MicStreamRecorderPlatform] that uses method channels.
class MethodChannelMicStreamRecorder extends MicStreamRecorderPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('mic_stream_recorder');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
