import SwiftUI

struct OnboardingContainerView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @Binding var showOnboarding: Bool
    
    var body: some View {
        ZStack {
            // Progress indicator
            VStack {
                ProgressView(value: viewModel.currentStep.progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: Color(red: 0.31, green: 0.27, blue: 0.90)))
                    .scaleEffect(x: 1, y: 2, anchor: .center)
                    .padding(.horizontal)
                    .padding(.top, 60)
                
                Spacer()
            }
            .zIndex(1)
            
            // Content
            Group {
                switch viewModel.currentStep {
                case .welcome:
                    WelcomeView()
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .leading)
                        ))
                    
                case .howItWorks:
                    OnboardingHowItWorks()
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .leading)
                        ))
                    
                case .connectHealth:
                    ConnectAppleHealthView(
                        onConnectTapped: {
                            await viewModel.connectToAppleHealth()
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))
                    
                case .notifications:
                    NotificationPermissionView(
                        onAllowTapped: {
                            await viewModel.requestNotificationPermission()
                        },
                        onSkipTapped: {
                            viewModel.skipNotifications()
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))
                    
                case .completed:
                    OnboardingCompletedView()
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .leading)
                        ))
                }
            }
            .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
        }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") {
                viewModel.error = nil
            }
        } message: {
            Text(viewModel.error?.localizedDescription ?? "An error occurred")
        }
        .onChange(of: viewModel.shouldShowMainApp) { shouldShow in
            if shouldShow {
                withAnimation {
                    showOnboarding = false
                }
            }
        }
    }
}

// MARK: - Notification Permission View (Placeholder)
struct NotificationPermissionView: View {
    var onAllowTapped: () async -> Void
    var onSkipTapped: () -> Void
    
    var body: some View {
        ZStack {
            Color(red: 0.06, green: 0.05, blue: 0.10)
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                VStack(spacing: 20) {
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 80))
                        .foregroundColor(Color(red: 0.31, green: 0.27, blue: 0.90))
                    
                    Text("Stay Updated")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("Get notified about your wellness rewards and health insights")
                        .font(.system(size: 16))
                        .foregroundColor(Color(red: 0.58, green: 0.64, blue: 0.72))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Spacer()
                
                VStack(spacing: 16) {
                    Button(action: {
                        Task {
                            await onAllowTapped()
                        }
                    }) {
                        Text("Allow Notifications")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color(red: 0.31, green: 0.27, blue: 0.90))
                            .cornerRadius(28)
                    }
                    
                    Button(action: onSkipTapped) {
                        Text("Skip for now")
                            .font(.system(size: 14))
                            .foregroundColor(Color(red: 0.58, green: 0.64, blue: 0.72))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
            }
            .padding(.top, 100)
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Onboarding Completed View (Placeholder)
struct OnboardingCompletedView: View {
    var body: some View {
        ZStack {
            Color(red: 0.06, green: 0.05, blue: 0.10)
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 100))
                        .foregroundColor(Color(red: 0.31, green: 0.27, blue: 0.90))
                    
                    Text("You're All Set!")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("Welcome to MindBuddy. Let's start your wellness journey!")
                        .font(.system(size: 16))
                        .foregroundColor(Color(red: 0.58, green: 0.64, blue: 0.72))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Spacer()
            }
            .padding(.top, 150)
        }
        .navigationBarHidden(true)
        .onAppear {
            // Auto-transition to main app after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                // Transition handled by parent view
            }
        }
    }
}

// MARK: - Preview
struct OnboardingContainerView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingContainerView(showOnboarding: .constant(true))
    }
}