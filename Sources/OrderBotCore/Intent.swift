import Foundation

public enum OrderIntent: Equatable, Sendable {
    case addItem(itemName: String, quantity: Int, notes: [String])
    case modifyItem(itemName: String, quantity: Int?, notes: [String])
    case deleteItem(itemName: String)
    case finishOrdering
    case confirmSubmit
    case reset
    case unclear(candidates: [String], reason: String)
    case noSpeech
}

public struct IntentResult: Equatable, Sendable {
    public let transcript: String
    public let intent: OrderIntent

    public init(transcript: String, intent: OrderIntent) {
        self.transcript = transcript
        self.intent = intent
    }
}

public struct AppliedIntent: Equatable, Sendable {
    public let intent: OrderIntent
    public let message: String
    public let order: Order
}
