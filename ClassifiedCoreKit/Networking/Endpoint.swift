import Foundation

public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

public struct Endpoint {
    public let url: URL
    public let method: HTTPMethod
    
    public init(url: URL, method: HTTPMethod = .get) {
        self.url = url
        self.method = method
    }
}

public extension Endpoint {
    static var categories: Endpoint {
        guard let url = URL(string: "https://raw.githubusercontent.com/leboncoin/paperclip/master/categories.json") else {
            fatalError("Invalid URL for categories endpoint")
        }
        return Endpoint(url: url)
    }
    
    static var classifieds: Endpoint {
        guard let url = URL(string: "https://raw.githubusercontent.com/leboncoin/paperclip/master/listing.json") else {
            fatalError("Invalid URL for classifieds endpoint")
        }
        return Endpoint(url: url)
    }
} 