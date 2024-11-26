import AVFoundation

class AudioRecorder: NSObject, AVAudioRecorderDelegate {
    var audioRecorder: AVAudioRecorder?
    var recordingTimer: Timer?
    var condensedTranscript: String
    var isStopping: Bool = false
    var isFirstRecording: Bool = true // Track the first recording
    
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
            try audioSession.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
            try audioSession.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }

    func startRecordingAudio() {
        let audioFilename = getDocumentsDirectory().appendingPathComponent("recording.wav")

        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
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
        
        DispatchQueue.global().asyncAfter(deadline: .now() + 0) {
            
            let audioFilePath = self.getDocumentsDirectory().appendingPathComponent("recording.wav")

            processWavFile(filePath: audioFilePath.path, condensedTranscript: self.condensedTranscript) { response in
                print("Processing response: \(response)")

                DispatchQueue.main.async {
                    if !self.isStopping {
                        self.clearAudioFileIfExists()
                        self.startRecordingAudio()
                    }
                }
            }
        }
    }
    
    //made a new function to clear audio file
    func clearAudioFileIfExists() {
        let audioFilePath = getDocumentsDirectory().appendingPathComponent("recording.wav")
        if FileManager.default.fileExists(atPath: audioFilePath.path) {
            do {
                try FileManager.default.removeItem(at: audioFilePath)
                print("Audio file cleared at path: \(audioFilePath.path)")
            } catch {
                print("Failed to clear audio file: \(error)")
            }
        }
    }


    func stopRecording() {
        isStopping = true

        recordingTimer?.invalidate()
        recordingTimer = nil

        audioRecorder?.stop()
        print("Recording stopped.")

        // Get the path of the recording file
//        let audioFilePath = getDocumentsDirectory().appendingPathComponent("recording.wav")

        // Check if the file exists
//        if FileManager.default.fileExists(atPath: audioFilePath.path) {
//            print("Recording saved at: \(audioFilePath.path)")
//            return audioFilePath.path
//        } else {
//            print("Recording file not found.")
//            return nil
//        }
    }

    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}

