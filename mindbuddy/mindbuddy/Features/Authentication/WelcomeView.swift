import SwiftUI

struct WelcomeView: View {
    @State private var navigateToOnboarding = false
    
    var body: some View {
        NavigationStack {
            ZStack {
            // Background
            Color(red: 0.0588, green: 0.0549, blue: 0.102)
                .ignoresSafeArea()

            // Overlays
            ZStack {
                Circle()
                    .fill(Color(red: 0.3098, green: 0.2745, blue: 0.898))
                    .opacity(0.3)
                    .frame(width: 600, height: 900)
                    .blur(radius: 64)
                    .offset(x: -50, y: -69)

                Circle()
                    .fill(Color(red: 0.7529, green: 0.149, blue: 0.8275))
                    .opacity(0.25)
                    .frame(width: 600, height: 900)
                    .blur(radius: 64)
                    .offset(x: -80, y: 360)
            }
            .ignoresSafeArea()
            .drawingGroup()
            .allowsHitTesting(false)

            // Content
            VStack(spacing: 0) {
                // Logo - positioned from top
                Image("LogoAppMB")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .padding(.top, 120)
                
                // Title
                Text("Welcome to\nMindBuddy")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.top, 32)

                // Subtitle
                Text("Track Your Stress. Get Rewarded.")
                    .font(.system(size: 16))
                    .foregroundColor(Color(red: 0.5804, green: 0.6392, blue: 0.7216))
                    .multilineTextAlignment(.center)
                    .padding(.top, 12)
                
                Spacer()
                    .frame(maxHeight: 180)

                // Buttons at bottom
                VStack(spacing: 16) {
                    // Get Started Button
                    NavigationLink(destination: OnboardingHowItWorks(onNext: {
                        // Navigation is handled within the onboarding flow
                    })) {
                        HStack {
                            Text("Get Started")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)

                            Image(systemName: "arrow.right")
                                .foregroundColor(.white)
                                .font(.system(size: 14))
                        }
                        .frame(width: 300)
                        .frame(height: 56)
                        .background(Color(red: 0.3098, green: 0.2745, blue: 0.898))
                        .cornerRadius(24)
                    }

                    // Already Have an Account Button
                    NavigationLink(destination: CreateAccountView()) {
                        Text("I Already Have an Account")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 300)
                            .frame(height: 56)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(24)
                    }
                }
                .padding(.horizontal, 24)

                // Footer Text
                Text("You can customise what you share in the next\nstep.")
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 0.5804, green: 0.6392, blue: 0.7216))
                    .multilineTextAlignment(.center)
                    .padding(.top, 24)
                    .padding(.bottom, 20)
            }
            }
            .navigationBarHidden(true)
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    WelcomeView()
}
