import AVFoundation

class AudioRecorder: NSObject, AVAudioRecorderDelegate {
    var audioRecorder: AVAudioRecorder?
    var recordingTimer: Timer?
    var condensedTranscript: String
    var isStopping: Bool = false
    var currentAudioFilename: URL?

    init(condensedTranscript: String) {
        self.condensedTranscript = condensedTranscript
        super.init()
    }

    func startRecording() {
        AVAudioApplication.requestRecordPermission { granted in
            guard granted else {
                print("Permission to record not granted.")
                return
            }
            DispatchQueue.main.async {
                self.setupRecordingSession()
                self.startRecordingAudio()
            }
        }
    }

    func setupRecordingSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }

    func startRecordingAudio() {
        // Generate a unique filename for each recording
        currentAudioFilename = getDocumentsDirectory().appendingPathComponent("recording_\(Date().timeIntervalSince1970).wav")

        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: currentAudioFilename!, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            print("Recording started.")

            // Set up a timer to rerecord every ten seconds
            recordingTimer?.invalidate()
            recordingTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { _ in
                self.restartRecording()
            }
        } catch {
            print("Could not start recording: \(error)")
        }
    }

    func restartRecording() {
        print("Restarting recording...")
        audioRecorder?.stop()
        // The rest is handled in the delegate method
    }

    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        guard flag else {
            print("Recording failed.")
            if !isStopping {
                startRecordingAudio()
            }
            return
        }

        // Start new recording immediately to minimize gaps
        if !isStopping {
            startRecordingAudio()
        }

        // Process the audio file in the background
        DispatchQueue.global(qos: .background).async {
            let audioFilePath = recorder.url
            processWavFile(filePath: audioFilePath.path, condensedTranscript: self.condensedTranscript) { response in
                print("Processing response: \(response)")
                // Handle UI updates if necessary on the main thread
                DispatchQueue.main.async {
                    // Update UI here
                }
                // Optionally delete the processed file to save space
                self.deleteAudioFile(at: audioFilePath)
            }
        }
    }

    func deleteAudioFile(at url: URL) {
        if FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.removeItem(at: url)
                print("Deleted audio file at path: \(url.path)")
            } catch {
                print("Failed to delete audio file: \(error)")
            }
        }
    }

    func stopRecording() {
        isStopping = true

        recordingTimer?.invalidate()
        recordingTimer = nil

        audioRecorder?.stop()
        print("Recording stopped.")
    }

    func getDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
