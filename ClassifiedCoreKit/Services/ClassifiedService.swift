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
    private var categoriesCache: [Category]?
    private var classifiedAdsCache: [ClassifiedAd]?
    
    public init(service: ClassifiedServiceProtocol) {
        self.service = service
    }
    
    public func getCategories(forceRefresh: Bool = false) async throws -> [Category] {
        if !forceRefresh, let categories = categoriesCache {
            return categories
        }
        
        let categories = try await service.fetchCategories()
        self.categoriesCache = categories
        
        return categories
    }
    
    public func getClassifiedAds(forceRefresh: Bool = false) async throws -> [ClassifiedAd] {
        if !forceRefresh, let ads = classifiedAdsCache {
            return ads
        }
        
        let ads = try await service.fetchClassifiedAds()
        self.classifiedAdsCache = ads
        
        return ads
    }
    
    public func getClassifiedAdsWithCategoryName(forceRefresh: Bool = false) async throws -> [(ClassifiedAd, String)] {
        async let adsResult = getClassifiedAds(forceRefresh: forceRefresh)
        async let categoriesResult = getCategories(forceRefresh: forceRefresh)
        
        let (ads, categories) = try await (adsResult, categoriesResult)
        
        let categoryDict = Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0.name) })
        
        return ads.map { ad in
            let categoryName = categoryDict[ad.categoryId] ?? "Unknown Category"
            return (ad, categoryName)
        }
    }
    
    public func getClassifiedAds(filteredBy categoryId: Int?, forceRefresh: Bool = false) async throws -> [ClassifiedAd] {
        let ads = try await getClassifiedAds(forceRefresh: forceRefresh)
        
        if categoryId == nil || categoryId == Category.all.id {
            return ads
        }
        
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