import XCTest
@testable import ClassifiedCoreKit

final class ClassifiedRepositoryTests: XCTestCase {
    
    // MARK: - Properties
    var mockService: MockClassifiedService!
    var sut: ClassifiedRepository! // System under test
    
    // MARK: - Sample Data
    let sampleCategories = [
        Category(id: 1, name: "Vehicles"),
        Category(id: 2, name: "Fashion"),
        Category(id: 3, name: "Home")
    ]
    
    let sampleAds: [ClassifiedAd] = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        
        let jsonData = """
        [
            {
                "id": 1,
                "category_id": 1,
                "title": "Car for sale",
                "description": "Nice car",
                "price": 10000.0,
                "images_url": {
                    "small": "https://example.com/small1.jpg",
                    "thumb": "https://example.com/thumb1.jpg"
                },
                "creation_date": "2023-01-05T10:00:00+0000",
                "is_urgent": true
            },
            {
                "id": 2,
                "category_id": 2,
                "title": "Dress for sale",
                "description": "Nice dress",
                "price": 50.0,
                "images_url": {
                    "small": "https://example.com/small2.jpg",
                    "thumb": "https://example.com/thumb2.jpg"
                },
                "creation_date": "2023-01-10T10:00:00+0000",
                "is_urgent": false
            },
            {
                "id": 3,
                "category_id": 3,
                "title": "Table for sale",
                "description": "Nice table",
                "price": 200.0,
                "images_url": {
                    "small": "https://example.com/small3.jpg",
                    "thumb": "https://example.com/thumb3.jpg"
                },
                "creation_date": "2023-01-07T10:00:00+0000",
                "is_urgent": false
            },
            {
                "id": 4,
                "category_id": 1,
                "title": "Another car",
                "description": "Another nice car",
                "price": 15000.0,
                "images_url": {
                    "small": "https://example.com/small4.jpg",
                    "thumb": "https://example.com/thumb4.jpg"
                },
                "creation_date": "2023-01-15T10:00:00+0000",
                "is_urgent": false
            }
        ]
        """.data(using: .utf8)!
        
