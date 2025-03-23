import XCTest
@testable import ClassifiedCoreKit

final class ModelParsingEdgeCasesTests: XCTestCase {
    
    // MARK: - Sample Data with Edge Cases
    
    let emptyTitleJSON = """
    {
        "id": 1461267313,
        "category_id": 4,
        "title": "",
        "description": "Description with empty title",
        "price": 140.00,
        "images_url": {
            "small": "https://example.com/small.jpg",
            "thumb": "https://example.com/thumb.jpg"
        },
        "creation_date": "2019-11-05T15:56:59+0000",
        "is_urgent": false
    }
    """
    
    let missingImagesJSON = """
    {
        "id": 1461267313,
        "category_id": 4,
        "title": "Ad with missing images",
        "description": "Description",
        "price": 140.00,
        "images_url": {
            "small": null,
            "thumb": null
        },
        "creation_date": "2019-11-05T15:56:59+0000",
        "is_urgent": false
    }
    """
    
    let invalidDateJSON = """
    {
        "id": 1461267313,
        "category_id": 4,
        "title": "Ad with invalid date",
        "description": "Description",
        "price": 140.00,
        "images_url": {
            "small": "https://example.com/small.jpg",
            "thumb": "https://example.com/thumb.jpg"
        },
        "creation_date": "invalid-date-format",
        "is_urgent": false
    }
    """
    
    let zeroPrice = """
    {
        "id": 1461267313,
        "category_id": 4,
        "title": "Free item",
        "description": "Description of free item",
        "price": 0.00,
        "images_url": {
            "small": "https://example.com/small.jpg",
            "thumb": "https://example.com/thumb.jpg"
        },
        "creation_date": "2019-11-05T15:56:59+0000",
        "is_urgent": false
    }
    """
    
    let decimalPrice = """
    {
        "id": 1461267313,
        "category_id": 4,
        "title": "Item with decimal price",
        "description": "Description",
        "price": 19.99,
        "images_url": {
            "small": "https://example.com/small.jpg",
            "thumb": "https://example.com/thumb.jpg"
        },
        "creation_date": "2019-11-05T15:56:59+0000",
        "is_urgent": false
    }
    """
    
    // MARK: - Tests
    
    func testEmptyTitleParsing() throws {
        let data = emptyTitleJSON.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        
        let ad = try decoder.decode(ClassifiedCoreKit.ClassifiedAd.self, from: data)
        
        XCTAssertEqual(ad.title, "")
        XCTAssertEqual(ad.description, "Description with empty title")
    }
    
    func testMissingImageURLs() throws {
        let data = missingImagesJSON.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        
        let ad = try decoder.decode(ClassifiedCoreKit.ClassifiedAd.self, from: data)
        
        XCTAssertNil(ad.imagesUrl.small)
        XCTAssertNil(ad.imagesUrl.thumb)
    }
    
    func testInvalidDateFormat() throws {
        let data = invalidDateJSON.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        
        XCTAssertThrowsError(try decoder.decode(ClassifiedCoreKit.ClassifiedAd.self, from: data)) { error in
            XCTAssertTrue(error is DecodingError, "Expected DecodingError for invalid date format")
        }
    }
    
    func testZeroPriceFormatting() throws {
        let data = zeroPrice.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        
        let ad = try decoder.decode(ClassifiedCoreKit.ClassifiedAd.self, from: data)
        
        XCTAssertEqual(ad.price, 0.0)
        // Should format without decimal places for whole numbers
        XCTAssertTrue(ad.formattedPrice.contains("0") || ad.formattedPrice.contains("€"))
        XCTAssertFalse(ad.formattedPrice.contains(".00"))
    }
    
    func testDecimalPriceFormatting() throws {
        let data = decimalPrice.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        
        let ad = try decoder.decode(ClassifiedCoreKit.ClassifiedAd.self, from: data)
        
        XCTAssertEqual(ad.price, 19.99)
        // Should format with decimal places for non-whole numbers
        XCTAssertTrue(ad.formattedPrice.contains("19") && ad.formattedPrice.contains("99"))
    }
    
    func testMalformedJSON() {
        let malformedJSON = "{ this is not valid JSON }"
        let data = malformedJSON.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        XCTAssertThrowsError(try decoder.decode(ClassifiedCoreKit.ClassifiedAd.self, from: data)) { error in
            XCTAssertTrue(error is DecodingError, "Expected DecodingError for malformed JSON")
        }
    }
} 