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
    private var allAds: [CoreClassifiedAd] = []
    private(set) var filteredAds: [CoreClassifiedAd] = []
    private(set) var categories: [ClassifiedCoreKit.Category] = []
    private(set) var selectedCategoryId: Int? = Category.all.id
    
    var onStateChange: ((State) -> Void)?
    
    // MARK: - Initialization
    init(repository: CoreClassifiedRepository) {
        self.repository = repository
    }
    
    // MARK: - Public Methods
    func loadCategories() {
        repository.getCategories { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let categories):
                self.categories = [Category.all] + categories
                self.onStateChange?(.categoriesLoaded)
                
            case .failure(let error):
                self.onStateChange?(.error("Failed to load categories: \(error.localizedDescription)"))
            }
        }
    }
    
    func loadClassifiedAds() {
        onStateChange?(.loading)
        
        repository.getClassifiedAds { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let ads):
                self.allAds = ads
                self.filterAds(by: self.selectedCategoryId)
                self.onStateChange?(.loaded)
                
            case .failure(let error):
                self.onStateChange?(.error("Failed to load classified ads: \(error.localizedDescription)"))
            }
        }
    }
    
    func filterAds(by categoryId: Int?) {
        self.selectedCategoryId = categoryId
        
        if categoryId == Category.all.id {
            // If "All" category is selected, show all ads but sort urgent ones first
            filteredAds = sortedAds(allAds)
        } else {
            // Filter by category and sort (urgent first)
            let filtered = allAds.filter { $0.categoryId == categoryId }
            filteredAds = sortedAds(filtered)
        }
        
        // Notify that the data has changed
        onStateChange?(.loaded)
    }
    
    func getCategoryName(for categoryId: Int) -> String {
        return categories.first(where: { $0.id == categoryId })?.name ?? "Unknown"
    }
    
    func refreshData() {
        loadCategories()
        loadClassifiedAds()
    }
    
    // MARK: - Private Methods
    private func sortedAds(_ ads: [CoreClassifiedAd]) -> [CoreClassifiedAd] {
        // Sort by urgency (urgent first) and then by date
        return ads.sorted { (first, second) -> Bool in
            if first.isUrgent != second.isUrgent {
                return first.isUrgent
            }
            return first.creationDate > second.creationDate
        }
    }
} 