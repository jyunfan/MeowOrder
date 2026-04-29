import Foundation

public struct OrderLine: Equatable, Sendable {
    public var itemName: String
    public var quantity: Int
    public var notes: [String]

    public init(itemName: String, quantity: Int, notes: [String] = []) {
        self.itemName = itemName
        self.quantity = quantity
        self.notes = notes
    }
}

public struct Order: Equatable, Sendable {
    public var lines: [OrderLine]
    public var isFinalConfirming: Bool
    public var isCompleted: Bool

    public init(lines: [OrderLine] = [], isFinalConfirming: Bool = false, isCompleted: Bool = false) {
        self.lines = lines
        self.isFinalConfirming = isFinalConfirming
        self.isCompleted = isCompleted
    }

    public mutating func add(itemName: String, quantity: Int, notes: [String]) {
        if let index = lines.firstIndex(where: { $0.itemName == itemName && $0.notes == notes }) {
            lines[index].quantity += quantity
        } else {
            lines.append(OrderLine(itemName: itemName, quantity: quantity, notes: notes))
        }
        isFinalConfirming = false
    }

    public mutating func modify(itemName: String, quantity: Int?, notes: [String]) -> Bool {
        guard let index = lines.firstIndex(where: { $0.itemName == itemName }) else {
            return false
        }

        if let quantity {
            lines[index].quantity = quantity
        }
        if !notes.isEmpty {
            lines[index].notes = notes
        }
        isFinalConfirming = false
        return true
    }

    public mutating func delete(itemName: String) -> Bool {
        let originalCount = lines.count
        lines.removeAll { $0.itemName == itemName }
        isFinalConfirming = false
        return lines.count != originalCount
    }

    public mutating func reset() {
        lines.removeAll()
        isFinalConfirming = false
        isCompleted = false
    }
}
