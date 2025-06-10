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

  @override
  Future<void> startRecording() => Future.value();

  @override
  Future<String?> stopRecording() => Future.value('/path/to/recording.m4a');

  @override
  Future<void> playRecording([String? filePath]) => Future.value();

  @override
  Future<void> pausePlayback() => Future.value();

  @override
  Future<void> stopPlayback() => Future.value();

  @override
  Future<bool> isPlaying() => Future.value(false);

  @override
  Future<void> configureRecording({
    double? sampleRate,
    int? channels,
    int? bufferSize,
    int? audioQuality,
  }) =>
      Future.value();

  @override
  Stream<double> getAmplitudeStream() => Stream.fromIterable([0.0, 0.5, 1.0]);
}

void main() {
  final MicStreamRecorderPlatform initialPlatform =
      MicStreamRecorderPlatform.instance;

  test('$MethodChannelMicStreamRecorder is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelMicStreamRecorder>());
  });

  test('getPlatformVersion', () async {
    MicStreamRecorder micStreamRecorderPlugin = MicStreamRecorder();
    MockMicStreamRecorderPlatform fakePlatform =
        MockMicStreamRecorderPlatform();
    MicStreamRecorderPlatform.instance = fakePlatform;

    expect(await micStreamRecorderPlugin.getPlatformVersion(), '42');
  });
}
