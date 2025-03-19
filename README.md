# ClassifiedList

A universal iOS application that displays classified ads fetched from an API, with the ability to filter by categories and view detailed information.

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