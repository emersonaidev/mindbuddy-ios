import SwiftUI
import Combine
import HealthKit

@MainActor
class HealthInsightsViewModel: ObservableObject {
    // Overview metrics
    @Published var healthScore: Int = 0
    @Published var averageHeartRate: Double = 0
    @Published var averageStressLevel: String = "Low"
    @Published var averageSteps: Int = 0
    @Published var sleepQuality: Double = 0
    
    // Trends
    @Published var heartRateTrend: Double = 0
    @Published var stressTrend: Double = 0
    @Published var stepsTrend: Double = 0
    @Published var sleepTrend: Double = 0
    
    // Recommendations
    @Published var recommendations: [HealthRecommendation] = []
    
    // Stress insights
    @Published var stressPatterns: [StressDataPoint] = []
    @Published var stressTriggers: [StressTrigger] = []
    @Published var stressManagementTips: [String] = []
    
    // Activity insights
    @Published var activityTrends: [ActivityDataPoint] = []
    @Published var activityGoals: [ActivityGoal] = []
    @Published var activityRecommendations: [String] = []
    
    // Sleep insights
    @Published var sleepPatterns: [SleepDataPoint] = []
    @Published var sleepStats = SleepStats()
    @Published var sleepTips: [String] = []
    
    // Heart health insights
    @Published var heartRateZones: [HeartRateZoneData] = []
    @Published var hrvTrends = HRVTrends()
    @Published var heartHealthTips: [String] = []
    
    private let healthManager: HealthServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(healthManager: HealthServiceProtocol = DependencyContainer.shared.healthService) {
        self.healthManager = healthManager
    }
    
    func loadInsights(for timeRange: HealthInsightsView.TimeRange) {
        Task {
            let endDate = Date()
            let startDate = Calendar.current.date(byAdding: .day, value: -timeRange.days, to: endDate)!
            
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await self.loadOverviewMetrics(from: startDate, to: endDate) }
                group.addTask { await self.loadStressInsights(from: startDate, to: endDate) }
                group.addTask { await self.loadActivityInsights(from: startDate, to: endDate) }
                group.addTask { await self.loadSleepInsights(from: startDate, to: endDate) }
                group.addTask { await self.loadHeartHealthInsights(from: startDate, to: endDate) }
            }
            
