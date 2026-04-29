import Foundation
import OrderBotCore

#if canImport(Speech)
import Speech
#endif

@main
struct OrderBotCLI {
    static func main() async {
        let arguments = Array(CommandLine.arguments.dropFirst())
        let parser = OrderParser()

        guard let command = arguments.first else {
            printHelp()
            return
        }

        do {
            switch command {
            case "menu":
                print(OrderBotFormatter.describe(menu: .taiwaneseDiner))

            case "parse":
                let text = joinedArguments(arguments.dropFirst())
                let result = parser.parse(text)
                print(OrderBotFormatter.describe(intent: result.intent))

            case "simulate":
                var order = Order()
                let utterances = Array(arguments.dropFirst())
                guard !utterances.isEmpty else {
                    print("請提供至少一句語音文字。")
                    return
                }
                for utterance in utterances {
                    print("使用者：\(utterance)")
                    let result = parser.parse(utterance)
                    let applied = parser.apply(result.intent, to: order)
                    order = applied.order
                    print("解析：")
                    print(OrderBotFormatter.describe(intent: applied.intent))
                    print("回覆：\(applied.message)")
                    print(OrderBotFormatter.describe(order: order))
                    print("")
                }

            case "transcribe":
                let path = try requiredPath(from: arguments)
                let transcript = try await transcribeAudioFile(path: path)
                print(transcript)

            case "parse-audio":
                let path = try requiredPath(from: arguments)
                let transcript = try await transcribeAudioFile(path: path)
                print("transcript: \(transcript)")
                let result = parser.parse(transcript)
                print(OrderBotFormatter.describe(intent: result.intent))

            case "help", "--help", "-h":
                printHelp()

            default:
                print("未知指令：\(command)")
                printHelp()
            }
        } catch {
            fputs("Error: \(error.localizedDescription)\n", stderr)
            Foundation.exit(1)
        }
    }

    private static func joinedArguments(_ slice: ArraySlice<String>) -> String {
        slice.joined(separator: " ")
    }

    private static func requiredPath(from arguments: [String]) throws -> String {
        guard arguments.count >= 2 else {
            throw CLIError.missingAudioPath
        }
        return arguments[1]
    }

    private static func printHelp() {
        print(
            """
            orderbot CLI

            Usage:
              orderbot menu
              orderbot parse "我要一份雞腿飯，不要辣"
              orderbot simulate "我要一份雞腿飯" "再加一碗貢丸湯" "好了" "確認"
              orderbot transcribe tests/audio/example.wav
              orderbot parse-audio tests/audio/example.wav
            """
        )
    }
}

enum CLIError: LocalizedError {
    case missingAudioPath
    case speechUnavailable
    case recognizerUnavailable
    case recognitionFailed

    var errorDescription: String? {
        switch self {
        case .missingAudioPath:
            return "請提供 .wav 音訊檔路徑。"
        case .speechUnavailable:
            return "此平台無法使用 Speech framework。"
        case .recognizerUnavailable:
            return "目前無法建立 zh-TW 語音辨識器。"
        case .recognitionFailed:
            return "語音辨識沒有產生結果。"
        }
    }
}

private func transcribeAudioFile(path: String) async throws -> String {
#if canImport(Speech)
    let status = await withCheckedContinuation { continuation in
        SFSpeechRecognizer.requestAuthorization { status in
            continuation.resume(returning: status)
        }
    }

    guard status == .authorized else {
        throw NSError(
            domain: "OrderBotSpeech",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "語音辨識權限未核准：\(status.rawValue)。"]
        )
    }

    guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-TW")) else {
        throw CLIError.recognizerUnavailable
    }

    let url = URL(fileURLWithPath: path)
    let request = SFSpeechURLRecognitionRequest(url: url)
    request.shouldReportPartialResults = false

    return try await withCheckedThrowingContinuation { continuation in
        var didResume = false
        recognizer.recognitionTask(with: request) { result, error in
            if let error, !didResume {
                didResume = true
                continuation.resume(throwing: error)
                return
            }

            guard let result, result.isFinal, !didResume else {
                return
            }

            didResume = true
            let transcript = result.bestTranscription.formattedString
            if transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                continuation.resume(throwing: CLIError.recognitionFailed)
            } else {
                continuation.resume(returning: transcript)
            }
        }
    }
#else
    throw CLIError.speechUnavailable
#endif
}
