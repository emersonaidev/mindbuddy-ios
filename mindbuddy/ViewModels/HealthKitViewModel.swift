import SwiftUI
import HealthKit
import Combine

@MainActor
class HealthKitViewModel: ObservableObject {
    @Published var isAuthorized = false
    @Published var authorizationStatus: HKAuthorizationStatus = .notDetermined
    @Published var error: Error?
    
    private let healthStore = HKHealthStore()
    private var cancellables = Set<AnyCancellable>()
    
    // Health data types we want to access
    let healthDataTypes: Set<HKSampleType> = [
        HKQuantityType.quantityType(forIdentifier: .heartRate)!,
        HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
        HKQuantityType.quantityType(forIdentifier: .restingHeartRate)!,
        HKQuantityType.quantityType(forIdentifier: .stepCount)!,
        HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKQuantityType.quantityType(forIdentifier: .basalEnergyBurned)!,
        HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!,
        HKQuantityType.quantityType(forIdentifier: .appleExerciseTime)!,
        HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!,
        HKCategoryType.categoryType(forIdentifier: .mindfulSession)!
    ]
    
    init() {
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            self.error = HealthKitError.notAvailable
            return
        }
        
        do {
            try await healthStore.requestAuthorization(toShare: [], read: healthDataTypes)
            checkAuthorizationStatus()
        } catch {
            self.error = error
        }
    }
    
    func checkAuthorizationStatus() {
        guard HKHealthStore.isHealthDataAvailable() else {
            authorizationStatus = .notDetermined
            isAuthorized = false
            return
        }
        
        // Check status for heart rate as a representative type
        if let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) {
            authorizationStatus = healthStore.authorizationStatus(for: heartRateType)
            isAuthorized = authorizationStatus == .sharingAuthorized
        }
    }
    
    // MARK: - Data Fetching
    
    func fetchLatestHeartRate() async throws -> Double? {
        guard isAuthorized else { throw HealthKitError.notAuthorized }
        
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: heartRateType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let heartRate = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                continuation.resume(returning: heartRate)
            }
            
            healthStore.execute(query)
        }
    }
    
    func fetchDailySteps(for date: Date = Date()) async throws -> Double {
        guard isAuthorized else { throw HealthKitError.notAuthorized }
        
        let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: endOfDay,
            options: .strictStartDate
        )
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepsType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let steps = statistics?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                continuation.resume(returning: steps)
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - Error Handling
    
    enum HealthKitError: LocalizedError {
        case notAvailable
        case notAuthorized
        
        var errorDescription: String? {
            switch self {
            case .notAvailable:
                return "Health data is not available on this device"
            case .notAuthorized:
                return "Please authorize MindBuddy to access your health data"
            }
        }
    }
}

// MARK: - Health Data Models

struct HealthMetrics {
    let heartRate: Double?
    let heartRateVariability: Double?
    let steps: Double
    let activeEnergy: Double
    let restingHeartRate: Double?
    let sleepHours: Double?
    let mindfulMinutes: Double?
    let timestamp: Date
}

extension HealthKitViewModel {
    func fetchTodayMetrics() async throws -> HealthMetrics {
        guard isAuthorized else { throw HealthKitError.notAuthorized }
        
        async let heartRate = fetchLatestHeartRate()
        async let steps = fetchDailySteps()
        
        // Fetch other metrics in parallel
        let (latestHR, dailySteps) = try await (heartRate, steps)
        
        return HealthMetrics(
            heartRate: latestHR,
            heartRateVariability: nil, // TODO: Implement
            steps: dailySteps,
            activeEnergy: 0, // TODO: Implement
            restingHeartRate: nil, // TODO: Implement
            sleepHours: nil, // TODO: Implement
            mindfulMinutes: nil, // TODO: Implement
            timestamp: Date()
        )
    }
}