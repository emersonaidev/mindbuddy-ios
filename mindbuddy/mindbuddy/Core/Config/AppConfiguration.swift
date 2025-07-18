import Foundation

// MARK: - App Configuration

class AppConfiguration: ConfigurationProtocol {
    static let shared = AppConfiguration()
    
    var apiBaseURL: String {
        return "https://mindbuddy-api.onrender.com/api/v1"
    }
    
    var cacheMaxAge: TimeInterval {
        return 300 // 5 minutes
    }
    
    var requestTimeout: TimeInterval {
        return 30 // 30 seconds
    }
    
    var maxRetryAttempts: Int {
        return 3
    }
    
    var isBackgroundProcessingEnabled: Bool {
        return true
    }
    
    var healthKitBackgroundDeliveryEnabled: Bool {
        return true
    }
    
    private init() {}
}

// MARK: - Mock Configuration

class MockConfiguration: ConfigurationProtocol {
    var apiBaseURL: String = "https://mock.mindbuddy.com/api/v1"
    var cacheMaxAge: TimeInterval = 60
    var requestTimeout: TimeInterval = 10
    var maxRetryAttempts: Int = 1
    var isBackgroundProcessingEnabled: Bool = false
    var healthKitBackgroundDeliveryEnabled: Bool = false
}