import 'package:flutter_test/flutter_test.dart';
import 'package:mic_stream_recorder/mic_stream_recorder.dart';
import 'package:mic_stream_recorder/mic_stream_recorder_platform_interface.dart';
import 'package:mic_stream_recorder/mic_stream_recorder_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockMicStreamRecorderPlatform
    with MockPlatformInterfaceMixin
    implements MicStreamRecorderPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final MicStreamRecorderPlatform initialPlatform = MicStreamRecorderPlatform.instance;

  test('$MethodChannelMicStreamRecorder is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelMicStreamRecorder>());
  });

  test('getPlatformVersion', () async {
    MicStreamRecorder micStreamRecorderPlugin = MicStreamRecorder();
    MockMicStreamRecorderPlatform fakePlatform = MockMicStreamRecorderPlatform();
    MicStreamRecorderPlatform.instance = fakePlatform;

    expect(await micStreamRecorderPlugin.getPlatformVersion(), '42');
  });
}
