import Foundation
import ClassifiedCoreKit

class ServiceFactory {
    
    // Singleton instance for convenient access
    static let shared = ServiceFactory()
    
    // Private init for singleton
    private init() {}
    
    // MARK: - Factory Methods
    
    func createClassifiedRepository() -> CoreClassifiedRepository {
        return CoreClassifiedRepository(service: createClassifiedService())
    }
    
    func createClassifiedService() -> CoreClassifiedService {
        return CoreClassifiedService(apiClient: createAPIClient())
    }
    
    func createAPIClient() -> CoreAPIClient {
        // Use a do-catch block to handle the potentially throwing initializer
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