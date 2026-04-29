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

            case "test-simulate":
                let path = arguments.count >= 2 ? arguments[1] : "testdata/simulate"
                let report = try runSimulateTests(path: path, parser: parser)
                print(report.render())
                if report.failedCaseCount > 0 {
                    Foundation.exit(1)
                }

            case "test-speech":
                let path = arguments.count >= 2 ? arguments[1] : "testdata/speech/manifest.json"
                let report = try await runSpeechTests(manifestPath: path, parser: parser)
                print(report.render())
                if report.failedRunnableCount > 0 {
                    Foundation.exit(1)
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
              orderbot test-simulate testdata/simulate
              orderbot test-speech testdata/speech/manifest.json
              orderbot transcribe tests/audio/example.wav
              orderbot parse-audio tests/audio/example.wav
            """
        )
    }
}

struct SimulateTestCase: Decodable {
    let name: String
    let utterances: [String]
    let expectedIntents: [ExpectedIntent]
    let expectedOrder: ExpectedOrder
}

struct ExpectedIntent: Decodable {
    let type: String
    let itemName: String?
    let quantity: Int?
    let notes: [String]?
}

struct ExpectedOrder: Decodable {
    let finalConfirming: Bool
    let completed: Bool
    let lines: [ExpectedOrderLine]
}

struct ExpectedOrderLine: Decodable, Equatable {
    let itemName: String
    let quantity: Int
    let notes: [String]
}

struct SimulateTestReport {
    let results: [SimulateCaseResult]

    var totalCaseCount: Int { results.count }
    var passedCaseCount: Int { results.filter(\.passed).count }
    var failedCaseCount: Int { totalCaseCount - passedCaseCount }
    var accuracy: Double {
        guard totalCaseCount > 0 else { return 0 }
        return Double(passedCaseCount) / Double(totalCaseCount)
    }

    func render() -> String {
        var lines = ["Simulate Tests"]
        lines.append("")

        for result in results {
            lines.append("\(result.passed ? "PASS" : "FAIL") \(result.name) (\(result.fileName))")
            for failure in result.failures {
                lines.append("  - \(failure)")
            }
        }

        lines.append("")
        lines.append("Passed: \(passedCaseCount)/\(totalCaseCount)")
        lines.append(String(format: "Accuracy: %.1f%%", accuracy * 100))
        return lines.joined(separator: "\n")
    }
}

struct SimulateCaseResult {
    let name: String
    let fileName: String
    let failures: [String]

    var passed: Bool { failures.isEmpty }
}

struct SpeechTestManifest: Decodable {
    let cases: [SpeechTestCase]
}

struct SpeechTestCase: Decodable {
    let id: String
    let audio: String
    let expectedTranscript: String
    let expectedIntent: ExpectedIntent
    let keywords: [String]
}

struct SpeechTestReport {
    let results: [SpeechCaseResult]

    var totalCaseCount: Int { results.count }
    var missingAudioCount: Int { results.filter { $0.status == .missingAudio }.count }
    var runnableResults: [SpeechCaseResult] {
        results.filter { $0.status != .missingAudio }
    }
    var runnableCaseCount: Int { runnableResults.count }
    var failedRunnableCount: Int {
        runnableResults.filter { $0.status != .pass && $0.status != .warn }.count
    }

    var transcriptExactAccuracy: Double? {
        accuracy { $0.transcriptExactPassed }
    }

    var keywordAccuracy: Double? {
        accuracy { $0.keywordPassed }
    }

    var intentAccuracy: Double? {
        accuracy { $0.intentPassed }
    }

    func render() -> String {
        var lines = ["Speech Recognition Tests"]
        lines.append("")

        for result in results {
            lines.append("\(result.status.rawValue) \(result.id)")
            lines.append("  file: \(result.audioPath)")
            if let expectedTranscript = result.expectedTranscript {
                lines.append("  expected: \(expectedTranscript)")
            }
            if let actualTranscript = result.actualTranscript {
                lines.append("  actual:   \(actualTranscript)")
            }
            for detail in result.details {
                lines.append("  - \(detail)")
            }
        }

        lines.append("")
        lines.append("Total: \(totalCaseCount)")
        lines.append("Runnable: \(runnableCaseCount)")
        lines.append("Missing audio: \(missingAudioCount)")
        lines.append("Transcript exact accuracy: \(formatAccuracy(transcriptExactAccuracy))")
        lines.append("Keyword accuracy: \(formatAccuracy(keywordAccuracy))")
        lines.append("Intent accuracy: \(formatAccuracy(intentAccuracy))")
        return lines.joined(separator: "\n")
    }

    private func accuracy(_ isPassed: (SpeechCaseResult) -> Bool?) -> Double? {
        let scored = runnableResults.compactMap(isPassed)
        guard !scored.isEmpty else {
            return nil
        }
        let passed = scored.filter { $0 }.count
        return Double(passed) / Double(scored.count)
    }

    private func formatAccuracy(_ value: Double?) -> String {
        guard let value else {
            return "N/A"
        }
        return String(format: "%.1f%%", value * 100)
    }
}

struct SpeechCaseResult {
    let id: String
    let audioPath: String
    let status: SpeechCaseStatus
    let expectedTranscript: String?
    let actualTranscript: String?
    let transcriptExactPassed: Bool?
    let keywordPassed: Bool?
    let intentPassed: Bool?
    let details: [String]
}

enum SpeechCaseStatus: String {
    case pass = "PASS"
    case warn = "WARN"
    case fail = "FAIL"
    case missingAudio = "MISSING_AUDIO"
}

private func runSimulateTests(path: String, parser: OrderParser) throws -> SimulateTestReport {
    let fileManager = FileManager.default
    let url = URL(fileURLWithPath: path)
    let isDirectory = (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false

    let files: [URL]
    if isDirectory {
        files = try fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: nil
        )
        .filter { $0.pathExtension == "json" }
        .sorted { $0.lastPathComponent < $1.lastPathComponent }
    } else {
        files = [url]
    }

    let decoder = JSONDecoder()
    let results = try files.map { file in
        let data = try Data(contentsOf: file)
        let testCase = try decoder.decode(SimulateTestCase.self, from: data)
        return runSimulateTestCase(testCase, fileName: file.lastPathComponent, parser: parser)
    }

    return SimulateTestReport(results: results)
}

private func runSpeechTests(manifestPath: String, parser: OrderParser) async throws -> SpeechTestReport {
    let manifestURL = URL(fileURLWithPath: manifestPath)
    let manifestDirectory = manifestURL.deletingLastPathComponent()
    let data = try Data(contentsOf: manifestURL)
    let manifest = try JSONDecoder().decode(SpeechTestManifest.self, from: data)

    var results: [SpeechCaseResult] = []
    for testCase in manifest.cases {
        let audioURL = resolveAudioURL(testCase.audio, relativeTo: manifestDirectory)
        let audioPath = audioURL.path

        guard FileManager.default.fileExists(atPath: audioPath) else {
            results.append(
                SpeechCaseResult(
                    id: testCase.id,
                    audioPath: audioPath,
                    status: .missingAudio,
                    expectedTranscript: testCase.expectedTranscript,
                    actualTranscript: nil,
                    transcriptExactPassed: nil,
                    keywordPassed: nil,
                    intentPassed: nil,
                    details: ["錄音檔尚未建立"]
                )
            )
            continue
        }

        do {
            let transcript = try await transcribeAudioFile(path: audioPath)
            let normalizedActual = normalizeSpeechText(transcript)
            let normalizedExpected = normalizeSpeechText(testCase.expectedTranscript)
            let transcriptExactPassed = normalizedActual == normalizedExpected
            let keywordPassed = testCase.keywords.allSatisfy {
                normalizedActual.contains(normalizeSpeechText($0))
            }

            let parsed = parser.parse(transcript)
            let intentFailures = compareIntent(
                parsed.intent,
                expected: testCase.expectedIntent,
                utteranceIndex: 0,
                utterance: transcript
            )
            let intentPassed = intentFailures.isEmpty

            var details: [String] = []
            if !transcriptExactPassed {
                details.append("transcript exact mismatch")
            }
            if !keywordPassed {
                details.append("keyword mismatch: expected \(testCase.keywords.joined(separator: "、"))")
            }
            details.append(contentsOf: intentFailures)

            let status: SpeechCaseStatus
            if transcriptExactPassed && keywordPassed && intentPassed {
                status = .pass
            } else if intentPassed {
                status = .warn
            } else {
                status = .fail
            }

            results.append(
                SpeechCaseResult(
                    id: testCase.id,
                    audioPath: audioPath,
                    status: status,
                    expectedTranscript: testCase.expectedTranscript,
                    actualTranscript: transcript,
                    transcriptExactPassed: transcriptExactPassed,
                    keywordPassed: keywordPassed,
                    intentPassed: intentPassed,
                    details: details
                )
            )
        } catch {
            results.append(
                SpeechCaseResult(
                    id: testCase.id,
                    audioPath: audioPath,
                    status: .fail,
                    expectedTranscript: testCase.expectedTranscript,
                    actualTranscript: nil,
                    transcriptExactPassed: false,
                    keywordPassed: false,
                    intentPassed: false,
                    details: ["recognition error: \(error.localizedDescription)"]
                )
            )
        }
    }

    return SpeechTestReport(results: results)
}

private func resolveAudioURL(_ path: String, relativeTo directory: URL) -> URL {
    if path.hasPrefix("/") {
        return URL(fileURLWithPath: path)
    }
    return directory.appendingPathComponent(path)
}

private func normalizeSpeechText(_ text: String) -> String {
    text
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .replacingOccurrences(of: " ", with: "")
        .replacingOccurrences(of: "，", with: "")
        .replacingOccurrences(of: ",", with: "")
        .replacingOccurrences(of: "。", with: "")
        .lowercased()
}

private func runSimulateTestCase(
    _ testCase: SimulateTestCase,
    fileName: String,
    parser: OrderParser
) -> SimulateCaseResult {
    var order = Order()
    var failures: [String] = []

    if testCase.utterances.count != testCase.expectedIntents.count {
        failures.append("utterances count \(testCase.utterances.count) != expectedIntents count \(testCase.expectedIntents.count)")
    }

    for (index, utterance) in testCase.utterances.enumerated() {
        let parsed = parser.parse(utterance)
        let applied = parser.apply(parsed.intent, to: order)
        order = applied.order

        guard index < testCase.expectedIntents.count else {
            continue
        }

        let expected = testCase.expectedIntents[index]
        failures.append(contentsOf: compareIntent(applied.intent, expected: expected, utteranceIndex: index, utterance: utterance))
    }

    failures.append(contentsOf: compareOrder(order, expected: testCase.expectedOrder))
    return SimulateCaseResult(name: testCase.name, fileName: fileName, failures: failures)
}

private func compareIntent(
    _ actual: OrderIntent,
    expected: ExpectedIntent,
    utteranceIndex: Int,
    utterance: String
) -> [String] {
    var failures: [String] = []
    let prefix = "utterance \(utteranceIndex + 1) \"\(utterance)\""
    let actualType = intentType(actual)

    if actualType != expected.type {
        failures.append("\(prefix): expected intent \(expected.type), got \(actualType)")
        return failures
    }

    if let expectedItem = expected.itemName, intentItemName(actual) != expectedItem {
        failures.append("\(prefix): expected item \(expectedItem), got \(intentItemName(actual) ?? "-")")
    }

    if let expectedQuantity = expected.quantity, intentQuantity(actual) != expectedQuantity {
        failures.append("\(prefix): expected quantity \(expectedQuantity), got \(intentQuantity(actual).map(String.init) ?? "-")")
    }

    if let expectedNotes = expected.notes, intentNotes(actual) != expectedNotes {
        failures.append("\(prefix): expected notes \(expectedNotes.joined(separator: "、")), got \(intentNotes(actual).joined(separator: "、"))")
    }

    return failures
}

private func compareOrder(_ actual: Order, expected: ExpectedOrder) -> [String] {
    var failures: [String] = []

    if actual.isFinalConfirming != expected.finalConfirming {
        failures.append("expected finalConfirming \(expected.finalConfirming), got \(actual.isFinalConfirming)")
    }

    if actual.isCompleted != expected.completed {
        failures.append("expected completed \(expected.completed), got \(actual.isCompleted)")
    }

    let actualLines = actual.lines.map {
        ExpectedOrderLine(itemName: $0.itemName, quantity: $0.quantity, notes: $0.notes)
    }

    if actualLines != expected.lines {
        failures.append("expected order lines \(describe(lines: expected.lines)), got \(describe(lines: actualLines))")
    }

    return failures
}

private func intentType(_ intent: OrderIntent) -> String {
    switch intent {
    case .addItem:
        return "add_item"
    case .modifyItem:
        return "modify_item"
    case .deleteItem:
        return "delete_item"
    case .finishOrdering:
        return "finish_ordering"
    case .confirmSubmit:
        return "confirm_submit"
    case .reset:
        return "reset"
    case .unclear:
        return "unclear"
    case .noSpeech:
        return "no_speech"
    }
}

private func intentItemName(_ intent: OrderIntent) -> String? {
    switch intent {
    case let .addItem(itemName, _, _),
         let .modifyItem(itemName, _, _),
         let .deleteItem(itemName):
        return itemName
    default:
        return nil
    }
}

private func intentQuantity(_ intent: OrderIntent) -> Int? {
    switch intent {
    case let .addItem(_, quantity, _):
        return quantity
    case let .modifyItem(_, quantity, _):
        return quantity
    default:
        return nil
    }
}

private func intentNotes(_ intent: OrderIntent) -> [String] {
    switch intent {
    case let .addItem(_, _, notes),
         let .modifyItem(_, _, notes):
        return notes
    default:
        return []
    }
}

private func describe(lines: [ExpectedOrderLine]) -> String {
    guard !lines.isEmpty else {
        return "[]"
    }

    return lines.map { line in
        let notes = line.notes.isEmpty ? "" : " notes=\(line.notes.joined(separator: "、"))"
        return "\(line.itemName) x\(line.quantity)\(notes)"
    }.joined(separator: "; ")
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
