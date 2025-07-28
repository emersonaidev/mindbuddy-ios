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
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        currentStep = 1
                    }
                })
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing)
                        .combined(with: .opacity)
                        .combined(with: .scale(scale: 0.95)),
                    removal: .move(edge: .leading)
                        .combined(with: .opacity)
                        .combined(with: .scale(scale: 1.05))
))
                .zIndex(currentStep == 0 ? 1 : 0)
                
            case 1:
                ConnectAppleHealthView(
                    onNext: {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            currentStep = 2
                        }
                    },
                    onBack: {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            currentStep = 0
                        }
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing)
                        .combined(with: .opacity)
                        .combined(with: .scale(scale: 0.95)),
                    removal: .move(edge: .leading)
                        .combined(with: .opacity)
                        .combined(with: .scale(scale: 1.05))
))
                .zIndex(currentStep == 1 ? 1 : 0)
                
            case 2:
                OnboardingCompletionView(
                    onContinue: {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            showingAuthentication = true
                        }
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing)
                        .combined(with: .opacity)
                        .combined(with: .scale(scale: 0.95)),
                    removal: .move(edge: .leading)
                        .combined(with: .opacity)
                        .combined(with: .scale(scale: 1.05))
))
                .zIndex(currentStep == 2 ? 1 : 0)
                
            default:
                EmptyView()
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentStep)
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