# ClassifiedList

[![Build ClassifiedCoreKit](https://github.com/maurovz/ClassifiedList/actions/workflows/build-corekit.yml/badge.svg)](https://github.com/maurovz/ClassifiedList/actions/workflows/build-corekit.yml)

A universal iOS application that displays classified ads fetched from an API, with the ability to filter by categories and view detailed information.

## How to Run

### Running the App
1. Open the Xcode project
2. Select the `ClassifiedList` target in the scheme selector (this is the default)
3. Select a device or simulator
4. Press Run (⌘R)

### Running Tests
1. To run tests, select the `ClassifiedCoreKitTests` scheme in the scheme selector
2. Press ⌘U to run tests

See screenshot below for reference:
![Test Configuration](test-configuration.png)

## Architecture

The project follows a clean, modular architecture with two main components:

### 1. CoreKit Framework (macOS)
A shared framework containing:
- **Networking Layer**
  - REST API client
  - API endpoints
  - Response models
  - Network error handling
- **Caching System**
  - Disk and memory cache
  - Data persistence
  - Fallback strategy when network is unavailable
- **Common Utilities**
  - Base protocols and interfaces
  - Extensions and helpers

### 2. ClassifiedList App (iOS)
The main iOS application organized in layers:
- **Data Layer**
  - Repositories (using CoreKit)
  - Domain models
- **Domain Layer**
  - Use cases and business logic
- **UI Layer**
  - View controllers
  - Custom views (programmatic Auto Layout)
  - View models

## Flow

1. App fetches categories and classified ads from the API via CoreKit
2. If the network request fails, data is retrieved from cache automatically
3. The UI displays the classified ads sorted by date with urgent items at the top
4. Users can filter items by category
5. Tapping an item shows a detailed view

## Technical Specifications

- Swift 5
- iOS 14+ (Universal app - iPhone/iPad)
- No external libraries
- UI created programmatically with Auto Layout (no Storyboards/XIBs/SwiftUI)
- MVVM architecture
- Protocol-oriented programming
- Dependency injection for testability

## Testing Strategy

The project includes a comprehensive test suite that validates various aspects of the application:

### 1. Model Parsing Tests

The `ModelParsingTests` and `ModelParsingEdgeCasesTests` classes verify that the application correctly parses data from the API endpoints:

- **Basic Parsing Validation**: Tests that JSON responses from both the Categories and Classified ads endpoints are correctly converted to model objects, with all properties properly mapped.

- **Edge Case Handling**: Tests for robustness when dealing with problematic data such as:
  - Missing optional fields (e.g., siret)
  - Empty strings
  - Null image URLs
  - Invalid date formats
  - Zero or decimal price values

- **Formatter Logic Testing**: Verifies that helper methods like `formattedPrice` and `formattedDate` correctly format data for display.

- **Error Handling**: Ensures the application gracefully handles invalid or malformed JSON responses.

These tests are critical for maintaining API contract integrity and preventing common runtime crashes resulting from unexpected data formats. They serve as an early warning system if the API contract changes and provide documentation for expected data structures.

### 2. Repository Layer Tests

The `ClassifiedRepositoryTests` and `ClassifiedAdArrayExtensionsTests` classes test the business logic for fetching, sorting, and filtering classified ads:

- **Repository Functionality Tests**: Validate that the repository layer correctly:
  - Fetches and caches categories and classified ads
  - Handles errors appropriately
  - Returns properly filtered results by category
  - Sorts data according to business requirements

- **Urgent Items Prioritization**: These tests specifically verify the critical business requirement that urgent items appear at the top of the list, regardless of their date, followed by non-urgent items sorted by date.

- **Category Filtering Tests**: Ensure that filtering by category works correctly, including the special "All Categories" case.

- **Sorting Algorithm Tests**: Verify different sorting options (date descending/ascending, price descending/ascending) work correctly.

- **Cache Behavior**: Tests confirm that the repository properly caches data and returns cached results when appropriate.

These tests are valuable because they validate the core business logic that drives the application's main functionality. They ensure that classified ads are presented to users in the correct order with urgent items prioritized, and that filtering works as expected.

### 3. Additional Tests (Coming Soon)

- UI Interaction Tests
- Image Loading Tests
- Network Error Handling Tests

## Development Process

Using GitFlow with the following branches:
- `main` - Production-ready code
- `develop` - Integration branch for features
- `feature/*` - Individual feature branches
- `bugfix/*` - Bug fix branches

## Features

- Display a list of classified ads with image, category, title, price, and urgency indicator
- Sort items by date with urgent items displayed at the top
- Filter ads by category
- View detailed information for each ad 