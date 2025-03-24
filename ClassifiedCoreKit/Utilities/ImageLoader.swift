import Foundation
import UIKit

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
    
    public func loadImage(from url: URL?, completion: @escaping (Result<UIImage, ImageLoadingError>) -> Void) {
        guard let url = url else {
            completion(.failure(.invalidURL))
            return
        }
        
        let key = url.absoluteString as NSString
        
        if let cachedImage = cache.object(forKey: key) as? UIImage {
            completion(.success(cachedImage))
            return
        }
        
        let task = session.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                completion(.failure(.networkError(error)))
                return
            }
            
            guard let data = data, !data.isEmpty else {
                completion(.failure(.invalidData))
                return
            }
            
            guard let image = UIImage(data: data) else {
                completion(.failure(.decodingError))
                return
            }
            
            self?.cache.setObject(image, forKey: key)
            
            completion(.success(image))
        }
        
        task.resume()
    }
    
    public func clearCache() {
        cache.removeAllObjects()
    }
} 
