import XCTest
@testable import ClassifiedCoreKit

final class APIClientTests: XCTestCase {
    
    var mockCache: MockCacheManager!
    var mockSession: MockURLSession!
    var sut: APIClient! // System under test
    
    override func setUp() {
        super.setUp()
        mockCache = MockCacheManager()
        mockSession = MockURLSession()
        sut = APIClient(session: mockSession, cache: mockCache)
    }
    
    override func tearDown() {
        mockCache = nil
        mockSession = nil
        sut = nil
        super.tearDown()
    }
    
    func testFetchWithTimeout() async {
        // Set up mock session to simulate timeout
        let endpoint = Endpoint(url: URL(string: "https://example.com/test")!)
        let timeoutError = NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut, userInfo: nil)
        mockSession.mockError = timeoutError
        
        do {
            let _: [String: String] = try await sut.fetch(from: endpoint)
            XCTFail("Expected fetch to throw a timeout error")
        } catch {
            if case APIError.requestFailed(let underlyingError) = error {
                XCTAssertEqual((underlyingError as NSError).code, NSURLErrorTimedOut)
            } else {
                XCTFail("Unexpected error type: \(error)")
            }
        }
    }
    
    func testFetchWithRetry() async {
        // Configure endpoint with retry count
        let endpoint = Endpoint(url: URL(string: "https://example.com/test")!, method: .get, retryCount: 3)
        
        // First two attempts fail, third succeeds
        mockSession.mockResponses = [
            .failure(NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut, userInfo: nil)),
            .failure(NSError(domain: NSURLErrorDomain, code: NSURLErrorNetworkConnectionLost, userInfo: nil)),
            .success((Data("{\"success\": true}".utf8), HTTPURLResponse(url: endpoint.url, statusCode: 200, httpVersion: nil, headerFields: nil)!))
        ]
        
        do {
            let result: [String: Bool] = try await sut.fetch(from: endpoint)
            XCTAssertEqual(result["success"], true)
            XCTAssertEqual(mockSession.requestCount, 3)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testRequestCancellation() async {
        // Configure endpoint
        let endpoint = Endpoint(url: URL(string: "https://example.com/test")!)
        
        // Prepare mock to handle cancellation
        mockSession.shouldCancelRequests = true
        
        // Set up a task that will be cancelled
        let task = Task {
            do {
                let _: [String: String] = try await sut.fetch(from: endpoint)
                XCTFail("Expected fetch to throw a cancellation error")
                return false
            } catch {
                // Check any form of cancellation error
                if case APIError.cancelled = error {
                    return true
                } else if let urlError = error as? URLError, urlError.code == .cancelled {
                    return true
                } else if case APIError.requestFailed(let underlyingError) = error,
                          let urlError = underlyingError as? URLError, 
                          urlError.code == .cancelled {
                    return true
                }
                
                XCTFail("Expected cancellation error, got \(error)")
                return false
            }
        }
        
        // Give the task a moment to start
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Cancel the request
        sut.cancelAllRequests()
        
        // Check the result
        let result = await task.value
        XCTAssertTrue(result, "Task should have been cancelled")
    }
    
    func testCancelAllRequests() async {
        // Set up a long-running request
        let endpoint = Endpoint(url: URL(string: "https://example.com/test")!)
        let longTask = Task {
            do {
                let _: [String: String] = try await sut.fetch(from: endpoint)
                XCTFail("Request should have been cancelled")
                return true
            } catch {
                if let urlError = error as? URLError, urlError.code == .cancelled {
                    return true // Successfully cancelled
                } else if case APIError.cancelled = error {
                    return true // Successfully cancelled with our custom error
                }
                XCTFail("Unexpected error: \(error)")
                return false
            }
        }
        
        // Cancel the request
        mockSession.shouldCancelRequests = true
        sut.cancelAllRequests()
        
        // Verify the task was cancelled
        let result = await longTask.value
        XCTAssertTrue(result, "Request should have been cancelled")
    }
}

// MARK: - Mock Classes

class MockURLSession: URLSessionProtocol {
    enum MockResponse {
        case success((Data, URLResponse))
        case failure(Error)
    }
    
    var mockError: Error?
    var mockData: Data?
    var mockResponse: URLResponse?
    var mockResponses: [MockResponse] = []
    var requestCount = 0
    var shouldCancelRequests = false
    var dataTaskCalled = false
    var tasks: [MockTask] = []
    
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        requestCount += 1
        dataTaskCalled = true
        
