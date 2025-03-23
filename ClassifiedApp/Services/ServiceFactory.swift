import Foundation
import ClassifiedCoreKit

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
}
