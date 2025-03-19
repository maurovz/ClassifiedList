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
    func fetch<T: Codable>(from endpoint: Endpoint, completion: @escaping (Result<T, Error>) -> Void)
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
    
    public func fetch<T: Codable>(from endpoint: Endpoint, completion: @escaping (Result<T, Error>) -> Void) {
        // Try to get cached data first
        if let cachedData: T = try? cache.fetch(for: endpoint.url.absoluteString) {
            completion(.success(cachedData))
            return
        }
        
        guard let url = URL(string: endpoint.url.absoluteString) else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.timeoutInterval = endpoint.timeoutInterval
        
        performRequest(request: request, endpoint: endpoint, attemptCount: 0, completion: completion)
    }
    
    private func performRequest<T: Codable>(
        request: URLRequest,
        endpoint: Endpoint,
        attemptCount: Int,
        lastError: Error? = nil,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        // Check if the task was cancelled
        if taskCancelled {
            completion(.failure(APIError.cancelled))
            return
        }
        
        let task = session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            // Handle cancellation
            if let error = error as NSError?, error.domain == NSURLErrorDomain, error.code == NSURLErrorCancelled {
                completion(.failure(APIError.cancelled))
                return
            }
            
            // Handle other errors
            if let error = error {
                self.handleRequestError(
                    error: error,
                    request: request,
                    endpoint: endpoint,
                    attemptCount: attemptCount,
                    completion: completion
                )
                return
            }
            
            guard let data = data, let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(APIError.noData))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(APIError.serverError(statusCode: httpResponse.statusCode)))
                return
            }
            
            guard !data.isEmpty else {
                completion(.failure(APIError.noData))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let decodedData = try decoder.decode(T.self, from: data)
                
                // Try to save to cache
                try? self.cache.save(decodedData, for: endpoint.url.absoluteString)
                
                completion(.success(decodedData))
            } catch {
                completion(.failure(APIError.decodingFailed(error)))
            }
        }
        
        // Add task to active tasks
        taskLock.lock()
        activeTasks.append(task)
        taskLock.unlock()
        
        task.resume()
    }
    
    private func handleRequestError<T: Codable>(
        error: Error,
        request: URLRequest,
        endpoint: Endpoint,
        attemptCount: Int,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        let nextAttempt = attemptCount + 1
        
        if nextAttempt <= endpoint.retryCount {
            if let nsError = error as NSError?,
               nsError.domain == NSURLErrorDomain,
               [NSURLErrorTimedOut, NSURLErrorNetworkConnectionLost, NSURLErrorNotConnectedToInternet].contains(nsError.code) {
                // This is a retryable network error, wait before retrying
                let delay = calculateBackoff(attempt: nextAttempt)
                
                DispatchQueue.global().asyncAfter(deadline: .now() + delay) { [weak self] in
                    guard let self = self else { return }
                    
                    // Check if the task was cancelled during the delay
                    if self.taskCancelled {
                        completion(.failure(APIError.cancelled))
                        return
                    }
                    
                    self.performRequest(
                        request: request,
                        endpoint: endpoint,
                        attemptCount: nextAttempt,
                        lastError: error,
                        completion: completion
                    )
                }
                return
            }
        }
        
        // If we've reached the maximum retry count or the error isn't retryable
        if attemptCount >= endpoint.retryCount {
            completion(.failure(APIError.maxRetryReached))
        } else if let apiError = error as? APIError {
            completion(.failure(apiError))
        } else {
            completion(.failure(APIError.requestFailed(error)))
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