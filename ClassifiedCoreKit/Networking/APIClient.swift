import Foundation

public enum APIError: Error {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case decodingFailed(Error)
    case serverError(statusCode: Int)
    case noData
    
    public var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .requestFailed(let error):
            return "Request failed: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid server response"
        case .decodingFailed(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .serverError(let statusCode):
            return "Server error with status code: \(statusCode)"
        case .noData:
            return "No data received"
        }
    }
}

public protocol APIClientProtocol {
    func fetch<T: Decodable>(from endpoint: Endpoint) async throws -> T
}

public final class APIClient: APIClientProtocol {
    private let session: URLSession
    private let cache: CacheManagerProtocol
    
    public init(session: URLSession = .shared, cache: CacheManagerProtocol) {
        self.session = session
        self.cache = cache
    }
    
    public func fetch<T: Decodable>(from endpoint: Endpoint) async throws -> T {
        // Try to get from cache first
        if let cachedData: T = try? cache.fetch(for: endpoint.url.absoluteString) {
            return cachedData
        }
        
        // If not in cache, perform network request
        guard let url = URL(string: endpoint.url.absoluteString) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                throw APIError.serverError(statusCode: httpResponse.statusCode)
            }
            
            guard !data.isEmpty else {
                throw APIError.noData
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let decodedData = try decoder.decode(T.self, from: data)
                
                // Save to cache
                try cache.save(decodedData, for: endpoint.url.absoluteString)
                
                return decodedData
            } catch {
                throw APIError.decodingFailed(error)
            }
        } catch {
            if let apiError = error as? APIError {
                throw apiError
            }
            throw APIError.requestFailed(error)
        }
    }
} 