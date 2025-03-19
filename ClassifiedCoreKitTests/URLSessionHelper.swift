import Foundation
import XCTest

class URLSessionHelper {
    static func fetchData(from url: URL, completion: @escaping (Data?, HTTPURLResponse?, Error?) -> Void) {
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            completion(data, response as? HTTPURLResponse, error)
        }
        task.resume()
    }
} 