        if shouldCancelRequests {
            throw URLError(.cancelled)
        }
        
        if !mockResponses.isEmpty {
            if requestCount <= mockResponses.count {
                let response = mockResponses[requestCount - 1]
                switch response {
                case .success(let result):
                    return result
                case .failure(let error):
                    throw error
                }
            }
        }
        
        if let mockError = mockError {
            throw mockError
        }
        
        guard let mockData = mockData, let mockResponse = mockResponse else {
            throw NSError(domain: "MockURLSession", code: 0, userInfo: [NSLocalizedDescriptionKey: "No mock data or response set"])
        }
        
        return (mockData, mockResponse)
    }
    
    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTaskProtocol {
        let task = MockTask(completionHandler: completionHandler)
        tasks.append(task)
        requestCount += 1
        
        if shouldCancelRequests {
            // Simulate a cancelled task
            DispatchQueue.main.async {
                task.cancel()
            }
            return task
        }
        
        // For retry test, get the appropriate response based on request count
        if !mockResponses.isEmpty {
            if requestCount <= mockResponses.count {
                let response = mockResponses[requestCount - 1]
                
                DispatchQueue.main.async {
                    switch response {
                    case .success(let result):
                        task.callCompletionHandler(data: result.0, response: result.1, error: nil)
                    case .failure(let error):
                        task.callCompletionHandler(data: nil, response: nil, error: error)
                    }
                }
                return task
            }
        }
        
        DispatchQueue.main.async {
            if let mockError = self.mockError {
                task.callCompletionHandler(data: nil, response: nil, error: mockError)
            } else if let mockData = self.mockData, let mockResponse = self.mockResponse {
                task.callCompletionHandler(data: mockData, response: mockResponse, error: nil)
            } else {
                task.callCompletionHandler(data: nil, response: nil, error: NSError(domain: "MockURLSession", code: 0, userInfo: [NSLocalizedDescriptionKey: "No mock data or response set"]))
            }
        }
        
        return task
    }
    
    func cancelAllTasks() {
        for task in tasks {
            task.cancel()
        }
    }
}

class MockTask: URLSessionDataTaskProtocol {
    var isCancelled = false
    var mockCompletionHandler: ((Data?, URLResponse?, Error?) -> Void)?
    private var completionHandlerCalled = false
    
    init(completionHandler: ((Data?, URLResponse?, Error?) -> Void)? = nil) {
        self.mockCompletionHandler = completionHandler
    }
    
    func cancel() {
        if isCancelled || completionHandlerCalled {
            return // Already cancelled or completion handler already called
        }
        
        isCancelled = true
        
        if let handler = mockCompletionHandler {
            completionHandlerCalled = true
            handler(nil, nil, URLError(.cancelled))
            mockCompletionHandler = nil // Clear to prevent multiple calls
        }
    }
    
    func resume() {
        // No-op for non-cancellation cases
    }
    
    func callCompletionHandler(data: Data?, response: URLResponse?, error: Error?) {
        if completionHandlerCalled {
            return // Don't call twice
        }
        
        completionHandlerCalled = true
        mockCompletionHandler?(data, response, error)
        mockCompletionHandler = nil // Clear to prevent multiple calls
    }
}

class MockCacheManager: CacheManagerProtocol {
    var savedItems: [String: Data] = [:]
    var fetchCalled = false
    var saveCalled = false
    var shouldFailFetch = false
    var shouldFailSave = false
    
    func save<T: Encodable>(_ data: T, for key: String) throws {
        saveCalled = true
        if shouldFailSave {
            throw CacheError.saveFailed(NSError(domain: "MockCacheManager", code: 1, userInfo: nil))
        }
        
        let encoder = JSONEncoder()
        savedItems[key] = try encoder.encode(data)
    }
    
    func fetch<T: Decodable>(for key: String) throws -> T {
        fetchCalled = true
        if shouldFailFetch {
            throw CacheError.notFound(key)
        }
        
        guard let data = savedItems[key] else {
            throw CacheError.notFound(key)
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }
    
    func remove(for key: String) throws {
        savedItems[key] = nil
    }
    
    func clearCache() throws {
        savedItems.removeAll()
    }
} 