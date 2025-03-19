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
    
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        requestCount += 1
        
        if !mockResponses.isEmpty {
            if mockResponses.count >= requestCount {
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