            generateRecommendations()
            calculateHealthScore()
        }
    }
    
    private func loadOverviewMetrics(from startDate: Date, to endDate: Date) async {
        do {
            // Load heart rate
            let heartRateData = try await healthManager.fetchHeartRateData(from: startDate, to: endDate)
            let avgHR = calculateAverage(from: heartRateData)
            await MainActor.run {
                self.averageHeartRate = avgHR
                self.heartRateTrend = calculateTrend(current: avgHR, baseline: 70)
            }
            
            // Load steps
            let stepsData = try await healthManager.fetchStepsData(from: startDate, to: endDate)
            let totalSteps = sumSteps(from: stepsData)
            let avgSteps = totalSteps / max(1, Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 1)
            await MainActor.run {
                self.averageSteps = avgSteps
                self.stepsTrend = calculateTrend(current: Double(avgSteps), baseline: 10000)
            }
            
            // Load stress (from HRV)
            let hrvData = try await healthManager.fetchHRVData(from: startDate, to: endDate)
            let stressLevel = calculateStressLevel(from: hrvData)
            await MainActor.run {
                self.averageStressLevel = stressLevel.level
                self.stressTrend = stressLevel.trend
            }
            
            // Load sleep
            let sleepData = try await healthManager.fetchSleepData(from: startDate, to: endDate)
            let quality = calculateSleepQuality(from: sleepData)
            await MainActor.run {
                self.sleepQuality = quality
                self.sleepTrend = calculateTrend(current: quality, baseline: 80)
            }
        } catch {
            print("Error loading overview metrics: \(error)")
        }
    }
    
    private func loadStressInsights(from startDate: Date, to endDate: Date) async {
        do {
            let hrvData = try await healthManager.fetchHRVData(from: startDate, to: endDate)
            
            // Create stress patterns
            let patterns = hrvData.prefix(100).map { data -> StressDataPoint in
                let hrv = extractDouble(from: data.value)
                let stressLevel = max(0, min(100, 100 - (hrv / 100 * 100)))
                return StressDataPoint(date: data.recordedAt, level: stressLevel)
            }
            
            // Identify triggers (simplified)
            let triggers = [
                StressTrigger(name: "Work Hours", frequency: "Weekdays 2-4 PM"),
                StressTrigger(name: "Low Activity", frequency: "When steps < 5000"),
                StressTrigger(name: "Poor Sleep", frequency: "After < 6 hours sleep")
            ]
            
            // Generate tips
            let tips = [
                "Take 5-minute breathing breaks every hour",
                "Try a 10-minute walk when stress levels rise",
                "Practice mindfulness meditation before bed",
                "Maintain consistent sleep schedule"
            ]
            
            await MainActor.run {
                self.stressPatterns = patterns
                self.stressTriggers = triggers
                self.stressManagementTips = tips
            }
        } catch {
            print("Error loading stress insights: \(error)")
        }
    }
    
    private func loadActivityInsights(from startDate: Date, to endDate: Date) async {
        do {
            let stepsData = try await healthManager.fetchStepsData(from: startDate, to: endDate)
            
            // Create activity trends
            let grouped = Dictionary(grouping: stepsData) { data in
                Calendar.current.startOfDay(for: data.recordedAt)
            }
            
            let trends = grouped.map { (date, dataPoints) -> ActivityDataPoint in
                let totalSteps = dataPoints.reduce(0) { sum, data in
                    sum + extractInt(from: data.value)
                }
                return ActivityDataPoint(date: date, steps: totalSteps, calories: Double(totalSteps) * 0.04)
            }.sorted { $0.date < $1.date }
            
            // Create goals
            let goals = [
                ActivityGoal(name: "Daily Steps", target: 10000, current: Double(averageSteps), progress: Double(averageSteps) / 10000),
                ActivityGoal(name: "Active Hours", target: 12, current: 8, progress: 8/12),
                ActivityGoal(name: "Weekly Workouts", target: 5, current: 3, progress: 3/5)
            ]
            
            // Generate recommendations
            let recommendations = [
                "Increase daily steps by 500 to reach your goal",
                "Add a 20-minute walk after lunch",
                "Try taking stairs instead of elevators",
                "Schedule regular movement breaks"
            ]
            
            await MainActor.run {
                self.activityTrends = trends
                self.activityGoals = goals
                self.activityRecommendations = recommendations
            }
        } catch {
            print("Error loading activity insights: \(error)")
        }
    }
    
    private func loadSleepInsights(from startDate: Date, to endDate: Date) async {
        do {
            let sleepData = try await healthManager.fetchSleepData(from: startDate, to: endDate)
            
            // Create sleep patterns
            let patterns = sleepData.map { data -> SleepDataPoint in
                let hours = extractDouble(from: data.value)
                return SleepDataPoint(date: data.recordedAt, duration: hours, quality: min(100, hours * 12.5))
            }
            
            // Calculate stats
            let avgDuration = patterns.isEmpty ? 0 : patterns.reduce(0) { $0 + $1.duration } / Double(patterns.count)
            let stats = SleepStats(
                averageDuration: avgDuration,
                deepSleepPercentage: 25,
                efficiency: 85,
                consistency: 75
            )
            
            // Generate tips
            let tips = [
                "Maintain a consistent bedtime routine",
                "Avoid screens 1 hour before bed",
                "Keep bedroom temperature between 60-67°F",
                "Limit caffeine after 2 PM"
            ]
            
            await MainActor.run {
                self.sleepPatterns = patterns
                self.sleepStats = stats
                self.sleepTips = tips
            }
        } catch {
            print("Error loading sleep insights: \(error)")
        }
    }
    
    private func loadHeartHealthInsights(from startDate: Date, to endDate: Date) async {
        do {
            let heartRateData = try await healthManager.fetchHeartRateData(from: startDate, to: endDate)
            let hrvData = try await healthManager.fetchHRVData(from: startDate, to: endDate)
            
            // Calculate heart rate zones
            let zones = calculateHeartRateZones(from: heartRateData)
            
            // Calculate HRV trends
            let currentHRV = hrvData.first.map { extractDouble(from: $0.value) } ?? 0
            let avgHRV = calculateAverage(from: hrvData)
            let trend = HRVTrends(
                current: Int(currentHRV),
                weekAverage: Int(avgHRV),
                trend: calculateTrend(current: currentHRV, baseline: avgHRV)
            )
            
            // Generate tips
            let tips = [
                "Aim for 150 minutes of moderate exercise weekly",
                "Include both cardio and strength training",
                "Monitor resting heart rate trends",
                "Practice stress-reduction techniques for better HRV"
            ]
            
            await MainActor.run {
                self.heartRateZones = zones
                self.hrvTrends = trend
                self.heartHealthTips = tips
            }
        } catch {
            print("Error loading heart health insights: \(error)")
        }
    }
    
    private func generateRecommendations() {
        var recommendations: [HealthRecommendation] = []
        
        // Stress recommendation
        if averageStressLevel == "High" {
            recommendations.append(HealthRecommendation(
                title: "Reduce Stress Levels",
                description: "Your stress levels have been elevated. Try meditation or breathing exercises.",
                icon: "brain.head.profile",
                priority: .high
            ))
        }
        
        // Activity recommendation
        if averageSteps < 7000 {
            recommendations.append(HealthRecommendation(
                title: "Increase Daily Activity",
                description: "You're averaging \(averageSteps) steps. Aim for at least 10,000 daily.",
                icon: "figure.walk",
                priority: .medium
            ))
        }
        
        // Sleep recommendation
        if sleepQuality < 70 {
            recommendations.append(HealthRecommendation(
                title: "Improve Sleep Quality",
                description: "Your sleep quality is below optimal. Consider a consistent bedtime routine.",
                icon: "bed.double.fill",
                priority: .high
            ))
        }
        
        // Heart health recommendation
        if averageHeartRate > 80 {
            recommendations.append(HealthRecommendation(
                title: "Monitor Heart Health",
                description: "Your resting heart rate is elevated. Consider cardiovascular exercise.",
                icon: "heart.fill",
                priority: .medium
            ))
        }
        
        self.recommendations = recommendations.sorted { $0.priority.rawValue > $1.priority.rawValue }
    }
    
    private func calculateHealthScore() {
        var score = 100
        
        // Deduct points based on metrics
        if averageStressLevel == "High" { score -= 20 }
        else if averageStressLevel == "Medium" { score -= 10 }
        
        if averageSteps < 5000 { score -= 20 }
        else if averageSteps < 10000 { score -= 10 }
        
        if sleepQuality < 60 { score -= 20 }
        else if sleepQuality < 80 { score -= 10 }
        
        if averageHeartRate > 90 { score -= 15 }
        else if averageHeartRate > 80 { score -= 5 }
        
        self.healthScore = max(0, score)
    }
    
    func exportInsights() {
        // Export functionality would be implemented here
        print("Exporting insights...")
    }
    
    // MARK: - Helper Methods
    
    private func calculateAverage(from data: [HealthData]) -> Double {
        guard !data.isEmpty else { return 0 }
        let sum = data.reduce(0) { $0 + extractDouble(from: $1.value) }
        return sum / Double(data.count)
    }
    
    private func sumSteps(from data: [HealthData]) -> Int {
        data.reduce(0) { $0 + extractInt(from: $1.value) }
    }
    
    private func extractDouble(from value: HealthDataValue) -> Double {
        switch value {
        case .number(let val):
            return val
        default:
            return 0
        }
    }
    
    private func extractInt(from value: HealthDataValue) -> Int {
        switch value {
        case .number(let val):
            return Int(val)
        default:
            return 0
        }
    }
    
    private func calculateTrend(current: Double, baseline: Double) -> Double {
        guard baseline > 0 else { return 0 }
        return ((current - baseline) / baseline) * 100
    }
    
    private func calculateStressLevel(from hrvData: [HealthData]) -> (level: String, trend: Double) {
        let avgHRV = calculateAverage(from: hrvData)
        let level: String
        if avgHRV > 60 { level = "Low" }
        else if avgHRV > 40 { level = "Medium" }
        else { level = "High" }
        
        let trend = calculateTrend(current: avgHRV, baseline: 50)
        return (level, -trend) // Negative because higher HRV = lower stress
    }
    
    private func calculateSleepQuality(from sleepData: [HealthData]) -> Double {
        let avgHours = calculateAverage(from: sleepData)
        // Simple quality calculation based on duration
        if avgHours >= 7 && avgHours <= 9 { return 90 }
        else if avgHours >= 6 && avgHours <= 10 { return 70 }
        else { return 50 }
    }
    
    private func calculateHeartRateZones(from data: [HealthData]) -> [HeartRateZoneData] {
        // Simplified zone calculation
        return [
            HeartRateZoneData(zone: "Resting", percentage: 60, minutes: 1000),
            HeartRateZoneData(zone: "Fat Burn", percentage: 25, minutes: 180),
            HeartRateZoneData(zone: "Cardio", percentage: 10, minutes: 60),
            HeartRateZoneData(zone: "Peak", percentage: 5, minutes: 30)
        ]
    }
}

// MARK: - Supporting Types

struct HealthRecommendation: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let priority: Priority
    
    enum Priority: Int {
        case low = 1
        case medium = 2
        case high = 3
        
        var color: Color {
            switch self {
            case .low: return .blue
            case .medium: return .orange
            case .high: return .red
            }
        }
    }
}

struct StressDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let level: Double
}

struct StressTrigger: Identifiable {
    let id = UUID()
    let name: String
    let frequency: String
}

struct ActivityDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let steps: Int
    let calories: Double
}

struct ActivityGoal: Identifiable {
    let id = UUID()
    let name: String
    let target: Double
    let current: Double
    let progress: Double
}

struct SleepDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let duration: Double
    let quality: Double
}

struct SleepStats {
    var averageDuration: Double = 0
    var deepSleepPercentage: Int = 0
    var efficiency: Int = 0
    var consistency: Int = 0
}

struct HeartRateZoneData: Identifiable {
    let id = UUID()
    let zone: String
    let percentage: Double
    let minutes: Int
}

struct HRVTrends {
    var current: Int = 0
    var weekAverage: Int = 0
    var trend: Double = 0
}