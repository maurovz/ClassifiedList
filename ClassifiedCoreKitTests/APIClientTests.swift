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
    
    func testFetchWithTimeout() {
        // Set up mock session to simulate timeout
        let endpoint = Endpoint(url: URL(string: "https://example.com/test")!)
        let timeoutError = NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut, userInfo: nil)
        
        // Use mockResponses instead of mockError for more consistent behavior
        mockSession.mockResponses = [
            .failure(timeoutError)
        ]
        
        let expectation = XCTestExpectation(description: "Fetch with timeout")
        
        sut.fetch(from: endpoint) { (result: Result<[String: String], Error>) in
            switch result {
            case .success:
                XCTFail("Expected fetch to throw a timeout error")
            case .failure(let error):
                if case APIError.requestFailed(let underlyingError) = error {
                    XCTAssertEqual((underlyingError as NSError).code, NSURLErrorTimedOut)
                } else if case APIError.maxRetryReached = error {
                    // This is also acceptable as the timeout could be treated as a retryable error
                    // that hit its max retries (which is 0 by default)
                    XCTAssertEqual(self.mockSession.requestCount, 1)
                } else {
                    XCTFail("Unexpected error type: \(error)")
                }
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testFetchWithRetry() {
        // Configure endpoint with retry count
        let endpoint = Endpoint(url: URL(string: "https://example.com/test")!, method: .get, retryCount: 3)
        
        // First two attempts fail, third succeeds
        mockSession.mockResponses = [
            .failure(NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut, userInfo: nil)),
            .failure(NSError(domain: NSURLErrorDomain, code: NSURLErrorNetworkConnectionLost, userInfo: nil)),
            .success((Data("{\"success\": true}".utf8), HTTPURLResponse(url: endpoint.url, statusCode: 200, httpVersion: nil, headerFields: nil)!))
        ]
        
        let expectation = XCTestExpectation(description: "Fetch with retry")
        
        sut.fetch(from: endpoint) { (result: Result<[String: Bool], Error>) in
            switch result {
            case .success(let value):
                XCTAssertEqual(value["success"], true)
                XCTAssertEqual(self.mockSession.requestCount, 3)
            case .failure(let error):
                XCTFail("Unexpected error: \(error)")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0) // Allow enough time for retries
    }
    
    func testRequestCancellation() {
        // Configure endpoint
        let endpoint = Endpoint(url: URL(string: "https://example.com/test")!)
        
        // Prepare mock to handle cancellation
        mockSession.shouldCancelRequests = true
        
        let expectation = XCTestExpectation(description: "Request cancellation")
        
        // Set up a request that will be cancelled
        sut.fetch(from: endpoint) { (result: Result<[String: String], Error>) in
            switch result {
            case .success:
                XCTFail("Expected fetch to be cancelled")
            case .failure(let error):
                // Check any form of cancellation error
                if case APIError.cancelled = error {
                    // Successfully cancelled
                } else if let urlError = error as? URLError, urlError.code == .cancelled {
                    // Successfully cancelled with URLError
                } else if case APIError.requestFailed(let underlyingError) = error,
                          let urlError = underlyingError as? URLError, 
                          urlError.code == .cancelled {
                    // Successfully cancelled with underlying URLError
                } else {
                    XCTFail("Expected cancellation error, got \(error)")
                }
            }
            expectation.fulfill()
        }
        
        // Give the request a moment to start
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Cancel the request
            self.sut.cancelAllRequests()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testCancelAllRequests() {
        // Set up a long-running request
        let endpoint = Endpoint(url: URL(string: "https://example.com/test")!)
        
        let expectation = XCTestExpectation(description: "Cancel all requests")
        
        sut.fetch(from: endpoint) { (result: Result<[String: String], Error>) in
            switch result {
            case .success:
                XCTFail("Request should have been cancelled")
            case .failure(let error):
                if let urlError = error as? URLError, urlError.code == .cancelled {
                    // Successfully cancelled
                } else if case APIError.cancelled = error {
                    // Successfully cancelled with our custom error
                } else {
                    XCTFail("Unexpected error: \(error)")
                }
            }
            expectation.fulfill()
        }
        
        // Cancel the request
        mockSession.shouldCancelRequests = true
        sut.cancelAllRequests()
        
        wait(for: [expectation], timeout: 1.0)
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