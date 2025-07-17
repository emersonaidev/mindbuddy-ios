import Foundation

struct User: Codable, Identifiable {
    let id: String
    let email: String
    let firstName: String
    let lastName: String
    let isVerified: Bool
    
    var fullName: String {
        "\(firstName) \(lastName)"
    }
}

// MARK: - Authentication DTOs

struct RefreshTokenRequest: Codable {
    let refreshToken: String
}

struct AuthResponse: Codable {
    let user: User
    let accessToken: String
    let refreshToken: String
}

struct RefreshTokenResponse: Codable {
    let accessToken: String
    let refreshToken: String
}

// MARK: - Firebase Auth DTOs

struct FirebaseAuthRequest: Codable {
    let idToken: String
}

struct FirebaseAuthResponse: Codable {
    let user: FirebaseUser
    let accessToken: String
    let refreshToken: String
}

struct FirebaseUser: Codable {
    let id: String
    let email: String
    let firstName: String
    let lastName: String
    let firebaseUid: String
    let authProvider: String
    let isVerified: Bool
}