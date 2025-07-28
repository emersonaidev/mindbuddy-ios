import SwiftUI

struct OnboardingHowItWorks: View {
    // MARK: - Properties
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var selectedStep: Int? = nil
    @State private var animateSteps = false
    
    // Callback for next button
    var onNext: () -> Void = {}
    
    // MARK: - Step Data
    private let steps = [
        HowItWorksStep(
            number: "1",
            title: "Collect real-world data",
            description: "We connect to your phone or wearable to track signals like HRV and sleep.",
            icon: "heart.text.square"
        ),
        HowItWorksStep(
            number: "2",
            title: "Earn $MNDY tokens",
            description: "Get rewarded for consistently sharing high-quality stress data.",
            icon: "bitcoinsign.circle"
        ),
        HowItWorksStep(
            number: "3",
            title: "Enrich research",
            description: "Your signals contribute to the world's largest real-world stress dataset.",
            icon: "chart.line.uptrend.xyaxis"
        )
    ]
    
    // MARK: - Computed Properties
    private var horizontalPadding: CGFloat {
        sizeClass == .compact ? 24 : 48
    }
    
    private var maxContentWidth: CGFloat {
        sizeClass == .compact ? .infinity : 600
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Background with gradient blurs
            backgroundView
            
            // Content
            VStack(spacing: 0) {
                // Header with back button
                headerView
                
                // Title
                titleView
                
                // Steps with scroll view for smaller devices
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                            StepCard(
                                step: step,
                                isSelected: selectedStep == index,
                                delay: Double(index) * 0.1
                            )
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    selectedStep = selectedStep == index ? nil : index
                                }
                            }
                            .opacity(animateSteps ? 1 : 0)
                            .offset(y: animateSteps ? 0 : 20)
                            .animation(
                                .spring(response: 0.6, dampingFraction: 0.8)
                                .delay(Double(index) * 0.1),
                                value: animateSteps
                            )
                        }
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, 48)
                    .padding(.bottom, 32)
                    .frame(maxWidth: maxContentWidth)
                }
                
                Spacer(minLength: 0)
                
                // Next button
                nextButton
                    .padding(.horizontal, horizontalPadding)
                    .padding(.bottom, 50)
                    .frame(maxWidth: maxContentWidth)
            }
            .frame(maxWidth: .infinity)
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
        .onAppear {
            animateSteps = true
        }
    }
    
    // MARK: - Subviews
    private var backgroundView: some View {
        ZStack {
            Color(red: 0.06, green: 0.05, blue: 0.10)
                .ignoresSafeArea()
            
            // Animated gradient blurs
            GeometryReader { geometry in
                // Primary gradient blur
                Circle()
                    .fill(Color(red: 0.31, green: 0.27, blue: 0.90).opacity(0.30))
                    .frame(width: min(520, geometry.size.width * 1.3))
                    .blur(radius: 64)
                    .offset(x: -32, y: -geometry.size.height * 0.34)
                    .animation(
                        .easeInOut(duration: 8)
                        .repeatForever(autoreverses: true),
                        value: animateSteps
                    )
                
                // Secondary gradient blur
                Circle()
                    .fill(Color(red: 0.75, green: 0.15, blue: 0.83).opacity(0.25))
                    .frame(width: min(620, geometry.size.width * 1.5))
                    .blur(radius: 64)
                    .offset(x: -33, y: geometry.size.height * 0.29)
                    .animation(
                        .easeInOut(duration: 10)
                        .repeatForever(autoreverses: true),
                        value: animateSteps
                    )
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            Button(action: { dismiss() }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .medium))
                    Text("Back")
                        .font(.system(size: 14))
                }
                .foregroundColor(Color(red: 0.80, green: 0.84, blue: 0.88))
            }
            .accessibilityLabel("Go back")
            .accessibilityHint("Returns to the previous screen")
            
            Spacer()
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.top, 60)
    }
    
    private var titleView: some View {
        Text("How it works")
            .font(.system(size: 30, weight: .semibold))
            .foregroundColor(.white)
            .accessibilityAddTraits(.isHeader)
            .padding(.top, 32)
    }
    
    private var nextButton: some View {
        Button(action: {
            withAnimation {
                onNext()
            }
        }) {
            HStack {
                Text("Next")
                    .font(.system(size: 16, weight: .semibold))
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.31, green: 0.27, blue: 0.90).opacity(0.8),
                        Color(red: 0.75, green: 0.15, blue: 0.83).opacity(0.8)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.1), radius: 6, y: 4)
        }
        .accessibilityLabel("Next")
        .accessibilityHint("Continue to the next onboarding step")
    }
}

// MARK: - Step Card Component
private struct StepCard: View {
    let step: HowItWorksStep
    let isSelected: Bool
    let delay: Double
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Number circle with icon
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.10))
                    .frame(width: 36, height: 36)
                
                if isSelected {
                    Image(systemName: step.icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Text(step.number)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .shadow(color: .white.opacity(0.1), radius: 0)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Step \(step.number)")
            
            // Text content
            VStack(alignment: .leading, spacing: 8) {
                Text(step.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(step.description)
                    .font(.system(size: 15))
                    .lineSpacing(7)
                    .foregroundColor(Color(red: 0.58, green: 0.64, blue: 0.72))
                    .fixedSize(horizontal: false, vertical: true)
                
                if isSelected {
                    // Additional info when selected
                    Text("Tap to collapse")
                        .font(.system(size: 12))
                        .foregroundColor(Color(red: 0.80, green: 0.84, blue: 0.88))
                        .padding(.top, 4)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            
            Spacer(minLength: 0)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            isSelected ? Color(red: 0.31, green: 0.27, blue: 0.90).opacity(0.3) : Color.clear,
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: .white.opacity(0.1), radius: 0)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .accessibilityElement(children: .combine)
        .accessibilityHint(isSelected ? "Tap to collapse details" : "Tap to expand details")
    }
}

// MARK: - Data Model
private struct HowItWorksStep: Identifiable {
    let id = UUID()
    let number: String
    let title: String
    let description: String
    let icon: String
}

// MARK: - Preview
struct OnboardingHowItWorks_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            OnboardingHowItWorks(onNext: {
                print("Next tapped")
            })
            .previewDisplayName("iPhone 15 Pro")
            
            OnboardingHowItWorks(onNext: {
                print("Next tapped")
            })
            .previewDevice("iPhone SE (3rd generation)")
            .previewDisplayName("iPhone SE")
            
            OnboardingHowItWorks(onNext: {
                print("Next tapped")
            })
            .previewDevice("iPad Pro (12.9-inch) (6th generation)")
            .previewDisplayName("iPad Pro")
        }
    }
}