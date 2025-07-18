import Foundation
import HealthKit

// MARK: - Authentication Service Protocol

protocol AuthenticationServiceProtocol {
    var isAuthenticated: Bool { get }
    var currentUser: User? { get }
    
    func login(email: String, password: String) async throws -> AuthResponse
    func register(email: String, password: String, firstName: String, lastName: String) async throws -> AuthResponse
    func signInWithGoogle() async throws -> AuthResponse
    func signInWithApple() async throws -> AuthResponse
    func resetPassword(email: String) async throws
    func logout()
    func refreshTokens() async throws
    func getAccessToken() -> String?
}

// MARK: - Network Service Protocol

protocol NetworkServiceProtocol {
    func request<T: Codable>(
        endpoint: String,
        method: HTTPMethod,
        body: Data?,
        headers: [String: String],
        responseType: T.Type,
        requiresAuth: Bool,
        isRetry: Bool
    ) async throws -> T
}

// MARK: - Keychain Service Protocol

protocol KeychainServiceProtocol {
    func saveTokens(accessToken: String, refreshToken: String) -> Bool
    func getAccessToken() -> String?
    func getRefreshToken() -> String?
    func hasValidTokens() -> Bool
    func clearAll() -> Bool
}

// MARK: - Health Service Protocol

protocol HealthServiceProtocol {
    var isAuthorized: Bool { get }
    
    func requestHealthKitPermissions() async throws
    func fetchHeartRateData(from startDate: Date, to endDate: Date) async throws -> [HealthData]
    func fetchHRVData(from startDate: Date, to endDate: Date) async throws -> [HealthData]
    func fetchStepsData(from startDate: Date, to endDate: Date) async throws -> [HealthData]
    func fetchBloodPressureData(from startDate: Date, to endDate: Date) async throws -> [HealthData]
    func fetchSleepData(from startDate: Date, to endDate: Date) async throws -> [HealthData]
    func submitHealthDataBatch(_ healthDataArray: [HealthData]) async throws
    func enableBackgroundDelivery() async throws
}

// MARK: - Rewards Service Protocol

protocol RewardsServiceProtocol {
    var currentBalance: Int { get }
    var recentRewards: [RewardTransaction] { get }
    
    func fetchTokenBalance() async throws
    func fetchRewardHistory() async throws
    func claimReward(for healthDataSubmission: String) async throws -> RewardTransaction
}

// MARK: - Cache Service Protocol

protocol CacheServiceProtocol {
    func store<T: Codable>(_ object: T, forKey key: String)
    func retrieve<T: Codable>(_ type: T.Type, forKey key: String) -> T?
    func remove(forKey key: String)
    func clearAll()
    func isExpired(forKey key: String, maxAge: TimeInterval) -> Bool
}

// MARK: - API Client Protocol

protocol APIClientProtocol {
    func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod,
        body: Data?,
        headers: [String: String],
        responseType: T.Type,
        requiresAuth: Bool
    ) async throws -> T
}

// MARK: - Firebase Auth Manager Protocol

protocol FirebaseAuthManagerProtocol {
    func signInWithGoogle() async throws -> String
    func signInWithApple() async throws -> String
    func signOut() throws
}

// MARK: - Configuration Protocol

protocol ConfigurationProtocol {
    var apiBaseURL: String { get }
    var cacheMaxAge: TimeInterval { get }
    var requestTimeout: TimeInterval { get }
    var maxRetryAttempts: Int { get }
    var isBackgroundProcessingEnabled: Bool { get }
    var healthKitBackgroundDeliveryEnabled: Bool { get }
}