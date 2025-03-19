import Foundation

public enum APIError: Error {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case decodingFailed(Error)
    case serverError(statusCode: Int)
    case noData
    case maxRetryReached
    
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
        case .maxRetryReached:
            return "Maximum retry attempts reached"
        }
    }
}

public protocol URLSessionProtocol {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol {}

public protocol APIClientProtocol {
    func fetch<T: Codable>(from endpoint: Endpoint) async throws -> T
}

public final class APIClient: APIClientProtocol {
    private let session: URLSessionProtocol
    private let cache: CacheManagerProtocol
    
    public init(session: URLSessionProtocol = URLSession.shared, cache: CacheManagerProtocol) {
        self.session = session
        self.cache = cache
    }
    
    public func fetch<T: Codable>(from endpoint: Endpoint) async throws -> T {
        if let cachedData: T = try? cache.fetch(for: endpoint.url.absoluteString) {
            return cachedData
        }
        
        guard let url = URL(string: endpoint.url.absoluteString) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.timeoutInterval = endpoint.timeoutInterval
        
        var attemptCount = 0
        var lastError: Error?
        
        repeat {
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
                    
                    try cache.save(decodedData, for: endpoint.url.absoluteString)
                    
                    return decodedData
                } catch {
                    throw APIError.decodingFailed(error)
                }
            } catch {
                lastError = error
                attemptCount += 1
                
                if attemptCount <= endpoint.retryCount {
                    if let nsError = error as NSError?,
                       nsError.domain == NSURLErrorDomain,
                       [NSURLErrorTimedOut, NSURLErrorNetworkConnectionLost, NSURLErrorNotConnectedToInternet].contains(nsError.code) {
                        // This is a retryable network error, wait before retrying
                        let delay = calculateBackoff(attempt: attemptCount)
                        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        continue
                    }
                }
                
                if let apiError = error as? APIError {
                    throw apiError
                }
                throw APIError.requestFailed(error)
            }
        } while attemptCount <= endpoint.retryCount
        
        if let lastError = lastError {
            throw APIError.requestFailed(lastError)
        } else {
            throw APIError.maxRetryReached
        }
    }
    
    private func calculateBackoff(attempt: Int) -> Double {
        // Exponential backoff with jitter
        let base = min(30.0, pow(2.0, Double(attempt)))
        let jitter = Double.random(in: 0...0.5)
        return base + jitter
    }
} 