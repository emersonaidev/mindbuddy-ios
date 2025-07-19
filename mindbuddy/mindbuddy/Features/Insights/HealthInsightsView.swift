import SwiftUI
import Charts

struct HealthInsightsView: View {
    @StateObject private var viewModel = HealthInsightsViewModel()
    @State private var selectedTimeRange = TimeRange.week
    @State private var selectedInsightCategory = InsightCategory.overview
    
    enum TimeRange: String, CaseIterable {
        case day = "Day"
        case week = "Week"
        case month = "Month"
        case year = "Year"
        
        var days: Int {
            switch self {
            case .day: return 1
            case .week: return 7
            case .month: return 30
            case .year: return 365
            }
        }
    }
    
    enum InsightCategory: String, CaseIterable {
        case overview = "Overview"
        case stress = "Stress"
        case activity = "Activity"
        case sleep = "Sleep"
        case heartHealth = "Heart"
        
        var icon: String {
            switch self {
            case .overview: return "chart.line.uptrend.xyaxis"
            case .stress: return "brain.head.profile"
            case .activity: return "figure.walk"
            case .sleep: return "bed.double.fill"
            case .heartHealth: return "heart.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .overview: return .blue
            case .stress: return .purple
            case .activity: return .green
            case .sleep: return .indigo
            case .heartHealth: return .red
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Time Range Picker
                    Picker("Time Range", selection: $selectedTimeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    .onChange(of: selectedTimeRange) { _, newValue in
                        viewModel.loadInsights(for: newValue)
                    }
                    
                    // Category Tabs
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(InsightCategory.allCases, id: \.self) { category in
                                CategoryTab(
                                    category: category,
                                    isSelected: selectedInsightCategory == category,
                                    action: {
                                        withAnimation {
                                            selectedInsightCategory = category
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Content based on selected category
                    switch selectedInsightCategory {
                    case .overview:
                        OverviewInsights(viewModel: viewModel, timeRange: selectedTimeRange)
                    case .stress:
                        StressInsights(viewModel: viewModel, timeRange: selectedTimeRange)
                    case .activity:
                        ActivityInsights(viewModel: viewModel, timeRange: selectedTimeRange)
                    case .sleep:
                        SleepInsights(viewModel: viewModel, timeRange: selectedTimeRange)
                    case .heartHealth:
                        HeartHealthInsights(viewModel: viewModel, timeRange: selectedTimeRange)
                    }
                    
                    Spacer(minLength: 50)
                }
                .padding(.top)
            }
            .navigationTitle("Health Insights")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { viewModel.exportInsights() }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .onAppear {
                viewModel.loadInsights(for: selectedTimeRange)
            }
        }
    }
}

// MARK: - Category Tab

struct CategoryTab: View {
    let category: HealthInsightsView.InsightCategory
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
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? category.color : Color(.systemGray6))
            )
        }
    }
}

// MARK: - Overview Insights

struct OverviewInsights: View {
    @ObservedObject var viewModel: HealthInsightsViewModel
    let timeRange: HealthInsightsView.TimeRange
    
    var body: some View {
        VStack(spacing: 20) {
            // Health Score
            HealthScoreCard(score: viewModel.healthScore)
            
            // Key Metrics Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                MetricCard(
                    title: "Avg Heart Rate",
                    value: "\(Int(viewModel.averageHeartRate))",
                    unit: "BPM",
                    trend: viewModel.heartRateTrend,
                    icon: "heart.fill",
                    color: .red
                )
                
                MetricCard(
                    title: "Stress Level",
                    value: viewModel.averageStressLevel,
                    unit: "",
                    trend: viewModel.stressTrend,
                    icon: "brain.head.profile",
                    color: .purple
                )
                
                MetricCard(
                    title: "Daily Steps",
                    value: "\(viewModel.averageSteps.formatted())",
                    unit: "",
                    trend: viewModel.stepsTrend,
                    icon: "figure.walk",
                    color: .green
                )
                
                MetricCard(
                    title: "Sleep Quality",
                    value: "\(Int(viewModel.sleepQuality))%",
                    unit: "",
                    trend: viewModel.sleepTrend,
                    icon: "bed.double.fill",
                    color: .indigo
                )
            }
            .padding(.horizontal)
            
            // Recommendations
            RecommendationsSection(recommendations: viewModel.recommendations)
        }
    }
}

