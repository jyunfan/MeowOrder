import Foundation

public enum KioskState: Equatable, Sendable {
    case idle
    case listening
    case parsing
    case orderUpdated
    case unclear
    case finalConfirm
    case completed
}

public enum MascotKind: String, CaseIterable, Identifiable, Sendable {
    case cat
    case corgi

    public var id: String { rawValue }

    var displayName: String {
        switch self {
        case .cat:
            return "點餐小貓"
        case .corgi:
            return "點餐柯基"
        }
    }

    var menuTitle: String {
        switch self {
        case .cat:
            return "貓咪版"
        case .corgi:
            return "柯基版"
        }
    }

    public static var configuredDefault: MascotKind {
        if let saved = UserDefaults.standard.string(forKey: "OrderBotMascot"),
           let kind = MascotKind(rawValue: saved) {
            return kind
        }

        if let plistValue = Bundle.main.object(forInfoDictionaryKey: "OrderBotMascot") as? String,
           let kind = MascotKind(rawValue: plistValue.lowercased()) {
            return kind
        }

        if let envValue = ProcessInfo.processInfo.environment["ORDERBOT_MASCOT"],
           let kind = MascotKind(rawValue: envValue.lowercased()) {
            return kind
        }

        return .corgi
    }
}

enum MascotMood: Equatable {
    case happy
    case listening
    case thinking
    case confused
    case confirming
    case completed
}
