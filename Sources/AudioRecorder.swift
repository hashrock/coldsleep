import AVFoundation

class AudioRecorder {
    static var saveDirectory: URL {
        let path = UserDefaults.standard.string(forKey: "savePath")
            ?? "~/Dropbox/Recordings"
        let expanded = NSString(string: path).expandingTildeInPath
        let url = URL(fileURLWithPath: expanded)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private var audioRecorder: AVAudioRecorder?

    func startRecording() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let fileName = formatter.string(from: Date())
        let url = Self.saveDirectory.appendingPathComponent("\(fileName).m4a")

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.record()
            print("録音開始: \(url.lastPathComponent)")
        } catch {
            print("録音エラー: \(error)")
        }
    }

    @discardableResult
    func stopRecording() -> URL? {
        guard let recorder = audioRecorder else { return nil }
        let url = recorder.url
        recorder.stop()
        audioRecorder = nil
        print("録音終了: \(url.lastPathComponent)")
        return url
    }
}
