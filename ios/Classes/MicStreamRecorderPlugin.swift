import AVFoundation
import Accelerate
import Flutter
import UIKit

// MARK: - Configuration Structures

struct RecordingConfig {
  var sampleRate: Double
  var channels: Int
  var bufferSize: Int
  var audioQuality: AVAudioQuality

  static let `default` = RecordingConfig(
    sampleRate: 44100,  // Use more standard sample rate
    channels: 1,
    bufferSize: 128,
    audioQuality: .high
  )
}

extension AVAudioQuality {
  init(from index: Int) {
    switch index {
    case 0: self = .min
    case 1: self = .low
    case 2: self = .medium
    case 3: self = .high
    case 4: self = .max
    default: self = .low
    }
  }
}

public class MicStreamRecorderPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private var audioEngine: AVAudioEngine?
  private var audioRecorder: AVAudioRecorder?
  private var audioPlayer: AVAudioPlayer?
  private var eventSink: FlutterEventSink?
  private var config = RecordingConfig.default

  private let amplitudeQueue = DispatchQueue(label: "amplitude.queue")

  private var customFilePath: String?

  private var tempFileURL: URL {
    if let customPath = customFilePath {
      return URL(fileURLWithPath: customPath)
    } else {
      let dir = FileManager.default.temporaryDirectory
      return dir.appendingPathComponent("mic_stream_recording.m4a")
    }
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = MicStreamRecorderPlugin()

    let methodChannel = FlutterMethodChannel(
      name: "mic_stream_recorder", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(instance, channel: methodChannel)

    let eventChannel = FlutterEventChannel(
      name: "mic_stream_recorder/amplitude", binaryMessenger: registrar.messenger())
    eventChannel.setStreamHandler(instance)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "start":
      let filePath = call.arguments as? String
      startSession(filePath: filePath)
      result(nil)
    case "stop":
      stopSession()
      result(tempFileURL.path)
    case "play":
      if let filePath = call.arguments as? String {
        playRecording(filePath: filePath)
        result(nil)
      } else {
        result(
          FlutterError(
            code: "MISSING_ARGUMENT",
            message: "File path is required for playback",
            details: nil))
      }
    case "pausePlayback":
      pausePlayback()
      result(nil)
    case "stopPlayback":
      stopPlayback()
      result(nil)
    case "isPlaying":
      result(audioPlayer?.isPlaying ?? false)
    case "configureRecording":
      handleConfigureRecording(call: call, result: result)
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func handleConfigureRecording(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any] else {
      result(
        FlutterError(
          code: "INVALID_ARGUMENTS", message: "Invalid configuration arguments",
          details: nil))
      return
    }

    do {
      // Update configuration with provided values
      if let sampleRate = args["sampleRate"] as? Double {
        // Validate sample rate
        let validSampleRates: [Double] = [8000, 16000, 22050, 44100, 48000]
        if validSampleRates.contains(sampleRate) {
          config.sampleRate = sampleRate
        }
      }

      if let channels = args["channels"] as? Int {
        config.channels = max(1, min(2, channels))  // Clamp to 1-2 channels
      }

      if let bufferSize = args["bufferSize"] as? Int {
        // Validate buffer size
        let validBufferSizes = [128, 256, 512, 1024]
        if validBufferSizes.contains(bufferSize) {
          config.bufferSize = bufferSize
        }
      }

      if let audioQualityIndex = args["audioQuality"] as? Int {
        config.audioQuality = AVAudioQuality(from: audioQualityIndex)
      }

      print("Recording configuration updated: \(config)")
      result(nil)
    } catch {
      result(
        FlutterError(
          code: "CONFIGURATION_ERROR",
          message: "Failed to configure recording: \(error.localizedDescription)",
          details: nil))
    }
  }

  public func onListen(withArguments args: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
    eventSink = events
    return nil
  }

  public func onCancel(withArguments args: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }

  private func startSession(filePath: String?) {
    customFilePath = filePath
    requestMicPermission { [weak self] granted in
      guard granted, let self = self else { return }

      DispatchQueue.main.async {
        self.setupAudioSession()
        self.setupRecorder()
        self.setupEngine()
      }
    }
  }

  private func stopSession() {
    audioEngine?.stop()
    audioEngine?.inputNode.removeTap(onBus: 0)
    audioEngine = nil

    audioRecorder?.stop()
    audioRecorder = nil
  }

  private func setupAudioSession() {
    do {
      let audioSession = AVAudioSession.sharedInstance()
      try audioSession.setCategory(
        .playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
      try audioSession.setActive(true)
    } catch {
      print("Error setting up audio session: \(error)")
    }
  }

  private func setupEngine() {
    do {
      audioEngine = AVAudioEngine()
      guard let engine = audioEngine else { return }

      let input = engine.inputNode
      let inputFormat = input.inputFormat(forBus: 0)

      // Log hardware capabilities for debugging
      print(
        "Hardware input format - Sample Rate: \(inputFormat.sampleRate), Channels: \(inputFormat.channelCount)"
      )
      print(
        "Recording config - Sample Rate: \(config.sampleRate), Channels: \(config.channels)"
      )

      // Use configurable buffer size
      input.installTap(
        onBus: 0, bufferSize: AVAudioFrameCount(config.bufferSize), format: inputFormat
      ) {
        [weak self] buffer, _ in
        self?.processBuffer(buffer: buffer)
      }

      try engine.start()
      print("Audio engine started successfully with buffer size: \(config.bufferSize)")
    } catch {
      print("Error setting up audio engine: \(error)")
    }
  }

  private func processBuffer(buffer: AVAudioPCMBuffer) {
    amplitudeQueue.async {
      guard let channelData = buffer.floatChannelData?[0] else { return }
      let frameLength = Int(buffer.frameLength)

      // Convert Float data to Double for consistent processing
      var doubleData = [Double](repeating: 0.0, count: frameLength)
      for i in 0..<frameLength {
        doubleData[i] = Double(channelData[i])
      }

      var rms: Double = 0
      vDSP_measqvD(doubleData, 1, &rms, vDSP_Length(frameLength))
      let db = (20 * log10(sqrt(rms))).clamped(to: -80...0)

      // Normalize to 0.0-1.0 range
      let normalizedAmplitude = (db + 80) / 80.0

      DispatchQueue.main.async {
        self.eventSink?(normalizedAmplitude)
      }
    }
  }

  private func setupRecorder() {
    var settings: [String: Any] = [
      AVFormatIDKey: kAudioFormatMPEG4AAC,
      AVSampleRateKey: config.sampleRate,
      AVNumberOfChannelsKey: config.channels,
      AVEncoderAudioQualityKey: config.audioQuality.rawValue,
    ]

    do {
      audioRecorder = try AVAudioRecorder(url: tempFileURL, settings: settings)
      audioRecorder?.prepareToRecord()
      audioRecorder?.record()
      print("Recorder started with settings: \(settings)")
    } catch {
      print("Failed to start recorder: \(error)")
    }
  }

  private func requestMicPermission(completion: @escaping (Bool) -> Void) {
    switch AVAudioSession.sharedInstance().recordPermission {
    case .granted:
      completion(true)
    case .denied:
      completion(false)
    case .undetermined:
      AVAudioSession.sharedInstance().requestRecordPermission { granted in
        DispatchQueue.main.async {
          completion(granted)
        }
      }
    @unknown default:
      completion(false)
    }
  }

  // MARK: - Playback Methods

  private func playRecording(filePath: String) {
    let fileURL = URL(fileURLWithPath: filePath)

    guard FileManager.default.fileExists(atPath: fileURL.path) else {
      print("Audio file does not exist at path: \(fileURL.path)")
      return
    }

    do {
      audioPlayer = try AVAudioPlayer(contentsOf: fileURL)
      audioPlayer?.prepareToPlay()
      audioPlayer?.play()
      print("Started playing audio from: \(fileURL.path)")
    } catch {
      print("Failed to play audio: \(error)")
    }
  }

  private func pausePlayback() {
    audioPlayer?.pause()
  }

  private func stopPlayback() {
    audioPlayer?.stop()
    audioPlayer = nil
  }
}

// Utility clamp extension
extension Comparable {
  func clamped(to limits: ClosedRange<Self>) -> Self {
    return min(max(self, limits.lowerBound), limits.upperBound)
  }
}