// MARK: - Stress Insights

struct StressInsights: View {
    @ObservedObject var viewModel: HealthInsightsViewModel
    let timeRange: HealthInsightsView.TimeRange
    
    var body: some View {
        VStack(spacing: 20) {
            // Stress Patterns Chart
            StressPatternsChart(data: viewModel.stressPatterns)
            
            // Stress Triggers
            StressTriggersSection(triggers: viewModel.stressTriggers)
            
            // Stress Management Tips
            StressManagementTips(tips: viewModel.stressManagementTips)
        }
    }
}

// MARK: - Activity Insights

struct ActivityInsights: View {
    @ObservedObject var viewModel: HealthInsightsViewModel
    let timeRange: HealthInsightsView.TimeRange
    
    var body: some View {
        VStack(spacing: 20) {
            // Activity Trends Chart
            ActivityTrendsChart(data: viewModel.activityTrends)
            
            // Activity Goals Progress
            ActivityGoalsProgress(goals: viewModel.activityGoals)
            
            // Activity Recommendations
            ActivityRecommendations(recommendations: viewModel.activityRecommendations)
        }
    }
}

// MARK: - Sleep Insights

struct SleepInsights: View {
    @ObservedObject var viewModel: HealthInsightsViewModel
    let timeRange: HealthInsightsView.TimeRange
    
    var body: some View {
        VStack(spacing: 20) {
            // Sleep Patterns Chart
            SleepPatternsChart(data: viewModel.sleepPatterns)
            
            // Sleep Stats
            SleepStatsGrid(stats: viewModel.sleepStats)
            
            // Sleep Improvement Tips
            SleepImprovementTips(tips: viewModel.sleepTips)
        }
    }
}

// MARK: - Heart Health Insights

struct HeartHealthInsights: View {
    @ObservedObject var viewModel: HealthInsightsViewModel
    let timeRange: HealthInsightsView.TimeRange
    
    var body: some View {
        VStack(spacing: 20) {
            // Heart Rate Zones Chart
            HeartRateZonesChart(data: viewModel.heartRateZones)
            
            // HRV Trends
            HRVTrendsSection(trends: viewModel.hrvTrends)
            
            // Heart Health Tips
            HeartHealthTips(tips: viewModel.heartHealthTips)
        }
    }
}

// MARK: - Supporting Components

struct HealthScoreCard: View {
    let score: Int
    
    var scoreColor: Color {
        if score >= 80 { return .green }
        else if score >= 60 { return .orange }
        else { return .red }
    }
    
    var scoreDescription: String {
        if score >= 80 { return "Excellent" }
        else if score >= 60 { return "Good" }
        else { return "Needs Attention" }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Overall Health Score")
                .font(.headline)
            
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                    .frame(width: 150, height: 150)
                
                Circle()
                    .trim(from: 0, to: CGFloat(score) / 100)
                    .stroke(scoreColor, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .frame(width: 150, height: 150)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(), value: score)
                
                VStack {
                    Text("\(score)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                    Text(scoreDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(20)
        .padding(.horizontal)
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let unit: String
    let trend: Double
    let icon: String
    let color: Color
    
    var trendIcon: String {
        if trend > 0 { return "arrow.up.right" }
        else if trend < 0 { return "arrow.down.right" }
        else { return "minus" }
    }
    
    var trendColor: Color {
        if trend > 0 { return .green }
        else if trend < 0 { return .red }
        else { return .gray }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                Spacer()
                
                HStack(spacing: 2) {
                    Image(systemName: trendIcon)
                        .font(.caption)
                    Text("\(abs(Int(trend)))%")
                        .font(.caption)
                }
                .foregroundColor(trendColor)
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct RecommendationsSection: View {
    let recommendations: [HealthRecommendation]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Personalized Recommendations")
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(recommendations) { recommendation in
                RecommendationRow(recommendation: recommendation)
            }
        }
    }
}

struct RecommendationRow: View {
    let recommendation: HealthRecommendation
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: recommendation.icon)
                .font(.title3)
                .foregroundColor(recommendation.priority.color)
                .frame(width: 40, height: 40)
                .background(recommendation.priority.color.opacity(0.1))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(recommendation.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(recommendation.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Chart Components (Simplified)

struct StressPatternsChart: View {
    let data: [StressDataPoint]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Stress Patterns")
                .font(.headline)
                .padding(.horizontal)
            
            if !data.isEmpty {
                Chart(data) { point in
                    LineMark(
                        x: .value("Time", point.date),
                        y: .value("Stress Level", point.level)
                    )
                    .foregroundStyle(Color.purple)
                    .interpolationMethod(.catmullRom)
                    
                    AreaMark(
                        x: .value("Time", point.date),
                        y: .value("Stress Level", point.level)
                    )
                    .foregroundStyle(Color.purple.opacity(0.1))
                    .interpolationMethod(.catmullRom)
                }
                .frame(height: 200)
                .padding(.horizontal)
            } else {
                Text("No stress data available")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

// Placeholder charts for other sections
struct ActivityTrendsChart: View {
    let data: [ActivityDataPoint]
    var body: some View {
        Text("Activity Trends Chart")
            .frame(height: 200)
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray6))
            .padding(.horizontal)
    }
}

struct SleepPatternsChart: View {
    let data: [SleepDataPoint]
    var body: some View {
        Text("Sleep Patterns Chart")
            .frame(height: 200)
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray6))
            .padding(.horizontal)
    }
}

struct HeartRateZonesChart: View {
    let data: [HeartRateZoneData]
    var body: some View {
        Text("Heart Rate Zones Chart")
            .frame(height: 200)
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray6))
            .padding(.horizontal)
    }
}

// Additional support sections
struct StressTriggersSection: View {
    let triggers: [StressTrigger]
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Common Stress Triggers")
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(triggers) { trigger in
                Text("• \(trigger.name): \(trigger.frequency)")
                    .font(.subheadline)
                    .padding(.horizontal)
            }
        }
    }
}

