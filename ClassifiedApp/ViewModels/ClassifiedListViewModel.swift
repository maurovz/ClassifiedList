import Foundation
import ClassifiedCoreKit

class ClassifiedListViewModel {
    
    // MARK: - Types
    enum State {
        case idle
        case loading
        case loaded
        case error(String)
        case categoriesLoaded
    }
    
    // MARK: - Properties
    private let repository: CoreClassifiedRepository
    
    private(set) var ads: [CoreClassifiedAd] = []
    private(set) var filteredAds: [CoreClassifiedAd] = []
    private(set) var categories: [CoreCategory] = []
    
    var onStateChange: ((State) -> Void)?
    
    // MARK: - Initialization
    init(repository: CoreClassifiedRepository) {
        self.repository = repository
    }
    
    // MARK: - Public Methods
    func loadCategories() {
        onStateChange?(.loading)
        
        repository.getCategories { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(var categories):
                // Add the "All Categories" option
                categories.insert(CoreCategory.all, at: 0)
                self.categories = categories
                self.onStateChange?(.categoriesLoaded)
                
            case .failure(let error):
                self.onStateChange?(.error("Failed to load categories: \(error.localizedDescription)"))
            }
        }
    }
    
    func loadClassifiedAds() {
        onStateChange?(.loading)
        
        repository.getClassifiedAds(sortedBy: .urgentFirst) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let ads):
                self.ads = ads
                self.filteredAds = ads
                self.onStateChange?(.loaded)
                
            case .failure(let error):
                self.onStateChange?(.error("Failed to load ads: \(error.localizedDescription)"))
            }
        }
    }
    
    func filterAds(by categoryId: Int?) {
        if categoryId == CoreCategory.all.id || categoryId == nil {
            filteredAds = ads
        } else {
            filteredAds = ads.filter { $0.categoryId == categoryId }
        }
        onStateChange?(.loaded)
    }
    
    func getCategoryName(for categoryId: Int) -> String {
        return categories.first(where: { $0.id == categoryId })?.name ?? "Unknown Category"
    }
    
    func refreshData() {
        loadCategories()
        loadClassifiedAds()
    }
} 