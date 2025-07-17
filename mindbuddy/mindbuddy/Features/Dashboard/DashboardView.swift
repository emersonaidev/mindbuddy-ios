import SwiftUI

struct DashboardView: View {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var rewardsManager = RewardsManager.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Welcome Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Welcome back,")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                                
                                Text(authManager.currentUser?.firstName ?? "User")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                authManager.logout()
                            }) {
                                Image(systemName: "person.circle")
                                    .font(.title)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Token Balance Card
                    TokenBalanceCard()
                    
                    // Health Stats Grid
                    HealthStatsGrid()
                    
                    // Recent Activity
                    RecentActivityCard()
                    
                    Spacer()
                }
                .padding(.top)
            }
            .navigationBarHidden(true)
            .refreshable {
                await refreshData()
            }
        }
        .onAppear {
            Task {
                await refreshData()
            }
        }
    }
    
    private func refreshData() async {
        do {
            try await rewardsManager.refreshAllData()
        } catch {
            print("Failed to refresh data: \(error)")
        }
    }
}

struct TokenBalanceCard: View {
    @StateObject private var rewardsManager = RewardsManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Token Balance")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("\(rewardsManager.formatTokenAmount(rewardsManager.tokenBalance)) MNDY")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Image(systemName: "bitcoinsign.circle.fill")
                    .font(.title)
                    .foregroundColor(.orange)
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Pending Rewards")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(rewardsManager.formatTokenAmount(rewardsManager.pendingRewards)) MNDY")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Total Earned")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(rewardsManager.formatTokenAmount(rewardsManager.totalEarned)) MNDY")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct HealthStatsGrid: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Health Overview")
                .font(.headline)
                .padding(.horizontal)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                HealthStatCard(
                    title: "Heart Rate",
                    value: "78 BPM",
                    icon: "heart.fill",
                    color: .red
                )
                
                HealthStatCard(
                    title: "Stress Level",
                    value: "Low",
                    icon: "brain.head.profile",
                    color: .green
                )
                
                HealthStatCard(
                    title: "Steps",
                    value: "8,432",
                    icon: "figure.walk",
                    color: .blue
                )
                
                HealthStatCard(
                    title: "Sleep",
                    value: "7.5 hrs",
                    icon: "bed.double.fill",
                    color: .purple
                )
            }
            .padding(.horizontal)
        }
    }
}

struct HealthStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct RecentActivityCard: View {
    @StateObject private var rewardsManager = RewardsManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                if rewardsManager.recentRewards.isEmpty {
                    Text("No recent activity")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    ForEach(rewardsManager.recentRewards.prefix(3)) { reward in
                        ActivityRow(reward: reward)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct ActivityRow: View {
    let reward: Reward
    
    var body: some View {
        HStack {
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
            
            Text("+\(RewardsManager.shared.formatTokenAmount(reward.amount)) MNDY")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.green)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else {
            return dateString
        }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        displayFormatter.timeStyle = .short
        return displayFormatter.string(from: date)
    }
}

#Preview {
    DashboardView()
}