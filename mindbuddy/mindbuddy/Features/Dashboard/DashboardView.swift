import SwiftUI
import Charts

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @StateObject private var authManager = AuthManager.shared
    @State private var selectedHealthMetric = HealthMetric.heartRate
    
    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading && viewModel.heartRateData.isEmpty {
                    ProgressView("Loading health data...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
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
                                    
                                    Menu {
                                        Button(action: {
                                            // Navigate to profile
                                        }) {
                                            Label("Profile", systemImage: "person.crop.circle")
                                        }
                                        
                                        Button(action: {
                                            authManager.logout()
                                        }) {
                                            Label("Logout", systemImage: "arrow.right.door.fill")
                                        }
                                    } label: {
                                        Image(systemName: "person.circle")
                                            .font(.title)
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding(.horizontal)
                            }
                            
                            // Token Balance Card
                            TokenBalanceCard(viewModel: viewModel)
                            
                            // Health Chart Section
                            HealthChartSection(viewModel: viewModel, selectedMetric: $selectedHealthMetric)
                            
                            // Health Stats Grid
                            HealthStatsGrid(viewModel: viewModel)
                            
                            // Recent Activity
                            RecentActivityCard(viewModel: viewModel)
                            
                            Spacer()
                        }
                        .padding(.top)
                    }
                    .navigationBarHidden(true)
                    .refreshable {
                        viewModel.refreshData()
                    }
                }
            }
            .alert("Error", isPresented: $viewModel.hasError) {
                Button("OK") {}
            } message: {
                Text(viewModel.errorMessage)
            }
        }
        .onAppear {
            viewModel.loadDashboardData()
        }
    }
}

// MARK: - Token Balance Card

struct TokenBalanceCard: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Token Balance")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(String(format: "%.2f", viewModel.tokenBalance))
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Text("MNDY")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
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
                    Text(String(format: "%.2f", viewModel.pendingRewards))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Total Earned")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.2f", viewModel.tokenBalance + viewModel.pendingRewards))
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

// MARK: - Health Chart Section

struct HealthChartSection: View {
    @ObservedObject var viewModel: DashboardViewModel
    @Binding var selectedMetric: HealthMetric
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Health Trends")
                    .font(.headline)
                
                Spacer()
                
                Picker("Metric", selection: $selectedMetric) {
                    ForEach(HealthMetric.allCases) { metric in
                        Text(metric.displayName).tag(metric)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 200)
            }
            .padding(.horizontal)
            
            if chartData.isEmpty {
                EmptyChartView()
            } else {
                Chart(chartData) { dataPoint in
                    LineMark(
                        x: .value("Time", dataPoint.date),
                        y: .value(selectedMetric.displayName, dataPoint.value)
                    )
                    .foregroundStyle(selectedMetric.color)
                    .interpolationMethod(.catmullRom)
                    
                    AreaMark(
                        x: .value("Time", dataPoint.date),
                        y: .value(selectedMetric.displayName, dataPoint.value)
                    )
                    .foregroundStyle(selectedMetric.color.opacity(0.1))
                    .interpolationMethod(.catmullRom)
                }
                .frame(height: 200)
                .padding(.horizontal)
                .chartYScale(domain: chartYDomain)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                        AxisValueLabel()
                        AxisGridLine()
                    }
                }
            }
            
            // Last updated
            HStack {
                Image(systemName: "clock")
                    .font(.caption)
                Text("Last updated: \(formatLastUpdated(viewModel.lastUpdated))")
                    .font(.caption)
            }
            .foregroundColor(.secondary)
            .padding(.horizontal)
        }
    }
    
    private var chartData: [ChartDataPoint] {
        switch selectedMetric {
        case .heartRate:
            return viewModel.heartRateData
        case .steps:
            return viewModel.stepsData
        case .stress:
            return viewModel.stressData
        }
    }
    
    private var chartYDomain: ClosedRange<Double> {
        switch selectedMetric {
        case .heartRate:
            return 40...120
        case .steps:
            return 0...15000
        case .stress:
            return 0...100
        }
    }
    
    private func formatLastUpdated(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Health Stats Grid

struct HealthStatsGrid: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Health Overview")
                .font(.headline)
                .padding(.horizontal)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                HealthStatCard(
                    title: "Heart Rate",
                    value: viewModel.currentHeartRate != nil ? "\(Int(viewModel.currentHeartRate!)) BPM" : "--",
                    icon: "heart.fill",
                    color: .red,
                    isLoading: viewModel.isLoading
                )
                
                HealthStatCard(
                    title: "Stress Level",
                    value: viewModel.averageStressLevel,
                    icon: "brain.head.profile",
                    color: stressColor(for: viewModel.averageStressLevel),
                    isLoading: viewModel.isLoading
                )
                
                HealthStatCard(
                    title: "Steps",
                    value: "\(viewModel.todaySteps.formatted())",
                    icon: "figure.walk",
                    color: .blue,
                    isLoading: viewModel.isLoading
                )
                
                HealthStatCard(
                    title: "Sleep",
                    value: String(format: "%.1f hrs", viewModel.sleepHours),
                    icon: "bed.double.fill",
                    color: .purple,
                    isLoading: viewModel.isLoading
                )
            }
            .padding(.horizontal)
        }
    }
    
    private func stressColor(for level: String) -> Color {
        switch level {
        case "Low": return .green
        case "Medium": return .orange
        case "High": return .red
        default: return .gray
        }
    }
}

struct HealthStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var isLoading: Bool = false
    
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
                
                if isLoading && value == "--" {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Text(value)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .animation(.easeInOut, value: value)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// MARK: - Recent Activity Card

struct RecentActivityCard: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                if viewModel.recentActivities.isEmpty {
                    EmptyStateView(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "No recent activity",
                        description: "Start tracking your health to earn rewards"
                    )
                    .padding()
                } else {
                    ForEach(viewModel.recentActivities.prefix(3)) { activity in
                        ActivityRow(activity: activity)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct ActivityRow: View {
    let activity: RecentActivity
    
    var body: some View {
        HStack {
            Image(systemName: activity.icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40, height: 40)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(activity.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(formatDate(activity.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("+\(String(format: "%.2f", activity.tokensEarned)) MNDY")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.green)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Supporting Views

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
                .foregroundColor(.primary)
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

struct EmptyChartView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(.systemGray6))
            .frame(height: 200)
            .overlay(
                VStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No data available")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            )
            .padding(.horizontal)
    }
}

// MARK: - Supporting Types

enum HealthMetric: String, CaseIterable, Identifiable {
    case heartRate = "heartRate"
    case steps = "steps"
    case stress = "stress"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .heartRate: return "Heart Rate"
        case .steps: return "Steps"
        case .stress: return "Stress"
        }
    }
    
    var color: Color {
        switch self {
        case .heartRate: return .red
        case .steps: return .blue
        case .stress: return .purple
        }
    }
}

#Preview {
    DashboardView()
}