import Foundation
import BackgroundTasks
import HealthKit

// MARK: - Background Task Manager

class BackgroundTaskManager: ObservableObject {
    static let shared = BackgroundTaskManager()
    
    // MARK: - Task Identifiers
    
    private enum TaskIdentifier {
        static let healthDataSync = "com.mindbuddy.healthsync"
        static let tokenRefresh = "com.mindbuddy.tokenrefresh"
    }
    
    // MARK: - Dependencies
    
    private let healthService: HealthServiceProtocol
    private let authService: AuthenticationServiceProtocol
    private let configuration: ConfigurationProtocol
    
    // MARK: - Initialization
    
    init(
        healthService: HealthServiceProtocol = DependencyContainer.shared.healthService,
        authService: AuthenticationServiceProtocol = DependencyContainer.shared.authService,
        configuration: ConfigurationProtocol = DependencyContainer.shared.configuration
    ) {
        self.healthService = healthService
        self.authService = authService
        self.configuration = configuration
    }
    
    // MARK: - Background Task Registration
    
    func registerBackgroundTasks() {
        guard configuration.isBackgroundProcessingEnabled else {
            #if DEBUG
            print("🔧 Background processing disabled in configuration")
            #endif
            return
        }
        
        registerHealthDataSync()
        registerTokenRefresh()
        
        #if DEBUG
        print("✅ Background tasks registered successfully")
        #endif
    }
    
    private func registerHealthDataSync() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: TaskIdentifier.healthDataSync,
            using: nil
        ) { task in
            self.handleHealthDataSync(task: task as! BGAppRefreshTask)
        }
    }
    
    private func registerTokenRefresh() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: TaskIdentifier.tokenRefresh,
            using: nil
        ) { task in
            self.handleTokenRefresh(task: task as! BGProcessingTask)
        }
    }
    
    // MARK: - Task Scheduling
    
    func scheduleHealthDataSync() {
        let request = BGAppRefreshTaskRequest(identifier: TaskIdentifier.healthDataSync)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 4 * 60 * 60) // 4 hours
        
        do {
            try BGTaskScheduler.shared.submit(request)
            #if DEBUG
            print("📅 Health data sync scheduled")
            #endif
        } catch {
            #if DEBUG
            print("❌ Failed to schedule health data sync: \(error)")
            #endif
        }
    }
    
    func scheduleTokenRefresh() {
        let request = BGProcessingTaskRequest(identifier: TaskIdentifier.tokenRefresh)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 50 * 60) // 50 minutes
        request.requiresNetworkConnectivity = true
        
        do {
            try BGTaskScheduler.shared.submit(request)
            #if DEBUG
            print("📅 Token refresh scheduled")
            #endif
        } catch {
            #if DEBUG
            print("❌ Failed to schedule token refresh: \(error)")
            #endif
        }
    }
    
    // MARK: - Task Handlers
    
    private func handleHealthDataSync(task: BGAppRefreshTask) {
        #if DEBUG
        print("🔄 Starting background health data sync")
        #endif
        
        // Schedule next sync
        scheduleHealthDataSync()
        
        let operation = HealthDataSyncOperation(
            healthService: healthService,
            authService: authService
        )
        
        task.expirationHandler = {
            operation.cancel()
        }
        
        operation.completionBlock = {
            task.setTaskCompleted(success: !operation.isCancelled)
        }
        
        let queue = OperationQueue()
        queue.addOperation(operation)
    }
    
    private func handleTokenRefresh(task: BGProcessingTask) {
        #if DEBUG
        print("🔄 Starting background token refresh")
        #endif
        
        // Schedule next refresh
        scheduleTokenRefresh()
        
        Task {
            do {
                try await authService.refreshTokens()
                task.setTaskCompleted(success: true)
                
                #if DEBUG
                print("✅ Background token refresh completed")
                #endif
            } catch {
                task.setTaskCompleted(success: false)
                
                #if DEBUG
                print("❌ Background token refresh failed: \(error)")
                #endif
            }
        }
    }
    
    // MARK: - App State Management
    
    func handleAppWillEnterBackground() {
        scheduleHealthDataSync()
        scheduleTokenRefresh()
    }
    
    func handleAppDidBecomeActive() {
        // Cancel any pending background tasks if app becomes active
        BGTaskScheduler.shared.cancelAllTaskRequests()
    }
}

