import SwiftUI
import FirebaseAuth

struct TemporarySuccessView: View {
    @StateObject private var authManager = AuthManager.shared
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var showCheckmark = false
    @State private var animateContent = false
    
    // MARK: - Computed Properties
    private var horizontalPadding: CGFloat {
        sizeClass == .compact ? 24 : 48
    }
    
    private var maxContentWidth: CGFloat {
        sizeClass == .compact ? .infinity : 600
    }
    
    private var userName: String {
        if let currentUser = authManager.currentUser {
            return currentUser.firstName ?? currentUser.email ?? "User"
        } else if let firebaseUser = Auth.auth().currentUser {
            return firebaseUser.displayName ?? firebaseUser.email ?? "User"
        }
        return "User"
    }
    
    var body: some View {
        ZStack {
            // Background
            backgroundGradient
            
            VStack(spacing: 0) {
                // Success Icon
                successIcon
                    .padding(.top, 120)
                    .padding(.bottom, 40)
                
                // Welcome Message
                VStack(spacing: 16) {
                    Text("Welcome to MindBuddy!")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundColor(Color.MindBuddy.textPrimary)
                        .multilineTextAlignment(.center)
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 20)
                    
                    Text("Hello, \(userName)")
                        .font(.system(size: 18))
                        .foregroundColor(Color.MindBuddy.textSecondary)
                        .multilineTextAlignment(.center)
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 20)
                }
                .padding(.horizontal, horizontalPadding)
                
                Spacer()
                    .frame(height: 60)
                
                // Temporary Info
                VStack(spacing: 24) {
                    InfoCard(
                        icon: "checkmark.circle.fill",
                        iconColor: Color.MindBuddy.success,
                        title: "Successfully Logged In",
                        description: "Your account is connected and ready to track wellness data."
                    )
                    
                    InfoCard(
                        icon: "heart.fill",
                        iconColor: Color.MindBuddy.primaryAccent,
                        title: "Health Data Connected",
                        description: "We're tracking your HRV, heart rate, and activity data."
                    )
                    
                    InfoCard(
                        icon: "bitcoinsign.circle.fill",
                        iconColor: Color.MindBuddy.warning,
                        title: "Earn MNDY Tokens",
                        description: "Stay healthy and earn rewards automatically."
                    )
                }
                .padding(.horizontal, horizontalPadding)
                .frame(maxWidth: maxContentWidth)
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 30)
                
                Spacer()
                
                // Sign Out Button
                Button(action: signOut) {
                    Text("Sign Out (Temporary)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.MindBuddy.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(28)
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.bottom, 50)
                .frame(maxWidth: maxContentWidth)
                .opacity(animateContent ? 1 : 0)
            }
            .frame(maxWidth: .infinity)
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
        .onAppear {
            animateView()
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
                .fill(Color.MindBuddy.success.opacity(0.2))
                .frame(width: 120, height: 120)
                .scaleEffect(showCheckmark ? 1 : 0.8)
                .opacity(showCheckmark ? 1 : 0)
            
            // Checkmark
            Image(systemName: "checkmark")
                .font(.system(size: 50, weight: .bold))
                .foregroundColor(Color.MindBuddy.success)
                .scaleEffect(showCheckmark ? 1 : 0.5)
                .opacity(showCheckmark ? 1 : 0)
                .rotationEffect(.degrees(showCheckmark ? 0 : -30))
        }
        .accessibilityLabel("Success checkmark")
    }
    
    // MARK: - Actions
    private func signOut() {
        Task {
            authManager.logout()
        }
    }
    
    private func animateView() {
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1)) {
            showCheckmark = true
        }
        
        withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
            animateContent = true
        }
    }
}

// MARK: - Info Card Component
private struct InfoCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(iconColor)
                .frame(width: 36, height: 36)
                .accessibilityHidden(true)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.MindBuddy.textPrimary)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(Color.MindBuddy.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(20)
        .background(Color.MindBuddy.cardBackground.opacity(0.5))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Preview
#Preview {
    TemporarySuccessView()
}