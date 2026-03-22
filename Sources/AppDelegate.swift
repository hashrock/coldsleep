import Cocoa
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var recorder: AudioRecorder!
    var transcriber: Transcriber!
    var isRecording = false
    var recordMenuItem: NSMenuItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            if let iconPath = Bundle.main.path(forResource: "icon", ofType: "png", inDirectory: "MenuBarIcon") {
                let img = NSImage(contentsOfFile: iconPath)
                img?.size = NSSize(width: 18, height: 18)
                img?.isTemplate = true
                button.image = img
            } else {
                button.image = NSImage(systemSymbolName: "mic", accessibilityDescription: "Coldsleep")
            }
        }

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
        let url = recorder.stopRecording()
        updateIcon(recording: false)
        recordMenuItem.title = "録音開始"
        if let url = url {
            showNotification(title: "録音を保存しました", body: url.lastPathComponent)
            recordMenuItem.title = "書き起こし中..."
            recordMenuItem.isEnabled = false
            transcriber.transcribeAndSave(audioURL: url) { [weak self] textURL in
                DispatchQueue.main.async {
                    self?.recordMenuItem.title = "録音開始"
                    self?.recordMenuItem.isEnabled = true
                    if let textURL = textURL {
                        self?.showNotification(title: "書き起こし完了", body: textURL.lastPathComponent)
                    }
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
        if recording {
            statusItem.button?.contentTintColor = .systemRed
            statusItem.button?.image?.isTemplate = false
        } else {
            statusItem.button?.contentTintColor = nil
            statusItem.button?.image?.isTemplate = true
        }
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
