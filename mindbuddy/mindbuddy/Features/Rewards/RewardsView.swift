import SwiftUI

struct RewardsView: View {
    @StateObject private var rewardsManager = RewardsManager.shared
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var selectedReward: Reward?
    @State private var showingRewardDetail = false
    @State private var animateBalance = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.98, green: 0.96, blue: 0.94),
                        Color.white
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Token Balance Overview
                        TokenBalanceOverview(animateBalance: $animateBalance)
                            .onAppear {
                                withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                                    animateBalance = true
                                }
                            }
                        
                        // Stats Overview
                        StatsOverview()
                        
                        // Recent Rewards
                        RecentRewardsSection(
                            selectedReward: $selectedReward,
                            showingRewardDetail: $showingRewardDetail
                        )
                        
                        Spacer(minLength: 50)
                    }
                    .padding(.top)
                }
                .navigationTitle("Rewards")
                .refreshable {
                    await refreshData()
                }
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.2))
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .sheet(item: $selectedReward) { reward in
                RewardDetailView(reward: reward)
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
            
            // Animate balance update
            await MainActor.run {
                withAnimation(.spring()) {
                    animateBalance.toggle()
                }
            }
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

// MARK: - Token Balance Overview

struct TokenBalanceOverview: View {
    @StateObject private var rewardsManager = RewardsManager.shared
    @Binding var animateBalance: Bool
    @State private var pulseAnimation = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Main Balance Card
            VStack(spacing: 16) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.orange, Color.orange.opacity(0.7)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 60)
                            .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                            .animation(
                                Animation.easeInOut(duration: 2).repeatForever(autoreverses: true),
                                value: pulseAnimation
                            )
                        
                        Image(systemName: "bitcoinsign.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    }
                    .onAppear {
                        pulseAnimation = true
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Total Balance")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(rewardsManager.formatTokenAmount(rewardsManager.tokenBalance))
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                                .scaleEffect(animateBalance ? 1.0 : 0.8)
                                .opacity(animateBalance ? 1.0 : 0.5)
                            
                            Text("MNDY")
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                }
                
                // Progress indicator
                ProgressBar(
                    value: Double(rewardsManager.pendingRewards) ?? 0,
                    total: (Double(rewardsManager.tokenBalance) ?? 0) + (Double(rewardsManager.pendingRewards) ?? 0),
                    label: "Progress to next milestone"
                )
                
                // Balance breakdown
                HStack(spacing: 0) {
                    BalanceBreakdownItem(
                        title: "Pending",
                        value: rewardsManager.formatTokenAmount(rewardsManager.pendingRewards),
                        color: .orange,
                        icon: "clock.fill"
                    )
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 1, height: 40)
                    
                    BalanceBreakdownItem(
                        title: "Total Earned",
                        value: rewardsManager.formatTokenAmount(rewardsManager.totalEarned),
                        color: .green,
                        icon: "checkmark.circle.fill"
                    )
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: 5)
            )
        }
        .padding(.horizontal)
    }
}

struct BalanceBreakdownItem: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ProgressBar: View {
    let value: Double
    let total: Double
    let label: String
    
    private var progress: Double {
        guard total > 0 else { return 0 }
        return min(value / total, 1.0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.orange, Color.orange.opacity(0.7)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 8)
                        .animation(.spring(), value: progress)
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - Stats Overview

struct StatsOverview: View {
    @StateObject private var rewardsManager = RewardsManager.shared
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                RewardStatCard(
                    title: "This Week",
                    value: "125.5",
                    unit: "MNDY",
                    change: "+12%",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .blue
                )
                
                RewardStatCard(
                    title: "This Month",
                    value: "485.2",
                    unit: "MNDY",
                    change: "+8%",
                    icon: "calendar",
                    color: .purple
                )
                
                RewardStatCard(
                    title: "Avg Daily",
                    value: "17.8",
                    unit: "MNDY",
                    change: "+5%",
                    icon: "chart.bar.fill",
                    color: .green
                )
            }
            .padding(.horizontal)
        }
    }
}

