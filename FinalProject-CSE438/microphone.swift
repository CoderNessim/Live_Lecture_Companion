import AVFoundation

class AudioRecorder: NSObject, AVAudioRecorderDelegate {
    var audioRecorder: AVAudioRecorder?
    var recordingTimer: Timer?

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
            
            // timer will rerecord every ten seconds
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
        
        //  record again and overwrite the same file
        startRecordingAudio()
    }

    func stopRecording() {
        recordingTimer?.invalidate()
        audioRecorder?.stop()
        print("Recording stopped.")
        
        let audioFilePath = getDocumentsDirectory().appendingPathComponent("recording.wav")
        print("Recording saved at: \(audioFilePath.path)")
    }

    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}
