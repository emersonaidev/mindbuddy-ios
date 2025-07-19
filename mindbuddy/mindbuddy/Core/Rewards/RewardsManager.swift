import Foundation

class RewardsManager: ObservableObject, RewardsServiceProtocol {
    static let shared = RewardsManager()
    
    @Published var tokenBalance: String = "0"
    @Published var pendingRewards: String = "0"
    @Published var totalEarned: String = "0"
    @Published var recentRewardsList: [Reward] = []
    @Published var recentActivities: [RecentActivity] = []
    private var _recentRewards: [Reward] = [] {
        didSet {
            recentRewardsList = _recentRewards
        }
    }
    
    var recentRewards: [RewardTransaction] {
        return _recentRewards.map { reward in
            TokenTransaction(
                id: reward.id,
                type: .reward,
                amount: reward.amount,
                status: .completed,
                transactionHash: nil,
                createdAt: reward.createdAt
            )
        }
    }
    
    // Protocol properties
    var currentBalance: Int {
        return Int(tokenBalance) ?? 0
    }
    
    private let apiClient: APIClientProtocol
    private let authService: AuthenticationServiceProtocol
    
    init(
        apiClient: APIClientProtocol = DependencyContainer.shared.apiClient,
        authService: AuthenticationServiceProtocol = DependencyContainer.shared.authService
    ) {
        self.apiClient = apiClient
        self.authService = authService
    }
    
    func fetchTokenBalance() async throws {
        guard let token = authService.getAccessToken() else {
            throw RewardsError.notAuthenticated
        }
        
        let response: TokenBalanceResponse
        if let apiClient = apiClient as? APIClient {
            response = try await apiClient.requestWithRetry(
                endpoint: "/rewards/balance",
                method: .GET,
                body: nil,
                headers: ["Authorization": "Bearer \(token)"],
                responseType: TokenBalanceResponse.self,
                requiresAuth: true,
                retryPolicy: .default
            )
        } else {
            response = try await apiClient.request(
                endpoint: "/rewards/balance",
                method: .GET,
                body: nil,
                headers: ["Authorization": "Bearer \(token)"],
                responseType: TokenBalanceResponse.self,
                requiresAuth: true
            )
        }
        
        await MainActor.run {
            self.tokenBalance = response.balance
            self.pendingRewards = response.pendingRewards
            self.totalEarned = response.totalEarned
        }
    }
    
    func fetchRewardHistory(limit: Int = 50, offset: Int = 0) async throws -> [Reward] {
        guard let token = authService.getAccessToken() else {
            throw RewardsError.notAuthenticated
        }
        
        let response: RewardHistoryResponse
        if let apiClient = apiClient as? APIClient {
            response = try await apiClient.requestWithRetry(
                endpoint: "/rewards/history?limit=\(limit)&offset=\(offset)",
                method: .GET,
                body: nil,
                headers: ["Authorization": "Bearer \(token)"],
                responseType: RewardHistoryResponse.self,
                requiresAuth: true,
                retryPolicy: .default
            )
        } else {
            response = try await apiClient.request(
                endpoint: "/rewards/history?limit=\(limit)&offset=\(offset)",
                method: .GET,
                body: nil,
                headers: ["Authorization": "Bearer \(token)"],
                responseType: RewardHistoryResponse.self,
                requiresAuth: true
            )
        }
        
        await MainActor.run {
            if offset == 0 {
                self._recentRewards = response.data
            } else {
                self._recentRewards.append(contentsOf: response.data)
            }
        }
        
        return response.data
    }
    
    func refreshAllData() async throws {
        try await fetchTokenBalance()
        _ = try await fetchRewardHistory()
        try await fetchRecentActivities()
    }
    
    func fetchRecentActivities() async throws {
        guard let token = authService.getAccessToken() else {
            throw RewardsError.notAuthenticated
        }
        
        let activities: [RecentActivity]
        if let apiClient = apiClient as? APIClient {
            activities = try await apiClient.requestWithRetry(
                endpoint: "/rewards/recent",
                method: .GET,
                body: nil,
                headers: ["Authorization": "Bearer \(token)"],
                responseType: [RecentActivity].self,
                requiresAuth: true,
                retryPolicy: .default
            )
        } else {
            activities = try await apiClient.request(
                endpoint: "/rewards/recent",
                method: .GET,
                body: nil,
                headers: ["Authorization": "Bearer \(token)"],
                responseType: [RecentActivity].self,
                requiresAuth: true
            )
        }
        
        await MainActor.run {
            self.recentActivities = activities
        }
    }
    
    func formatTokenAmount(_ amount: String) -> String {
        guard let doubleAmount = Double(amount) else {
            return amount
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        
        return formatter.string(from: NSNumber(value: doubleAmount)) ?? amount
    }
    
    // MARK: - RewardsServiceProtocol Methods
    
    func fetchRewardHistory() async throws {
        _ = try await fetchRewardHistory(limit: 50, offset: 0)
    }
    
    func claimReward(for healthDataSubmission: String) async throws -> RewardTransaction {
        guard let token = authService.getAccessToken() else {
            throw RewardsError.notAuthenticated
        }
        
        let requestData = ["submissionId": healthDataSubmission]
        let body = try JSONEncoder().encode(requestData)
        
        let response: TokenTransaction
        if let apiClient = apiClient as? APIClient {
            response = try await apiClient.requestWithRetry(
                endpoint: "/rewards/claim",
                method: .POST,
                body: body,
                headers: ["Authorization": "Bearer \(token)"],
                responseType: TokenTransaction.self,
                requiresAuth: true,
                retryPolicy: .aggressive  // More aggressive for important transactions
            )
        } else {
            response = try await apiClient.request(
                endpoint: "/rewards/claim",
                method: .POST,
                body: body,
                headers: ["Authorization": "Bearer \(token)"],
                responseType: TokenTransaction.self,
                requiresAuth: true
            )
        }
        
        // Refresh balance after claiming
        try await fetchTokenBalance()
        
        return response
    }
}

enum RewardsError: Error {
    case notAuthenticated
    case invalidResponse
    
    var localizedDescription: String {
        switch self {
        case .notAuthenticated:
            return "User not authenticated"
        case .invalidResponse:
            return "Invalid response from server"
        }
    }
}