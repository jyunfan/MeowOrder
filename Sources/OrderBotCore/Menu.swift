import Foundation

public enum MenuCategory: String, Sendable {
    case rice = "飯類"
    case soup = "湯類"
}

public struct MenuItem: Equatable, Sendable {
    public let name: String
    public let category: MenuCategory
    public let aliases: [String]

    public init(name: String, category: MenuCategory, aliases: [String] = []) {
        self.name = name
        self.category = category
        self.aliases = aliases
    }
}

public struct Menu: Sendable {
    public let items: [MenuItem]
    public let noteOptions: [String]

    public init(items: [MenuItem], noteOptions: [String]) {
        self.items = items
        self.noteOptions = noteOptions
    }

    public static let taiwaneseDiner = Menu(
        items: [
            MenuItem(name: "雞腿飯", category: .rice, aliases: ["雞腿便當", "雞腿"]),
            MenuItem(name: "控肉飯", category: .rice, aliases: ["爌肉飯", "焢肉飯", "控肉便當", "爌肉便當", "焢肉便當"]),
            MenuItem(name: "排骨飯", category: .rice, aliases: ["排骨便當", "排骨"]),
            MenuItem(name: "滷肉飯", category: .rice, aliases: ["魯肉飯", "肉燥飯"]),
            MenuItem(name: "雞排飯", category: .rice, aliases: ["雞排便當", "雞排"]),
            MenuItem(name: "貢丸湯", category: .soup, aliases: ["貢丸"]),
            MenuItem(name: "魚丸湯", category: .soup, aliases: ["魚丸"]),
            MenuItem(name: "蛋花湯", category: .soup, aliases: ["蛋花"])
        ],
        noteOptions: [
            "不要辣",
            "小辣",
            "加辣",
            "飯少",
            "飯多",
            "不要酸菜",
            "不要香菜"
        ]
    )
}
