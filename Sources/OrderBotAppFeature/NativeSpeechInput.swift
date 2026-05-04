import Foundation

#if os(iOS)
import AVFoundation
import Speech

private func requestNativeSpeechAuthorization() async -> Bool {
    await withCheckedContinuation { continuation in
        SFSpeechRecognizer.requestAuthorization { status in
            continuation.resume(returning: status == .authorized)
        }
    }
}

private func requestNativeMicrophoneAuthorization() async -> Bool {
    await withCheckedContinuation { continuation in
        AVAudioApplication.requestRecordPermission { granted in
            continuation.resume(returning: granted)
        }
    }
}

private func installNativeSpeechAudioTap(
    on inputNode: AVAudioInputNode,
    format: AVAudioFormat,
    request: SFSpeechAudioBufferRecognitionRequest
) {
    inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak request] buffer, _ in
        request?.append(buffer)
    }
}

@MainActor
final class NativeSpeechInput {
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-TW"))
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var isInputTapInstalled = false

    var isRecording: Bool {
        audioEngine.isRunning
    }

    func start(
        onPartialResult: @MainActor @Sendable @escaping (String) -> Void,
        onFinalResult: @MainActor @Sendable @escaping (String) -> Void,
        onError: @MainActor @Sendable @escaping (String) -> Void
    ) async {
        stop(submitCurrentAudio: false)

        guard let recognizer, recognizer.isAvailable else {
            onError("目前無法使用語音辨識，請稍後再試。")
            return
        }

        guard await requestNativeSpeechAuthorization() else {
            onError("請允許語音辨識權限，才能用說話點餐。")
            return
        }

        guard await requestNativeMicrophoneAuthorization() else {
            onError("請允許麥克風權限，才能聽到你的點餐內容。")
            return
        }

        do {
            try configureAudioSession()
            try startRecognition(with: recognizer, onPartialResult: onPartialResult, onFinalResult: onFinalResult, onError: onError)
        } catch {
            onError("語音輸入啟動失敗，請再試一次。")
        }
    }

    func stop(submitCurrentAudio: Bool = true) {
        if audioEngine.isRunning {
            audioEngine.stop()
        }

        if isInputTapInstalled {
            audioEngine.inputNode.removeTap(onBus: 0)
            isInputTapInstalled = false
        }

        if submitCurrentAudio {
            recognitionRequest?.endAudio()
        } else {
            recognitionTask?.cancel()
        }

        recognitionRequest = nil
        recognitionTask = nil
    }

    private func startRecognition(
        with recognizer: SFSpeechRecognizer,
        onPartialResult: @MainActor @Sendable @escaping (String) -> Void,
        onFinalResult: @MainActor @Sendable @escaping (String) -> Void,
        onError: @MainActor @Sendable @escaping (String) -> Void
    ) throws {
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request

        recognitionTask = recognizer.recognitionTask(with: request) { @Sendable result, error in
            if let result {
                let transcript = result.bestTranscription.formattedString
                let isFinal = result.isFinal

                Task { @MainActor in
                    onPartialResult(transcript)

                    if isFinal {
                        onFinalResult(transcript)
                    }
                }
            }

            if error != nil {
                Task { @MainActor in
                    onError("沒有辨識成功，請再說一次。")
                }
            }
        }

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        guard recordingFormat.sampleRate > 0, recordingFormat.channelCount > 0 else {
            recognitionTask?.cancel()
            recognitionTask = nil
            recognitionRequest = nil
            onError("沒有可用的麥克風輸入，請檢查裝置或模擬器音訊設定。")
            return
        }

        installNativeSpeechAudioTap(on: inputNode, format: recordingFormat, request: request)
        isInputTapInstalled = true

        audioEngine.prepare()

        do {
            try audioEngine.start()
        } catch {
            stop(submitCurrentAudio: false)
            throw error
        }
    }

    private func configureAudioSession() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: [.duckOthers])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    }

}
#else
@MainActor
final class NativeSpeechInput {
    var isRecording: Bool { false }

    func start(
        onPartialResult: @MainActor @Sendable @escaping (String) -> Void,
        onFinalResult: @MainActor @Sendable @escaping (String) -> Void,
        onError: @MainActor @Sendable @escaping (String) -> Void
    ) async {
        onError("此平台不支援 iOS 原生語音輸入。")
    }

    func stop(submitCurrentAudio: Bool = true) {}
}
#endif
