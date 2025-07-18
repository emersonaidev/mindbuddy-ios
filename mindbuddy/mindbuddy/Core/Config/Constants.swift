import Foundation
import UIKit

// MARK: - App Constants

enum Constants {
    
    // MARK: - UI Constants
    
    enum UI {
        static let padding: CGFloat = 16
        static let cornerRadius: CGFloat = 12
        static let iconSize: CGFloat = 24
        static let buttonHeight: CGFloat = 48
        static let cardShadowRadius: CGFloat = 4
        static let animationDuration: TimeInterval = 0.3
    }
    
    // MARK: - Cache Constants
    
    enum Cache {
        static let defaultMaxAge: TimeInterval = 300 // 5 minutes
        static let memoryLimit = 50 * 1024 * 1024 // 50MB
        static let countLimit = 100
    }
    
    // MARK: - Network Constants
    
    enum Network {
        static let timeout: TimeInterval = 30
        static let maxRetries = 3
    }
    
    // MARK: - Health Constants
    
    enum Health {
        static let syncInterval: TimeInterval = 4 * 60 * 60 // 4 hours
        static let tokenRefreshInterval: TimeInterval = 50 * 60 // 50 minutes
    }
}