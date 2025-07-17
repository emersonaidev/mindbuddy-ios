import Foundation
import Security
import FirebaseAuth

class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    
    private let keychainService = KeychainService.shared
    private let firebaseAuthManager = FirebaseAuthManager.shared
    
    private init() {
        checkAuthStatus()
    }
    
    func login(email: String, password: String) async throws -> AuthResponse {
        // Use Firebase Auth SDK for email/password authentication
        return try await withCheckedThrowingContinuation { continuation in
            Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                // Get Firebase ID token and authenticate with backend
                authResult?.user.getIDToken { idToken, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    guard let idToken = idToken else {
                        continuation.resume(throwing: AuthError.noFirebaseToken)
                        return
                    }
                    
                    Task {
                        do {
                            let response = try await self?.authenticateWithFirebase(idToken: idToken)
                            continuation.resume(returning: response!)
                        } catch {
                            continuation.resume(throwing: error)
                        }
                    }
                }
            }
        }
    }
    
    func register(email: String, password: String, firstName: String, lastName: String) async throws -> AuthResponse {
        // Use Firebase Auth SDK for user registration
        return try await withCheckedThrowingContinuation { continuation in
            Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                // Update display name
                let changeRequest = authResult?.user.createProfileChangeRequest()
                changeRequest?.displayName = "\(firstName) \(lastName)"
                changeRequest?.commitChanges { _ in
                    // Get Firebase ID token and authenticate with backend
                    authResult?.user.getIDToken { idToken, error in
                        if let error = error {
                            continuation.resume(throwing: error)
                            return
                        }
                        
                        guard let idToken = idToken else {
                            continuation.resume(throwing: AuthError.noFirebaseToken)
                            return
                        }
                        
                        Task {
                            do {
                                let response = try await self?.authenticateWithFirebase(idToken: idToken)
                                continuation.resume(returning: response!)
                            } catch {
                                continuation.resume(throwing: error)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func resetPassword(email: String) async throws {
        // Use Firebase Auth SDK for password reset
        return try await withCheckedThrowingContinuation { continuation in
            Auth.auth().sendPasswordReset(withEmail: email) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    // MARK: - Firebase Authentication
    
    func signInWithGoogle() async throws -> AuthResponse {
        let firebaseIDToken = try await firebaseAuthManager.signInWithGoogle()
        return try await authenticateWithFirebase(idToken: firebaseIDToken)
    }
    
    func signInWithApple() async throws -> AuthResponse {
        let firebaseIDToken = try await firebaseAuthManager.signInWithApple()
        return try await authenticateWithFirebase(idToken: firebaseIDToken)
    }
    
    private func authenticateWithFirebase(idToken: String) async throws -> AuthResponse {
        #if DEBUG
        print("🔥 Starting Firebase token verification...")
        #endif
        
        let firebaseRequest = FirebaseAuthRequest(idToken: idToken)
        let requestData = try JSONEncoder().encode(firebaseRequest)
        
        do {
            let response: FirebaseAuthResponse = try await APIClient.shared.request(
                endpoint: "/auth/firebase/verify",
                method: .POST,
                body: requestData,
                responseType: FirebaseAuthResponse.self,
                requiresAuth: false
            )
            #if DEBUG
            print("✅ Firebase authentication successful!")
            #endif
            return await convertFirebaseResponse(response)
        } catch {
            #if DEBUG
            print("❌ Firebase authentication failed: \(error)")
            #endif
            throw error
        }
    }
    
    private func convertFirebaseResponse(_ response: FirebaseAuthResponse) async -> AuthResponse {
        // Store tokens securely
        _ = keychainService.saveTokens(accessToken: response.accessToken, refreshToken: response.refreshToken)
        
        // Convert FirebaseUser to User
        let user = User(
            id: response.user.id,
            email: response.user.email,
            firstName: response.user.firstName,
            lastName: response.user.lastName,
            isVerified: response.user.isVerified
        )
        
        await MainActor.run {
            self.currentUser = user
            self.isAuthenticated = true
        }
        
        return AuthResponse(
            user: user,
            accessToken: response.accessToken,
            refreshToken: response.refreshToken
        )
    }
    
    func logout() {
        // Clear keychain tokens
        _ = keychainService.clearAll()
        
        // Sign out from Firebase as well
        try? firebaseAuthManager.signOut()
        
        currentUser = nil
        isAuthenticated = false
    }
    
    func refreshTokens() async throws {
        guard let refreshToken = keychainService.getRefreshToken() else {
            throw AuthError.noRefreshToken
        }
        
        let refreshRequest = RefreshTokenRequest(refreshToken: refreshToken)
        let requestData = try JSONEncoder().encode(refreshRequest)
        
        let response: RefreshTokenResponse = try await APIClient.shared.request(
            endpoint: "/auth/refresh",
            method: .POST,
            body: requestData,
            responseType: RefreshTokenResponse.self,
            requiresAuth: false
        )
        
        // Update stored tokens
        _ = keychainService.saveTokens(accessToken: response.accessToken, refreshToken: response.refreshToken)
    }
    
    func getAccessToken() -> String? {
        return keychainService.getAccessToken()
    }
    
    private func checkAuthStatus() {
        if keychainService.hasValidTokens() {
            isAuthenticated = true
        }
    }
    
    // MARK: - Keychain Methods (Now handled by KeychainService)
}

enum AuthError: Error {
    case invalidCredentials
    case noRefreshToken
    case noFirebaseToken
    case keychainError(OSStatus)
    
    var localizedDescription: String {
        switch self {
        case .invalidCredentials:
            return "Invalid credentials"
        case .noRefreshToken:
            return "No refresh token available"
        case .noFirebaseToken:
            return "No Firebase ID token received"
        case .keychainError(let status):
            return "Keychain error: \(status)"
        }
    }
}