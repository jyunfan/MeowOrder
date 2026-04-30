import Foundation
import Observation
import OrderBotCore

@Observable
@MainActor
public final class OrderKioskViewModel {
    public var state: KioskState = .idle
    public var mascotKind: MascotKind
    public var currentTranscript = ""
    public var currentTitle = "歡迎光臨"
    public var currentMessage: String
    public var candidateItems: [String] = []
    public var order = Order()

    private let parser: OrderParser

    public init(parser: OrderParser = OrderParser(), mascotKind: MascotKind = .configuredDefault) {
        self.parser = parser
        self.mascotKind = mascotKind
        self.currentMessage = Self.welcomeMessage(for: mascotKind)
    }

    var promptText: String {
        switch state {
        case .idle:
            return "請直接說：「我要一份雞腿飯，不要辣」"
        case .listening:
            return "正在聽你說，請說出想點的餐點。"
        case .parsing:
            return "我正在幫你確認剛剛說的內容。"
        case .orderUpdated:
            return "請繼續說餐點，或說「好了」完成點餐。"
        case .unclear:
            return "請換個方式再說一次，或說出完整餐點名稱。"
        case .finalConfirm:
            return "請說「確認」送出，或繼續說要修改的餐點。"
        case .completed:
            return "訂單已送出，請稍候取餐。"
        }
    }

    var mascotMood: MascotMood {
        switch state {
        case .idle:
            return .happy
        case .listening:
            return .listening
        case .parsing:
            return .thinking
        case .orderUpdated:
            return .happy
        case .unclear:
            return .confused
        case .finalConfirm:
            return .confirming
        case .completed:
            return .completed
        }
    }

    public func startListening() {
        guard !order.isCompleted else {
            reset()
            return
        }

        state = .listening
        currentTitle = "正在聽你說"
        currentMessage = "請說出想點的餐點。"
        currentTranscript = ""
        candidateItems = []
    }

    public func setMascotKind(_ kind: MascotKind) {
        mascotKind = kind
        UserDefaults.standard.set(kind.rawValue, forKey: "OrderBotMascot")

        if state == .idle {
            currentMessage = Self.welcomeMessage(for: kind)
        }
    }

    public func handleDebugUtterance(_ utterance: String) {
        let trimmed = utterance.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            state = .unclear
            currentTitle = "沒有聽到內容"
            currentMessage = "請再說一次。"
            currentTranscript = ""
            candidateItems = []
            return
        }

        state = .parsing
        currentTranscript = trimmed
        currentTitle = "我聽到"
        currentMessage = trimmed
        candidateItems = []

        let parsed = parser.parse(trimmed)
        let applied = parser.apply(parsed.intent, to: order)
        order = applied.order
        updatePresentation(for: applied)
    }

    public func reset() {
        order.reset()
        state = .idle
        currentTranscript = ""
        currentTitle = "歡迎光臨"
        currentMessage = Self.welcomeMessage(for: mascotKind)
        candidateItems = []
    }

    private func updatePresentation(for applied: AppliedIntent) {
        switch applied.intent {
        case let .addItem(itemName, quantity, notes):
            state = .orderUpdated
            currentTitle = "已加入"
            currentMessage = itemSummary(itemName: itemName, quantity: quantity, notes: notes)

        case let .modifyItem(itemName, quantity, notes):
            state = .orderUpdated
            currentTitle = "已修改"
            currentMessage = itemSummary(itemName: itemName, quantity: quantity, notes: notes)

        case let .deleteItem(itemName):
            state = .orderUpdated
            currentTitle = "已刪除"
            currentMessage = itemName

        case .finishOrdering:
            state = .finalConfirm
            currentTitle = "請確認訂單"
            currentMessage = "正確的話請說「確認」。"

        case .confirmSubmit:
            state = .completed
            currentTitle = "訂單已送出"
            currentMessage = "謝謝你，請稍候取餐。"

        case .reset:
            state = .idle
            currentTitle = "已清空訂單"
            currentMessage = "可以重新開始點餐。"

        case let .unclear(candidates, reason):
            state = .unclear
            currentTitle = "我不太確定"
            currentMessage = reason
            candidateItems = candidates

        case .noSpeech:
            state = .unclear
            currentTitle = "沒有聽到內容"
            currentMessage = "請再說一次。"
        }
    }

    private func itemSummary(itemName: String, quantity: Int?, notes: [String]) -> String {
        let quantityText = quantity.map { " x\($0)" } ?? ""
        let notesText = notes.isEmpty ? "" : "\n\(notes.joined(separator: " / "))"
        return "\(itemName)\(quantityText)\(notesText)"
    }

    private static func welcomeMessage(for mascotKind: MascotKind) -> String {
        "我是\(mascotKind.displayName)，請看菜單，想點什麼可以直接跟我說。"
    }
}
