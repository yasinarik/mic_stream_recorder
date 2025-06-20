import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'mic_stream_recorder_platform_interface.dart';

/// An implementation of [MicStreamRecorderPlatform] that uses method channels.
class MethodChannelMicStreamRecorder extends MicStreamRecorderPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('mic_stream_recorder');

  /// The event channel used for amplitude streaming.
  @visibleForTesting
  final eventChannel = const EventChannel('mic_stream_recorder/amplitude');

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<void> startRecording([String? filePath]) async {
    await methodChannel.invokeMethod<void>('start', filePath);
  }

  @override
  Future<String?> stopRecording() async {
    final filePath = await methodChannel.invokeMethod<String>('stop');
    return filePath;
  }

  @override
  Future<void> playRecording(String filePath) async {
    await methodChannel.invokeMethod<void>('play', filePath);
  }

  @override
  Future<void> pausePlayback() async {
    await methodChannel.invokeMethod<void>('pausePlayback');
  }

  @override
  Future<void> stopPlayback() async {
    await methodChannel.invokeMethod<void>('stopPlayback');
  }

  @override
  Future<bool> isPlaying() async {
    final isPlaying = await methodChannel.invokeMethod<bool>('isPlaying');
    return isPlaying ?? false;
  }

  @override
  Future<void> configureRecording({
    double? sampleRate,
    int? channels,
    int? bufferSize,
    int? audioQuality,
    double? amplitudeMin,
    double? amplitudeMax,
  }) async {
    final args = <String, dynamic>{};
    if (sampleRate != null) args['sampleRate'] = sampleRate;
    if (channels != null) args['channels'] = channels;
    if (bufferSize != null) args['bufferSize'] = bufferSize;
    if (audioQuality != null) args['audioQuality'] = audioQuality;
    if (amplitudeMin != null) args['amplitudeMin'] = amplitudeMin;
    if (amplitudeMax != null) args['amplitudeMax'] = amplitudeMax;

    await methodChannel.invokeMethod<void>('configureRecording', args);
  }

  @override
  Stream<double> getAmplitudeStream() {
    return eventChannel
        .receiveBroadcastStream()
        .map((event) => event as double);
  }
}
