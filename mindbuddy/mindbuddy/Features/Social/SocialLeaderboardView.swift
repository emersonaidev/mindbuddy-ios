import SwiftUI

struct SocialLeaderboardView: View {
    @StateObject private var viewModel = SocialLeaderboardViewModel()
    @State private var selectedTimeframe = Timeframe.weekly
    @State private var selectedCategory = LeaderboardCategory.overall
    @State private var showingInviteFriends = false
    
    enum Timeframe: String, CaseIterable {
        case daily = "Daily"
        case weekly = "Weekly"
        case monthly = "Monthly"
        case allTime = "All Time"
    }
    
    enum LeaderboardCategory: String, CaseIterable {
        case overall = "Overall"
        case steps = "Steps"
        case stress = "Stress"
        case tokens = "Tokens"
        
        var icon: String {
            switch self {
            case .overall: return "trophy.fill"
            case .steps: return "figure.walk"
            case .stress: return "brain.head.profile"
            case .tokens: return "bitcoinsign.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .overall: return .yellow
            case .steps: return .green
            case .stress: return .purple
            case .tokens: return .orange
            }
        }
    }
    
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
                        // Timeframe Picker
                        Picker("Timeframe", selection: $selectedTimeframe) {
                            ForEach(Timeframe.allCases, id: \.self) { timeframe in
                                Text(timeframe.rawValue).tag(timeframe)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal)
                        .onChange(of: selectedTimeframe) { _, newValue in
                            viewModel.loadLeaderboard(timeframe: newValue, category: selectedCategory)
                        }
                        
                        // Category Tabs
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(LeaderboardCategory.allCases, id: \.self) { category in
                                    CategoryButton(
                                        category: category,
                                        isSelected: selectedCategory == category,
                                        action: {
                                            withAnimation {
                                                selectedCategory = category
                                                viewModel.loadLeaderboard(timeframe: selectedTimeframe, category: category)
                                            }
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // User's Position Card
                        if let userPosition = viewModel.userPosition {
                            UserPositionCard(position: userPosition)
                        }
                        
                        // Top 3 Podium
                        if viewModel.topThree.count >= 3 {
                            PodiumView(topThree: viewModel.topThree)
                        }
                        
                        // Leaderboard List
                        LeaderboardList(
                            entries: viewModel.leaderboardEntries,
                            currentUserId: viewModel.currentUserId
                        )
                        
                        // Invite Friends Button
                        Button(action: { showingInviteFriends = true }) {
                            Label("Invite Friends", systemImage: "person.badge.plus")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        
                        Spacer(minLength: 50)
                    }
                    .padding(.top)
                }
                
                if viewModel.isLoading {
                    ProgressView("Loading leaderboard...")
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(radius: 5)
                }
            }
            .navigationTitle("Leaderboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { viewModel.refreshLeaderboard() }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .sheet(isPresented: $showingInviteFriends) {
                InviteFriendsView()
            }
            .onAppear {
                viewModel.loadLeaderboard(timeframe: selectedTimeframe, category: selectedCategory)
            }
        }
    }
}

// MARK: - Category Button

struct CategoryButton: View {
    let category: SocialLeaderboardView.LeaderboardCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .white : category.color)
                
                Text(category.rawValue)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? category.color : Color(.systemGray6))
            )
        }
    }
}

// MARK: - User Position Card

struct UserPositionCard: View {
    let position: LeaderboardEntry
    
    var positionColor: Color {
        switch position.rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2) // Bronze
        default: return .blue
        }
    }
    
    var body: some View {
        HStack {
            // Rank
            ZStack {
                Circle()
                    .fill(positionColor)
                    .frame(width: 50, height: 50)
                
                Text("\(position.rank)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            // User Info
            VStack(alignment: .leading, spacing: 4) {
                Text("Your Position")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(position.user.displayName)
                    .font(.headline)
            }
            
            Spacer()
            
            // Score
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatScore(position.score))
                    .font(.title3)
                    .fontWeight(.bold)
                
                HStack(spacing: 2) {
                    Image(systemName: position.change > 0 ? "arrow.up" : position.change < 0 ? "arrow.down" : "minus")
                        .font(.caption)
                    Text("\(abs(position.change))")
                        .font(.caption)
                }
                .foregroundColor(position.change > 0 ? .green : position.change < 0 ? .red : .gray)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: positionColor.opacity(0.3), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal)
    }
    
    private func formatScore(_ score: Double) -> String {
        if score >= 1000 {
            return String(format: "%.1fK", score / 1000)
        }
        return String(format: "%.0f", score)
    }
}

// MARK: - Podium View

struct PodiumView: View {
    let topThree: [LeaderboardEntry]
    @State private var showPodium = false
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Top Performers")
                .font(.headline)
                .padding(.bottom)
            
