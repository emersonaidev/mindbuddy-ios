import SwiftUI

// MARK: - Example Usage in Main App
struct OnboardingExampleApp: App {
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    
    var body: some Scene {
        WindowGroup {
            if showOnboarding {
                OnboardingContainerView(showOnboarding: $showOnboarding)
            } else {
                ContentView()
            }
        }
    }
}

// MARK: - Standalone Apple Health Connection Example
struct AppleHealthConnectionExample: View {
    @StateObject private var healthKitViewModel = HealthKitViewModel()
    @State private var showingHealthView = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("HealthKit Integration Example")
                    .font(.title)
                    .padding()
                
                // Status Display
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Authorization Status:")
                        Text(healthKitViewModel.authorizationStatus.description)
                            .foregroundColor(healthKitViewModel.isAuthorized ? .green : .orange)
                    }
                    
                    HStack {
                        Text("Connected:")
                        Image(systemName: healthKitViewModel.isAuthorized ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(healthKitViewModel.isAuthorized ? .green : .red)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                // Connect Button
                Button(action: {
                    showingHealthView = true
                }) {
                    Text("Connect Apple Health")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                // Test Data Fetching
                if healthKitViewModel.isAuthorized {
                    Button(action: {
                        Task {
                            do {
                                let metrics = try await healthKitViewModel.fetchTodayMetrics()
                                print("Today's steps: \(metrics.steps)")
                                if let heartRate = metrics.heartRate {
                                    print("Latest heart rate: \(heartRate)")
                                }
                            } catch {
                                print("Error fetching metrics: \(error)")
                            }
                        }
                    }) {
                        Text("Fetch Today's Metrics")
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                
                Spacer()
            }
            .navigationTitle("HealthKit Example")
            .sheet(isPresented: $showingHealthView) {
                ConnectAppleHealthView(
                    onConnectTapped: {
                        await healthKitViewModel.requestAuthorization()
                        showingHealthView = false
                    }
                )
            }
        }
    }
}

// MARK: - HKAuthorizationStatus Extension
extension HKAuthorizationStatus {
    var description: String {
        switch self {
        case .notDetermined:
            return "Not Determined"
        case .sharingDenied:
            return "Sharing Denied"
        case .sharingAuthorized:
            return "Sharing Authorized"
        @unknown default:
            return "Unknown"
        }
    }
}

// MARK: - Integration with Existing App
extension ContentView {
    func checkOnboardingStatus() -> Bool {
        return UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }
}

// MARK: - Preview
struct OnboardingExample_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Full onboarding flow
            OnboardingContainerView(showOnboarding: .constant(true))
                .previewDisplayName("Full Onboarding")
            
            // Just the Apple Health connection screen
            ConnectAppleHealthView(
                onConnectTapped: {
                    print("Connect tapped in preview")
                }
            )
            .previewDisplayName("Apple Health Screen")
            
            // HealthKit integration example
            AppleHealthConnectionExample()
                .previewDisplayName("HealthKit Example")
        }
    }
}