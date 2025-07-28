import SwiftUI

struct OnboardingFlowView: View {
    @State private var currentStep = 0
    @State private var showingAuthentication = false
    
    var body: some View {
        ZStack {
            Color.MindBuddy.background
                .ignoresSafeArea()
            
            switch currentStep {
            case 0:
                OnboardingHowItWorks(onNext: {
                    currentStep = 1
                })
                
            case 1:
                ConnectAppleHealthView(
                    onNext: {
                        currentStep = 2
                    },
                    onBack: {
                        currentStep = 0
                    }
                )
                
            case 2:
                OnboardingCompletionView(
                    onContinue: {
                        showingAuthentication = true
                    }
                )
                
            default:
                EmptyView()
            }
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $showingAuthentication) {
            CreateAccountView()
                .navigationBarHidden(true)
        }
    }
}

#Preview {
    NavigationStack {
        OnboardingFlowView()
    }
}