import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:mic_stream_recorder/mic_stream_recorder.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mic Stream Recorder',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const RecordingPage(),
    );
  }
}

class RecordingPage extends StatefulWidget {
  const RecordingPage({super.key});

  @override
  State<RecordingPage> createState() => _RecordingPageState();
}

class _RecordingPageState extends State<RecordingPage> {
  String _platformVersion = 'Unknown';
  final _micStreamRecorderPlugin = MicStreamRecorder();

  bool _isRecording = false;
  bool _isPlaying = false;
  double _currentAmplitude = 0.0;
  String? _recordedFilePath;
  StreamSubscription<double>? _amplitudeSubscription;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  @override
  void dispose() {
    _amplitudeSubscription?.cancel();
    super.dispose();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion = await _micStreamRecorderPlugin.getPlatformVersion() ??
          'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  Future<void> _startRecording() async {
    try {
      // Configure recording settings (optional)
      await _micStreamRecorderPlugin.configureRecording(
        sampleRate: 44100,
        channels: 1,
        audioFormat: AudioFormat.m4a,
        audioQuality: AudioQuality.high,
      );

      // Start recording
      await _micStreamRecorderPlugin.startRecording();

      // Start listening to amplitude changes
      _amplitudeSubscription =
          _micStreamRecorderPlugin.amplitudeStream.listen((amplitude) {
        setState(() {
          _currentAmplitude = amplitude;
        });
      });

      setState(() {
        _isRecording = true;
        _recordedFilePath = null;
      });
    } catch (e) {
      _showError('Failed to start recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final filePath = await _micStreamRecorderPlugin.stopRecording();
      _amplitudeSubscription?.cancel();

      setState(() {
        _isRecording = false;
        _currentAmplitude = 0.0;
        _recordedFilePath = filePath;
      });

      if (filePath != null) {
        _showMessage('Recording saved to: $filePath');
      }
    } catch (e) {
      _showError('Failed to stop recording: $e');
    }
  }

  Future<void> _playRecording() async {
    if (_recordedFilePath == null) {
      _showError('No recording available to play');
      return;
    }

    try {
      await _micStreamRecorderPlugin.playRecording(_recordedFilePath);
      setState(() {
        _isPlaying = true;
      });

      // Check playing status periodically
      Timer.periodic(const Duration(milliseconds: 500), (timer) async {
        final isPlaying = await _micStreamRecorderPlugin.isPlaying();
        if (!isPlaying) {
          timer.cancel();
          if (mounted) {
            setState(() {
              _isPlaying = false;
            });
          }
        }
      });
    } catch (e) {
      _showError('Failed to play recording: $e');
    }
  }

  Future<void> _pausePlayback() async {
    try {
      await _micStreamRecorderPlugin.pausePlayback();
      setState(() {
        _isPlaying = false;
      });
    } catch (e) {
      _showError('Failed to pause playback: $e');
    }
  }

  Future<void> _stopPlayback() async {
    try {
      await _micStreamRecorderPlugin.stopPlayback();
      setState(() {
        _isPlaying = false;
      });
    } catch (e) {
      _showError('Failed to stop playback: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mic Stream Recorder'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Running on: $_platformVersion',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            // Amplitude Meter
            if (_isRecording) ...[
              Text(
                'Recording...',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 20,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: LinearProgressIndicator(
                  value: _currentAmplitude,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _currentAmplitude > 0.7
                        ? Colors.red
                        : _currentAmplitude > 0.3
                            ? Colors.orange
                            : Colors.green,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Amplitude: ${(_currentAmplitude * 100).toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 30),
            ],

            // Recording Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _isRecording ? _stopRecording : _startRecording,
                  icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                  label: Text(_isRecording ? 'Stop' : 'Record'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isRecording ? Colors.red : Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Playback Controls
            if (_recordedFilePath != null) ...[
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'Playback Controls',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _isPlaying ? null : _playRecording,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Play'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isPlaying ? _pausePlayback : null,
                    icon: const Icon(Icons.pause),
                    label: const Text('Pause'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isPlaying ? _stopPlayback : null,
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_isPlaying)
                const Text(
                  'Playing...',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
