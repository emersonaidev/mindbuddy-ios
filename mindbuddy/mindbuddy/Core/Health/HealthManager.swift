import Foundation
import HealthKit

class HealthManager: ObservableObject, HealthServiceProtocol {
    static let shared = HealthManager()
    
    private let healthStore = HKHealthStore()
    @Published var isHealthDataAvailable = false
    @Published var authorizationStatus: HKAuthorizationStatus = .notDetermined
    
    var isAuthorized: Bool {
        return authorizationStatus == .sharingAuthorized
    }
    
    private let apiClient: APIClientProtocol
    private let cacheService: CacheServiceProtocol
    
    init(
        apiClient: APIClientProtocol = DependencyContainer.shared.apiClient,
        cacheService: CacheServiceProtocol = DependencyContainer.shared.cacheService
    ) {
        self.apiClient = apiClient
        self.cacheService = cacheService
        self.isHealthDataAvailable = HKHealthStore.isHealthDataAvailable()
    }
    
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
    
    
    func requestHealthKitPermissions() async throws {
        try await requestAuthorization()
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
    
    private func fetchHeartRateSamples(from startDate: Date, to endDate: Date) async throws -> [HKQuantitySample] {
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
    
    private func fetchHRVSamples(from startDate: Date, to endDate: Date) async throws -> [HKQuantitySample] {
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
    
    private func fetchStepsSamples(from startDate: Date, to endDate: Date) async throws -> [HKQuantitySample] {
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
        
        let response: HealthDataBatchResponse = try await apiClient.request(
            endpoint: "/health-data/batch",
            method: .POST,
            body: requestData,
            headers: ["Authorization": "Bearer \(token)"],
            responseType: HealthDataBatchResponse.self,
            requiresAuth: true
        )
        
        return response
    }
    
    // MARK: - HealthServiceProtocol Implementation
    
    func fetchHeartRateData(from startDate: Date, to endDate: Date) async throws -> [HealthData] {
        let samples = try await fetchHeartRateSamples(from: startDate, to: endDate)
        return samples.map { sample in
            HealthData(
                type: "heartRate",
                value: .double(sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))),
                unit: "bpm",
                recordedAt: sample.startDate
            )
        }
    }
    
    func fetchStepsData(from startDate: Date, to endDate: Date) async throws -> [HealthData] {
        guard let stepsType = HKSampleType.quantityType(forIdentifier: .stepCount) else {
            throw HealthError.invalidDataType
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let samples: [HKQuantitySample] = try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: stepsType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { query, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    let quantitySamples = samples as? [HKQuantitySample] ?? []
                    continuation.resume(returning: quantitySamples)
                }
            }
            
            healthStore.execute(query)
        }
        
        return samples.map { sample in
            HealthData(
                type: "steps",
                value: .integer(Int(sample.quantity.doubleValue(for: HKUnit.count()))),
                unit: "steps",
                recordedAt: sample.startDate
            )
        }
    }
    
    func submitHealthDataBatch(_ healthData: [HealthData]) async throws {
        let submitRequests = healthData.map { data in
            HealthDataSubmitRequest(
                dataType: data.type,
                value: data.value,
                unit: data.unit,
                timestamp: DateUtilities.toISO8601String(data.recordedAt),
                source: DataSource.appleWatch.rawValue
            )
        }
        _ = try await submitHealthDataToBackend(submitRequests)
    }
    
    func enableBackgroundDelivery() async throws {
        for dataType in healthDataTypes {
            if let quantityType = dataType as? HKQuantityType {
                try await healthStore.enableBackgroundDelivery(
                    for: quantityType,
                    frequency: .immediate
                )
            }
        }
    }
    
    // MARK: - Additional Protocol Methods
    
    func fetchHRVData(from startDate: Date, to endDate: Date) async throws -> [HealthData] {
        guard let hrvType = HKSampleType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else {
            throw HealthError.invalidDataType
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let samples: [HKQuantitySample] = try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: hrvType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { query, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    let quantitySamples = samples as? [HKQuantitySample] ?? []
                    continuation.resume(returning: quantitySamples)
                }
            }
            
            healthStore.execute(query)
        }
        
        return samples.map { sample in
            HealthData(
                type: "hrv",
                value: .double(sample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))),
                unit: "ms",
                recordedAt: sample.startDate
            )
        }
    }
    
    func fetchBloodPressureData(from startDate: Date, to endDate: Date) async throws -> [HealthData] {
        guard let systolicType = HKSampleType.quantityType(forIdentifier: .bloodPressureSystolic),
              let diastolicType = HKSampleType.quantityType(forIdentifier: .bloodPressureDiastolic) else {
            throw HealthError.invalidDataType
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        // Fetch systolic
        let systolicSamples: [HKQuantitySample] = try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: systolicType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { query, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    let quantitySamples = samples as? [HKQuantitySample] ?? []
                    continuation.resume(returning: quantitySamples)
                }
            }
            
            healthStore.execute(query)
        }
        
        return systolicSamples.map { sample in
            HealthData(
                type: "bloodPressure",
                value: .string("\(Int(sample.quantity.doubleValue(for: HKUnit.millimeterOfMercury())))/80"), // Simplified
                unit: "mmHg",
                recordedAt: sample.startDate
            )
        }
    }
    
    func fetchSleepData(from startDate: Date, to endDate: Date) async throws -> [HealthData] {
        guard let sleepType = HKSampleType.categoryType(forIdentifier: .sleepAnalysis) else {
            throw HealthError.invalidDataType
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let samples: [HKCategorySample] = try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { query, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    let categorySamples = samples as? [HKCategorySample] ?? []
                    continuation.resume(returning: categorySamples)
                }
            }
            
            healthStore.execute(query)
        }
        
        return samples.map { sample in
            let duration = sample.endDate.timeIntervalSince(sample.startDate) / 3600 // hours
            return HealthData(
                type: "sleep",
                value: .double(duration),
                unit: "hours",
                recordedAt: sample.startDate
            )
        }
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