            HStack(alignment: .bottom, spacing: 12) {
                // Second Place
                if topThree.count > 1 {
                    PodiumPlace(
                        entry: topThree[1],
                        place: 2,
                        height: 120,
                        color: .gray,
                        delay: 0.2
                    )
                    .opacity(showPodium ? 1 : 0)
                    .offset(y: showPodium ? 0 : 20)
                }
                
                // First Place
                if !topThree.isEmpty {
                    PodiumPlace(
                        entry: topThree[0],
                        place: 1,
                        height: 150,
                        color: .yellow,
                        delay: 0
                    )
                    .opacity(showPodium ? 1 : 0)
                    .offset(y: showPodium ? 0 : 20)
                }
                
                // Third Place
                if topThree.count > 2 {
                    PodiumPlace(
                        entry: topThree[2],
                        place: 3,
                        height: 100,
                        color: Color(red: 0.8, green: 0.5, blue: 0.2),
                        delay: 0.4
                    )
                    .opacity(showPodium ? 1 : 0)
                    .offset(y: showPodium ? 0 : 20)
                }
            }
            .padding(.horizontal)
            .onAppear {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                    showPodium = true
                }
            }
        }
    }
}

struct PodiumPlace: View {
    let entry: LeaderboardEntry
    let place: Int
    let height: CGFloat
    let color: Color
    let delay: Double
    
    var body: some View {
        VStack(spacing: 8) {
            // User Avatar
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 60, height: 60)
                .foregroundColor(.gray)
            
            // Name
            Text(entry.user.displayName)
                .font(.caption)
                .lineLimit(1)
                .truncationMode(.tail)
            
            // Score
            Text(formatScore(entry.score))
                .font(.caption2)
                .fontWeight(.bold)
            
            // Podium
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(color)
                    .frame(width: 80, height: height)
                
                Text("\(place)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 20)
            }
        }
        .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(delay), value: height)
    }
    
    private func formatScore(_ score: Double) -> String {
        if score >= 1000 {
            return String(format: "%.1fK", score / 1000)
        }
        return String(format: "%.0f", score)
    }
}

// MARK: - Leaderboard List

struct LeaderboardList: View {
    let entries: [LeaderboardEntry]
    let currentUserId: String
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(entries) { entry in
                LeaderboardRow(
                    entry: entry,
                    isCurrentUser: entry.user.id == currentUserId
                )
            }
        }
        .padding(.horizontal)
    }
}

struct LeaderboardRow: View {
    let entry: LeaderboardEntry
    let isCurrentUser: Bool
    
    var rankColor: Color {
        switch entry.rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2)
        default: return .clear
        }
    }
    
    var body: some View {
        HStack {
            // Rank
            ZStack {
                if entry.rank <= 3 {
                    Circle()
                        .fill(rankColor)
                        .frame(width: 40, height: 40)
                }
                
                Text("\(entry.rank)")
                    .font(.subheadline)
                    .fontWeight(entry.rank <= 3 ? .bold : .medium)
                    .foregroundColor(entry.rank <= 3 ? .white : .primary)
                    .frame(width: 40)
            }
            
            // Avatar
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 40, height: 40)
                .foregroundColor(.gray)
            
            // User Info
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.user.displayName)
                    .font(.subheadline)
                    .fontWeight(isCurrentUser ? .semibold : .regular)
                
                if let subtitle = entry.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Score and Change
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatScore(entry.score))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                if entry.change != 0 {
                    HStack(spacing: 2) {
                        Image(systemName: entry.change > 0 ? "arrow.up" : "arrow.down")
                            .font(.caption2)
                        Text("\(abs(entry.change))")
                            .font(.caption2)
                    }
                    .foregroundColor(entry.change > 0 ? .green : .red)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isCurrentUser ? Color.blue.opacity(0.1) : Color(.systemGray6))
        )
    }
    
    private func formatScore(_ score: Double) -> String {
        if score >= 1000 {
            return String(format: "%.1fK", score / 1000)
        }
        return String(format: "%.0f", score)
    }
}

// MARK: - Invite Friends View

struct InviteFriendsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Invite Code
                VStack(spacing: 16) {
                    Text("Your Invite Code")
                        .font(.headline)
                    
                    Text("MIND123")
                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    
                    Button(action: shareInviteCode) {
                        Label("Share Code", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                .padding()
                
                // Or divider
                HStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 1)
                    Text("OR")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 1)
                }
                .padding(.horizontal)
                
                // Search contacts
                VStack(alignment: .leading, spacing: 12) {
                    Text("Invite from Contacts")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search contacts...", text: $searchText)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .navigationTitle("Invite Friends")
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
    
    private func shareInviteCode() {
        let activityVC = UIActivityViewController(
            activityItems: ["Join me on MindBuddy! Use my invite code: MIND123 https://mindbuddy.health/join"],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
}

#Preview {
    SocialLeaderboardView()
}