        return try! decoder.decode([ClassifiedAd].self, from: jsonData)
    }()
    
    // MARK: - Setup and Teardown
    override func setUp() {
        super.setUp()
        mockService = MockClassifiedService()
        sut = ClassifiedRepository(service: mockService)
    }
    
    override func tearDown() {
        mockService = nil
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    
    func testGetCategories() {
        // Given
        mockService.mockedCategoriesResult = Result<[ClassifiedCoreKit.Category], Error>.success(sampleCategories)
        
        // When
        let expectation = XCTestExpectation(description: "Fetch categories")
        var receivedCategories: [ClassifiedCoreKit.Category]?
        var receivedError: Error?
        
        sut.getCategories { result in
            switch result {
            case .success(let categories):
                receivedCategories = categories
            case .failure(let error):
                receivedError = error
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
        
        // Then
        XCTAssertNil(receivedError)
        XCTAssertEqual(receivedCategories?.count, 3)
        XCTAssertEqual(receivedCategories?[0].id, 1)
        XCTAssertEqual(receivedCategories?[0].name, "Vehicles")
    }
    
    func testGetCategoriesFromCache() {
        mockService.mockedCategoriesResult = Result<[ClassifiedCoreKit.Category], Error>.success(sampleCategories)
        
        let firstExpectation = XCTestExpectation(description: "First categories fetch")
        sut.getCategories { _ in
            firstExpectation.fulfill()
        }
        wait(for: [firstExpectation], timeout: 1.0)
        
        mockService.mockedCategoriesResult = Result<[ClassifiedCoreKit.Category], Error>.failure(NSError(domain: "test", code: 1))
        
        let secondExpectation = XCTestExpectation(description: "Second categories fetch")
        var receivedCategories: [ClassifiedCoreKit.Category]?
        var receivedError: Error?
        
        sut.getCategories { result in
            switch result {
            case .success(let categories):
                receivedCategories = categories
            case .failure(let error):
                receivedError = error
            }
            secondExpectation.fulfill()
        }
        
        wait(for: [secondExpectation], timeout: 1.0)
        
        // Then
        XCTAssertNil(receivedError)
        XCTAssertEqual(receivedCategories?.count, 3) // Still get the cached data
        XCTAssertEqual(mockService.fetchCategoriesCallCount, 1) // Service was only called once
    }
    
    func testGetClassifiedAds() {
        // Given
        mockService.mockedClassifiedAdsResult = Result<[ClassifiedCoreKit.ClassifiedAd], Error>.success(sampleAds)
        
        // When
        let expectation = XCTestExpectation(description: "Fetch ads")
        var receivedAds: [ClassifiedAd]?
        var receivedError: Error?
        
        sut.getClassifiedAds { result in
            switch result {
            case .success(let ads):
                receivedAds = ads
            case .failure(let error):
                receivedError = error
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
        
        // Then
        XCTAssertNil(receivedError)
        XCTAssertEqual(receivedAds?.count, 4)
        XCTAssertEqual(receivedAds?[0].id, 1)
        XCTAssertEqual(receivedAds?[0].title, "Car for sale")
    }
    
    func testGetClassifiedAdsWithFiltering() {
        // Given
        mockService.mockedClassifiedAdsResult = Result<[ClassifiedCoreKit.ClassifiedAd], Error>.success(sampleAds)
        
        // When
        let expectation = XCTestExpectation(description: "Fetch filtered ads")
        var receivedAds: [ClassifiedAd]?
        var receivedError: Error?
        
        sut.getClassifiedAds(filteredBy: 1) { result in
            switch result {
            case .success(let ads):
                receivedAds = ads
            case .failure(let error):
                receivedError = error
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
        
        // Then
        XCTAssertNil(receivedError)
        XCTAssertEqual(receivedAds?.count, 2) // Should have 2 cars (category_id: 1)
        XCTAssertEqual(receivedAds?[0].categoryId, 1)
        XCTAssertEqual(receivedAds?[1].categoryId, 1)
    }
    
    func testGetClassifiedAdsFilteredByAllCategories() {
        // Given
        mockService.mockedClassifiedAdsResult = Result<[ClassifiedCoreKit.ClassifiedAd], Error>.success(sampleAds)
        
        // When
        let expectation = XCTestExpectation(description: "Fetch all category ads")
        var receivedAds: [ClassifiedAd]?
        var receivedError: Error?
        
        sut.getClassifiedAds(filteredBy: ClassifiedCoreKit.Category.all.id) { result in
            switch result {
            case .success(let ads):
                receivedAds = ads
            case .failure(let error):
                receivedError = error
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
        
        // Then
        XCTAssertNil(receivedError)
        XCTAssertEqual(receivedAds?.count, 4) // Should return all ads
    }
    
    func testGetClassifiedAdsSortedByDateDescending() {
        // Given
        mockService.mockedClassifiedAdsResult = Result<[ClassifiedCoreKit.ClassifiedAd], Error>.success(sampleAds)
        
        // When
        let expectation = XCTestExpectation(description: "Fetch sorted ads")
        var receivedAds: [ClassifiedAd]?
        var receivedError: Error?
        
        sut.getClassifiedAds(sortedBy: .dateDescending) { result in
            switch result {
            case .success(let ads):
                receivedAds = ads
            case .failure(let error):
                receivedError = error
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
        
        // Then
        XCTAssertNil(receivedError)
        XCTAssertEqual(receivedAds?.count, 4)
        // Ensure ads are sorted by date (most recent first)
        XCTAssertEqual(receivedAds?[0].id, 4) // Jan 15
        XCTAssertEqual(receivedAds?[1].id, 2) // Jan 10
        XCTAssertEqual(receivedAds?[2].id, 3) // Jan 07
        XCTAssertEqual(receivedAds?[3].id, 1) // Jan 05
    }
    
    func testGetClassifiedAdsSortedByUrgentFirst() {
        // Given
        mockService.mockedClassifiedAdsResult = Result<[ClassifiedCoreKit.ClassifiedAd], Error>.success(sampleAds)
        
        // When
        let expectation = XCTestExpectation(description: "Fetch urgent-first ads")
        var receivedAds: [ClassifiedAd]?
        var receivedError: Error?
        
        sut.getClassifiedAds(sortedBy: .urgentFirst) { result in
            switch result {
            case .success(let ads):
                receivedAds = ads
            case .failure(let error):
                receivedError = error
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
        
        // Then
        XCTAssertNil(receivedError)
        XCTAssertEqual(receivedAds?.count, 4)
        
        // First item should be urgent, regardless of date
        XCTAssertTrue(receivedAds?[0].isUrgent ?? false)
        XCTAssertEqual(receivedAds?[0].id, 1) // Urgent car
        
        // Non-urgent items should be sorted by date (newest first)
        XCTAssertEqual(receivedAds?[1].id, 4) // Jan 15
        XCTAssertEqual(receivedAds?[2].id, 2) // Jan 10
        XCTAssertEqual(receivedAds?[3].id, 3) // Jan 07
    }
    
    func testGetClassifiedAdsWithCategoryName() {
        // Given
        mockService.mockedClassifiedAdsResult = Result<[ClassifiedCoreKit.ClassifiedAd], Error>.success(sampleAds)
        mockService.mockedCategoriesResult = Result<[ClassifiedCoreKit.Category], Error>.success(sampleCategories)
        
        // When
        let expectation = XCTestExpectation(description: "Fetch ads with category names")
        var receivedAdsWithCategories: [(ClassifiedCoreKit.ClassifiedAd, String)]?
        var receivedError: Error?
        
        sut.getClassifiedAdsWithCategoryName { result in
            switch result {
            case .success(let adsWithCategories):
                receivedAdsWithCategories = adsWithCategories
            case .failure(let error):
                receivedError = error
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
        
        // Then
        XCTAssertNil(receivedError)
        XCTAssertEqual(receivedAdsWithCategories?.count, 4)
        
        // Check that category names are correctly mapped
        XCTAssertEqual(receivedAdsWithCategories?[0].1, "Vehicles")
        XCTAssertEqual(receivedAdsWithCategories?[1].1, "Fashion")
        XCTAssertEqual(receivedAdsWithCategories?[2].1, "Home")
        XCTAssertEqual(receivedAdsWithCategories?[3].1, "Vehicles")
    }
}

// MARK: - Mock Service

class MockClassifiedService: ClassifiedServiceProtocol {
    var mockedCategoriesResult: Result<[ClassifiedCoreKit.Category], Error>?
    var mockedClassifiedAdsResult: Result<[ClassifiedCoreKit.ClassifiedAd], Error>?
    
    var fetchCategoriesCallCount = 0
    var fetchClassifiedAdsCallCount = 0
    
    func fetchCategories(completion: @escaping (Result<[ClassifiedCoreKit.Category], Error>) -> Void) {
        fetchCategoriesCallCount += 1
        
        if let result = mockedCategoriesResult {
            completion(result)
        } else {
            completion(.failure(NSError(domain: "MockService", code: 1, userInfo: [NSLocalizedDescriptionKey: "No mocked result"])))
        }
    }
    
    func fetchClassifiedAds(completion: @escaping (Result<[ClassifiedCoreKit.ClassifiedAd], Error>) -> Void) {
        fetchClassifiedAdsCallCount += 1
        
        if let result = mockedClassifiedAdsResult {
            completion(result)
        } else {
            completion(.failure(NSError(domain: "MockService", code: 2, userInfo: [NSLocalizedDescriptionKey: "No mocked result"])))
        }
    }
} 
