import Foundation

class RewardsManager: ObservableObject {
    static let shared = RewardsManager()
    
    @Published var tokenBalance: String = "0"
    @Published var pendingRewards: String = "0"
    @Published var totalEarned: String = "0"
    @Published var recentRewards: [Reward] = []
    
    private init() {}
    
    func fetchTokenBalance() async throws {
        guard let token = AuthManager.shared.getAccessToken() else {
            throw RewardsError.notAuthenticated
        }
        
        let response: TokenBalanceResponse = try await APIClient.shared.request(
            endpoint: "/rewards/balance",
            method: .GET,
            headers: ["Authorization": "Bearer \(token)"],
            responseType: TokenBalanceResponse.self
        )
        
        await MainActor.run {
            self.tokenBalance = response.balance
            self.pendingRewards = response.pendingRewards
            self.totalEarned = response.totalEarned
        }
    }
    
    func fetchRewardHistory(limit: Int = 50, offset: Int = 0) async throws -> [Reward] {
        guard let token = AuthManager.shared.getAccessToken() else {
            throw RewardsError.notAuthenticated
        }
        
        let response: RewardHistoryResponse = try await APIClient.shared.request(
            endpoint: "/rewards/history?limit=\(limit)&offset=\(offset)",
            method: .GET,
            headers: ["Authorization": "Bearer \(token)"],
            responseType: RewardHistoryResponse.self
        )
        
        await MainActor.run {
            if offset == 0 {
                self.recentRewards = response.data
            } else {
                self.recentRewards.append(contentsOf: response.data)
            }
        }
        
        return response.data
    }
    
    func refreshAllData() async throws {
        try await fetchTokenBalance()
        _ = try await fetchRewardHistory()
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