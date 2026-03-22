import Cocoa
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var recorder: AudioRecorder!
    var transcriber: Transcriber!
    var isRecording = false
    var recordMenuItem: NSMenuItem!
    var normalIcon: NSImage?
    var recordingIcon: NSImage?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        // 通常アイコン
        if let iconPath = Bundle.main.path(forResource: "icon", ofType: "png", inDirectory: "MenuBarIcon") {
            let img = NSImage(contentsOfFile: iconPath)
            img?.size = NSSize(width: 18, height: 18)
            img?.isTemplate = true
            normalIcon = img
        } else {
            normalIcon = NSImage(systemSymbolName: "mic", accessibilityDescription: "Coldsleep")
        }

        // 録音中アイコン（赤丸）
        recordingIcon = NSImage(size: NSSize(width: 18, height: 18), flipped: false) { rect in
            NSColor.systemRed.setFill()
            let circle = NSBezierPath(ovalIn: rect.insetBy(dx: 3, dy: 3))
            circle.fill()
            return true
        }
        recordingIcon?.isTemplate = false

        statusItem.button?.image = normalIcon

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Coldsleep", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        recordMenuItem = NSMenuItem(title: "録音開始", action: #selector(toggleRecording), keyEquivalent: "r")
        menu.addItem(recordMenuItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "保存先を開く", action: #selector(openSaveFolder), keyEquivalent: "o"))
        menu.addItem(NSMenuItem(title: "保存先を変更...", action: #selector(changeSaveFolder), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "終了", action: #selector(quit), keyEquivalent: "q"))
        statusItem.menu = menu

        recorder = AudioRecorder()
        transcriber = Transcriber()

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert]) { _, _ in }
    }

    func startRecording() {
        guard !isRecording else { return }
        isRecording = true
        recorder.startRecording()
        updateIcon(recording: true)
        recordMenuItem.title = "録音停止"
    }

    func stopRecording() {
        guard isRecording else { return }
        isRecording = false
        let tempURL = recorder.stopRecording()
        updateIcon(recording: false)
        recordMenuItem.title = "録音開始"
        guard let tempURL = tempURL else { return }

        recordMenuItem.title = "書き起こし中..."
        recordMenuItem.isEnabled = false

        transcriber.transcribeAndSave(audioURL: tempURL) { [weak self] textURL in
            DispatchQueue.main.async {
                var audioToMove = tempURL
                var textToMove = textURL

                // 書き起こし成功時、テキスト先頭100文字をファイル名に含める
                if let textURL = textURL,
                   let text = try? String(contentsOf: textURL, encoding: .utf8) {
                    let baseName = tempURL.deletingPathExtension().lastPathComponent
                    let snippet = AudioRecorder.sanitizeForFileName(text)
                    if !snippet.isEmpty {
                        let newBase = "\(baseName)_\(snippet)"
                        if let renamedAudio = AudioRecorder.renameInPlace(url: audioToMove, newBaseName: newBase) {
                            audioToMove = renamedAudio
                        }
                        if let renamedText = AudioRecorder.renameInPlace(url: textURL, newBaseName: newBase) {
                            textToMove = renamedText
                        }
                    }
                }

                // 保存先へ移動
                let savedAudio = AudioRecorder.moveToSaveDirectory(tempURL: audioToMove)
                var savedText: URL? = nil
                if let textToMove = textToMove {
                    savedText = AudioRecorder.moveToSaveDirectory(tempURL: textToMove)
                }
                // エラーファイルがあればそれも移動
                let errorURL = tempURL.deletingPathExtension().appendingPathExtension("error.txt")
                if FileManager.default.fileExists(atPath: errorURL.path) {
                    _ = AudioRecorder.moveToSaveDirectory(tempURL: errorURL)
                }

                self?.recordMenuItem.title = "録音開始"
                self?.recordMenuItem.isEnabled = true

                if let savedText = savedText {
                    self?.showNotification(title: "書き起こし完了", body: savedText.lastPathComponent)
                } else if let savedAudio = savedAudio {
                    self?.showNotification(title: "録音を保存しました", body: "\(savedAudio.lastPathComponent)（書き起こし失敗）")
                }
            }
        }
    }

    @objc func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    func updateIcon(recording: Bool) {
        statusItem.button?.image = recording ? recordingIcon : normalIcon
    }

    func showNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    @objc func openSaveFolder() {
        NSWorkspace.shared.open(AudioRecorder.saveDirectory)
    }

    @objc func changeSaveFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "録音ファイルの保存先を選択してください"
        panel.directoryURL = AudioRecorder.saveDirectory

        if panel.runModal() == .OK, let url = panel.url {
            UserDefaults.standard.set(url.path, forKey: "savePath")
        }
    }

    @objc func quit() {
        stopRecording()
        NSApp.terminate(nil)
    }
}
