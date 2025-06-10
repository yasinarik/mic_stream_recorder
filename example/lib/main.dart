import 'package:flutter/material.dart';
import 'package:mic_stream_recorder/mic_stream_recorder.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mic Stream Recorder Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
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
  final _micStreamRecorderPlugin = MicStreamRecorder();

  bool _isRecording = false;
  bool _isPlaying = false;
  double _currentAmplitude = 0.0;
  String? _lastRecordingPath;
  List<String> _recordingFiles = [];
  final TextEditingController _fileNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _setupAmplitudeListener();
    _loadRecordingFiles();
  }

  void _setupAmplitudeListener() {
    _micStreamRecorderPlugin.amplitudeStream.listen((amplitude) {
      if (mounted) {
        setState(() {
          _currentAmplitude = amplitude;
        });
      }
    });
  }

  Future<void> _loadRecordingFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory
          .listSync()
          .where((file) => file.path.endsWith('.m4a'))
          .map((file) => file.path)
          .toList();

      setState(() {
        _recordingFiles = files;
      });
    } catch (e) {
      _showError('Failed to load recording files: $e');
    }
  }

  Future<String> _getCustomFilePath(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$fileName.m4a';
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _startRecording() async {
    if (_isRecording) return;

    try {
      String? customPath;
      if (_fileNameController.text.isNotEmpty) {
        customPath = await _getCustomFilePath(_fileNameController.text);
      }

      await _micStreamRecorderPlugin.startRecording(customPath);
      setState(() {
        _isRecording = true;
      });
      _showSuccess(customPath != null
          ? 'Started recording to: ${_fileNameController.text}.m4a'
          : 'Started recording to default location');
    } catch (e) {
      _showError('Failed to start recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    try {
      final recordingPath = await _micStreamRecorderPlugin.stopRecording();
      setState(() {
        _isRecording = false;
        _lastRecordingPath = recordingPath;
        _currentAmplitude = 0.0;
      });

      // Clear the file name input
      _fileNameController.clear();

      // Reload the file list
      await _loadRecordingFiles();

      _showSuccess(
          'Recording saved: ${recordingPath?.split('/').last ?? 'Unknown'}');
    } catch (e) {
      _showError('Failed to stop recording: $e');
    }
  }

  Future<void> _playRecording(String filePath) async {
    try {
      await _micStreamRecorderPlugin.playRecording(filePath);
      setState(() {
        _isPlaying = true;
      });
      _showSuccess('Playing: ${filePath.split('/').last}');

      // Check playing status periodically
      _checkPlayingStatus();
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
      _showSuccess('Playback paused');
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
      _showSuccess('Playback stopped');
    } catch (e) {
      _showError('Failed to stop playback: $e');
    }
  }

  void _checkPlayingStatus() async {
    while (_isPlaying) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        final isPlaying = await _micStreamRecorderPlugin.isPlaying();
        if (!isPlaying && _isPlaying) {
          setState(() {
            _isPlaying = false;
          });
          _showSuccess('Playback completed');
          break;
        }
      }
    }
  }

  Color _getAmplitudeColor() {
    if (_currentAmplitude < 0.3) return Colors.green;
    if (_currentAmplitude < 0.7) return Colors.orange;
    return Colors.red;
  }

  @override
  void dispose() {
    _fileNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Mic Stream Recorder'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // File name input
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Custom Recording Name (Optional)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _fileNameController,
                      enabled: !_isRecording,
                      decoration: const InputDecoration(
                        hintText: 'Enter filename (without extension)',
                        border: OutlineInputBorder(),
                        suffixText: '.m4a',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Recording controls
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Recording Controls',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),

                    // Amplitude meter
                    if (_isRecording) ...[
                      Text(
                        'Audio Level',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: _currentAmplitude,
                        backgroundColor: Colors.grey[300],
                        valueColor:
                            AlwaysStoppedAnimation<Color>(_getAmplitudeColor()),
                        minHeight: 8,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Record button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed:
                            _isRecording ? _stopRecording : _startRecording,
                        icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                        label: Text(_isRecording
                            ? 'Stop Recording'
                            : 'Start Recording'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _isRecording ? Colors.red : Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Playback controls
            if (_lastRecordingPath != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Last Recording Playback',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _isPlaying
                                ? null
                                : () => _playRecording(_lastRecordingPath!),
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Play'),
                          ),
                          ElevatedButton.icon(
                            onPressed: _isPlaying ? _pausePlayback : null,
                            icon: const Icon(Icons.pause),
                            label: const Text('Pause'),
                          ),
                          ElevatedButton.icon(
                            onPressed: _isPlaying ? _stopPlayback : null,
                            icon: const Icon(Icons.stop),
                            label: const Text('Stop'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Recording files list
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recording Files',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          IconButton(
                            onPressed: _loadRecordingFiles,
                            icon: const Icon(Icons.refresh),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _recordingFiles.isEmpty
                            ? const Center(
                                child: Text('No recordings found'),
                              )
                            : ListView.builder(
                                itemCount: _recordingFiles.length,
                                itemBuilder: (context, index) {
                                  final filePath = _recordingFiles[index];
                                  final fileName = filePath.split('/').last;

                                  return ListTile(
                                    leading: const Icon(Icons.audiotrack),
                                    title: Text(fileName),
                                    subtitle: Text(
                                      'File: ${filePath.replaceAll(RegExp(r'.*/'), '')}',
                                    ),
                                    trailing: IconButton(
                                      onPressed: _isPlaying
                                          ? null
                                          : () => _playRecording(filePath),
                                      icon: const Icon(Icons.play_arrow),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
