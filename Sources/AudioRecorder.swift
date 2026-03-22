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

    static var tempDirectory: URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Coldsleep")
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private var audioRecorder: AVAudioRecorder?
    private(set) var currentFileName: String?

    func startRecording() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        currentFileName = formatter.string(from: Date())
        let url = Self.tempDirectory.appendingPathComponent("\(currentFileName!).m4a")

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

    /// 録音を停止し、一時ディレクトリ上の音声ファイルURLを返す（まだ移動しない）
    @discardableResult
    func stopRecording() -> URL? {
        guard let recorder = audioRecorder else { return nil }
        let url = recorder.url
        recorder.stop()
        audioRecorder = nil
        print("録音終了: \(url.lastPathComponent)")
        return url
    }

    /// ファイル名に使えない文字を除去してサニタイズする
    static func sanitizeForFileName(_ text: String, maxLength: Int = 100) -> String {
        let truncated = String(text.prefix(maxLength))
        // ファイル名に使えない文字を置換
        let illegal = CharacterSet(charactersIn: "/\\:*?\"<>|\n\r\t")
        let sanitized = truncated.components(separatedBy: illegal).joined(separator: " ")
        // 連続スペースを1つに
        let collapsed = sanitized.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        return collapsed.trimmingCharacters(in: .whitespaces)
    }

    /// 一時ディレクトリ内でファイルをリネームする
    static func renameInPlace(url: URL, newBaseName: String) -> URL? {
        let newURL = url.deletingLastPathComponent()
            .appendingPathComponent(newBaseName)
            .appendingPathExtension(url.pathExtension)
        do {
            try FileManager.default.moveItem(at: url, to: newURL)
            return newURL
        } catch {
            print("リネームエラー: \(error)")
            return nil
        }
    }

    /// 一時ディレクトリから保存先へファイルを移動する
    static func moveToSaveDirectory(tempURL: URL) -> URL? {
        let dest = saveDirectory.appendingPathComponent(tempURL.lastPathComponent)
        do {
            if FileManager.default.fileExists(atPath: dest.path) {
                try FileManager.default.removeItem(at: dest)
            }
            try FileManager.default.moveItem(at: tempURL, to: dest)
            print("移動完了: \(dest.lastPathComponent)")
            return dest
        } catch {
            print("ファイル移動エラー: \(error)")
            return nil
        }
    }
}
