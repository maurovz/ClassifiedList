import Foundation

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

public enum ImageLoadingError: Error {
    case invalidURL
    case networkError(Error)
    case invalidData
    case decodingError
    
    public var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid image URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidData:
            return "Invalid image data received"
        case .decodingError:
            return "Failed to decode image"
        }
    }
}

public class ImageLoader {
    private let session: URLSession
    private let cache: NSCache<NSString, AnyObject>
    
    public static let shared = ImageLoader()
    
    private init(session: URLSession = .shared) {
        self.session = session
        self.cache = NSCache<NSString, AnyObject>()
        self.cache.countLimit = 100
    }
    
    #if canImport(UIKit)
    public func loadImage(from url: URL?) async throws -> UIImage {
        guard let url = url else {
            throw ImageLoadingError.invalidURL
        }
        
        let key = url.absoluteString as NSString
        
        if let cachedImage = cache.object(forKey: key) as? UIImage {
            return cachedImage
        }
        
        do {
            let (data, _) = try await session.data(from: url)
            
            guard !data.isEmpty else {
                throw ImageLoadingError.invalidData
            }
            
            guard let image = UIImage(data: data) else {
                throw ImageLoadingError.decodingError
            }
            
            cache.setObject(image, forKey: key)
            
            return image
        } catch {
            throw ImageLoadingError.networkError(error)
        }
    }
    #endif
    
    #if canImport(AppKit)
    public func loadImage(from url: URL?) async throws -> NSImage {
        guard let url = url else {
            throw ImageLoadingError.invalidURL
        }
        
        let key = url.absoluteString as NSString
        
        if let cachedImage = cache.object(forKey: key) as? NSImage {
            return cachedImage
        }
        
        do {
            let (data, _) = try await session.data(from: url)
            
            guard !data.isEmpty else {
                throw ImageLoadingError.invalidData
            }
            
            guard let image = NSImage(data: data) else {
                throw ImageLoadingError.decodingError
            }
            
            cache.setObject(image, forKey: key)
            
            return image
        } catch {
            throw ImageLoadingError.networkError(error)
        }
    }
    #endif
    
    public func clearCache() {
        cache.removeAllObjects()
    }
} 