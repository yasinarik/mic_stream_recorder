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
            FileNameInputCard(
              controller: _fileNameController,
              isRecording: _isRecording,
            ),
            const SizedBox(height: 16),
            AmplitudeRangeCard(
              amplitudeRange: _amplitudeRange,
              isRecording: _isRecording,
              onRangeChanged: (values) =>
                  setState(() => _amplitudeRange = values),
              onRangeChangeEnd: (_) => _updateAmplitudeRange(),
              onPresetSelected: _setAmplitudeRange,
            ),
            const SizedBox(height: 16),
            RecordingControlsCard(
              isRecording: _isRecording,
              currentAmplitude: _currentAmplitude,
              amplitudeProgress: _getAmplitudeProgress(_currentAmplitude),
              amplitudeColor: _getAmplitudeColor(_currentAmplitude),
              onStartRecording: _startRecording,
              onStopRecording: _stopRecording,
            ),
            const SizedBox(height: 16),
            if (_lastRecordingPath != null)
              PlaybackControlsCard(
                isPlaying: _isPlaying,
                onPlay: () => _playRecording(_lastRecordingPath!),
                onPause: _pausePlayback,
                onStop: _stopPlayback,
              ),
            const SizedBox(height: 16),
            RecordingFilesCard(
              recordingFiles: _recordingFiles,
              isPlaying: _isPlaying,
              onRefresh: _loadRecordingFiles,
              onPlayFile: _playRecording,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// Reusable card wrapper widget
class CardWrapper extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailingItem;

  const CardWrapper({
    super.key,
    required this.title,
    required this.child,
    this.trailingItem,
  });

  @override
  Widget build(BuildContext context) {
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
                if (trailingItem != null) trailingItem!,
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

// File name input widget
class FileNameInputCard extends StatelessWidget {
  final TextEditingController controller;
  final bool isRecording;

  const FileNameInputCard({
    super.key,
    required this.controller,
    required this.isRecording,
  });

  @override
  Widget build(BuildContext context) {
    return CardWrapper(
      title: 'Custom Recording Name (Optional)',
      child: TextField(
        controller: controller,
        enabled: !isRecording,
        decoration: const InputDecoration(
          hintText: 'Enter filename (without extension)',
          border: OutlineInputBorder(),
          suffixText: '.m4a',
        ),
      ),
    );
  }
}

// Amplitude range slider widget
class AmplitudeRangeCard extends StatelessWidget {
  final RangeValues amplitudeRange;
  final bool isRecording;
  final ValueChanged<RangeValues> onRangeChanged;
  final ValueChanged<RangeValues> onRangeChangeEnd;
  final Function(double, double) onPresetSelected;

  const AmplitudeRangeCard({
    super.key,
    required this.amplitudeRange,
    required this.isRecording,
    required this.onRangeChanged,
    required this.onRangeChangeEnd,
    required this.onPresetSelected,
  });

  @override
  Widget build(BuildContext context) {
    return CardWrapper(
      title: 'Amplitude Range',
      child: Column(
        children: [
          Text(
            'Min: ${amplitudeRange.start.toStringAsFixed(1)}% | Max: ${amplitudeRange.end.toStringAsFixed(1)}%',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          RangeSlider(
            values: amplitudeRange,
            min: 0.0,
            max: 100.0,
            divisions: 100,
            labels: RangeLabels(
              '${amplitudeRange.start.toStringAsFixed(1)}%',
              '${amplitudeRange.end.toStringAsFixed(1)}%',
            ),
            onChanged: isRecording ? null : onRangeChanged,
            onChangeEnd: isRecording ? null : onRangeChangeEnd,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              PresetButton(
                label: 'Full 0-100%',
                isEnabled: !isRecording,
                onPressed: () => onPresetSelected(0.0, 100.0),
              ),
              PresetButton(
                label: 'Mid 20-80%',
                isEnabled: !isRecording,
                onPressed: () => onPresetSelected(20.0, 80.0),
              ),
              PresetButton(
                label: 'Focus 30-70%',
                isEnabled: !isRecording,
                onPressed: () => onPresetSelected(30.0, 70.0),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Preset button widget
class PresetButton extends StatelessWidget {
  final String label;
  final bool isEnabled;
  final VoidCallback onPressed;

  const PresetButton({
    super.key,
    required this.label,
    required this.isEnabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: isEnabled ? onPressed : null,
      child: Text(label),
    );
  }
}

// Recording controls widget
class RecordingControlsCard extends StatelessWidget {
  final bool isRecording;
  final double currentAmplitude;
  final double amplitudeProgress;
  final Color amplitudeColor;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;

  const RecordingControlsCard({
    super.key,
    required this.isRecording,
    required this.currentAmplitude,
    required this.amplitudeProgress,
    required this.amplitudeColor,
    required this.onStartRecording,
    required this.onStopRecording,
  });

  @override
  Widget build(BuildContext context) {
    return CardWrapper(
      title: 'Recording Controls',
      child: Column(
        children: [
          if (isRecording) ...[
            Text(
              'Audio Level: ${(currentAmplitude * 100).toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: amplitudeProgress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(amplitudeColor),
              minHeight: 8,
            ),
            const SizedBox(height: 16),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isRecording ? onStopRecording : onStartRecording,
              icon: Icon(isRecording ? Icons.stop : Icons.mic),
              label: Text(isRecording ? 'Stop Recording' : 'Start Recording'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isRecording ? Colors.red : Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Playback controls widget
class PlaybackControlsCard extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final VoidCallback onStop;

  const PlaybackControlsCard({
    super.key,
    required this.isPlaying,
    required this.onPlay,
    required this.onPause,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return CardWrapper(
      title: 'Last Recording Playback',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          PlaybackButton(
            icon: Icons.play_arrow,
            label: 'Play',
            onPressed: isPlaying ? null : onPlay,
          ),
          PlaybackButton(
            icon: Icons.pause,
            label: 'Pause',
            onPressed: isPlaying ? onPause : null,
          ),
          PlaybackButton(
            icon: Icons.stop,
            label: 'Stop',
            onPressed: isPlaying ? onStop : null,
          ),
        ],
      ),
    );
  }
}

// Playback button widget
class PlaybackButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const PlaybackButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

// Recording files list widget
class RecordingFilesCard extends StatelessWidget {
  final List<String> recordingFiles;
  final bool isPlaying;
  final VoidCallback onRefresh;
  final Function(String) onPlayFile;

  const RecordingFilesCard({
    super.key,
    required this.recordingFiles,
    required this.isPlaying,
    required this.onRefresh,
    required this.onPlayFile,
  });

  @override
  Widget build(BuildContext context) {
    return CardWrapper(
      title: 'Recorded Files',
      trailingItem: IconButton(
        onPressed: onRefresh,
        icon: const Icon(Icons.refresh),
      ),
      child: recordingFiles.isEmpty
          ? const Center(child: Text('No recordings found'))
          : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recordingFiles.length,
              itemBuilder: (context, index) {
                final filePath = recordingFiles[index];
                final fileName = filePath.split('/').last;
                return ListTile(
                  leading: const Icon(Icons.audiotrack),
                  title: Text(fileName),
                  trailing: IconButton(
                    onPressed: isPlaying ? null : () => onPlayFile(filePath),
                    icon: const Icon(Icons.play_arrow),
                  ),
                );
              },
            ),
    );
  }
}
