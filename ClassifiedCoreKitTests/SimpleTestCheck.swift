import XCTest

class SimpleTestCheck: XCTestCase {
    
    func testSimplePrintAndPass() {
        print("✅ Simple test is running - this confirms the test runner is working properly!")
        XCTAssertTrue(true, "This assertion always passes")
    }
    
    func testSimpleNetworkRequest() {
        print("🔄 Starting simple network test")
        
        let categoriesURLString = "https://raw.githubusercontent.com/leboncoin/paperclip/master/categories.json"
        guard let url = URL(string: categoriesURLString) else {
            XCTFail("Invalid URL")
            return
        }
        
        let expectation = self.expectation(description: "Network request completes")
        
        // This is the exact same pattern as used in the working testDirectURLAccess method
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("❌ Network error: \(error.localizedDescription)")
                XCTFail("Network error: \(error.localizedDescription)")
                expectation.fulfill()
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid response type")
                XCTFail("Invalid response type")
                expectation.fulfill()
                return
            }
            
            print("📊 HTTP Status Code: \(httpResponse.statusCode)")
            
            guard let data = data, !data.isEmpty else {
                print("❌ No data received")
                XCTFail("No data received")
                expectation.fulfill()
                return
            }
            
            print("✅ Received \(data.count) bytes of data")
            expectation.fulfill()
        }
        
        task.resume()
        
        wait(for: [expectation], timeout: 10.0)
        print("✅ Simple network test completed")
    }
} 