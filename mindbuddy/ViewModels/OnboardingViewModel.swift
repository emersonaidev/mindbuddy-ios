import SwiftUI
import Combine

@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var currentStep: OnboardingStep = .welcome
    @Published var isLoading = false
    @Published var error: Error?
    @Published var shouldShowMainApp = false
    
    private let healthKitViewModel = HealthKitViewModel()
    private let userService: UserService
    private let authManager: AuthManager
    
    init(userService: UserService = UserService(), authManager: AuthManager = AuthManager.shared) {
        self.userService = userService
        self.authManager = authManager
    }
    
    // MARK: - Navigation
    
    func nextStep() {
        switch currentStep {
        case .welcome:
            currentStep = .howItWorks
        case .howItWorks:
            currentStep = .connectHealth
        case .connectHealth:
            currentStep = .notifications
        case .notifications:
            completeOnboarding()
        case .completed:
            shouldShowMainApp = true
        }
    }
    
    func previousStep() {
        switch currentStep {
        case .welcome:
            break // Can't go back from welcome
        case .howItWorks:
            currentStep = .welcome
        case .connectHealth:
            currentStep = .howItWorks
        case .notifications:
            currentStep = .connectHealth
        case .completed:
            currentStep = .notifications
        }
    }
    
    // MARK: - Apple Health Connection
    
    func connectToAppleHealth() async {
        isLoading = true
        error = nil
        
        do {
            // Request HealthKit authorization
            await healthKitViewModel.requestAuthorization()
            
            // Check if authorization was granted
            healthKitViewModel.checkAuthorizationStatus()
            
            if healthKitViewModel.isAuthorized {
                // Update user profile to indicate health connection
                try await updateHealthConnectionStatus(true)
                
                // Move to next step
                await MainActor.run {
                    self.nextStep()
                }
            } else {
                // User denied permission or didn't make a selection
                // Still allow them to continue
                await MainActor.run {
                    self.nextStep()
                }
            }
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    // MARK: - Notifications
    
    func requestNotificationPermission() async {
        isLoading = true
        error = nil
        
        do {
            let notificationCenter = UNUserNotificationCenter.current()
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .badge, .sound])
            
            // Update user profile with notification preference
            try await updateNotificationStatus(granted)
            
            // Complete onboarding regardless of permission
            await MainActor.run {
                self.completeOnboarding()
            }
        } catch {
            self.error = error
            // Still complete onboarding even if there's an error
            await MainActor.run {
                self.completeOnboarding()
            }
        }
        
        isLoading = false
    }
    
    // MARK: - Completion
    
    private func completeOnboarding() {
        Task {
            do {
                // Mark onboarding as completed in user profile
                try await markOnboardingCompleted()
                
                await MainActor.run {
                    self.currentStep = .completed
                    self.shouldShowMainApp = true
                }
            } catch {
                self.error = error
                // Still show main app even if update fails
                await MainActor.run {
                    self.shouldShowMainApp = true
                }
            }
        }
    }
    
    // MARK: - API Updates
    
    private func updateHealthConnectionStatus(_ connected: Bool) async throws {
        // Update user profile via API
        // This is a placeholder - implement based on your API structure
        print("Updating health connection status: \(connected)")
    }
    
    private func updateNotificationStatus(_ enabled: Bool) async throws {
        // Update user profile via API
        // This is a placeholder - implement based on your API structure
        print("Updating notification status: \(enabled)")
    }
    
    private func markOnboardingCompleted() async throws {
        // Mark onboarding as completed in user profile
        // This is a placeholder - implement based on your API structure
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        print("Onboarding completed")
    }
    
    // MARK: - Skip Options
    
    func skipHealthConnection() {
        nextStep()
    }
    
    func skipNotifications() {
        completeOnboarding()
    }
}

// MARK: - Onboarding Step Extension
extension OnboardingStep {
    var title: String {
        switch self {
        case .welcome:
            return "Welcome to MindBuddy"
        case .howItWorks:
            return "How It Works"
        case .connectHealth:
            return "Connect Your Data"
        case .notifications:
            return "Stay Updated"
        case .completed:
            return "All Set!"
        }
    }
    
    var progress: Double {
        switch self {
        case .welcome:
            return 0.2
        case .howItWorks:
            return 0.4
        case .connectHealth:
            return 0.6
        case .notifications:
            return 0.8
        case .completed:
            return 1.0
        }
    }
}