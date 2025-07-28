import SwiftUI
import HealthKit

struct ConnectAppleHealthView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var isConnecting = false
    @State private var showCompletion = false
    
    // Callback for when user taps connect
    var onConnectTapped: () async -> Void
    
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
                // Header
                headerSection
                
                Spacer()
                    .frame(height: 40)
                
                // Information Cards
                ScrollView {
                    VStack(spacing: 16) {
                        healthDataAccessCard
                        privacyControlCard
                        appleHealthCard
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.vertical, 20)
                    .frame(maxWidth: maxContentWidth)
                }
                
                Spacer()
                
                // Bottom Section
                bottomSection
                    .padding(.horizontal, horizontalPadding)
                    .padding(.bottom, 50)
                    .frame(maxWidth: maxContentWidth)
            }
            .frame(maxWidth: .infinity)
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
        .navigationDestination(isPresented: $showCompletion) {
            OnboardingCompletionView(
                onConnectHealthTapped: {
                    // User wants to connect again
                    showCompletion = false
                },
                onSkipTapped: {
                    // Complete onboarding
                    dismiss()
                }
            )
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
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .medium))
                        Text("Back")
                            .font(.system(size: 14))
                    }
                    .foregroundColor(Color.MindBuddy.textTertiary)
                }
                .accessibilityLabel("Go back")
                
                Spacer()
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.top, 60)
            
            Text("Connect your data")
                .font(.system(size: 30, weight: .semibold))
                .foregroundColor(Color.MindBuddy.textPrimary)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
        }
    }
    
    // MARK: - Information Cards
    private var healthDataAccessCard: some View {
        InfoCard(
            icon: "heart.text.square.fill",
            iconColor: Color.MindBuddy.primaryAccent,
            title: "Health Data Access",
            description: "We need permission to read your health and phone data via Apple Health or your device."
        )
        .accessibilityElement(children: .combine)
    }
    
    private var privacyControlCard: some View {
        InfoCard(
            icon: "lock.shield.fill",
            iconColor: Color.MindBuddy.secondaryAccent,
            title: "Privacy Control",
            description: "You'll stay in control and can change what you share later."
        )
        .accessibilityElement(children: .combine)
    }
    
    private var appleHealthCard: some View {
        InfoCard(
            icon: "heart.fill",
            iconColor: .red,
            title: "Apple Health",
            description: "Connect to sync your health metrics."
        )
        .accessibilityElement(children: .combine)
    }
    
    // MARK: - Bottom Section
    private var bottomSection: some View {
        VStack(spacing: 16) {
            Button(action: {
                Task {
                    isConnecting = true
                    await onConnectTapped()
                    isConnecting = false
                    showCompletion = true
                }
            }) {
                HStack {
                    if isConnecting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Text("Connect to Apple Health")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
                .foregroundColor(Color.MindBuddy.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color(red: 0.12, green: 0.12, blue: 0.12))
                .cornerRadius(28)
                .shadow(color: Color.black.opacity(0.1), radius: 6, y: 4)
            }
            .disabled(isConnecting)
            .accessibilityLabel("Connect to Apple Health")
            .accessibilityHint("Tap to request permission to access your health data")
            
            Text("You can customise what you share in the next step.")
                .font(.system(size: 12))
                .foregroundColor(Color.MindBuddy.textSecondary)
                .multilineTextAlignment(.center)
                .accessibilityLabel("You can customize what you share in the next step")
        }
    }
}

// MARK: - InfoCard Component
private struct InfoCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon Container
            ZStack {
                Circle()
                    .fill(Color.MindBuddy.numberBackground)
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(iconColor)
            }
            .mindBuddyCardShadow()
            
            // Text Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.MindBuddy.textPrimary)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(Color.MindBuddy.textSecondary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(20)
        .background(Color.MindBuddy.cardBackground)
        .cornerRadius(16)
        .mindBuddyCardShadow()
    }
}

// MARK: - HealthKit Manager Extension
extension ConnectAppleHealthView {
    static func requestHealthKitAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }
        
        let healthStore = HKHealthStore()
        
        // Define the health data types we want to read
        let typesToRead: Set<HKObjectType> = [
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKQuantityType.quantityType(forIdentifier: .restingHeartRate)!,
            HKQuantityType.quantityType(forIdentifier: .stepCount)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .basalEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKQuantityType.quantityType(forIdentifier: .appleExerciseTime)!,
            HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKCategoryType.categoryType(forIdentifier: .mindfulSession)!
        ]
        
        try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
    }
    
    enum HealthKitError: LocalizedError {
        case notAvailable
        
        var errorDescription: String? {
            switch self {
            case .notAvailable:
                return "Health data is not available on this device"
            }
        }
    }
}

// MARK: - Preview
struct ConnectAppleHealthView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ConnectAppleHealthView(
                onConnectTapped: {
                    // Preview action
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                }
            )
            .previewDisplayName("iPhone 15 Pro")
            
            ConnectAppleHealthView(
                onConnectTapped: {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                }
            )
            .previewDevice("iPhone SE (3rd generation)")
            .previewDisplayName("iPhone SE")
        }
    }
}