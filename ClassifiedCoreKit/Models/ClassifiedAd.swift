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
    
    // HashableID for collections that need Hashable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: ClassifiedAd, rhs: ClassifiedAd) -> Bool {
        lhs.id == rhs.id
    }
    
    // Computed property for formatted price
    public var formattedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "€"
        formatter.minimumFractionDigits = price.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 2
        return formatter.string(from: NSNumber(value: price)) ?? "\(price) €"
    }
    
    // Computed property for formatted date
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
}

// Extension for date decoding strategy
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
        
        // Handle date decoding
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
}

// Extension for sorting
public extension Array where Element == ClassifiedAd {
    /// Sorts classified ads by date (newest first) with urgent items at the top
    func sortedByDateAndUrgency() -> [ClassifiedAd] {
        return self.sorted { lhs, rhs in
            if lhs.isUrgent != rhs.isUrgent {
                return lhs.isUrgent
            }
            return lhs.creationDate > rhs.creationDate
        }
    }
    
    /// Filters classified ads by categoryId
    func filtered(by categoryId: Int?) -> [ClassifiedAd] {
        guard let categoryId = categoryId, categoryId != Category.all.id else {
            return self
        }
        return self.filter { $0.categoryId == categoryId }
    }
} 