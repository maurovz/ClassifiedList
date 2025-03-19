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
    public let retryCount: Int
    public let timeoutInterval: TimeInterval
    
    public init(url: URL, method: HTTPMethod = .get, retryCount: Int = 0, timeoutInterval: TimeInterval = 30.0) {
        self.url = url
        self.method = method
        self.retryCount = retryCount
        self.timeoutInterval = timeoutInterval
    }
}

public extension Endpoint {
    static var categories: Endpoint {
        guard let url = URL(string: "https://raw.githubusercontent.com/leboncoin/paperclip/master/categories.json") else {
            fatalError("Invalid URL for categories endpoint")
        }
        return Endpoint(url: url, retryCount: 2)
    }
    
    static var classifieds: Endpoint {
        guard let url = URL(string: "https://raw.githubusercontent.com/leboncoin/paperclip/master/listing.json") else {
            fatalError("Invalid URL for classifieds endpoint")
        }
        return Endpoint(url: url, retryCount: 2)
    }
} 