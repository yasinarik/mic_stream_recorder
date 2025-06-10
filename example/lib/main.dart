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
  final _recorder = MicStreamRecorder();
  final _fileNameController = TextEditingController();

  bool _isRecording = false;
  bool _isPlaying = false;
  double _currentAmplitude = 0.0;
  String? _lastRecordingPath;
  List<String> _recordingFiles = [];
  RangeValues _amplitudeRange = const RangeValues(0.0, 100.0);

  @override
  void initState() {
    super.initState();
    _recorder.amplitudeStream.listen((amplitude) {
      if (mounted) setState(() => _currentAmplitude = amplitude);
    });
    _loadRecordingFiles();
  }

  @override
  void dispose() {
    _fileNameController.dispose();
    super.dispose();
  }

  // Core functionality methods
  Future<void> _loadRecordingFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory
          .listSync()
          .where((file) => file.path.endsWith('.m4a'))
          .map((file) => file.path)
          .toList();
      setState(() => _recordingFiles = files);
    } catch (e) {
      _showMessage('Failed to load files: $e', isError: true);
    }
  }

  Future<void> _updateAmplitudeRange() async {
    try {
      await _recorder.configureRecording(
        amplitudeMin: _amplitudeRange.start / 100.0,
        amplitudeMax: _amplitudeRange.end / 100.0,
      );
    } catch (e) {
      _showMessage('Failed to update range: $e', isError: true);
    }
  }

  Future<void> _startRecording() async {
    if (_isRecording) return;
    try {
      await _updateAmplitudeRange();
      String? customPath;
      if (_fileNameController.text.isNotEmpty) {
        final directory = await getApplicationDocumentsDirectory();
        customPath = '${directory.path}/${_fileNameController.text}.m4a';
        _showMessage('Recording: ${_fileNameController.text}.m4a');
      }
      await _recorder.startRecording(customPath);
      setState(() => _isRecording = true);
    } catch (e) {
      _showMessage('Failed to start recording: $e', isError: true);
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;
    try {
      final recordingPath = await _recorder.stopRecording();
      setState(() {
        _isRecording = false;
        _lastRecordingPath = recordingPath;
        _currentAmplitude = 0.0;
      });
      _fileNameController.clear();
      await _loadRecordingFiles();
      _showMessage('Recording saved');
    } catch (e) {
      _showMessage('Failed to stop recording: $e', isError: true);
    }
  }

  Future<void> _playRecording(String filePath) async {
    try {
      await _recorder.playRecording(filePath);
      setState(() => _isPlaying = true);
      _checkPlayingStatus();
    } catch (e) {
      _showMessage('Failed to play: $e', isError: true);
    }
  }

  Future<void> _pausePlayback() async {
    try {
      await _recorder.pausePlayback();
      setState(() => _isPlaying = false);
    } catch (e) {
      _showMessage('Failed to pause: $e', isError: true);
    }
  }

  Future<void> _stopPlayback() async {
    try {
      await _recorder.stopPlayback();
      setState(() => _isPlaying = false);
    } catch (e) {
      _showMessage('Failed to stop: $e', isError: true);
    }
  }

  void _checkPlayingStatus() async {
    while (_isPlaying && mounted) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        final isPlaying = await _recorder.isPlaying();
        if (!isPlaying && _isPlaying) {
          setState(() => _isPlaying = false);
          break;
        }
      }
    }
  }

  // UI helper methods
  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Color _getAmplitudeColor(double amplitude) {
    final progress = _getAmplitudeProgress(amplitude);
    if (progress < 0.3) return Colors.green;
    if (progress < 0.7) return Colors.orange;
    return Colors.red;
  }

  double _getAmplitudeProgress(double amplitude) {
    final minPercent = _amplitudeRange.start / 100.0;
    final maxPercent = _amplitudeRange.end / 100.0;
    if (maxPercent == minPercent) return 0.0;
    final clampedAmplitude = amplitude.clamp(minPercent, maxPercent);
    return ((clampedAmplitude - minPercent) / (maxPercent - minPercent))
        .clamp(0.0, 1.0);
  }

  void _setAmplitudeRange(double start, double end) {
    setState(() => _amplitudeRange = RangeValues(start, end));
    _updateAmplitudeRange();
  }

  // Reusable UI components
  Widget _buildCard({
    required String title,
    required Widget child,
    Widget? trailingItem,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                if (trailingItem != null) trailingItem,
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildFileNameInput() {
    return _buildCard(
      title: 'Custom Recording Name (Optional)',
      child: TextField(
        controller: _fileNameController,
        enabled: !_isRecording,
        decoration: const InputDecoration(
          hintText: 'Enter filename (without extension)',
          border: OutlineInputBorder(),
          suffixText: '.m4a',
        ),
      ),
    );
  }

  Widget _buildAmplitudeRangeSlider() {
    return _buildCard(
      title: 'Amplitude Range',
      child: Column(
        children: [
          Text(
            'Min: ${_amplitudeRange.start.toStringAsFixed(1)}% | Max: ${_amplitudeRange.end.toStringAsFixed(1)}%',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          RangeSlider(
            values: _amplitudeRange,
            min: 0.0,
            max: 100.0,
            divisions: 100,
            labels: RangeLabels(
              '${_amplitudeRange.start.toStringAsFixed(1)}%',
              '${_amplitudeRange.end.toStringAsFixed(1)}%',
            ),
            onChanged: _isRecording
                ? null
                : (values) => setState(() => _amplitudeRange = values),
            onChangeEnd: _isRecording ? null : (_) => _updateAmplitudeRange(),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _buildPresetButton(
                  'Full 0-100%', () => _setAmplitudeRange(0.0, 100.0)),
              _buildPresetButton(
                  'Mid 20-80%', () => _setAmplitudeRange(20.0, 80.0)),
              _buildPresetButton(
                  'Focus 30-70%', () => _setAmplitudeRange(30.0, 70.0)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPresetButton(String label, VoidCallback onPressed) {
    return TextButton(
      onPressed: _isRecording ? null : onPressed,
      child: Text(label),
    );
  }

  Widget _buildRecordingControls() {
    return _buildCard(
      title: 'Recording Controls',
      child: Column(
        children: [
          if (_isRecording) ...[
            Text(
              'Audio Level: ${(_currentAmplitude * 100).toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: _getAmplitudeProgress(_currentAmplitude),
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                  _getAmplitudeColor(_currentAmplitude)),
              minHeight: 8,
            ),
            const SizedBox(height: 16),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isRecording ? _stopRecording : _startRecording,
              icon: Icon(_isRecording ? Icons.stop : Icons.mic),
              label: Text(_isRecording ? 'Stop Recording' : 'Start Recording'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isRecording ? Colors.red : Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaybackControls() {
    if (_lastRecordingPath == null) return const SizedBox.shrink();

    return _buildCard(
      title: 'Last Recording Playback',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildPlaybackButton(
            icon: Icons.play_arrow,
            label: 'Play',
            onPressed:
                _isPlaying ? null : () => _playRecording(_lastRecordingPath!),
          ),
          _buildPlaybackButton(
            icon: Icons.pause,
            label: 'Pause',
            onPressed: _isPlaying ? _pausePlayback : null,
          ),
          _buildPlaybackButton(
            icon: Icons.stop,
            label: 'Stop',
            onPressed: _isPlaying ? _stopPlayback : null,
          ),
        ],
      ),
    );
  }

  Widget _buildPlaybackButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }

  Widget _buildFilesList() {
    return _buildCard(
      title: 'Recorded Files',
      trailingItem: IconButton(
        onPressed: _loadRecordingFiles,
        icon: const Icon(Icons.refresh),
      ),
      child: Column(
        children: [
          _recordingFiles.isEmpty
              ? const Center(child: Text('No recordings found'))
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _recordingFiles.length,
                  itemBuilder: (context, index) {
                    final filePath = _recordingFiles[index];
                    final fileName = filePath.split('/').last;
                    return ListTile(
                      leading: const Icon(Icons.audiotrack),
                      title: Text(fileName),
                      trailing: IconButton(
                        onPressed:
                            _isPlaying ? null : () => _playRecording(filePath),
                        icon: const Icon(Icons.play_arrow),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Mic Stream Recorder'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildFileNameInput(),
            const SizedBox(height: 16),
            _buildAmplitudeRangeSlider(),
            const SizedBox(height: 16),
            _buildRecordingControls(),
            const SizedBox(height: 16),
            _buildPlaybackControls(),
            const SizedBox(height: 16),
            _buildFilesList(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
