import SwiftUI

struct OnboardingCompletionView: View {
    let onContinue: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var showSuccessAnimation = false
    @State private var iconScale: CGFloat = 0.8
    @State private var iconOpacity: Double = 0
    
    // MARK: - Computed Properties
    private var horizontalPadding: CGFloat {
        sizeClass == .compact ? 24 : 48
    }
    
    private var maxContentWidth: CGFloat {
        sizeClass == .compact ? .infinity : 600
    }
    
    var body: some View {
        ZStack {
            // Background
            backgroundGradient
            
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 120)
                
                // Success Icon
                successIcon
                    .padding(.bottom, 40)
                
                // Title
                Text("You're all set!")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                    .padding(.bottom, 16)
                
                // Subtitle
                Text("Great! We can now track your wellness data.\nLet's create your account to start earning rewards.")
                    .font(.system(size: 14))
                    .lineHeight(20)
                    .foregroundColor(Color.MindBuddy.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, horizontalPadding)
                    .padding(.bottom, 48)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
                
                // Action Buttons
                actionButtons
                    .padding(.horizontal, horizontalPadding)
                    .padding(.bottom, 50)
                    .frame(maxWidth: maxContentWidth)
            }
            .frame(maxWidth: .infinity)
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
        .onAppear {
            startAnimations()
        }
    }
    
    // MARK: - Background
    private var backgroundGradient: some View {
        ZStack {
            Color.MindBuddy.background
                .ignoresSafeArea()
            
            GeometryReader { geometry in
                // Top purple gradient
                Circle()
                    .fill(Color.MindBuddy.primaryAccent.opacity(0.30))
                    .frame(width: min(520, geometry.size.width * 1.3))
                    .blur(radius: 64)
                    .offset(x: -33, y: -geometry.size.height * 0.34)
                
                // Bottom pink gradient
                Circle()
                    .fill(Color.MindBuddy.secondaryAccent.opacity(0.25))
                    .frame(width: min(620, geometry.size.width * 1.5))
                    .blur(radius: 64)
                    .offset(x: -34, y: geometry.size.height * 0.29)
            }
        }
    }
    
    // MARK: - Success Icon
    private var successIcon: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(Color.white.opacity(0.10))
                .frame(width: 80, height: 80)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
                .mindBuddyCardShadow()
            
            // Checkmark icon
            Image(systemName: "checkmark")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.white)
                .scaleEffect(iconScale)
                .opacity(iconOpacity)
        }
        .scaleEffect(showSuccessAnimation ? 1.0 : 0.8)
        .opacity(showSuccessAnimation ? 1.0 : 0)
        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: showSuccessAnimation)
        .accessibilityLabel("Success")
        .accessibilityAddTraits(.isImage)
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        Button(action: onContinue) {
            Text("Continue")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.black)
                .cornerRadius(28)
                .mindBuddyButtonShadow()
        }
        .accessibilityLabel("Continue")
        .accessibilityHint("Tap to create your account")
    }
    
    // MARK: - Animations
    private func startAnimations() {
        // Delay the animation slightly for better visual impact
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation {
                showSuccessAnimation = true
            }
            
            // Animate the checkmark separately for a nice effect
            withAnimation(.easeOut(duration: 0.4).delay(0.2)) {
                iconScale = 1.0
                iconOpacity = 1.0
            }
        }
    }
}

// MARK: - Line Height Extension
extension View {
    func lineHeight(_ height: CGFloat) -> some View {
        self.environment(\.lineSpacing, height - UIFont.preferredFont(forTextStyle: .body).lineHeight)
    }
}

// MARK: - Preview
struct OnboardingCompletionView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            OnboardingCompletionView(
                onContinue: {
                    print("Continue tapped")
                }
            )
            .previewDisplayName("iPhone 15 Pro")
            
            OnboardingCompletionView(
                onContinue: {
                    print("Continue tapped")
                }
            )
            .previewDevice("iPhone SE (3rd generation)")
            .previewDisplayName("iPhone SE")
            
            OnboardingCompletionView(
                onContinue: {
                    print("Continue tapped")
                }
            )
            .previewDevice("iPad Pro (12.9-inch) (6th generation)")
            .previewDisplayName("iPad Pro")
        }
    }
}