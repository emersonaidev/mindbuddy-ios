import SwiftUI
import Combine
import HealthKit

@MainActor
class HealthViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var hasError = false
    @Published var errorMessage = ""
    @Published var authorizationStatus: HKAuthorizationStatus = .notDetermined
    @Published var isSubmitting = false
    @Published var submissionResult: SubmissionResult?
    
    // Available data types
    @Published var availableDataTypes: [HealthDataTypeInfo] = []
    @Published var selectedDataTypes: Set<HealthDataType> = []
    
    // Collected data
    @Published var collectedData: [HealthData] = []
    @Published var lastSubmissionDate: Date?
    
    private let healthManager: HealthServiceProtocol
    private let authManager: AuthServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(
        healthManager: HealthServiceProtocol = DependencyContainer.shared.healthManager,
        authManager: AuthServiceProtocol = DependencyContainer.shared.authManager
    ) {
        self.healthManager = healthManager
        self.authManager = authManager
        
        setupAvailableDataTypes()
        checkAuthorizationStatus()
    }
    
    private func setupAvailableDataTypes() {
        availableDataTypes = [
            HealthDataTypeInfo(
                type: .heartRate,
                title: "Heart Rate",
                description: "Monitor your heart health",
                icon: "heart.fill",
                color: .red,
                isAvailable: true
            ),
            HealthDataTypeInfo(
                type: .hrv,
                title: "Heart Rate Variability",
                description: "Track stress and recovery",
                icon: "waveform.path.ecg",
                color: .purple,
                isAvailable: true
            ),
            HealthDataTypeInfo(
                type: .steps,
                title: "Steps",
                description: "Count your daily activity",
                icon: "figure.walk",
                color: .green,
                isAvailable: true
            ),
            HealthDataTypeInfo(
                type: .sleep,
                title: "Sleep",
                description: "Analyze your rest patterns",
                icon: "bed.double.fill",
                color: .blue,
                isAvailable: true
            ),
            HealthDataTypeInfo(
                type: .bloodPressure,
                title: "Blood Pressure",
                description: "Track cardiovascular health",
                icon: "heart.text.square",
                color: .orange,
                isAvailable: true
            ),
            HealthDataTypeInfo(
                type: .calories,
                title: "Active Calories",
                description: "Monitor energy burned",
                icon: "flame.fill",
                color: .orange,
                isAvailable: true
            )
        ]
        
        // Select first 4 by default
        selectedDataTypes = Set(availableDataTypes.prefix(4).map { $0.type })
    }
    
    func checkAuthorizationStatus() {
        guard HKHealthStore.isHealthDataAvailable() else {
            authorizationStatus = .notDetermined
            return
        }
        
        // Check status for heart rate as a proxy
        let healthStore = HKHealthStore()
        if let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) {
            authorizationStatus = healthStore.authorizationStatus(for: heartRateType)
        }
    }
    
    func requestHealthKitAccess() async {
        isLoading = true
        hasError = false
        
        do {
            try await healthManager.requestHealthKitPermissions()
            checkAuthorizationStatus()
            
            // If authorized, start collecting data
            if authorizationStatus == .sharingAuthorized {
                await collectHealthData()
            }
        } catch {
            await MainActor.run {
                hasError = true
                errorMessage = "Failed to request HealthKit access: \(error.localizedDescription)"
            }
        }
        
        isLoading = false
    }
    
    func collectHealthData() async {
        isLoading = true
        collectedData.removeAll()
        
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .hour, value: -24, to: endDate)!
        
        // Collect data for each selected type
        for dataType in selectedDataTypes {
            do {
                let data: [HealthData]
                
                switch dataType {
                case .heartRate:
                    data = try await healthManager.fetchHeartRateData(from: startDate, to: endDate)
                case .hrv:
                    data = try await healthManager.fetchHRVData(from: startDate, to: endDate)
                case .steps:
                    let stepsEndDate = Date()
                    let stepsStartDate = Calendar.current.startOfDay(for: stepsEndDate)
                    data = try await healthManager.fetchStepsData(from: stepsStartDate, to: stepsEndDate)
                case .sleep:
                    let sleepEndDate = Date()
                    let sleepStartDate = Calendar.current.date(byAdding: .day, value: -1, to: sleepEndDate)!
                    data = try await healthManager.fetchSleepData(from: sleepStartDate, to: sleepEndDate)
                case .bloodPressure:
                    data = try await healthManager.fetchBloodPressureData(from: startDate, to: endDate)
                default:
                    data = []
                }
                
                await MainActor.run {
                    collectedData.append(contentsOf: data)
                }
            } catch {
                print("Error collecting \(dataType.rawValue) data: \(error)")
            }
        }
        
        isLoading = false
    }
    
    func submitHealthData() async {
        guard !collectedData.isEmpty else {
            submissionResult = SubmissionResult(
                success: false,
                message: "No data to submit. Please collect data first.",
                tokensEarned: 0
            )
            return
        }
        
        isSubmitting = true
        submissionResult = nil
        
        do {
            // Submit to backend
            try await healthManager.submitHealthDataBatch(collectedData)
            
            let tokensEarned = calculateTokensEarned(for: collectedData)
            
            await MainActor.run {
                self.submissionResult = SubmissionResult(
                    success: true,
                    message: "Successfully submitted \(collectedData.count) health data points!",
                    tokensEarned: tokensEarned
                )
                self.lastSubmissionDate = Date()
                self.collectedData.removeAll()
            }
        } catch {
            await MainActor.run {
                self.submissionResult = SubmissionResult(
                    success: false,
                    message: "Failed to submit data: \(error.localizedDescription)",
                    tokensEarned: 0
                )
            }
        }
        
        isSubmitting = false
    }
    
    private func calculateTokensEarned(for data: [HealthData]) -> Double {
        // Token rewards per data type (simplified calculation)
        let rewards: [String: Double] = [
            "heartRate": 0.1,
            "hrv": 0.15,
            "steps": 0.05,
            "sleep": 1.0,
            "bloodPressure": 0.2,
            "calories": 0.05
        ]
        
        return data.reduce(0) { total, healthData in
            total + (rewards[healthData.type] ?? 0.1)
        }
    }
    
    func toggleDataType(_ type: HealthDataType) {
        if selectedDataTypes.contains(type) {
            selectedDataTypes.remove(type)
        } else {
            selectedDataTypes.insert(type)
        }
    }
    
    func refreshData() async {
        if authorizationStatus == .sharingAuthorized {
            await collectHealthData()
        }
    }
}

// MARK: - Supporting Types

struct HealthDataTypeInfo: Identifiable {
    let id = UUID()
    let type: HealthDataType
    let title: String
    let description: String
    let icon: String
    let color: Color
    let isAvailable: Bool
}

struct SubmissionResult: Identifiable {
    let id = UUID()
    let success: Bool
    let message: String
    let tokensEarned: Double
}