// MARK: - Health Data Sync Operation

private class HealthDataSyncOperation: Operation {
    private let healthService: HealthServiceProtocol
    private let authService: AuthenticationServiceProtocol
    
    private var _isExecuting = false
    private var _isFinished = false
    
    override var isExecuting: Bool {
        return _isExecuting
    }
    
    override var isFinished: Bool {
        return _isFinished
    }
    
    init(healthService: HealthServiceProtocol, authService: AuthenticationServiceProtocol) {
        self.healthService = healthService
        self.authService = authService
        super.init()
    }
    
    override func start() {
        guard !isCancelled else {
            finish()
            return
        }
        
        willChangeValue(forKey: "isExecuting")
        _isExecuting = true
        didChangeValue(forKey: "isExecuting")
        
        Task {
            await performHealthDataSync()
        }
    }
    
    private func performHealthDataSync() async {
        guard !isCancelled else {
            finish()
            return
        }
        
        do {
            // Check if user is authenticated
            guard authService.isAuthenticated else {
                #if DEBUG
                print("⚠️ User not authenticated, skipping background sync")
                #endif
                finish()
                return
            }
            
            // Sync last 24 hours of health data
            let endDate = Date()
            let startDate = Calendar.current.date(byAdding: .day, value: -1, to: endDate) ?? endDate
            
            // Fetch and submit health data
            async let heartRateData = healthService.fetchHeartRateData(from: startDate, to: endDate)
            async let stepsData = healthService.fetchStepsData(from: startDate, to: endDate)
            
            let allHealthData = try await [heartRateData, stepsData].flatMap { $0 }
            
            if !allHealthData.isEmpty {
                try await healthService.submitHealthDataBatch(allHealthData)
                
                #if DEBUG
                print("✅ Background sync completed: \(allHealthData.count) records")
                #endif
            }
            
        } catch {
            #if DEBUG
            print("❌ Background health sync failed: \(error)")
            #endif
        }
        
        finish()
    }
    
    private func finish() {
        willChangeValue(forKey: "isExecuting")
        willChangeValue(forKey: "isFinished")
        _isExecuting = false
        _isFinished = true
        didChangeValue(forKey: "isExecuting")
        didChangeValue(forKey: "isFinished")
    }
}

// MARK: - Background Processing Extensions

extension BackgroundTaskManager {
    
    // Enable HealthKit background delivery
    func enableHealthKitBackgroundDelivery() async throws {
        guard configuration.healthKitBackgroundDeliveryEnabled else { return }
        
        try await healthService.enableBackgroundDelivery()
        
        #if DEBUG
        print("✅ HealthKit background delivery enabled")
        #endif
    }
    
    // Handle HealthKit background updates
    func handleHealthKitBackgroundUpdate() {
        #if DEBUG
        print("🔄 HealthKit background update received")
        #endif
        
        // Trigger immediate health data sync
        Task {
            let operation = HealthDataSyncOperation(
                healthService: healthService,
                authService: authService
            )
            
            let queue = OperationQueue()
            queue.addOperation(operation)
        }
    }
}

// MARK: - Mock Background Task Manager

class MockBackgroundTaskManager: BackgroundTaskManager {
    override func registerBackgroundTasks() {
        // No-op for testing
    }
    
    override func scheduleHealthDataSync() {
        // No-op for testing
    }
    
    override func scheduleTokenRefresh() {
        // No-op for testing
    }
}