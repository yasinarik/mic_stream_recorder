
import 'mic_stream_recorder_platform_interface.dart';

class MicStreamRecorder {
  Future<String?> getPlatformVersion() {
    return MicStreamRecorderPlatform.instance.getPlatformVersion();
  }
}
