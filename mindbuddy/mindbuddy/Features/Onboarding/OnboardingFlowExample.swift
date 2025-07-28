import SwiftUI

// MARK: - Example Onboarding Flow Integration
// This file demonstrates how to integrate the OnboardingCompletionView
// into a complete onboarding flow

struct OnboardingFlowExample: View {
    @State private var currentStep = OnboardingStep.completion
    @State private var shouldShowHealthPermission = false
    
    enum OnboardingStep {
        case welcome
        case howItWorks
        case completion
        case finished
    }
    
    var body: some View {
        NavigationStack {
            switch currentStep {
            case .welcome:
                // Your welcome view
                Text("Welcome View")
                    .onTapGesture {
                        currentStep = .howItWorks
                    }
                
            case .howItWorks:
                // Your how it works view
                Text("How It Works View")
                    .onTapGesture {
                        currentStep = .completion
                    }
                
            case .completion:
                OnboardingCompletionView(
                    onConnectHealthTapped: {
                        // Handle Apple Health connection
                        shouldShowHealthPermission = true
                    },
                    onSkipTapped: {
                        // Handle skip action
                        completeOnboarding()
                    }
                )
                .sheet(isPresented: $shouldShowHealthPermission) {
                    ConnectAppleHealthView(
                        onConnectTapped: {
                            // Request HealthKit authorization
                            Task {
                                do {
                                    try await ConnectAppleHealthView.requestHealthKitAuthorization()
                                    await MainActor.run {
                                        shouldShowHealthPermission = false
                                        completeOnboarding()
                                    }
                                } catch {
                                    print("Health authorization failed: \(error)")
                                    // Handle error appropriately
                                }
                            }
                        }
                    )
                }
                
            case .finished:
                // Transition to main app
                Text("Main App")
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func completeOnboarding() {
        // Save onboarding completion state
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        
        // Transition to main app
        withAnimation {
            currentStep = .finished
        }
    }
}

// MARK: - Alternative Integration with Navigation Path
struct OnboardingFlowWithPath: View {
    @State private var navigationPath = NavigationPath()
    @State private var shouldShowHealthPermission = false
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            // Initial view
            VStack {
                Text("Start Onboarding")
                Button("Begin") {
                    navigationPath.append("completion")
                }
            }
            .navigationDestination(for: String.self) { destination in
                switch destination {
                case "completion":
                    OnboardingCompletionView(
                        onConnectHealthTapped: {
                            shouldShowHealthPermission = true
                        },
                        onSkipTapped: {
                            // Navigate to main app or dismiss onboarding
                            navigationPath.removeLast(navigationPath.count)
                        }
                    )
                    .navigationBarHidden(true)
                    
                default:
                    EmptyView()
                }
            }
        }
        .sheet(isPresented: $shouldShowHealthPermission) {
            ConnectAppleHealthView(
                onConnectTapped: {
                    Task {
                        do {
                            try await ConnectAppleHealthView.requestHealthKitAuthorization()
                            await MainActor.run {
                                shouldShowHealthPermission = false
                                // Navigate to main app
                                navigationPath.removeLast(navigationPath.count)
                            }
                        } catch {
                            print("Health authorization failed: \(error)")
                        }
                    }
                }
            )
        }
    }
}

// MARK: - Preview
struct OnboardingFlowExample_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingFlowExample()
    }
}