import Foundation

public enum APIError: Error {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case decodingFailed(Error)
    case serverError(statusCode: Int)
    case noData
    case maxRetryReached
    case cancelled
    
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
        case .cancelled:
            return "Request was cancelled"
        }
    }
}

public protocol URLSessionProtocol {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTaskProtocol
}

public protocol URLSessionDataTaskProtocol {
    func cancel()
    func resume()
}

extension URLSessionTask: URLSessionDataTaskProtocol {}

extension URLSession: URLSessionProtocol {
    public func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTaskProtocol {
        return dataTask(with: request, completionHandler: completionHandler) as URLSessionDataTask
    }
}

public protocol APIClientProtocol {
    func fetch<T: Codable>(from endpoint: Endpoint) async throws -> T
    func cancelAllRequests()
}

public final class APIClient: APIClientProtocol {
    private let session: URLSessionProtocol
    private let cache: CacheManagerProtocol
    private var activeTasks = [URLSessionDataTaskProtocol]()
    private let taskLock = NSLock()
    
    private var taskCancelled = false
    
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
                // Check if the task was cancelled
                if Task.isCancelled || taskCancelled {
                    throw APIError.cancelled
                }
                
                let (data, response) = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<(Data, URLResponse), Error>) in
                    let task = session.dataTask(with: request) { data, response, error in
                        if let error = error {
                            continuation.resume(throwing: error)
                            return
                        }
                        
                        guard let data = data, let response = response else {
                            continuation.resume(throwing: APIError.noData)
                            return
                        }
                        
                        continuation.resume(returning: (data, response))
                    }
                    
                    // Add task to active tasks
                    taskLock.lock()
                    activeTasks.append(task)
                    taskLock.unlock()
                    
                    task.resume()
                }
                
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
                // If the task was cancelled, propagate the cancellation
                if let urlError = error as? URLError, urlError.code == .cancelled {
                    throw APIError.cancelled
                }
                
                if case APIError.cancelled = error {
                    throw error
                }
                
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
    
    public func cancelAllRequests() {
        taskCancelled = true
        
        taskLock.lock()
        let tasks = activeTasks
        taskLock.unlock()
        
        for task in tasks {
            task.cancel()
        }
        
        taskLock.lock()
        activeTasks.removeAll()
        taskLock.unlock()
    }
    
    private func calculateBackoff(attempt: Int) -> Double {
        // Exponential backoff with jitter
        let base = min(30.0, pow(2.0, Double(attempt)))
        let jitter = Double.random(in: 0...0.5)
        return base + jitter
    }
} 