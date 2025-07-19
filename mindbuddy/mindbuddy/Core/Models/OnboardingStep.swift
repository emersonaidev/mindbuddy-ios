import SwiftUI

struct OnboardingStep: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let imageName: String
    let imageColor: Color
    let backgroundColor: Color
}

extension OnboardingStep {
    static let steps: [OnboardingStep] = [
        OnboardingStep(
            title: "Track Your Wellness Journey",
            description: "Monitor your health metrics seamlessly with Apple Watch integration. Get real-time insights into your heart rate, stress levels, and daily activities.",
            imageName: "heart.text.square.fill",
            imageColor: .purple,
            backgroundColor: Color(red: 0.96, green: 0.94, blue: 1.0)
        ),
        OnboardingStep(
            title: "Monitor Your Health Data",
            description: "Connect with Apple Health to automatically track your vital signs, sleep patterns, and physical activity. All your health data in one place.",
            imageName: "waveform.path.ecg",
            imageColor: .blue,
            backgroundColor: Color(red: 0.94, green: 0.96, blue: 1.0)
        ),
        OnboardingStep(
            title: "Get Rewarded for Staying Healthy",
            description: "Earn MNDY tokens for maintaining healthy habits and sharing your wellness data. Turn your health journey into rewards.",
            imageName: "dollarsign.circle.fill",
            imageColor: .green,
            backgroundColor: Color(red: 0.94, green: 1.0, blue: 0.96)
        ),
        OnboardingStep(
            title: "Ready to Begin?",
            description: "Join thousands of users who are taking control of their health and earning rewards. Your wellness journey starts now.",
            imageName: "figure.walk.motion",
            imageColor: .orange,
            backgroundColor: Color(red: 1.0, green: 0.96, blue: 0.94)
        )
    ]
}