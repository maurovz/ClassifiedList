import XCTest
@testable import ClassifiedCoreKit

final class ClassifiedAdArrayExtensionsTests: XCTestCase {
    
    // MARK: - Sample Data
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
                "is_urgent": false
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
                "category_id": 1,
                "title": "Urgent car",
                "description": "Urgent nice car",
                "price": 5000.0,
                "images_url": {
                    "small": "https://example.com/small3.jpg",
                    "thumb": "https://example.com/thumb3.jpg"
                },
                "creation_date": "2023-01-01T10:00:00+0000",
                "is_urgent": true
            },
            {
                "id": 4,
                "category_id": 3,
                "title": "Table for sale",
                "description": "Nice table",
                "price": 200.0,
                "images_url": {
                    "small": "https://example.com/small4.jpg",
                    "thumb": "https://example.com/thumb4.jpg"
                },
                "creation_date": "2023-01-07T10:00:00+0000",
                "is_urgent": false
            },
            {
                "id": 5,
                "category_id": 2,
                "title": "Urgent shoes",
                "description": "Urgent nice shoes",
                "price": 80.0,
                "images_url": {
                    "small": "https://example.com/small5.jpg",
                    "thumb": "https://example.com/thumb5.jpg"
                },
                "creation_date": "2023-01-03T10:00:00+0000",
                "is_urgent": true
            }
        ]
        """.data(using: .utf8)!
        
        return try! decoder.decode([ClassifiedAd].self, from: jsonData)
    }()
    
    // MARK: - Tests
    
    func testSortedByDateAndUrgency() {
        // When
        let sortedAds = sampleAds.sortedByDateAndUrgency()
        
        // Then
        XCTAssertEqual(sortedAds.count, 5)
        XCTAssertTrue(sortedAds[0].isUrgent)
        XCTAssertTrue(sortedAds[1].isUrgent)
        XCTAssertFalse(sortedAds[2].isUrgent)
        XCTAssertFalse(sortedAds[3].isUrgent)
        XCTAssertFalse(sortedAds[4].isUrgent)
        
        XCTAssertEqual(sortedAds[0].id, 5) // Urgent shoes (Jan 3)
        XCTAssertEqual(sortedAds[1].id, 3) // Urgent car (Jan 1)
        
        XCTAssertEqual(sortedAds[2].id, 2) // Dress (Jan 10)
        XCTAssertEqual(sortedAds[3].id, 4) // Table (Jan 7)
        XCTAssertEqual(sortedAds[4].id, 1) // Car (Jan 5)
    }
    
    func testSortedByDateAndUrgencyWithNoUrgentItems() {
        // Given
        var nonUrgentAds = sampleAds
        nonUrgentAds = nonUrgentAds.filter { !$0.isUrgent }
        
        // When
        let sortedAds = nonUrgentAds.sortedByDateAndUrgency()
        
        // Then
        XCTAssertEqual(sortedAds.count, 3)
        // Should just be sorted by date descending
        XCTAssertEqual(sortedAds[0].id, 2) // Dress (Jan 10)
        XCTAssertEqual(sortedAds[1].id, 4) // Table (Jan 7)
        XCTAssertEqual(sortedAds[2].id, 1) // Car (Jan 5)
    }
    
    func testSortedByDateAndUrgencyWithAllUrgentItems() {
        // Given
        var urgentOnlyAds = sampleAds
        urgentOnlyAds = urgentOnlyAds.filter { $0.isUrgent }
        
        // When
        let sortedAds = urgentOnlyAds.sortedByDateAndUrgency()
        
        // Then
        XCTAssertEqual(sortedAds.count, 2)
        // Should just be sorted by date descending
        XCTAssertEqual(sortedAds[0].id, 5) // Urgent shoes (Jan 3)
        XCTAssertEqual(sortedAds[1].id, 3) // Urgent car (Jan 1)
    }
    
    func testFilteredByCategoryId() {
        // When
        let filteredAds = sampleAds.filtered(by: 1)
        
        // Then
        XCTAssertEqual(filteredAds.count, 2)
        // All should be category 1
        XCTAssertEqual(filteredAds[0].categoryId, 1)
        XCTAssertEqual(filteredAds[1].categoryId, 1)
        // Should include both urgent and non-urgent
        XCTAssertEqual(filteredAds[0].id, 1) // Non-urgent car
        XCTAssertEqual(filteredAds[1].id, 3) // Urgent car
    }
    
    func testFilteredByAllCategoryId() {
        // When
        let filteredAds = sampleAds.filtered(by: Category.all.id)
        
        // Then
        XCTAssertEqual(filteredAds.count, 5)
        // Should include all categories
        XCTAssertEqual(filteredAds[0].id, 1)
        XCTAssertEqual(filteredAds[1].id, 2)
        XCTAssertEqual(filteredAds[2].id, 3)
        XCTAssertEqual(filteredAds[3].id, 4)
        XCTAssertEqual(filteredAds[4].id, 5)
    }
    
    func testFilteredByNonExistentCategoryId() {
        // When
        let filteredAds = sampleAds.filtered(by: 999) // Non-existent category
        
        // Then
        XCTAssertEqual(filteredAds.count, 0)
    }
    
    func testCombinationOfSortingAndFiltering() {
        // When - First filter by category, then sort
        let filteredAds = sampleAds.filtered(by: 1)
        let sortedFilteredAds = filteredAds.sortedByDateAndUrgency()
        
        // Then
        XCTAssertEqual(sortedFilteredAds.count, 2)
        // Urgent car should be first despite older date
        XCTAssertEqual(sortedFilteredAds[0].id, 3) // Urgent car (Jan 1)
        XCTAssertEqual(sortedFilteredAds[1].id, 1) // Non-urgent car (Jan 5)
    }
} 