struct StressManagementTips: View {
    let tips: [String]
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Stress Management Tips")
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(tips, id: \.self) { tip in
                Text("• \(tip)")
                    .font(.subheadline)
                    .padding(.horizontal)
            }
        }
    }
}

struct ActivityGoalsProgress: View {
    let goals: [ActivityGoal]
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activity Goals")
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(goals) { goal in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(goal.name)
                            .font(.subheadline)
                        Spacer()
                        Text("\(Int(goal.progress * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    ProgressView(value: goal.progress)
                        .tint(goal.progress >= 1.0 ? .green : .blue)
                }
                .padding(.horizontal)
            }
        }
    }
}

struct ActivityRecommendations: View {
    let recommendations: [String]
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activity Recommendations")
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(recommendations, id: \.self) { recommendation in
                Text("• \(recommendation)")
                    .font(.subheadline)
                    .padding(.horizontal)
            }
        }
    }
}

struct SleepStatsGrid: View {
    let stats: SleepStats
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
            StatCard(title: "Avg Duration", value: "\(stats.averageDuration) hrs")
            StatCard(title: "Deep Sleep", value: "\(stats.deepSleepPercentage)%")
            StatCard(title: "Sleep Efficiency", value: "\(stats.efficiency)%")
            StatCard(title: "Consistency", value: "\(stats.consistency)%")
        }
        .padding(.horizontal)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct SleepImprovementTips: View {
    let tips: [String]
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sleep Improvement Tips")
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(tips, id: \.self) { tip in
                Text("• \(tip)")
                    .font(.subheadline)
                    .padding(.horizontal)
            }
        }
    }
}

struct HRVTrendsSection: View {
    let trends: HRVTrends
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("HRV Trends")
                .font(.headline)
                .padding(.horizontal)
            
            HStack(spacing: 20) {
                VStack {
                    Text("Current")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(trends.current) ms")
                        .font(.headline)
                }
                
                VStack {
                    Text("7-Day Avg")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(trends.weekAverage) ms")
                        .font(.headline)
                }
                
                VStack {
                    Text("Trend")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HStack(spacing: 2) {
                        Image(systemName: trends.trend > 0 ? "arrow.up" : "arrow.down")
                        Text("\(abs(trends.trend))%")
                    }
                    .font(.headline)
                    .foregroundColor(trends.trend > 0 ? .green : .red)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
}

struct HeartHealthTips: View {
    let tips: [String]
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Heart Health Tips")
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(tips, id: \.self) { tip in
                Text("• \(tip)")
                    .font(.subheadline)
                    .padding(.horizontal)
            }
        }
    }
}

#Preview {
    HealthInsightsView()
}