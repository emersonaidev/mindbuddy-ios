import SwiftUI

struct ChallengesView: View {
    @StateObject private var viewModel = ChallengesViewModel()
    @State private var selectedTab = ChallengeTab.active
    @State private var showingChallengeDetail: Challenge?
    
    enum ChallengeTab: String, CaseIterable {
        case active = "Active"
        case available = "Available"
        case completed = "Completed"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Stats Overview
                    ChallengeStatsOverview(stats: viewModel.userStats)
                    
                    // Tab Selection
                    Picker("Challenge Type", selection: $selectedTab) {
                        ForEach(ChallengeTab.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    // Challenge List based on selected tab
                    switch selectedTab {
                    case .active:
                        ActiveChallengesSection(
                            challenges: viewModel.activeChallenges,
                            onChallengeSelected: { showingChallengeDetail = $0 }
                        )
                    case .available:
                        AvailableChallengesSection(
                            challenges: viewModel.availableChallenges,
                            onJoinChallenge: viewModel.joinChallenge,
                            onChallengeSelected: { showingChallengeDetail = $0 }
                        )
                    case .completed:
                        CompletedChallengesSection(
                            challenges: viewModel.completedChallenges,
                            onChallengeSelected: { showingChallengeDetail = $0 }
                        )
                    }
                    
                    Spacer(minLength: 50)
                }
                .padding(.top)
            }
            .navigationTitle("Challenges")
            .sheet(item: $showingChallengeDetail) { challenge in
                ChallengeDetailView(challenge: challenge, viewModel: viewModel)
            }
            .onAppear {
                viewModel.loadChallenges()
            }
        }
    }
}

// MARK: - Challenge Stats Overview

struct ChallengeStatsOverview: View {
    let stats: ChallengeStats
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Your Challenge Stats")
                .font(.headline)
            
            HStack(spacing: 20) {
                StatItem(
                    value: "\(stats.totalCompleted)",
                    label: "Completed",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                
                StatItem(
                    value: "\(stats.currentStreak)",
                    label: "Day Streak",
                    icon: "flame.fill",
                    color: .orange
                )
                
                StatItem(
                    value: "\(stats.tokensEarned)",
                    label: "MNDY Earned",
                    icon: "bitcoinsign.circle.fill",
                    color: .yellow
                )
                
                StatItem(
                    value: "\(stats.rank)",
                    label: "Rank",
                    icon: "star.fill",
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

struct StatItem: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Active Challenges Section

struct ActiveChallengesSection: View {
    let challenges: [Challenge]
    let onChallengeSelected: (Challenge) -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            if challenges.isEmpty {
                EmptyStateView(
                    icon: "target",
                    title: "No Active Challenges",
                    description: "Join a challenge to start earning rewards!"
                )
                .padding()
            } else {
                ForEach(challenges) { challenge in
                    ActiveChallengeCard(
                        challenge: challenge,
                        onTap: { onChallengeSelected(challenge) }
                    )
                }
            }
        }
        .padding(.horizontal)
    }
}

struct ActiveChallengeCard: View {
    let challenge: Challenge
    let onTap: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 16) {
                HStack {
                    // Icon
                    Image(systemName: challenge.icon)
                        .font(.title2)
                        .foregroundColor(challenge.color)
                        .frame(width: 50, height: 50)
                        .background(challenge.color.opacity(0.1))
                        .cornerRadius(12)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(challenge.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(challenge.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    // Time remaining
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(timeRemaining(challenge.endDate))
                            .font(.caption)
                            .fontWeight(.medium)
                        Text("remaining")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Progress
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Progress")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(Int(challenge.progress * 100))%")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 8)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(challenge.color)
                                .frame(width: geometry.size.width * challenge.progress, height: 8)
                                .animation(.spring(), value: challenge.progress)
                        }
                    }
                    .frame(height: 8)
                }
                
                // Participants and Reward
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.caption)
                        Text("\(challenge.participants) participants")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "bitcoinsign.circle.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text("+\(challenge.reward) MNDY")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
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
    
    private func timeRemaining(_ date: Date) -> String {
        let interval = date.timeIntervalSince(Date())
        if interval < 3600 {
            return "\(Int(interval / 60))m"
        } else if interval < 86400 {
            return "\(Int(interval / 3600))h"
        } else {
            return "\(Int(interval / 86400))d"
        }
    }
}

// MARK: - Available Challenges Section

