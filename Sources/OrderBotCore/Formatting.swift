import Foundation

public enum OrderBotFormatter {
    public static func describe(intent: OrderIntent) -> String {
        switch intent {
        case let .addItem(itemName, quantity, notes):
            return """
            intent: add_item
            item: \(itemName)
            quantity: \(quantity)
            notes: \(notes.isEmpty ? "-" : notes.joined(separator: "、"))
            """
        case let .modifyItem(itemName, quantity, notes):
            return """
            intent: modify_item
            item: \(itemName)
            quantity: \(quantity.map(String.init) ?? "-")
            notes: \(notes.isEmpty ? "-" : notes.joined(separator: "、"))
            """
        case let .deleteItem(itemName):
            return """
            intent: delete_item
            item: \(itemName)
            """
        case .finishOrdering:
            return "intent: finish_ordering"
        case .confirmSubmit:
            return "intent: confirm_submit"
        case .reset:
            return "intent: reset"
        case let .unclear(candidates, reason):
            return """
            intent: unclear
            reason: \(reason)
            candidates: \(candidates.isEmpty ? "-" : candidates.joined(separator: "、"))
            """
        case .noSpeech:
            return "intent: no_speech"
        }
    }

    public static func describe(order: Order) -> String {
        guard !order.lines.isEmpty else {
            return "目前訂單：空"
        }

        let lines = order.lines.enumerated().map { index, line in
            let notes = line.notes.isEmpty ? "" : "\n   備註：\(line.notes.joined(separator: "、"))"
            return "\(index + 1). \(line.itemName) x\(line.quantity)\(notes)"
        }.joined(separator: "\n")

        let status: String
        if order.isCompleted {
            status = "狀態：已送出"
        } else if order.isFinalConfirming {
            status = "狀態：等待最終確認"
        } else {
            status = "狀態：點餐中"
        }

        return """
        目前訂單：
        \(lines)
        \(status)
        """
    }

    public static func describe(menu: Menu) -> String {
        let rice = menu.items.filter { $0.category == .rice }.map { "- \($0.name)" }.joined(separator: "\n")
        let soup = menu.items.filter { $0.category == .soup }.map { "- \($0.name)" }.joined(separator: "\n")
        return """
        飯類：
        \(rice)

        湯類：
        \(soup)
        """
    }
}
