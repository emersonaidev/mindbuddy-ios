import SwiftUI
import Combine

@MainActor
class SocialLeaderboardViewModel: ObservableObject {
    @Published var leaderboardEntries: [LeaderboardEntry] = []
    @Published var topThree: [LeaderboardEntry] = []
    @Published var userPosition: LeaderboardEntry?
    @Published var isLoading = false
    @Published var currentUserId = ""
    
    private let authManager: AuthenticationServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(authManager: AuthenticationServiceProtocol = DependencyContainer.shared.authService) {
        self.authManager = authManager
        self.currentUserId = authManager.currentUser?.id ?? ""
    }
    
    func loadLeaderboard(timeframe: SocialLeaderboardView.Timeframe, category: SocialLeaderboardView.LeaderboardCategory) {
        isLoading = true
        
        // Simulate API call with mock data
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self = self else { return }
            
            // Generate mock leaderboard data
            let mockEntries = self.generateMockLeaderboard(for: category)
            
            self.leaderboardEntries = mockEntries
            self.topThree = Array(mockEntries.prefix(3))
            
            // Find user position
            if let userIndex = mockEntries.firstIndex(where: { $0.user.id == self.currentUserId }) {
                self.userPosition = mockEntries[userIndex]
            } else {
                // If user not in top entries, create their position
                self.userPosition = LeaderboardEntry(
                    rank: 42,
                    user: LeaderboardUser(
                        id: self.currentUserId,
                        displayName: "You",
                        avatarURL: nil
                    ),
                    score: 850,
                    change: -3,
                    subtitle: "Keep going!"
                )
            }
            
            self.isLoading = false
        }
    }
    
    func refreshLeaderboard() {
        // Re-fetch current leaderboard
        loadLeaderboard(timeframe: .weekly, category: .overall)
    }
    
    private func generateMockLeaderboard(for category: SocialLeaderboardView.LeaderboardCategory) -> [LeaderboardEntry] {
        let names = [
            "Sarah Johnson", "Mike Chen", "Emma Wilson", "Alex Thompson",
            "Lisa Garcia", "David Kim", "Rachel Brown", "James Miller",
            "Sophie Davis", "Chris Martinez", "Amy Rodriguez", "Kevin Lee",
            "Maria Gonzalez", "Brian Taylor", "Jessica Anderson"
        ]
        
        var entries: [LeaderboardEntry] = []
        
        for (index, name) in names.enumerated() {
            let rank = index + 1
            let score = generateScore(for: category, rank: rank)
            let change = Int.random(in: -5...5)
            let subtitle = generateSubtitle(for: category)
            
            let entry = LeaderboardEntry(
                rank: rank,
                user: LeaderboardUser(
                    id: UUID().uuidString,
                    displayName: name,
                    avatarURL: nil
                ),
                score: score,
                change: change,
                subtitle: subtitle
            )
            
            entries.append(entry)
        }
        
        // Insert current user at position 7 if not already in list
        if !entries.contains(where: { $0.user.id == currentUserId }) && entries.count > 6 {
            let userEntry = LeaderboardEntry(
                rank: 7,
                user: LeaderboardUser(
                    id: currentUserId,
                    displayName: authManager.currentUser?.fullName ?? "You",
                    avatarURL: nil
                ),
                score: generateScore(for: category, rank: 7),
                change: 2,
                subtitle: generateSubtitle(for: category)
            )
            
            entries.insert(userEntry, at: 6)
            
            // Update ranks for entries after insertion
            for i in 7..<entries.count {
                entries[i] = LeaderboardEntry(
                    rank: i + 1,
                    user: entries[i].user,
                    score: entries[i].score,
                    change: entries[i].change,
                    subtitle: entries[i].subtitle
                )
            }
        }
        
        return entries
    }
    
    private func generateScore(for category: SocialLeaderboardView.LeaderboardCategory, rank: Int) -> Double {
        let baseScore: Double
        
        switch category {
        case .overall:
            baseScore = 10000
        case .steps:
            baseScore = 50000
        case .stress:
            baseScore = 95
        case .tokens:
            baseScore = 5000
        }
        
        // Decrease score based on rank with some randomness
        let decrease = Double(rank - 1) * (baseScore * 0.08)
        let randomFactor = Double.random(in: 0.9...1.1)
        
        return max(100, (baseScore - decrease) * randomFactor)
    }
    
    private func generateSubtitle(for category: SocialLeaderboardView.LeaderboardCategory) -> String {
        switch category {
        case .overall:
            return ["Health Champion", "Wellness Warrior", "Fitness Enthusiast", "Active Member"].randomElement()!
        case .steps:
            return ["Marathon Walker", "Daily Stepper", "Movement Master", "Step Champion"].randomElement()!
        case .stress:
            return ["Zen Master", "Calm Achiever", "Mindful Living", "Stress Buster"].randomElement()!
        case .tokens:
            return ["Token Master", "Reward Hunter", "MNDY Collector", "Top Earner"].randomElement()!
        }
    }
}

// MARK: - Supporting Types

struct LeaderboardEntry: Identifiable {
    let id = UUID()
    let rank: Int
    let user: LeaderboardUser
    let score: Double
    let change: Int
    let subtitle: String?
}

struct LeaderboardUser: Identifiable {
    let id: String
    let displayName: String
    let avatarURL: String?
}