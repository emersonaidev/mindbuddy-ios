# MindBuddy iOS

A stress monitoring and rewards application that integrates with HealthKit to track health metrics and reward users with MNDY tokens.

## Features

- 🔐 **Multi-Authentication**: Email/Password, Google Sign-In, Apple Sign-In via Firebase
- 📱 **HealthKit Integration**: Heart rate, HRV, steps, sleep, and blood pressure monitoring
- 🪙 **Token Rewards**: Earn MNDY tokens for health data submissions
- 🎨 **Modern UI**: SwiftUI-based interface with clean design
- 🔒 **Secure Storage**: Keychain-based token management

## Requirements

- iOS 18.5+
- Xcode 16.4+
- Swift 5.0+

## Setup

### 1. Clone and Install
```bash
git clone <repository-url>
cd mindbuddy-ios
```

### 2. Firebase Configuration
1. Download `GoogleService-Info.plist` from Firebase Console
2. Add to Xcode project (mindbuddy target)
3. Ensure it's included in the bundle

### 3. Dependencies
Dependencies are managed via Swift Package Manager and will be resolved automatically when opening the project.

### 4. Build and Run
```bash
# Open in Xcode
open mindbuddy/mindbuddy.xcodeproj

# Or build from command line
cd mindbuddy
xcodebuild -scheme mindbuddy -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Testing

### Run Unit Tests
```bash
cd mindbuddy
xcodebuild test -scheme mindbuddy -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Run SwiftLint
```bash
# Install SwiftLint
brew install swiftlint

# Run linting
swiftlint lint
```

## Architecture

The app follows MVVM architecture with the following structure:

```
mindbuddy/
├── Core/                 # Core business logic
│   ├── Auth/            # Authentication management
│   ├── Health/          # HealthKit integration
│   ├── Models/          # Data models
│   ├── Network/         # API client
│   ├── Rewards/         # Token rewards system
│   └── Security/        # Keychain services
├── Features/            # UI features
│   ├── Authentication/ # Login/Register views
│   ├── Dashboard/       # Main dashboard
│   ├── Health/          # Health monitoring
│   ├── Rewards/         # Token management
│   └── Settings/        # App settings
└── Components/          # Reusable UI components
```

## Security

- 🔐 All sensitive data stored in iOS Keychain
- 🛡️ No sensitive information logged in production
- 🔒 HTTPS-only API communication
- 🎯 Firebase Authentication integration
- ⚡ Automatic token refresh handling

## API Integration

The app integrates with the MindBuddy backend API:
- **Base URL**: `https://mindbuddy-api.onrender.com/api/v1`
- **Authentication**: JWT tokens with automatic refresh
- **Health Data**: Batch submission of HealthKit data
- **Rewards**: Token balance and transaction history

## CI/CD

GitHub Actions pipeline includes:
- ✅ Automated testing
- 🧹 Code linting (SwiftLint)
- 🔒 Security scanning
- 📦 Release builds

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests and linting
5. Submit a pull request

## License

[License information]