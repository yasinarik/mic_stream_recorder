import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mic_stream_recorder/mic_stream_recorder.dart';

void main() {
  const MethodChannel channel = MethodChannel('mic_stream_recorder');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'getPlatformVersion':
            return '42';
          case 'start':
            return null;
          case 'stop':
            return '/path/to/recording.m4a';
          case 'play':
            return null;
          case 'pausePlayback':
            return null;
          case 'stopPlayback':
            return null;
          case 'isPlaying':
            return false;
          case 'configureRecording':
            return null;
          default:
            return null;
        }
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await MicStreamRecorder().getPlatformVersion(), '42');
  });

  test('startRecording without file path', () async {
    final recorder = MicStreamRecorder();
    expect(() => recorder.startRecording(), returnsNormally);
  });

  test('startRecording with custom file path', () async {
    final recorder = MicStreamRecorder();
    expect(() => recorder.startRecording('/custom/path/recording.m4a'),
        returnsNormally);
  });

  test('stopRecording', () async {
    final recorder = MicStreamRecorder();
    final result = await recorder.stopRecording();
    expect(result, '/path/to/recording.m4a');
  });
}
