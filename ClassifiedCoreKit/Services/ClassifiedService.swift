import Foundation

public protocol ClassifiedServiceProtocol {
    func fetchCategories() async throws -> [Category]
    func fetchClassifiedAds() async throws -> [ClassifiedAd]
}

public final class ClassifiedService: ClassifiedServiceProtocol {
    private let apiClient: APIClientProtocol
    
    public init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }
    
    public func fetchCategories() async throws -> [Category] {
        return try await apiClient.fetch(from: Endpoint.categories)
    }
    
    public func fetchClassifiedAds() async throws -> [ClassifiedAd] {
        return try await apiClient.fetch(from: Endpoint.classifieds)
    }
}

public final class ClassifiedRepository {
    private let service: ClassifiedServiceProtocol
    
    // In-memory storage
    private var categoriesCache: [Category]?
    private var classifiedAdsCache: [ClassifiedAd]?
    
    public init(service: ClassifiedServiceProtocol) {
        self.service = service
    }
    
    // MARK: - Public methods
    
    public func getCategories(forceRefresh: Bool = false) async throws -> [Category] {
        if !forceRefresh, let categories = categoriesCache {
            return categories
        }
        
        // Fetch from service
        let categories = try await service.fetchCategories()
        
        // Update in-memory cache
        self.categoriesCache = categories
        
        return categories
    }
    
    public func getClassifiedAds(forceRefresh: Bool = false) async throws -> [ClassifiedAd] {
        if !forceRefresh, let ads = classifiedAdsCache {
            return ads
        }
        
        // Fetch from service
        let ads = try await service.fetchClassifiedAds()
        
        // Update in-memory cache
        self.classifiedAdsCache = ads
        
        return ads
    }
    
    public func getClassifiedAdsWithCategoryName(forceRefresh: Bool = false) async throws -> [(ClassifiedAd, String)] {
        // Get classified ads and categories
        async let adsResult = getClassifiedAds(forceRefresh: forceRefresh)
        async let categoriesResult = getCategories(forceRefresh: forceRefresh)
        
        let (ads, categories) = try await (adsResult, categoriesResult)
        
        // Create a dictionary for fast category lookup
        let categoryDict = Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0.name) })
        
        // Map ads to tuples containing the ad and its category name
        return ads.map { ad in
            let categoryName = categoryDict[ad.categoryId] ?? "Unknown Category"
            return (ad, categoryName)
        }
    }
    
    public func getClassifiedAds(filteredBy categoryId: Int?, forceRefresh: Bool = false) async throws -> [ClassifiedAd] {
        let ads = try await getClassifiedAds(forceRefresh: forceRefresh)
        
        // If categoryId is nil or matches the "all" category, return all ads
        if categoryId == nil || categoryId == Category.all.id {
            return ads
        }
        
        // Otherwise filter by category
        return ads.filter { $0.categoryId == categoryId }
    }
    
    public func getClassifiedAds(sortedBy sortOption: SortOption, forceRefresh: Bool = false) async throws -> [ClassifiedAd] {
        let ads = try await getClassifiedAds(forceRefresh: forceRefresh)
        
        switch sortOption {
        case .dateDescending:
            return ads.sorted(by: { $0.creationDate > $1.creationDate })
        case .dateAscending:
            return ads.sorted(by: { $0.creationDate < $1.creationDate })
        case .priceAscending:
            return ads.sorted(by: { $0.price < $1.price })
        case .priceDescending:
            return ads.sorted(by: { $0.price > $1.price })
        case .urgentFirst:
            return ads.sortedByDateAndUrgency()
        }
    }
}

public enum SortOption {
    case dateDescending
    case dateAscending
    case priceAscending
    case priceDescending
    case urgentFirst
} 