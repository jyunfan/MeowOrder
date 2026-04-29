import Foundation

public struct OrderParser: Sendable {
    public let menu: Menu

    private let finishPhrases = ["好了", "就這樣", "不用了", "結帳", "完成"]
    private let confirmPhrases = ["正確", "對", "沒錯", "可以", "送出", "確認"]
    private let resetPhrases = ["全部重來", "重新來", "重來"]
    private let deletePhrases = ["不要了", "取消", "刪掉", "拿掉"]
    private let modifyPhrases = ["改", "換成", "變成"]

    public init(menu: Menu = .taiwaneseDiner) {
        self.menu = menu
    }

    public func parse(_ rawText: String) -> IntentResult {
        let text = normalize(rawText)
        guard !text.isEmpty else {
            return IntentResult(transcript: rawText, intent: .noSpeech)
        }

        if containsAny(text, resetPhrases) {
            return IntentResult(transcript: rawText, intent: .reset)
        }

        if containsAny(text, confirmPhrases) {
            return IntentResult(transcript: rawText, intent: .confirmSubmit)
        }

        if containsAny(text, finishPhrases) {
            return IntentResult(transcript: rawText, intent: .finishOrdering)
        }

        let matches = matchingMenuItems(in: text)
        if matches.isEmpty {
            return IntentResult(transcript: rawText, intent: .unclear(candidates: [], reason: "找不到菜單品項"))
        }

        if matches.count > 1 && !hasExactMenuMatch(in: text, matches: matches) {
            return IntentResult(
                transcript: rawText,
                intent: .unclear(candidates: matches.map(\.name), reason: "可能對應多個菜單品項")
            )
        }

        let item = bestMatch(in: text, matches: matches)

        if containsAny(text, deletePhrases) {
            return IntentResult(transcript: rawText, intent: .deleteItem(itemName: item.name))
        }

        let quantity = parseQuantity(from: text)
        let notes = parseNotes(from: text)

        if containsAny(text, modifyPhrases) {
            return IntentResult(
                transcript: rawText,
                intent: .modifyItem(itemName: item.name, quantity: quantity, notes: notes)
            )
        }

        return IntentResult(
            transcript: rawText,
            intent: .addItem(itemName: item.name, quantity: quantity ?? 1, notes: notes)
        )
    }

    public func apply(_ intent: OrderIntent, to order: Order) -> AppliedIntent {
        var next = order

        switch intent {
        case let .addItem(itemName, quantity, notes):
            next.add(itemName: itemName, quantity: quantity, notes: notes)
            return AppliedIntent(intent: intent, message: "已加入 \(itemName) x\(quantity)\(notesText(notes))。", order: next)

        case let .modifyItem(itemName, quantity, notes):
            if next.modify(itemName: itemName, quantity: quantity, notes: notes) {
                return AppliedIntent(intent: intent, message: "已修改 \(itemName)\(quantityText(quantity))\(notesText(notes))。", order: next)
            }
            return AppliedIntent(intent: .unclear(candidates: [itemName], reason: "訂單內沒有這個品項"), message: "訂單內沒有 \(itemName)，請再確認一次。", order: next)

        case let .deleteItem(itemName):
            if next.delete(itemName: itemName) {
                return AppliedIntent(intent: intent, message: "已刪除 \(itemName)。", order: next)
            }
            return AppliedIntent(intent: .unclear(candidates: [itemName], reason: "訂單內沒有這個品項"), message: "訂單內沒有 \(itemName)，請再確認一次。", order: next)

        case .finishOrdering:
            next.isFinalConfirming = true
            return AppliedIntent(intent: intent, message: "請確認訂單，正確的話請說「確認」。", order: next)

        case .confirmSubmit:
            guard next.isFinalConfirming else {
                return AppliedIntent(intent: .unclear(candidates: [], reason: "尚未進入最終確認"), message: "請先說「好了」進入訂單確認。", order: next)
            }
            next.isCompleted = true
            return AppliedIntent(intent: intent, message: "訂單已送出。", order: next)

        case .reset:
            next.reset()
            return AppliedIntent(intent: intent, message: "已清空訂單，可以重新開始。", order: next)

        case let .unclear(candidates, reason):
            let candidateText = candidates.isEmpty ? "" : " 候選：\(candidates.joined(separator: "、"))"
            return AppliedIntent(intent: intent, message: "我不太確定：\(reason)。\(candidateText)", order: next)

        case .noSpeech:
            return AppliedIntent(intent: intent, message: "沒有聽到內容，請再說一次。", order: next)
        }
    }

    private func normalize(_ text: String) -> String {
        text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "，", with: ",")
            .replacingOccurrences(of: "。", with: "")
    }

    private func containsAny(_ text: String, _ phrases: [String]) -> Bool {
        phrases.contains { text.contains($0) }
    }

    private func matchingMenuItems(in text: String) -> [MenuItem] {
        menu.items.filter { item in
            ([item.name] + item.aliases).contains { alias in
                text.contains(alias)
            }
        }
    }

    private func hasExactMenuMatch(in text: String, matches: [MenuItem]) -> Bool {
        matches.contains { text.contains($0.name) }
    }

    private func bestMatch(in text: String, matches: [MenuItem]) -> MenuItem {
        if let exact = matches.first(where: { text.contains($0.name) }) {
            return exact
        }
        return matches.max { lhs, rhs in
            longestAliasLength(lhs, in: text) < longestAliasLength(rhs, in: text)
        } ?? matches[0]
    }

    private func longestAliasLength(_ item: MenuItem, in text: String) -> Int {
        ([item.name] + item.aliases)
            .filter { text.contains($0) }
            .map(\.count)
            .max() ?? 0
    }

    private func parseQuantity(from text: String) -> Int? {
        let directPatterns: [(String, Int)] = [
            ("一", 1), ("1", 1),
            ("兩", 2), ("二", 2), ("2", 2),
            ("三", 3), ("3", 3),
            ("四", 4), ("4", 4),
            ("五", 5), ("5", 5)
        ]

        for (token, value) in directPatterns {
            if text.contains("\(token)份") || text.contains("\(token)碗") || text.contains("\(token)個") || text.contains("\(token)杯") {
                return value
            }
        }

        return nil
    }

    private func parseNotes(from text: String) -> [String] {
        menu.noteOptions.filter { text.contains($0) }
    }

    private func notesText(_ notes: [String]) -> String {
        notes.isEmpty ? "" : "，\(notes.joined(separator: "、"))"
    }

    private func quantityText(_ quantity: Int?) -> String {
        guard let quantity else { return "" }
        return " x\(quantity)"
    }
}
