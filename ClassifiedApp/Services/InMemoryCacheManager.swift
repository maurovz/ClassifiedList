import Foundation
import ClassifiedCoreKit

/// A simple in-memory implementation of CacheManagerProtocol for when file-based caching fails
final class InMemoryCacheManager: CoreCacheManagerProtocol {
    private let memoryCache = NSCache<NSString, NSData>()
    
    func save<T: Encodable>(_ data: T, for key: String) throws {
        let encoder = JSONEncoder()
        do {
            let encodedData = try encoder.encode(data)
            memoryCache.setObject(encodedData as NSData, forKey: key as NSString)
        } catch {
            throw CoreCacheError.saveFailed(error)
        }
    }
    
    func fetch<T: Decodable>(for key: String) throws -> T {
        guard let cachedData = memoryCache.object(forKey: key as NSString) else {
            throw CoreCacheError.notFound(key)
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: cachedData as Data)
        } catch {
            throw CoreCacheError.decodeFailed(error)
        }
    }
    
    func remove(for key: String) throws {
        memoryCache.removeObject(forKey: key as NSString)
    }
    
    func clearCache() throws {
        memoryCache.removeAllObjects()
    }
} 