import Foundation
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import AuthenticationServices
import CryptoKit

class FirebaseAuthManager: NSObject, ObservableObject {
    static let shared = FirebaseAuthManager()
    
    var currentNonce: String?
    private var appleSignInDelegate: AppleSignInDelegate?
    private var appleContextProvider: ApplePresentationContextProvider?
    
    private override init() {
        super.init()
    }
    
    // MARK: - Google Sign In
    
    func signInWithGoogle() async throws -> String {
        guard let presentingViewController = await getRootViewController() else {
            throw FirebaseAuthError.noViewController
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let user = result?.user,
                      let idToken = user.idToken?.tokenString else {
                    continuation.resume(throwing: FirebaseAuthError.invalidGoogleToken)
                    return
                }
                
                let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                               accessToken: user.accessToken.tokenString)
                
                Auth.auth().signIn(with: credential) { authResult, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    // Get Firebase ID token
                    authResult?.user.getIDToken { token, error in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else if let token = token {
                            continuation.resume(returning: token)
                        } else {
                            continuation.resume(throwing: FirebaseAuthError.noIDToken)
                        }
                    }
                }
                }
            }
        }
    }
    
    // MARK: - Apple Sign In
    
    func signInWithApple() async throws -> String {
        let nonce = randomNonceString()
        currentNonce = nonce
        
        return try await withCheckedThrowingContinuation { continuation in
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let request = appleIDProvider.createRequest()
            request.requestedScopes = [.fullName, .email]
            request.nonce = sha256(nonce)
            
            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            
            // Store delegate as instance property to prevent deallocation
            self.appleSignInDelegate = AppleSignInDelegate { [weak self] result in
                defer { 
                    self?.currentNonce = nil
                    self?.appleSignInDelegate = nil
                    self?.appleContextProvider = nil
                }
                switch result {
                case .success(let idToken):
                    continuation.resume(returning: idToken)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            authorizationController.delegate = self.appleSignInDelegate
            
            Task { @MainActor in
                guard let scene = await self.getWindowScene() else {
                    continuation.resume(throwing: FirebaseAuthError.noViewController)
                    return
                }
                
                // Store context provider as instance property
                self.appleContextProvider = ApplePresentationContextProvider(windowScene: scene)
                authorizationController.presentationContextProvider = self.appleContextProvider
                authorizationController.performRequests()
            }
        }
    }
    
    // MARK: - Sign Out
    
    func signOut() throws {
        try Auth.auth().signOut()
        GIDSignIn.sharedInstance.signOut()
    }
    
    // MARK: - Helper Methods
    
    @MainActor
    private func getRootViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return nil
        }
        return window.rootViewController
    }
    
    @MainActor
    private func getWindowScene() -> UIWindowScene? {
        return UIApplication.shared.connectedScenes.first as? UIWindowScene
    }
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
}

// MARK: - Apple Sign In Delegate

class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate {
    private let completion: (Result<String, Error>) -> Void
    
    init(completion: @escaping (Result<String, Error>) -> Void) {
        self.completion = completion
        super.init()
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = FirebaseAuthManager.shared.currentNonce else {
                completion(.failure(FirebaseAuthError.invalidNonce))
                return
            }
            
            guard let appleIDToken = appleIDCredential.identityToken else {
                completion(.failure(FirebaseAuthError.noAppleIDToken))
                return
            }
            
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                completion(.failure(FirebaseAuthError.invalidAppleToken))
                return
            }
            
            let credential = OAuthProvider.appleCredential(withIDToken: idTokenString,
                                                           rawNonce: nonce,
                                                           fullName: appleIDCredential.fullName)
            
            Auth.auth().signIn(with: credential) { [weak self] authResult, error in
                if let error = error {
                    self?.completion(.failure(error))
                    return
                }
                
                // Get Firebase ID token
                authResult?.user.getIDToken { token, error in
                    if let error = error {
                        self?.completion(.failure(error))
                    } else if let token = token {
                        self?.completion(.success(token))
                    } else {
                        self?.completion(.failure(FirebaseAuthError.noIDToken))
                    }
                }
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // Check if user cancelled
        if let authError = error as? ASAuthorizationError, authError.code == .canceled {
            completion(.failure(FirebaseAuthError.userCancelled))
        } else {
            completion(.failure(error))
        }
    }
}

// MARK: - Presentation Context Provider

class ApplePresentationContextProvider: NSObject, ASAuthorizationControllerPresentationContextProviding {
    private let windowScene: UIWindowScene
    
    init(windowScene: UIWindowScene) {
        self.windowScene = windowScene
        super.init()
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return windowScene.windows.first { $0.isKeyWindow } ?? windowScene.windows.first!
    }
}

// MARK: - Firebase Auth Errors

enum FirebaseAuthError: LocalizedError {
    case noViewController
    case noClientID
    case invalidGoogleToken
    case noIDToken
    case invalidNonce
    case noAppleIDToken
    case invalidAppleToken
    case userCancelled
    
    var errorDescription: String? {
        switch self {
        case .noViewController:
            return "No view controller available for presentation"
        case .noClientID:
            return "Google client ID not found"
        case .invalidGoogleToken:
            return "Invalid Google authentication token"
        case .noIDToken:
            return "No Firebase ID token received"
        case .invalidNonce:
            return "Invalid nonce for Apple Sign In"
        case .noAppleIDToken:
            return "No Apple ID token received"
        case .invalidAppleToken:
            return "Invalid Apple authentication token"
        case .userCancelled:
            return "User cancelled authentication"
        }
    }
}