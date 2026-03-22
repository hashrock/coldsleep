import Speech

class Transcriber {
    private let recognizer: SFSpeechRecognizer?

    init() {
        recognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))
    }

    func transcribe(audioURL: URL, completion: @escaping (Result<String, Error>) -> Void) {
        guard let recognizer = recognizer, recognizer.isAvailable else {
            completion(.failure(TranscriberError.unavailable))
            return
        }

        SFSpeechRecognizer.requestAuthorization { status in
            guard status == .authorized else {
                completion(.failure(TranscriberError.notAuthorized(status)))
                return
            }

            let request = SFSpeechURLRecognitionRequest(url: audioURL)
            request.shouldReportPartialResults = false
            request.requiresOnDeviceRecognition = true

            recognizer.recognitionTask(with: request) { result, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let result = result, result.isFinal else { return }

                let text = result.bestTranscription.formattedString
                if text.isEmpty {
                    completion(.failure(TranscriberError.emptyResult))
                } else {
                    completion(.success(text))
                }
            }
        }
    }

    func transcribeAndSave(audioURL: URL, completion: @escaping (URL?) -> Void) {
        transcribe(audioURL: audioURL) { result in
            let errorURL = audioURL.deletingPathExtension().appendingPathExtension("error.txt")

            switch result {
            case .success(let text):
                let textURL = audioURL.deletingPathExtension().appendingPathExtension("txt")
                do {
                    try text.write(to: textURL, atomically: true, encoding: .utf8)
                    // 成功したら古いエラーファイルがあれば消す
                    try? FileManager.default.removeItem(at: errorURL)
                    print("書き起こし保存: \(textURL.lastPathComponent)")
                    completion(textURL)
                } catch {
                    self.saveError("ファイル保存エラー: \(error.localizedDescription)", to: errorURL)
                    completion(nil)
                }

            case .failure(let error):
                self.saveError(error.localizedDescription, to: errorURL)
                completion(nil)
            }
        }
    }

    private func saveError(_ message: String, to url: URL) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let content = "[\(timestamp)] \(message)"
        try? content.write(to: url, atomically: true, encoding: .utf8)
        print("書き起こしエラー: \(message) -> \(url.lastPathComponent)")
    }
}

enum TranscriberError: LocalizedError {
    case unavailable
    case notAuthorized(SFSpeechRecognizerAuthorizationStatus)
    case emptyResult

    var errorDescription: String? {
        switch self {
        case .unavailable:
            return "音声認識エンジンが利用できません"
        case .notAuthorized(let status):
            return "音声認識の権限がありません (status: \(status.rawValue))"
        case .emptyResult:
            return "書き起こし結果が空でした"
        }
    }
}
