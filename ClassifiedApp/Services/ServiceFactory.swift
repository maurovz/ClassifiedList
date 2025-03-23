import Foundation
import ClassifiedCoreKit
import UIKit

class ServiceFactory {
    static let shared = ServiceFactory()
    
    private init() {}
    
    // MARK: - Factory Methods
    
    func createClassifiedRepository() -> CoreClassifiedRepository {
        return CoreClassifiedRepository(service: createClassifiedService())
    }
    
    func createClassifiedService() -> CoreClassifiedService {
        return CoreClassifiedService(apiClient: createAPIClient())
    }
    
    func createAPIClient() -> CoreAPIClient {
        do {
            let cacheManager = try createCacheManager()
            return CoreAPIClient(cache: cacheManager)
        } catch {
            print("Failed to create cache manager: \(error.localizedDescription)")
            return CoreAPIClient(cache: createMemoryCache())
        }
    }
    
    func createCacheManager() throws -> CoreCacheManager {
        return try CoreCacheManager()
    }
    
    func createMemoryCache() -> CoreCacheManagerProtocol {
        return InMemoryCacheManager()
    }
    
    func createImageLoader() -> CoreImageLoader {
        return CoreImageLoader.shared
    }
    
    // MARK: - View Controllers Factory Methods
    
    func createClassifiedListViewController() -> UIViewController {
        let repository = createClassifiedRepository()
        let viewModel = ClassifiedListViewModel(repository: repository)
        let imageLoader = createImageLoader()
        return ClassifiedListViewController(viewModel: viewModel, imageLoader: imageLoader)
    }
    
    func createClassifiedDetailViewController(classifiedAd: CoreClassifiedAd, categoryName: String) -> UIViewController {
        let imageLoader = createImageLoader()
        return ClassifiedDetailViewController(classifiedAd: classifiedAd, categoryName: categoryName, imageLoader: imageLoader)
    }
}
