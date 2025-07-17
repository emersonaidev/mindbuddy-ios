import Foundation
import HealthKit

class HealthManager: ObservableObject {
    static let shared = HealthManager()
    
    private let healthStore = HKHealthStore()
    @Published var isHealthDataAvailable = false
    @Published var authorizationStatus: HKAuthorizationStatus = .notDetermined
    
    // Health data types we want to read
    private let healthDataTypes: Set<HKSampleType> = [
        HKSampleType.quantityType(forIdentifier: .heartRate)!,
        HKSampleType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
        HKSampleType.quantityType(forIdentifier: .stepCount)!,
        HKSampleType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKSampleType.categoryType(forIdentifier: .sleepAnalysis)!,
        HKSampleType.quantityType(forIdentifier: .bloodPressureSystolic)!,
        HKSampleType.quantityType(forIdentifier: .bloodPressureDiastolic)!
    ]
    
    private init() {
        isHealthDataAvailable = HKHealthStore.isHealthDataAvailable()
    }
    
    func requestAuthorization() async throws {
        guard isHealthDataAvailable else {
            throw HealthError.healthDataNotAvailable
        }
        
        try await healthStore.requestAuthorization(toShare: [], read: healthDataTypes)
        
        await MainActor.run {
            self.authorizationStatus = self.healthStore.authorizationStatus(for: HKSampleType.quantityType(forIdentifier: .heartRate)!)
        }
    }
    
    func fetchHeartRateData(from startDate: Date, to endDate: Date) async throws -> [HKQuantitySample] {
        guard let heartRateType = HKSampleType.quantityType(forIdentifier: .heartRate) else {
            throw HealthError.invalidDataType
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: heartRateType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    let heartRateSamples = samples?.compactMap { $0 as? HKQuantitySample } ?? []
                    continuation.resume(returning: heartRateSamples)
                }
            }
            
            healthStore.execute(query)
        }
    }
    
    func fetchHRVData(from startDate: Date, to endDate: Date) async throws -> [HKQuantitySample] {
        guard let hrvType = HKSampleType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else {
            throw HealthError.invalidDataType
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: hrvType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    let hrvSamples = samples?.compactMap { $0 as? HKQuantitySample } ?? []
                    continuation.resume(returning: hrvSamples)
                }
            }
            
            healthStore.execute(query)
        }
    }
    
    func fetchStepsData(from startDate: Date, to endDate: Date) async throws -> [HKQuantitySample] {
        guard let stepsType = HKSampleType.quantityType(forIdentifier: .stepCount) else {
            throw HealthError.invalidDataType
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: stepsType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    let stepsSamples = samples?.compactMap { $0 as? HKQuantitySample } ?? []
                    continuation.resume(returning: stepsSamples)
                }
            }
            
            healthStore.execute(query)
        }
    }
    
    func submitHealthDataToBackend(_ healthData: [HealthDataSubmitRequest]) async throws -> HealthDataBatchResponse {
        guard let token = AuthManager.shared.getAccessToken() else {
            throw HealthError.notAuthenticated
        }
        
        let batchRequest = HealthDataBatchRequest(data: healthData)
        let requestData = try JSONEncoder().encode(batchRequest)
        
        let response: HealthDataBatchResponse = try await APIClient.shared.request(
            endpoint: "/health-data/batch",
            method: .POST,
            body: requestData,
            headers: ["Authorization": "Bearer \(token)"],
            responseType: HealthDataBatchResponse.self
        )
        
        return response
    }
    
    func convertHKSampleToHealthData(_ sample: HKQuantitySample, dataType: HealthDataType) -> HealthDataSubmitRequest {
        let value: HealthDataValue
        let unit: String
        
        switch dataType {
        case .heartRate:
            value = .number(sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute())))
            unit = "BPM"
        case .hrv:
            value = .number(sample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli)))
            unit = "ms"
        case .steps:
            value = .number(sample.quantity.doubleValue(for: HKUnit.count()))
            unit = "steps"
        case .calories:
            value = .number(sample.quantity.doubleValue(for: HKUnit.kilocalorie()))
            unit = "kcal"
        default:
            // Use a default unit for unknown data types
            let defaultUnit = HKUnit.count()
            value = .number(sample.quantity.doubleValue(for: defaultUnit))
            unit = defaultUnit.unitString
        }
        
        return HealthDataSubmitRequest(
            dataType: dataType.rawValue,
            value: value,
            unit: unit,
            timestamp: ISO8601DateFormatter().string(from: sample.startDate),
            source: DataSource.appleWatch.rawValue
        )
    }
}

enum HealthError: Error {
    case healthDataNotAvailable
    case invalidDataType
    case notAuthenticated
    case authorizationDenied
    
    var localizedDescription: String {
        switch self {
        case .healthDataNotAvailable:
            return "Health data is not available on this device"
        case .invalidDataType:
            return "Invalid health data type"
        case .notAuthenticated:
            return "User not authenticated"
        case .authorizationDenied:
            return "Health data access denied"
        }
    }
}