struct RewardStatCard: View {
    let title: String
    let value: String
    let unit: String
    let change: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                Spacer()
                
                Text(change)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(change.hasPrefix("+") ? .green : .red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill((change.hasPrefix("+") ? Color.green : Color.red).opacity(0.1))
                    )
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 140)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 2)
        )
    }
}

// MARK: - Recent Rewards Section

struct RecentRewardsSection: View {
    @StateObject private var rewardsManager = RewardsManager.shared
    @Binding var selectedReward: Reward?
    @Binding var showingRewardDetail: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Rewards")
                    .font(.headline)
                
                Spacer()
                
                Button("See All") {
                    // Navigate to full history
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            .padding(.horizontal)
            
            if rewardsManager.recentRewardsList.isEmpty {
                EmptyRewardsView()
                    .transition(.opacity)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(Array(rewardsManager.recentRewardsList.enumerated()), id: \.element.id) { index, reward in
                        RewardRow(reward: reward)
                            .transition(.asymmetric(
                                insertion: .slide.combined(with: .opacity),
                                removal: .scale.combined(with: .opacity)
                            ))
                            .animation(
                                .spring(response: 0.6, dampingFraction: 0.8)
                                    .delay(Double(index) * 0.05),
                                value: rewardsManager.recentRewardsList.count
                            )
                            .onTapGesture {
                                selectedReward = reward
                            }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct RewardRow: View {
    let reward: Reward
    @State private var isPressed = false
    
    var body: some View {
        HStack {
            // Reward type icon with animation
            ZStack {
                Circle()
                    .fill(rewardTypeColor.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: rewardTypeIcon)
                    .font(.title2)
                    .foregroundColor(rewardTypeColor)
                    .scaleEffect(isPressed ? 0.9 : 1.0)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(reward.rewardType.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if let description = reward.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text(formatDate(reward.createdAt))
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 2) {
                    Text("+")
                        .font(.caption)
                        .fontWeight(.medium)
                    Text(RewardsManager.shared.formatTokenAmount(reward.amount))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.green)
                
                Text("MNDY")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isPressed = false
                }
            }
        }
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
        
        let relativeFormatter = RelativeDateTimeFormatter()
        relativeFormatter.unitsStyle = .abbreviated
        return relativeFormatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Empty State

struct EmptyRewardsView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: 100, height: 100)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                
                Image(systemName: "gift")
                    .font(.system(size: 50))
                    .foregroundColor(.orange)
                    .rotationEffect(.degrees(isAnimating ? 10 : -10))
            }
            .onAppear {
                withAnimation(
                    Animation.easeInOut(duration: 2).repeatForever(autoreverses: true)
                ) {
                    isAnimating = true
                }
            }
            
            VStack(spacing: 8) {
                Text("No rewards yet")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Start sharing your health data to earn your first MNDY tokens!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {
                // Navigate to health tab
            }) {
                Label("Start Earning", systemImage: "arrow.right")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(25)
            }
        }
        .padding(.vertical, 40)
        .padding(.horizontal)
    }
}

// MARK: - Reward Detail View

struct RewardDetailView: View {
    let reward: Reward
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Icon and amount
                    VStack(spacing: 16) {
                        Image(systemName: rewardTypeIcon)
                            .font(.system(size: 60))
                            .foregroundColor(rewardTypeColor)
                        
                        VStack(spacing: 8) {
                            Text("+\(RewardsManager.shared.formatTokenAmount(reward.amount)) MNDY")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                            
                            Text(reward.rewardType.displayName)
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Details
                    VStack(alignment: .leading, spacing: 16) {
                        if let description = reward.description {
                            DetailRow(label: "Description", value: description)
                        }
                        
                        DetailRow(label: "Date", value: formatDate(reward.createdAt))
                        DetailRow(label: "Transaction ID", value: String(reward.id.prefix(8)) + "...")
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Reward Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
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
        displayFormatter.dateStyle = .long
        displayFormatter.timeStyle = .short
        return displayFormatter.string(from: date)
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .multilineTextAlignment(.trailing)
        }
    }
}

#Preview {
    RewardsView()
}