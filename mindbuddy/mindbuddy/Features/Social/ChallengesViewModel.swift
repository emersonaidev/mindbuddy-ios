import SwiftUI
import Combine

@MainActor
class ChallengesViewModel: ObservableObject {
    @Published var activeChallenges: [Challenge] = []
    @Published var availableChallenges: [Challenge] = []
    @Published var completedChallenges: [Challenge] = []
    @Published var userStats = ChallengeStats()
    @Published var isLoading = false
    
    private var cancellables = Set<AnyCancellable>()
    
    func loadChallenges() {
        isLoading = true
        
        // Simulate API call with mock data
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.loadMockData()
            self?.isLoading = false
        }
    }
    
    func joinChallenge(_ challenge: Challenge) {
        // Move challenge from available to active
        if let index = availableChallenges.firstIndex(where: { $0.id == challenge.id }) {
            var updatedChallenge = availableChallenges.remove(at: index)
            updatedChallenge.status = .active
            updatedChallenge.progress = 0
            activeChallenges.append(updatedChallenge)
        }
    }
    
    private func loadMockData() {
        // User Stats
        userStats = ChallengeStats(
            totalCompleted: 12,
            currentStreak: 7,
            tokensEarned: 2450,
            rank: 42
        )
        
        // Active Challenges
        activeChallenges = [
            Challenge(
                title: "Daily Steps Goal",
                description: "Walk 10,000 steps every day for a week",
                icon: "figure.walk",
                color: .green,
                status: .active,
                progress: 0.7,
                startDate: Date().addingTimeInterval(-5 * 24 * 3600),
                endDate: Date().addingTimeInterval(2 * 24 * 3600),
                participants: 234,
                reward: 100,
                duration: "7 days",
                requirements: [
                    "Walk at least 10,000 steps daily",
                    "Track your steps with Apple Health",
                    "Complete all 7 days consecutively"
                ]
            ),
            Challenge(
                title: "Stress Buster",
                description: "Keep your stress levels low for 5 consecutive days",
                icon: "brain.head.profile",
                color: .purple,
                status: .active,
                progress: 0.4,
                startDate: Date().addingTimeInterval(-2 * 24 * 3600),
                endDate: Date().addingTimeInterval(3 * 24 * 3600),
                participants: 156,
                reward: 150,
                duration: "5 days",
                requirements: [
                    "Maintain low stress levels",
                    "Log at least 3 readings per day",
                    "Practice daily meditation"
                ]
            )
        ]
        
        // Available Challenges
        availableChallenges = [
            Challenge(
                title: "Sleep Champion",
                description: "Get 7+ hours of quality sleep for 2 weeks",
                icon: "bed.double.fill",
                color: .indigo,
                status: .available,
                progress: 0,
                startDate: Date(),
                endDate: Date().addingTimeInterval(14 * 24 * 3600),
                participants: 89,
                reward: 300,
                duration: "14 days",
                requirements: [
                    "Sleep at least 7 hours nightly",
                    "Track sleep with Apple Health",
                    "Maintain consistent bedtime"
                ]
            ),
            Challenge(
                title: "Heart Health Hero",
                description: "Keep your resting heart rate below 70 BPM",
                icon: "heart.fill",
                color: .red,
                status: .available,
                progress: 0,
                startDate: Date(),
                endDate: Date().addingTimeInterval(7 * 24 * 3600),
                participants: 145,
                reward: 200,
                duration: "7 days",
                requirements: [
                    "Monitor heart rate daily",
                    "Maintain resting HR < 70 BPM",
                    "Record at least 5 readings daily"
                ]
            ),
            Challenge(
                title: "Mindful Minutes",
                description: "Complete 10 minutes of meditation daily",
                icon: "leaf.fill",
                color: .green,
                status: .available,
                progress: 0,
                startDate: Date(),
                endDate: Date().addingTimeInterval(30 * 24 * 3600),
                participants: 312,
                reward: 500,
                duration: "30 days",
                requirements: [
                    "Meditate for 10+ minutes daily",
                    "Use any meditation app",
                    "Log your sessions in MindBuddy"
                ]
            ),
            Challenge(
                title: "Weekend Warrior",
                description: "Complete 5 workouts this weekend",
                icon: "figure.run",
                color: .orange,
                status: .available,
                progress: 0,
                startDate: nextWeekend(),
                endDate: nextWeekend().addingTimeInterval(2 * 24 * 3600),
                participants: 67,
                reward: 75,
                duration: "2 days",
                requirements: [
                    "Complete 5 separate workouts",
                    "Each workout minimum 20 minutes",
                    "Track with Apple Health"
                ]
            )
        ]
        
        // Completed Challenges
        completedChallenges = [
            Challenge(
                title: "New Year New You",
                description: "Complete daily health check-ins for January",
                icon: "star.fill",
                color: .yellow,
                status: .completed,
                progress: 1.0,
                startDate: Date().addingTimeInterval(-30 * 24 * 3600),
                endDate: Date().addingTimeInterval(-1 * 24 * 3600),
                participants: 1024,
                reward: 1000,
                duration: "30 days",
                requirements: [
                    "Daily health check-ins",
                    "Track all vital metrics",
                    "No missed days"
                ]
            ),
            Challenge(
                title: "Hydration Station",
                description: "Drink 8 glasses of water daily for a week",
                icon: "drop.fill",
                color: .blue,
                status: .completed,
                progress: 1.0,
                startDate: Date().addingTimeInterval(-14 * 24 * 3600),
                endDate: Date().addingTimeInterval(-7 * 24 * 3600),
                participants: 456,
                reward: 100,
                duration: "7 days",
                requirements: [
                    "Drink 8 glasses daily",
                    "Log water intake",
                    "Complete all 7 days"
                ]
            )
        ]
    }
    
    private func nextWeekend() -> Date {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let daysUntilSaturday = (7 - weekday + 7) % 7
        return calendar.date(byAdding: .day, value: daysUntilSaturday == 0 ? 7 : daysUntilSaturday, to: today)!
    }
}

// MARK: - Supporting Types

struct Challenge: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let color: Color
    var status: ChallengeStatus
    var progress: Double
    let startDate: Date
    let endDate: Date
    let participants: Int
    let reward: Int
    let duration: String
    let requirements: [String]
}

enum ChallengeStatus {
    case active
    case available
    case completed
}

struct ChallengeStats {
    var totalCompleted: Int = 0
    var currentStreak: Int = 0
    var tokensEarned: Int = 0
    var rank: Int = 0
}