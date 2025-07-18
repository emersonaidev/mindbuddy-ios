import SwiftUI

struct RewardsView: View {
    @StateObject private var rewardsManager = RewardsManager.shared
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Token Balance Overview
                    TokenBalanceOverview()
                    
                    // Recent Rewards
                    RecentRewardsSection()
                    
                    Spacer()
                }
                .padding(.top)
            }
            .navigationTitle("Rewards")
            .refreshable {
                await refreshData()
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                Task {
                    await refreshData()
                }
            }
        }
    }
    
    private func refreshData() async {
        isLoading = true
        
        do {
            try await rewardsManager.refreshAllData()
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.showingError = true
            }
        }
        
        await MainActor.run {
            self.isLoading = false
        }
    }
}

struct TokenBalanceOverview: View {
    @StateObject private var rewardsManager = RewardsManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            // Main Balance Card
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "bitcoinsign.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)
                    
                    VStack(alignment: .leading) {
                        Text("Total Balance")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("\(rewardsManager.formatTokenAmount(rewardsManager.tokenBalance)) MNDY")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    }
                    
                    Spacer()
                }
                
                // Balance breakdown
                HStack(spacing: 0) {
                    VStack {
                        Text("Pending")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(rewardsManager.formatTokenAmount(rewardsManager.pendingRewards))")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                    }
                    .frame(maxWidth: .infinity)
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 1, height: 30)
                    
                    VStack {
                        Text("Total Earned")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(rewardsManager.formatTokenAmount(rewardsManager.totalEarned))")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(16)
        }
        .padding(.horizontal)
    }
}

struct RecentRewardsSection: View {
    @StateObject private var rewardsManager = RewardsManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Rewards")
                .font(.headline)
                .padding(.horizontal)
            
            if rewardsManager.recentRewardsList.isEmpty {
                EmptyRewardsView()
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(rewardsManager.recentRewardsList) { reward in
                        RewardRow(reward: reward)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct RewardRow: View {
    let reward: Reward
    
    var body: some View {
        HStack {
            // Reward type icon
            Image(systemName: rewardTypeIcon)
                .font(.title2)
                .foregroundColor(rewardTypeColor)
                .frame(width: 40, height: 40)
                .background(rewardTypeColor.opacity(0.1))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(reward.rewardType.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if let description = reward.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(formatDate(reward.createdAt))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("+\(RewardsManager.shared.formatTokenAmount(reward.amount))")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
                
                Text("MNDY")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var rewardTypeIcon: String {
        switch reward.rewardType {
        case .dailyCheckIn:
            return "checkmark.circle.fill"
        case .stressMonitoring:
            return "brain.head.profile"
        case .healthDataSharing:
            return "heart.circle.fill"
        case .milestoneAchievement:
            return "trophy.fill"
        case .referral:
            return "person.2.fill"
        }
    }
    
    private var rewardTypeColor: Color {
        switch reward.rewardType {
        case .dailyCheckIn:
            return .blue
        case .stressMonitoring:
            return .purple
        case .healthDataSharing:
            return .red
        case .milestoneAchievement:
            return .orange
        case .referral:
            return .green
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else {
            return dateString
        }
        
        let displayFormatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            displayFormatter.dateStyle = .none
            displayFormatter.timeStyle = .short
            return "Today at \(displayFormatter.string(from: date))"
        } else if Calendar.current.isDateInYesterday(date) {
            displayFormatter.dateStyle = .none
            displayFormatter.timeStyle = .short
            return "Yesterday at \(displayFormatter.string(from: date))"
        } else {
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .none
            return displayFormatter.string(from: date)
        }
    }
}

struct EmptyRewardsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "gift")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No rewards yet")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Start sharing your health data to earn your first MNDY tokens!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 32)
        .padding(.horizontal)
    }
}

#Preview {
    RewardsView()
}