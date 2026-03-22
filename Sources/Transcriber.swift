import Speech

class Transcriber {
    private let recognizer: SFSpeechRecognizer?

    init() {
        recognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))
    }

    func transcribe(audioURL: URL, completion: @escaping (String?) -> Void) {
        guard let recognizer = recognizer, recognizer.isAvailable else {
            print("音声認識が利用できません")
            completion(nil)
            return
        }

        SFSpeechRecognizer.requestAuthorization { status in
            guard status == .authorized else {
                print("音声認識の権限がありません: \(status.rawValue)")
                completion(nil)
                return
            }

            let request = SFSpeechURLRecognitionRequest(url: audioURL)
            request.shouldReportPartialResults = false
            request.requiresOnDeviceRecognition = true

            recognizer.recognitionTask(with: request) { result, error in
                if let error = error {
                    print("書き起こしエラー: \(error.localizedDescription)")
                    completion(nil)
                    return
                }

                guard let result = result, result.isFinal else { return }

                let text = result.bestTranscription.formattedString
                completion(text)
            }
        }
    }

    func transcribeAndSave(audioURL: URL, completion: @escaping (URL?) -> Void) {
        transcribe(audioURL: audioURL) { text in
            guard let text = text, !text.isEmpty else {
                completion(nil)
                return
            }

            let textURL = audioURL.deletingPathExtension().appendingPathExtension("txt")
            do {
                try text.write(to: textURL, atomically: true, encoding: .utf8)
                print("書き起こし保存: \(textURL.lastPathComponent)")
                completion(textURL)
            } catch {
                print("書き起こしファイル保存エラー: \(error)")
                completion(nil)
            }
        }
    }
}
