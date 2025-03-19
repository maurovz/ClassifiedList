import Foundation

public protocol CacheManagerProtocol {
    func save<T: Encodable>(_ data: T, for key: String) throws
    func fetch<T: Decodable>(for key: String) throws -> T
    func remove(for key: String) throws
    func clearCache() throws
}

public final class CacheManager: CacheManagerProtocol {
    private let fileManager: FileManager
    private let cacheDirectory: URL
    private let memoryCache = NSCache<NSString, NSData>()
    
    public init(fileManager: FileManager = .default) throws {
        self.fileManager = fileManager
        
        guard let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            throw CacheError.noCacheDirectory
        }
        
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.classifiedlist.app"
        self.cacheDirectory = cacheDir.appendingPathComponent(bundleIdentifier)
        
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
    }
    
    public func save<T: Encodable>(_ data: T, for key: String) throws {
        let encoder = JSONEncoder()
        do {
            let encodedData = try encoder.encode(data)
            
            memoryCache.setObject(encodedData as NSData, forKey: key as NSString)
            
            let fileURL = cacheURL(for: key)
            try encodedData.write(to: fileURL, options: .atomic)
        } catch {
            throw CacheError.saveFailed(error)
        }
    }
    
    public func fetch<T: Decodable>(for key: String) throws -> T {
        if let cachedData = memoryCache.object(forKey: key as NSString) {
            return try decode(data: cachedData as Data)
        }
        
        let fileURL = cacheURL(for: key)
        guard fileManager.fileExists(atPath: fileURL.path) else {
            throw CacheError.notFound(key)
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            
            memoryCache.setObject(data as NSData, forKey: key as NSString)
            
            return try decode(data: data)
        } catch {
            throw CacheError.readFailed(error)
        }
    }
    
    public func remove(for key: String) throws {
        memoryCache.removeObject(forKey: key as NSString)
        
        let fileURL = cacheURL(for: key)
        if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
        }
    }
    
    public func clearCache() throws {
        memoryCache.removeAllObjects()
        
        let contents = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
        for fileURL in contents {
            try fileManager.removeItem(at: fileURL)
        }
    }
    
    private func cacheURL(for key: String) -> URL {
        let sanitizedKey = key
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")
        return cacheDirectory.appendingPathComponent(sanitizedKey)
    }
    
    private func decode<T: Decodable>(data: Data) throws -> T {
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            throw CacheError.decodeFailed(error)
        }
    }
}

public enum CacheError: Error {
    case noCacheDirectory
    case saveFailed(Error)
    case readFailed(Error)
    case decodeFailed(Error)
    case notFound(String)
    
    public var localizedDescription: String {
        switch self {
        case .noCacheDirectory:
            return "Failed to locate cache directory"
        case .saveFailed(let error):
            return "Failed to save to cache: \(error.localizedDescription)"
        case .readFailed(let error):
            return "Failed to read from cache: \(error.localizedDescription)"
        case .decodeFailed(let error):
            return "Failed to decode cache data: \(error.localizedDescription)"
        case .notFound(let key):
            return "Cache item not found for key: \(key)"
        }
    }
} 