import Foundation
import HealthKit

// MARK: - Mock Auth Service

class MockAuthService: AuthenticationServiceProtocol {
    var isAuthenticated: Bool = false
    var currentUser: User? = nil
    
    func login(email: String, password: String) async throws -> AuthResponse {
        return AuthResponse(
            user: User(id: "test-id", email: email, firstName: "Test", lastName: "User", isVerified: true),
            accessToken: "mock-access-token",
            refreshToken: "mock-refresh-token"
        )
    }
    
    func register(email: String, password: String, firstName: String, lastName: String) async throws -> AuthResponse {
        return AuthResponse(
            user: User(id: "test-id", email: email, firstName: firstName, lastName: lastName, isVerified: false),
            accessToken: "mock-access-token",
            refreshToken: "mock-refresh-token"
        )
    }
    
    func signInWithGoogle() async throws -> AuthResponse {
        return try await login(email: "google@test.com", password: "password")
    }
    
    func signInWithApple() async throws -> AuthResponse {
        return try await login(email: "apple@test.com", password: "password")
    }
    
    func resetPassword(email: String) async throws {
        // Mock implementation
    }
    
    func logout() {
        isAuthenticated = false
        currentUser = nil
    }
    
    func refreshTokens() async throws {
        // Mock implementation
    }
    
    func getAccessToken() -> String? {
        return isAuthenticated ? "mock-access-token" : nil
    }
}

// MARK: - Mock Network Service

class MockNetworkService: NetworkServiceProtocol {
    func request<T>(endpoint: String, method: HTTPMethod, body: Data?, headers: [String : String], responseType: T.Type, requiresAuth: Bool, isRetry: Bool) async throws -> T where T : Decodable, T : Encodable {
        // Return mock data based on endpoint
        if endpoint.contains("health-data") {
            return HealthDataBatchResponse(submitted: 1, tokensEarned: "10", errors: nil) as! T
        }
        throw APIError.invalidResponse
    }
}

// MARK: - Mock Keychain Service

class MockKeychainService: KeychainServiceProtocol {
    private var storage: [String: String] = [:]
    
    func saveTokens(accessToken: String, refreshToken: String) -> Bool {
        storage["access_token"] = accessToken
        storage["refresh_token"] = refreshToken
        return true
    }
    
    func getAccessToken() -> String? {
        return storage["access_token"]
    }
    
    func getRefreshToken() -> String? {
        return storage["refresh_token"]
    }
    
    func hasValidTokens() -> Bool {
        return getAccessToken() != nil && getRefreshToken() != nil
    }
    
    func clearAll() -> Bool {
        storage.removeAll()
        return true
    }
}

// MARK: - Mock Health Service

class MockHealthService: HealthServiceProtocol {
    var isAuthorized: Bool = true
    
    func requestHealthKitPermissions() async throws {
        // Mock implementation
    }
    
    func fetchHeartRateData(from startDate: Date, to endDate: Date) async throws -> [HealthData] {
        return [
            HealthData(type: "heartRate", value: .double(72), unit: "bpm", recordedAt: Date())
        ]
    }
    
    func fetchHRVData(from startDate: Date, to endDate: Date) async throws -> [HealthData] {
        return [
            HealthData(type: "hrv", value: .double(50), unit: "ms", recordedAt: Date())
        ]
    }
    
    func fetchStepsData(from startDate: Date, to endDate: Date) async throws -> [HealthData] {
        return [
            HealthData(type: "steps", value: .integer(5000), unit: "steps", recordedAt: Date())
        ]
    }
    
    func fetchBloodPressureData(from startDate: Date, to endDate: Date) async throws -> [HealthData] {
        return [
            HealthData(type: "bloodPressure", value: .string("120/80"), unit: "mmHg", recordedAt: Date())
        ]
    }
    
    func fetchSleepData(from startDate: Date, to endDate: Date) async throws -> [HealthData] {
        return [
            HealthData(type: "sleep", value: .double(7.5), unit: "hours", recordedAt: Date())
        ]
    }
    
    func submitHealthDataBatch(_ healthDataArray: [HealthData]) async throws {
        // Mock implementation
    }
    
    func enableBackgroundDelivery() async throws {
        // Mock implementation
    }
}

// MARK: - Mock Rewards Service

class MockRewardsService: RewardsServiceProtocol {
    var currentBalance: Int = 100
    var recentRewards: [RewardTransaction] = []
    
    func fetchTokenBalance() async throws {
        // Mock implementation
    }
    
    func fetchRewardHistory() async throws {
        recentRewards = [
            TokenTransaction(
                id: "1",
                type: .reward,
                amount: "10",
                status: .completed,
                transactionHash: "0x123",
                createdAt: Date().iso8601String
            )
        ]
    }
    
    func claimReward(for healthDataSubmission: String) async throws -> RewardTransaction {
        return TokenTransaction(
            id: UUID().uuidString,
            type: .reward,
            amount: "5",
            status: .pending,
            transactionHash: nil,
            createdAt: Date().iso8601String
        )
    }
}

// MARK: - Mock Cache Service
// Note: MockCacheService is already defined in CacheService.swift

// MARK: - Mock API Client

class MockAPIClient: APIClientProtocol {
    func request<T>(endpoint: String, method: HTTPMethod, body: Data?, headers: [String : String], responseType: T.Type, requiresAuth: Bool) async throws -> T where T : Decodable {
        // Return mock data based on endpoint
        if endpoint.contains("auth") {
            return AuthResponse(
                user: User(id: "test-id", email: "test@example.com", firstName: "Test", lastName: "User", isVerified: true),
                accessToken: "mock-access-token",
                refreshToken: "mock-refresh-token"
            ) as! T
        }
        throw APIError.invalidResponse
    }
}

// MARK: - Mock Firebase Auth Manager

class MockFirebaseAuthManager: FirebaseAuthManagerProtocol {
    func signInWithGoogle() async throws -> String {
        return "mock-google-token"
    }
    
    func signInWithApple() async throws -> String {
        return "mock-apple-token"
    }
    
    func signOut() throws {
        // Mock implementation
    }
}