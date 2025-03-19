import Foundation

public struct Category: Codable, Identifiable, Hashable {
    public let id: Int
    public let name: String
    
    public init(id: Int, name: String) {
        self.id = id
        self.name = name
    }
}

public extension Category {
    static let all = Category(id: -1, name: "All Categories")
} 