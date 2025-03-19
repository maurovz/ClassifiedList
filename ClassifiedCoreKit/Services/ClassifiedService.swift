import Foundation

public protocol ClassifiedServiceProtocol {
    func fetchCategories(completion: @escaping (Result<[Category], Error>) -> Void)
    func fetchClassifiedAds(completion: @escaping (Result<[ClassifiedAd], Error>) -> Void)
}

public final class ClassifiedService: ClassifiedServiceProtocol {
    private let apiClient: APIClientProtocol
    
    public init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }
    
    public func fetchCategories(completion: @escaping (Result<[Category], Error>) -> Void) {
        apiClient.fetch(from: Endpoint.categories, completion: completion)
    }
    
    public func fetchClassifiedAds(completion: @escaping (Result<[ClassifiedAd], Error>) -> Void) {
        apiClient.fetch(from: Endpoint.classifieds, completion: completion)
    }
}

public final class ClassifiedRepository {
    private let service: ClassifiedServiceProtocol
    private var categoriesCache: [Category]?
    private var classifiedAdsCache: [ClassifiedAd]?
    
    public init(service: ClassifiedServiceProtocol) {
        self.service = service
    }
    
    public func getCategories(forceRefresh: Bool = false, completion: @escaping (Result<[Category], Error>) -> Void) {
        if !forceRefresh, let categories = categoriesCache {
            completion(.success(categories))
            return
        }
        
        service.fetchCategories { [weak self] result in
            switch result {
            case .success(let categories):
                self?.categoriesCache = categories
                completion(.success(categories))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func getClassifiedAds(forceRefresh: Bool = false, completion: @escaping (Result<[ClassifiedAd], Error>) -> Void) {
        if !forceRefresh, let ads = classifiedAdsCache {
            completion(.success(ads))
            return
        }
        
        service.fetchClassifiedAds { [weak self] result in
            switch result {
            case .success(let ads):
                self?.classifiedAdsCache = ads
                completion(.success(ads))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func getClassifiedAdsWithCategoryName(forceRefresh: Bool = false, completion: @escaping (Result<[(ClassifiedAd, String)], Error>) -> Void) {
        let group = DispatchGroup()
        
        var adsResult: Result<[ClassifiedAd], Error>?
        var categoriesResult: Result<[Category], Error>?
        
        group.enter()
        getClassifiedAds(forceRefresh: forceRefresh) { result in
            adsResult = result
            group.leave()
        }
        
        group.enter()
        getCategories(forceRefresh: forceRefresh) { result in
            categoriesResult = result
            group.leave()
        }
        
        group.notify(queue: .main) {
            guard let adsResult = adsResult, let categoriesResult = categoriesResult else {
                completion(.failure(NSError(domain: "ClassifiedRepository", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to get results"])))
                return
            }
            
            switch (adsResult, categoriesResult) {
            case (.success(let ads), .success(let categories)):
                let categoryDict = Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0.name) })
                let result = ads.map { ad in
                    let categoryName = categoryDict[ad.categoryId] ?? "Unknown Category"
                    return (ad, categoryName)
                }
                completion(.success(result))
            case (.failure(let error), _):
                completion(.failure(error))
            case (_, .failure(let error)):
                completion(.failure(error))
            }
        }
    }
    
    public func getClassifiedAds(filteredBy categoryId: Int?, forceRefresh: Bool = false, completion: @escaping (Result<[ClassifiedAd], Error>) -> Void) {
        getClassifiedAds(forceRefresh: forceRefresh) { result in
            switch result {
            case .success(let ads):
                if categoryId == nil || categoryId == Category.all.id {
                    completion(.success(ads))
                } else {
                    let filteredAds = ads.filter { $0.categoryId == categoryId }
                    completion(.success(filteredAds))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func getClassifiedAds(sortedBy sortOption: SortOption, forceRefresh: Bool = false, completion: @escaping (Result<[ClassifiedAd], Error>) -> Void) {
        getClassifiedAds(forceRefresh: forceRefresh) { result in
            switch result {
            case .success(let ads):
                let sortedAds: [ClassifiedAd]
                
                switch sortOption {
                case .dateDescending:
                    sortedAds = ads.sorted(by: { $0.creationDate > $1.creationDate })
                case .dateAscending:
                    sortedAds = ads.sorted(by: { $0.creationDate < $1.creationDate })
                case .priceAscending:
                    sortedAds = ads.sorted(by: { $0.price < $1.price })
                case .priceDescending:
                    sortedAds = ads.sorted(by: { $0.price > $1.price })
                case .urgentFirst:
                    sortedAds = ads.sortedByDateAndUrgency()
                }
                
                completion(.success(sortedAds))
            case .failure(let error):
                completion(.failure(error))
            }
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