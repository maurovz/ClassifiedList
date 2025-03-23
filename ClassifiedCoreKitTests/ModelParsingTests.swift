import XCTest
@testable import ClassifiedCoreKit

final class ModelParsingTests: XCTestCase {
    
    // MARK: - Sample Data
    
    let sampleCategoryJSON = """
    {
        "id": 1,
        "name": "Véhicule"
    }
    """
    
    let sampleCategoriesJSON = """
    [
        {
            "id": 1,
            "name": "Véhicule"
        },
        {
            "id": 2,
            "name": "Mode"
        },
        {
            "id": 3,
            "name": "Bricolage"
        }
    ]
    """
    
    let sampleClassifiedAdJSON = """
    {
        "id": 1461267313,
        "category_id": 4,
        "title": "Statue homme noir assis en plâtre polychrome",
        "description": "Magnifique Statuette homme noir assis fumant le cigare en terre cuite",
        "price": 140.00,
        "images_url": {
            "small": "https://raw.githubusercontent.com/leboncoin/paperclip/master/ad-small/2c9563bbe85f12a5dcaeb2c40989182463270404.jpg",
            "thumb": "https://raw.githubusercontent.com/leboncoin/paperclip/master/ad-thumb/2c9563bbe85f12a5dcaeb2c40989182463270404.jpg"
        },
        "creation_date": "2019-11-05T15:56:59+0000",
        "is_urgent": false
    }
    """
    
    let sampleClassifiedAdWithSiretJSON = """
    {
        "id": 1664493117,
        "category_id": 9,
        "title": "Professeur natif d'espagnol à domicile",
        "description": "Doctorant espagnol, ayant fait des études de linguistique comparée",
        "price": 25.00,
        "images_url": {
            "small": "https://raw.githubusercontent.com/leboncoin/paperclip/master/ad-small/af9c43ff5a3b3692f9f1aa3c17d7b46d8b740311.jpg",
            "thumb": "https://raw.githubusercontent.com/leboncoin/paperclip/master/ad-thumb/af9c43ff5a3b3692f9f1aa3c17d7b46d8b740311.jpg"
        },
        "creation_date": "2019-11-05T15:56:55+0000",
        "is_urgent": false,
        "siret": "123 323 002"
    }
    """
    
    // MARK: - Category Tests
    
    func testCategoryParsing() throws {
        let data = sampleCategoryJSON.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        let category = try decoder.decode(ClassifiedCoreKit.Category.self, from: data)
        
        XCTAssertEqual(category.id, 1)
        XCTAssertEqual(category.name, "Véhicule")
    }
    
    func testCategoriesArrayParsing() throws {
        let data = sampleCategoriesJSON.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        let categories = try decoder.decode(Array<ClassifiedCoreKit.Category>.self, from: data)
        
        XCTAssertEqual(categories.count, 3)
        XCTAssertEqual(categories[0].id, 1)
        XCTAssertEqual(categories[0].name, "Véhicule")
        XCTAssertEqual(categories[1].id, 2)
        XCTAssertEqual(categories[1].name, "Mode")
        XCTAssertEqual(categories[2].id, 3)
        XCTAssertEqual(categories[2].name, "Bricolage")
    }
    
    // MARK: - ClassifiedAd Tests
    
    func testClassifiedAdParsing() throws {
        let data = sampleClassifiedAdJSON.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        
        let ad = try decoder.decode(ClassifiedAd.self, from: data)
        
        XCTAssertEqual(ad.id, 1461267313)
        XCTAssertEqual(ad.categoryId, 4)
        XCTAssertEqual(ad.title, "Statue homme noir assis en plâtre polychrome")
        XCTAssertEqual(ad.description, "Magnifique Statuette homme noir assis fumant le cigare en terre cuite")
        XCTAssertEqual(ad.price, 140.00)
        XCTAssertEqual(ad.isUrgent, false)
        XCTAssertNil(ad.siret)
        
        // Check image URLs
        XCTAssertNotNil(ad.imagesUrl.small)
        XCTAssertNotNil(ad.imagesUrl.thumb)
        XCTAssertEqual(ad.imagesUrl.small?.absoluteString, "https://raw.githubusercontent.com/leboncoin/paperclip/master/ad-small/2c9563bbe85f12a5dcaeb2c40989182463270404.jpg")
        
        // Check date format
        let expectedDate = ISO8601DateFormatter().date(from: "2019-11-05T15:56:59+0000")
        XCTAssertEqual(ad.creationDate, expectedDate)
    }
    
    func testClassifiedAdWithSiretParsing() throws {
        let data = sampleClassifiedAdWithSiretJSON.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        
        let ad = try decoder.decode(ClassifiedAd.self, from: data)
        
        XCTAssertEqual(ad.id, 1664493117)
        XCTAssertEqual(ad.categoryId, 9)
        XCTAssertEqual(ad.siret, "123 323 002")
    }
    
    func testClassifiedAdFormattedPrice() throws {
        let data = sampleClassifiedAdJSON.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        
        let ad = try decoder.decode(ClassifiedAd.self, from: data)
        
        XCTAssertTrue(ad.formattedPrice.contains("140"))
        XCTAssertTrue(ad.formattedPrice.contains("€"))
    }
    
    func testClassifiedAdFormattedDate() throws {
        let data = sampleClassifiedAdJSON.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        
        let ad = try decoder.decode(ClassifiedAd.self, from: data)
        
        XCTAssertTrue(ad.formattedDate.contains("2019"))
        XCTAssertTrue(ad.formattedDate.contains("5") || ad.formattedDate.contains("05") || ad.formattedDate.contains("Nov"))
    }
} 