struct AvailableChallengesSection: View {
    let challenges: [Challenge]
    let onJoinChallenge: (Challenge) -> Void
    let onChallengeSelected: (Challenge) -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(challenges) { challenge in
                AvailableChallengeCard(
                    challenge: challenge,
                    onJoin: { onJoinChallenge(challenge) },
                    onTap: { onChallengeSelected(challenge) }
                )
            }
        }
        .padding(.horizontal)
    }
}

struct AvailableChallengeCard: View {
    let challenge: Challenge
    let onJoin: () -> Void
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                // Icon
                Image(systemName: challenge.icon)
                    .font(.title2)
                    .foregroundColor(challenge.color)
                    .frame(width: 50, height: 50)
                    .background(challenge.color.opacity(0.1))
                    .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(challenge.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(challenge.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    HStack(spacing: 12) {
                        Label("\(challenge.duration)", systemImage: "clock")
                        Label("\(challenge.participants)", systemImage: "person.2")
                        Label("+\(challenge.reward) MNDY", systemImage: "bitcoinsign.circle")
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    onJoin()
                }) {
                    Text("Join")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(challenge.color)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Completed Challenges Section

struct CompletedChallengesSection: View {
    let challenges: [Challenge]
    let onChallengeSelected: (Challenge) -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            if challenges.isEmpty {
                EmptyStateView(
                    icon: "trophy",
                    title: "No Completed Challenges",
                    description: "Complete your first challenge to see it here!"
                )
                .padding()
            } else {
                ForEach(challenges) { challenge in
                    CompletedChallengeCard(
                        challenge: challenge,
                        onTap: { onChallengeSelected(challenge) }
                    )
                }
            }
        }
        .padding(.horizontal)
    }
}

struct CompletedChallengeCard: View {
    let challenge: Challenge
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                // Icon with checkmark
                ZStack(alignment: .bottomTrailing) {
                    Image(systemName: challenge.icon)
                        .font(.title2)
                        .foregroundColor(challenge.color)
                        .frame(width: 50, height: 50)
                        .background(challenge.color.opacity(0.1))
                        .cornerRadius(12)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                        .background(Color.white)
                        .clipShape(Circle())
                        .offset(x: 5, y: 5)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(challenge.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 8) {
                        Text("Completed \(formatDate(challenge.endDate))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 2) {
                            Image(systemName: "bitcoinsign.circle.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                            Text("+\(challenge.reward)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.green)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Challenge Detail View

struct ChallengeDetailView: View {
    let challenge: Challenge
    @ObservedObject var viewModel: ChallengesViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showingLeaderboard = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: challenge.icon)
                            .font(.system(size: 60))
                            .foregroundColor(challenge.color)
                        
                        Text(challenge.title)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(challenge.description)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                    .padding(.top)
                    
                    // Stats
                    HStack(spacing: 20) {
                        DetailStat(label: "Duration", value: challenge.duration, icon: "clock")
                        DetailStat(label: "Participants", value: "\(challenge.participants)", icon: "person.2")
                        DetailStat(label: "Reward", value: "\(challenge.reward) MNDY", icon: "bitcoinsign.circle")
                    }
                    .padding(.horizontal)
                    
                    // Progress (if active)
                    if challenge.status == .active {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Your Progress")
                                .font(.headline)
                            
                            ProgressView(value: challenge.progress)
                                .tint(challenge.color)
                            
                            Text("\(Int(challenge.progress * 100))% Complete")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Requirements
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Requirements")
                            .font(.headline)
                        
                        ForEach(challenge.requirements, id: \.self) { requirement in
                            HStack(alignment: .top) {
                                Image(systemName: "checkmark.circle")
                                    .foregroundColor(.green)
                                Text(requirement)
                                    .font(.subheadline)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Leaderboard Button
                    if challenge.status == .active {
                        Button(action: { showingLeaderboard = true }) {
                            Label("View Leaderboard", systemImage: "list.number")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                    
                    // Action Button
                    if challenge.status == .available {
                        Button(action: { 
                            viewModel.joinChallenge(challenge)
                            dismiss()
                        }) {
                            Text("Join Challenge")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(challenge.color)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("Challenge Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingLeaderboard) {
                ChallengeLeaderboardView(challenge: challenge)
            }
        }
    }
}

struct DetailStat: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.headline)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// MARK: - Challenge Leaderboard View

struct ChallengeLeaderboardView: View {
    let challenge: Challenge
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Text("Challenge Leaderboard for \(challenge.title)")
                .navigationTitle("Leaderboard")
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
}

// MARK: - Empty State

struct EmptyStateView: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.headline)
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

#Preview {
    ChallengesView()
}