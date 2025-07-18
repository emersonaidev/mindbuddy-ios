import Foundation

// Type alias for backward compatibility
typealias RewardTransaction = TokenTransaction

struct TokenTransaction: Codable, Identifiable {
    let id: String
    let type: TransactionType
    let amount: String
    let status: TransactionStatus
    let transactionHash: String?
    let createdAt: String
}

enum TransactionType: String, Codable {
    case reward = "REWARD"
    case transferIn = "TRANSFER_IN"
    case transferOut = "TRANSFER_OUT"
    case burn = "BURN"
    case mint = "MINT"
    
    var displayName: String {
        switch self {
        case .reward:
            return "Reward"
        case .transferIn:
            return "Transfer In"
        case .transferOut:
            return "Transfer Out"
        case .burn:
            return "Burn"
        case .mint:
            return "Mint"
        }
    }
}

enum TransactionStatus: String, Codable {
    case pending = "PENDING"
    case completed = "COMPLETED"
    case failed = "FAILED"
    
    var displayName: String {
        switch self {
        case .pending:
            return "Pending"
        case .completed:
            return "Completed"
        case .failed:
            return "Failed"
        }
    }
}

struct Reward: Codable, Identifiable {
    let id: String
    let rewardType: RewardType
    let amount: String
    let description: String?
    let createdAt: String
}

enum RewardType: String, Codable {
    case dailyCheckIn = "DAILY_CHECK_IN"
    case stressMonitoring = "STRESS_MONITORING"
    case healthDataSharing = "HEALTH_DATA_SHARING"
    case milestoneAchievement = "MILESTONE_ACHIEVEMENT"
    case referral = "REFERRAL"
    
    var displayName: String {
        switch self {
        case .dailyCheckIn:
            return "Daily Check-in"
        case .stressMonitoring:
            return "Stress Monitoring"
        case .healthDataSharing:
            return "Health Data Sharing"
        case .milestoneAchievement:
            return "Milestone Achievement"
        case .referral:
            return "Referral"
        }
    }
}

// MARK: - Reward DTOs

struct TokenBalanceResponse: Codable {
    let balance: String
    let pendingRewards: String
    let totalEarned: String
}

struct RewardHistoryResponse: Codable {
    let data: [Reward]
    let total: Int
    let limit: Int
    let offset: Int
}