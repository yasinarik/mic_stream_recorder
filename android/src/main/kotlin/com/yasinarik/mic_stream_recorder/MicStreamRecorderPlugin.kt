package com.yasinarik.mic_stream_recorder

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaPlayer
import android.media.MediaRecorder
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import java.io.File
import java.io.IOException
import kotlin.math.*

// MARK: - Configuration Data Classes

data class RecordingConfig(
    var sampleRate: Int = 44100,
    var channels: Int = 1,
    var bufferSize: Int = 1024,
    var audioQuality: AudioQuality = AudioQuality.HIGH,
    var amplitudeMin: Double = 0.0,
    var amplitudeMax: Double = 1.0
) {
    enum class AudioQuality(val bitRate: Int) {
        MIN(32000),
        LOW(64000),
        MEDIUM(96000),
        HIGH(128000),
        MAX(192000)
    }

    fun getChannelConfig(): Int {
        return if (channels == 1) AudioFormat.CHANNEL_IN_MONO else AudioFormat.CHANNEL_IN_STEREO
    }

    fun getAudioFormat(): Int {
        return AudioFormat.ENCODING_PCM_16BIT
    }
}

/** MicStreamRecorderPlugin */
class MicStreamRecorderPlugin: FlutterPlugin, MethodCallHandler, ActivityAware, 
    PluginRegistry.RequestPermissionsResultListener, EventChannel.StreamHandler {

    // Channels
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    
    // Context and Activity
    private lateinit var context: Context
    private var activityBinding: ActivityPluginBinding? = null
    
    // Recording components
    private var mediaRecorder: MediaRecorder? = null
    private var audioRecord: AudioRecord? = null
    private var mediaPlayer: MediaPlayer? = null
    
    // Configuration
    private var config = RecordingConfig()
    
    // State management
    private var isRecording = false
    private var isMonitoring = false
    
    // Event sink for amplitude
    private var eventSink: EventChannel.EventSink? = null
    
    // File management
    private var currentRecordingFile: File? = null
    
    // Threading
    private val mainHandler = Handler(Looper.getMainLooper())
    private var monitoringThread: Thread? = null
    
    // Permission handling
    private var pendingResult: Result? = null
    private val PERMISSION_REQUEST_CODE = 1001

    private var amplitudeMonitoringHandler: Handler? = null
    private var isAmplitudeMonitoring = false
    private var customFilePath: String? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        
        methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "mic_stream_recorder")
        methodChannel.setMethodCallHandler(this)
        
        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "mic_stream_recorder/amplitude")
        eventChannel.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        stopRecording()
        stopMonitoring()
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityBinding?.removeRequestPermissionsResultListener(this)
        activityBinding = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activityBinding = binding
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivity() {
        activityBinding?.removeRequestPermissionsResultListener(this)
        activityBinding = null
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "start" -> {
                customFilePath = call.arguments as? String
                startRecording(result)
            }
            "stop" -> {
                val filePath = stopRecording()
                result.success(filePath)
            }
            "play" -> {
                val filePath = call.arguments as? String
                if (filePath.isNullOrEmpty()) {
                    result.error("MISSING_ARGUMENT", "File path is required for playback", null)
                } else {
                    playRecording(filePath, result)
                }
            }
            "pausePlayback" -> pausePlayback(result)
            "stopPlayback" -> stopPlayback(result)
            "isPlaying" -> result.success(mediaPlayer?.isPlaying ?: false)
            "configureRecording" -> handleConfigureRecording(call, result)
            "getPlatformVersion" -> result.success("Android ${Build.VERSION.RELEASE}")
            else -> result.notImplemented()
        }
    }

    // MARK: - Event Channel Stream Handler

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    // MARK: - Recording Methods

    private fun startRecording(result: Result) {
        if (isRecording) {
            result.error("ALREADY_RECORDING", "Recording is already in progress", null)
            return
        }

        if (!hasRecordPermission()) {
            pendingResult = result
            requestRecordPermission()
            return
        }

        try {
            setupRecording()
            startAmplitudeMonitoring()
            isRecording = true
            result.success(null)
        } catch (e: Exception) {
            result.error("RECORDING_ERROR", "Failed to start recording: ${e.message}", null)
        }
    }

    private fun stopRecording(): String? {
        if (!isRecording) {
            return null
        }

        try {
            mediaRecorder?.apply {
                stop()
                release()
            }
            mediaRecorder = null
            
            stopMonitoring()
            isRecording = false
            
            val filePath = getFilePath()
            return filePath
        } catch (e: Exception) {
            return null
        }
    }

    private fun setupRecording() {
        // Create recording file
        val fileName = "mic_stream_recording.m4a"
        currentRecordingFile = File(context.cacheDir, fileName)

        // Setup MediaRecorder
        mediaRecorder = MediaRecorder().apply {
            setAudioSource(MediaRecorder.AudioSource.MIC)
            setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
            setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
            setAudioSamplingRate(config.sampleRate)
            setAudioChannels(config.channels)
            setAudioEncodingBitRate(config.audioQuality.bitRate)
            setOutputFile(getFilePath())
            
            prepare()
            start()
        }
    }

    // MARK: - Amplitude Monitoring

    private fun startAmplitudeMonitoring() {
        if (isMonitoring) return

        try {
            val minBufferSize = AudioRecord.getMinBufferSize(
                config.sampleRate,
                config.getChannelConfig(),
                config.getAudioFormat()
            )
            
            val bufferSize = maxOf(minBufferSize, config.bufferSize)

            audioRecord = AudioRecord(
                MediaRecorder.AudioSource.MIC,
                config.sampleRate,
                config.getChannelConfig(),
                config.getAudioFormat(),
                bufferSize
            )

            audioRecord?.startRecording()
            isMonitoring = true

            monitoringThread = Thread {
                val buffer = ShortArray(bufferSize)
                
                while (isMonitoring && !Thread.currentThread().isInterrupted) {
                    try {
                        val bytesRead = audioRecord?.read(buffer, 0, buffer.size) ?: 0
                        if (bytesRead > 0) {
                            val amplitude = calculateAmplitude(buffer, bytesRead)
                            
                            mainHandler.post {
                                eventSink?.success(amplitude)
                            }
                        }
                        
                        Thread.sleep(50) // Update frequency: ~20 FPS
                    } catch (e: Exception) {
                        break
                    }
                }
            }
            
            monitoringThread?.start()
            
        } catch (e: Exception) {
            // Handle AudioRecord creation failure
            isMonitoring = false
        }
    }

    private fun stopMonitoring() {
        isMonitoring = false
        
        monitoringThread?.apply {
            interrupt()
            try {
                join(1000) // Wait up to 1 second
            } catch (e: InterruptedException) {
                // Handle interruption
            }
        }
        monitoringThread = null

        audioRecord?.apply {
            try {
                stop()
                release()
            } catch (e: Exception) {
                // Handle stop/release failure
            }
        }
        audioRecord = null
    }

    private fun calculateAmplitude(buffer: ShortArray, length: Int): Double {
        var sum = 0.0
        for (i in 0 until length) {
            sum += (buffer[i] * buffer[i]).toDouble()
        }
        
        val rms = sqrt(sum / length)
        val db = 20 * log10(rms + 1) // Add 1 to avoid log(0)
        
        // Normalize to 0.0 - 1.0 range first
        val normalizedDb = maxOf(0.0, minOf(80.0, db)) // Clamp between 0-80 dB
        val baseNormalized = normalizedDb / 80.0
        
        // Apply custom range normalization
        return config.amplitudeMin + (baseNormalized * (config.amplitudeMax - config.amplitudeMin))
    }

    // MARK: - Playback Methods

    private fun playRecording(filePath: String, result: Result) {
        val fileToPlay = File(filePath)

        if (!fileToPlay.exists()) {
            result.error("FILE_NOT_FOUND", "Audio file does not exist at ${fileToPlay.absolutePath}", null)
            return
        }

        try {
            mediaPlayer?.release()
            mediaPlayer = MediaPlayer().apply {
                setDataSource(fileToPlay.absolutePath)
                prepare()
                start()
                
                setOnCompletionListener {
                    release()
                    mediaPlayer = null
                }
            }
            
            result.success(null)
        } catch (e: Exception) {
            result.error("PLAYBACK_ERROR", "Failed to play recording: ${e.message}", null)
        }
    }

    private fun pausePlayback(result: Result) {
        try {
            mediaPlayer?.pause()
            result.success(null)
        } catch (e: Exception) {
            result.error("PAUSE_ERROR", "Failed to pause playback: ${e.message}", null)
        }
    }

    private fun stopPlayback(result: Result) {
        try {
            mediaPlayer?.apply {
                stop()
                release()
            }
            mediaPlayer = null
            result.success(null)
        } catch (e: Exception) {
            result.error("STOP_PLAYBACK_ERROR", "Failed to stop playback: ${e.message}", null)
        }
    }

    // MARK: - Configuration

    private fun handleConfigureRecording(call: MethodCall, result: Result) {
        if (call.arguments == null) {
            result.error("INVALID_ARGUMENTS", "Configuration arguments are required", null)
            return
        }

        try {
            @Suppress("UNCHECKED_CAST")
            val args = call.arguments as? Map<String, Any> ?: return
            
            args["sampleRate"]?.let { 
                val sampleRate = (it as? Number)?.toInt() ?: config.sampleRate
                if (isValidSampleRate(sampleRate)) {
                    config.sampleRate = sampleRate
                }
            }

            args["channels"]?.let {
                val channels = (it as? Number)?.toInt() ?: config.channels
                config.channels = maxOf(1, minOf(2, channels)) // Clamp to 1-2
            }

            args["bufferSize"]?.let {
                val bufferSize = (it as? Number)?.toInt() ?: config.bufferSize
                if (isValidBufferSize(bufferSize)) {
                    config.bufferSize = bufferSize
                }
            }

            args["audioQuality"]?.let {
                val qualityIndex = (it as? Number)?.toInt() ?: 3
                config.audioQuality = when (qualityIndex) {
                    0 -> RecordingConfig.AudioQuality.MIN
                    1 -> RecordingConfig.AudioQuality.LOW
                    2 -> RecordingConfig.AudioQuality.MEDIUM
                    3 -> RecordingConfig.AudioQuality.HIGH
                    4 -> RecordingConfig.AudioQuality.MAX
                    else -> RecordingConfig.AudioQuality.HIGH
                }
            }

            args["amplitudeMin"]?.let {
                val amplitudeMin = (it as? Number)?.toDouble() ?: 0.0
                config.amplitudeMin = amplitudeMin
            }

            args["amplitudeMax"]?.let {
                val amplitudeMax = (it as? Number)?.toDouble() ?: 1.0
                config.amplitudeMax = amplitudeMax
            }

            result.success(null)
        } catch (e: Exception) {
            result.error("CONFIGURATION_ERROR", "Failed to configure recording: ${e.message}", null)
        }
    }

    private fun isValidSampleRate(sampleRate: Int): Boolean {
        val validRates = listOf(8000, 16000, 22050, 44100, 48000)
        return validRates.contains(sampleRate)
    }

    private fun isValidBufferSize(bufferSize: Int): Boolean {
        val validSizes = listOf(128, 256, 512, 1024, 2048, 4096)
        return validSizes.contains(bufferSize)
    }

    // MARK: - Permission Handling

    private fun hasRecordPermission(): Boolean {
        return ActivityCompat.checkSelfPermission(
            context,
            Manifest.permission.RECORD_AUDIO
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun requestRecordPermission() {
        activityBinding?.activity?.let { activity ->
            ActivityCompat.requestPermissions(
                activity,
                arrayOf(Manifest.permission.RECORD_AUDIO),
                PERMISSION_REQUEST_CODE
            )
        } ?: run {
            pendingResult?.error("NO_ACTIVITY", "No activity available for permission request", null)
            pendingResult = null
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ): Boolean {
        if (requestCode == PERMISSION_REQUEST_CODE) {
            val granted = grantResults.isNotEmpty() && 
                         grantResults[0] == PackageManager.PERMISSION_GRANTED
            
            if (granted) {
                // Retry the recording start
                pendingResult?.let { result ->
                    startRecording(result)
                }
            } else {
                pendingResult?.error("PERMISSION_DENIED", "Microphone permission denied", null)
            }
            
            pendingResult = null
            return true
        }
        return false
    }

    private fun getFilePath(): String {
        return customFilePath ?: File(context.cacheDir, "mic_stream_recording.m4a").absolutePath
    }
} 