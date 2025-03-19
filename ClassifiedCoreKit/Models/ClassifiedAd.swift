import Foundation

public struct ClassifiedAd: Codable, Identifiable, Hashable {
    public let id: Int
    public let categoryId: Int
    public let title: String
    public let description: String
    public let price: Double
    public let creationDate: Date
    public let isUrgent: Bool
    public let siret: String?
    public let imagesUrl: ImageUrls
    
    enum CodingKeys: String, CodingKey {
        case id
        case categoryId
        case title
        case description
        case price
        case creationDate
        case isUrgent
        case siret
        case imagesUrl
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: ClassifiedAd, rhs: ClassifiedAd) -> Bool {
        lhs.id == rhs.id
    }
    
    public var formattedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "€"
        formatter.minimumFractionDigits = price.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 2
        return formatter.string(from: NSNumber(value: price)) ?? "\(price) €"
    }
    
    public var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: creationDate)
    }
}

public struct ImageUrls: Codable, Hashable {
    public let small: URL?
    public let thumb: URL?
    
    enum CodingKeys: String, CodingKey {
        case small
        case thumb
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let smallString = try? container.decode(String.self, forKey: .small) {
            small = URL(string: smallString)
        } else {
            small = nil
        }
        
        if let thumbString = try? container.decode(String.self, forKey: .thumb) {
            thumb = URL(string: thumbString)
        } else {
            thumb = nil
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(small?.absoluteString, forKey: .small)
        try container.encode(thumb?.absoluteString, forKey: .thumb)
    }
}

extension ClassifiedAd {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        categoryId = try container.decode(Int.self, forKey: .categoryId)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        price = try container.decode(Double.self, forKey: .price)
        isUrgent = try container.decode(Bool.self, forKey: .isUrgent)
        siret = try container.decodeIfPresent(String.self, forKey: .siret)
        imagesUrl = try container.decode(ImageUrls.self, forKey: .imagesUrl)
        
        let dateString = try container.decode(String.self, forKey: .creationDate)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        if let date = dateFormatter.date(from: dateString) {
            creationDate = date
        } else {
            throw DecodingError.dataCorruptedError(
                forKey: .creationDate,
                in: container,
                debugDescription: "Date string does not match format expected by formatter."
            )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(categoryId, forKey: .categoryId)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(price, forKey: .price)
        try container.encode(isUrgent, forKey: .isUrgent)
        try container.encodeIfPresent(siret, forKey: .siret)
        try container.encode(imagesUrl, forKey: .imagesUrl)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        let dateString = dateFormatter.string(from: creationDate)
        try container.encode(dateString, forKey: .creationDate)
    }
}

public extension Array where Element == ClassifiedAd {
    func sortedByDateAndUrgency() -> [ClassifiedAd] {
        return self.sorted { lhs, rhs in
            if lhs.isUrgent != rhs.isUrgent {
                return lhs.isUrgent
            }
            return lhs.creationDate > rhs.creationDate
        }
    }
    
    func filtered(by categoryId: Int?) -> [ClassifiedAd] {
        guard let categoryId = categoryId, categoryId != Category.all.id else {
            return self
        }
        return self.filter { $0.categoryId == categoryId }
    }
} 