import SwiftUI

struct OnboardingView: View {
    @State private var currentStep = 0
    @State private var isShowingAuth = false
    @State private var isShowingHealthKitPermission = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    private let steps = OnboardingStep.steps
    
    var body: some View {
        ZStack {
            // Background color for current step
            steps[currentStep].backgroundColor
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.5), value: currentStep)
            
            VStack {
                // Skip button
                HStack {
                    Spacer()
                    Button("Skip") {
                        completeOnboarding()
                    }
                    .padding()
                    .foregroundColor(.secondary)
                }
                
                // Page content
                TabView(selection: $currentStep) {
                    ForEach(0..<steps.count, id: \.self) { index in
                        OnboardingStepView(step: steps[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                // Custom page indicator and buttons
                VStack(spacing: 20) {
                    // Page indicators
                    HStack(spacing: 8) {
                        ForEach(0..<steps.count, id: \.self) { index in
                            Circle()
                                .fill(currentStep == index ? Color.primary : Color.secondary.opacity(0.3))
                                .frame(width: 8, height: 8)
                                .animation(.easeInOut, value: currentStep)
                        }
                    }
                    .padding(.bottom, 10)
                    
                    // Action buttons
                    if currentStep < steps.count - 1 {
                        Button(action: {
                            withAnimation {
                                currentStep += 1
                            }
                        }) {
                            Label("Next", systemImage: "arrow.right")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.primary)
                                .foregroundColor(steps[currentStep].backgroundColor)
                                .cornerRadius(12)
                        }
                    } else {
                        VStack(spacing: 12) {
                            Button(action: {
                                isShowingHealthKitPermission = true
                            }) {
                                Text("Get Started")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.primary)
                                    .foregroundColor(steps[currentStep].backgroundColor)
                                    .cornerRadius(12)
                            }
                            
                            Button(action: {
                                completeOnboarding()
                                isShowingAuth = true
                            }) {
                                Text("Already have an account? Sign In")
                                    .foregroundColor(.primary)
                                    .font(.subheadline)
                            }
                        }
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 50)
            }
        }
        .fullScreenCover(isPresented: $isShowingAuth) {
            LoginView()
        }
        .sheet(isPresented: $isShowingHealthKitPermission) {
            HealthKitPermissionView(isPresented: $isShowingHealthKitPermission)
                .onDisappear {
                    // After health kit permission, complete onboarding and show auth
                    completeOnboarding()
                    isShowingAuth = true
                }
        }
    }
    
    private func completeOnboarding() {
        hasCompletedOnboarding = true
    }
}

struct OnboardingStepView: View {
    let step: OnboardingStep
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Icon
            Image(systemName: step.imageName)
                .font(.system(size: 100))
                .foregroundColor(step.imageColor)
                .shadow(color: step.imageColor.opacity(0.3), radius: 20, x: 0, y: 10)
            
            // Text content
            VStack(spacing: 20) {
                Text(step.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                
                Text(step.description)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 40)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            Spacer()
        }
        .padding()
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}