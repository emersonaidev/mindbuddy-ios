import SwiftUI
import Combine
import HealthKit

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var hasError = false
    @Published var errorMessage = ""
    
    // Health Data
    @Published var currentHeartRate: Double?
    @Published var averageStressLevel: String = "Low"
    @Published var todaySteps: Int = 0
    @Published var sleepHours: Double = 0.0
    @Published var lastUpdated = Date()
    
    // Token Data
    @Published var tokenBalance: Double = 0.0
    @Published var pendingRewards: Double = 0.0
    @Published var recentActivities: [RecentActivity] = []
    
    // Chart Data
    @Published var heartRateData: [ChartDataPoint] = []
    @Published var stepsData: [ChartDataPoint] = []
    @Published var stressData: [ChartDataPoint] = []
    
    private let healthManager: HealthServiceProtocol
    private let rewardsManager: RewardsServiceProtocol
    private let authManager: AuthServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(
        healthManager: HealthServiceProtocol = DependencyContainer.shared.healthManager,
        rewardsManager: RewardsServiceProtocol = DependencyContainer.shared.rewardsManager,
        authManager: AuthServiceProtocol = DependencyContainer.shared.authManager
    ) {
        self.healthManager = healthManager
        self.rewardsManager = rewardsManager
        self.authManager = authManager
        
        setupSubscriptions()
    }
    
    private func setupSubscriptions() {
        // Subscribe to rewards updates
        rewardsManager.balancePublisher
            .receive(on: DispatchQueue.main)
            .assign(to: &$tokenBalance)
        
        rewardsManager.pendingRewardsPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: &$pendingRewards)
        
        rewardsManager.recentActivitiesPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: &$recentActivities)
    }
    
    func loadDashboardData() {
        Task {
            await fetchAllData()
        }
    }
    
    private func fetchAllData() async {
        isLoading = true
        hasError = false
        
        do {
            // Check HealthKit authorization first
            if !healthManager.isAuthorized {
                try await healthManager.requestHealthKitPermissions()
            }
            
            // Fetch data in parallel
            async let heartRateTask = fetchHeartRateData()
            async let stepsTask = fetchStepsData()
            async let sleepTask = fetchSleepData()
            async let rewardsTask = fetchRewardsData()
            
            // Wait for all tasks
            let _ = await (heartRateTask, stepsTask, sleepTask, rewardsTask)
            
            // Calculate stress level based on HRV data
            await calculateStressLevel()
            
            lastUpdated = Date()
            isLoading = false
        } catch {
            await MainActor.run {
                hasError = true
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
    
    private func fetchHeartRateData() async {
        do {
            let endDate = Date()
            let startDate = Calendar.current.date(byAdding: .hour, value: -24, to: endDate)!
            
            let heartRateData = try await healthManager.fetchHeartRateData(from: startDate, to: endDate)
            
            // Update current heart rate
            if let latestReading = heartRateData.first {
                await MainActor.run {
                    if case .double(let value) = latestReading.value {
                        self.currentHeartRate = value
                    }
                }
            }
            
            // Update chart data
            let chartData = heartRateData.prefix(50).map { data -> ChartDataPoint in
                let value = {
                    switch data.value {
                    case .double(let v): return v
                    case .integer(let v): return Double(v)
                    default: return 0
                    }
                }()
                return ChartDataPoint(date: data.recordedAt, value: value)
            }
            
            await MainActor.run {
                self.heartRateData = chartData
            }
        } catch {
            print("Error fetching heart rate: \(error)")
        }
    }
    
    private func fetchStepsData() async {
        do {
            let endDate = Date()
            let startDate = Calendar.current.startOfDay(for: endDate)
            
            let stepsData = try await healthManager.fetchStepsData(from: startDate, to: endDate)
            
            // Calculate total steps for today
            let totalSteps = stepsData.reduce(0) { total, data in
                switch data.value {
                case .integer(let steps): return total + steps
                case .double(let steps): return total + Int(steps)
                default: return total
                }
            }
            
            await MainActor.run {
                self.todaySteps = totalSteps
            }
            
            // Get steps for last 7 days for chart
            let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: endDate)!
            let weeklySteps = try await healthManager.fetchStepsData(from: weekAgo, to: endDate)
            
            // Group by day
            let grouped = Dictionary(grouping: weeklySteps) { data in
                Calendar.current.startOfDay(for: data.recordedAt)
            }
            
            let chartData = grouped.map { (date, dataPoints) -> ChartDataPoint in
                let total = dataPoints.reduce(0) { sum, data in
                    switch data.value {
                    case .integer(let steps): return sum + Double(steps)
                    case .double(let steps): return sum + steps
                    default: return sum
                    }
                }
                return ChartDataPoint(date: date, value: total)
            }.sorted { $0.date < $1.date }
            
            await MainActor.run {
                self.stepsData = chartData
            }
        } catch {
            print("Error fetching steps: \(error)")
        }
    }
    
    private func fetchSleepData() async {
        do {
            let endDate = Date()
            let startDate = Calendar.current.date(byAdding: .day, value: -1, to: endDate)!
            
            let sleepData = try await healthManager.fetchSleepData(from: startDate, to: endDate)
            
            // Calculate total sleep hours
            let totalHours = sleepData.reduce(0) { total, data in
                switch data.value {
                case .double(let hours): return total + hours
                default: return total
                }
            }
            
            await MainActor.run {
                self.sleepHours = totalHours
            }
        } catch {
            print("Error fetching sleep data: \(error)")
        }
    }
    
    private func fetchRewardsData() async {
        do {
            try await rewardsManager.fetchTokenBalance()
            try await rewardsManager.fetchRecentActivities()
        } catch {
            print("Error fetching rewards: \(error)")
        }
    }
    
    private func calculateStressLevel() async {
        do {
            let endDate = Date()
            let startDate = Calendar.current.date(byAdding: .hour, value: -6, to: endDate)!
            
            let hrvData = try await healthManager.fetchHRVData(from: startDate, to: endDate)
            
            guard !hrvData.isEmpty else { return }
            
            // Calculate average HRV
            let totalHRV = hrvData.reduce(0) { sum, data in
                switch data.value {
                case .double(let hrv): return sum + hrv
                default: return sum
                }
            }
            
            let averageHRV = totalHRV / Double(hrvData.count)
            
            // Simple stress calculation based on HRV
            let stressLevel: String
            if averageHRV > 60 {
                stressLevel = "Low"
            } else if averageHRV > 40 {
                stressLevel = "Medium"
            } else {
                stressLevel = "High"
            }
            
            await MainActor.run {
                self.averageStressLevel = stressLevel
            }
            
            // Create stress chart data
            let stressChartData = hrvData.prefix(20).map { data -> ChartDataPoint in
                let hrv = {
                    switch data.value {
                    case .double(let v): return v
                    default: return 0
                    }
                }()
                // Convert HRV to stress score (inverse relationship)
                let stressScore = max(0, min(100, 100 - (hrv / 100 * 100)))
                return ChartDataPoint(date: data.recordedAt, value: stressScore)
            }
            
            await MainActor.run {
                self.stressData = stressChartData
            }
        } catch {
            print("Error calculating stress level: \(error)")
        }
    }
    
    func refreshData() {
        Task {
            await fetchAllData()
        }
    }
}

// MARK: - Supporting Types

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct RecentActivity: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let tokensEarned: Double
    let timestamp: Date
    let icon: String
}