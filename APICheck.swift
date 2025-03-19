#!/usr/bin/env swift

import Foundation

// Simple standalone script to check the API endpoints
print("Starting direct API endpoint checks...")

// Categories URL
let categoriesURL = URL(string: "https://raw.githubusercontent.com/leboncoin/paperclip/master/categories.json")!
print("Checking Categories URL: \(categoriesURL.absoluteString)")

// Classifieds URL
let classifiedsURL = URL(string: "https://raw.githubusercontent.com/leboncoin/paperclip/master/listing.json")!
print("Checking Classifieds URL: \(classifiedsURL.absoluteString)")

// Create a semaphore to wait for async network calls to complete
let semaphore = DispatchSemaphore(value: 0)

// Check Categories URL
print("\n--- Categories URL Check ---")
URLSession.shared.dataTask(with: categoriesURL) { data, response, error in
    if let error = error {
        print("❌ Categories URL Error: \(error.localizedDescription)")
    } else if let httpResponse = response as? HTTPURLResponse {
        print("Status Code: \(httpResponse.statusCode)")
        
        if let data = data {
            print("Received \(data.count) bytes of data")
            
            if let jsonString = String(data: data.prefix(500), encoding: .utf8) {
                print("Sample JSON data: \(jsonString)...")
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data)
                print("✅ Successfully parsed JSON")
                
                if let array = json as? [[String: Any]], !array.isEmpty {
                    print("Found \(array.count) categories")
                    if let first = array.first {
                        print("First category: \(first)")
                    }
                }
            } catch {
                print("❌ JSON Parsing Error: \(error.localizedDescription)")
            }
        } else {
            print("❌ No data received")
        }
    }
    
    semaphore.signal()
}.resume()

// Wait for categories check to complete
semaphore.wait()

// Check Classifieds URL
print("\n--- Classifieds URL Check ---")
URLSession.shared.dataTask(with: classifiedsURL) { data, response, error in
    if let error = error {
        print("❌ Classifieds URL Error: \(error.localizedDescription)")
    } else if let httpResponse = response as? HTTPURLResponse {
        print("Status Code: \(httpResponse.statusCode)")
        
        if let data = data {
            print("Received \(data.count) bytes of data")
            
            if let jsonString = String(data: data.prefix(500), encoding: .utf8) {
                print("Sample JSON data: \(jsonString)...")
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data)
                print("✅ Successfully parsed JSON")
                
                if let array = json as? [[String: Any]], !array.isEmpty {
                    print("Found \(array.count) classified ads")
                    if let first = array.first {
                        print("First classified ad title: \(first["title"] ?? "Unknown")")
                    }
                }
            } catch {
                print("❌ JSON Parsing Error: \(error.localizedDescription)")
            }
        } else {
            print("❌ No data received")
        }
    }
    
    semaphore.signal()
}.resume()

// Wait for classifieds check to complete
semaphore.wait()

print("\nAPI endpoint checks completed.") 