import SwiftUI
import HealthKit

struct HealthKitPermissionView: View {
    @StateObject private var healthManager = HealthManager.shared
    @State private var isRequestingPermission = false
    @State private var permissionStatus: HealthKitPermissionStatus = .notDetermined
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.94, green: 0.96, blue: 1.0),
                        Color(red: 0.96, green: 0.94, blue: 1.0)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // Icon and title
                    VStack(spacing: 20) {
                        Image(systemName: "heart.text.square.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.red)
                            .shadow(color: .red.opacity(0.3), radius: 20, x: 0, y: 10)
                        
                        Text("Connect Apple Health")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("To provide personalized insights and rewards, MindBuddy needs access to your health data.")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 40)
                    }
                    
                    // Health data types list
                    VStack(alignment: .leading, spacing: 15) {
                        Text("We'll track:")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(healthDataTypes, id: \.title) { dataType in
                            HStack(spacing: 15) {
                                Image(systemName: dataType.icon)
                                    .font(.title3)
                                    .foregroundColor(dataType.color)
                                    .frame(width: 30)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(dataType.title)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text(dataType.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical, 20)
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(15)
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Action buttons
                    VStack(spacing: 12) {
                        Button(action: requestHealthKitPermission) {
                            if isRequestingPermission {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(12)
                            } else {
                                Text(permissionButtonText)
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(permissionButtonColor)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                        }
                        .disabled(isRequestingPermission || permissionStatus == .authorized)
                        
                        if permissionStatus != .authorized {
                            Button("Skip for Now") {
                                isPresented = false
                            }
                            .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 30)
                }
            }
            .navigationBarItems(trailing: Button("Done") {
                isPresented = false
            })
        }
        .onAppear {
            checkHealthKitAuthorization()
        }
    }
    
    private func requestHealthKitPermission() {
        isRequestingPermission = true
        
        Task {
            do {
                try await healthManager.requestAuthorization()
                let authorized = healthManager.isAuthorized
                await MainActor.run {
                    permissionStatus = authorized ? .authorized : .denied
                    isRequestingPermission = false
                    
                    if authorized {
                        // Automatically dismiss after a short delay when authorized
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            isPresented = false
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    permissionStatus = .error
                    isRequestingPermission = false
                }
            }
        }
    }
    
    private func checkHealthKitAuthorization() {
        if HKHealthStore.isHealthDataAvailable() {
            // Check current authorization status
            let healthStore = HKHealthStore()
            let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
            
            switch healthStore.authorizationStatus(for: heartRateType) {
            case .sharingAuthorized:
                permissionStatus = .authorized
            case .sharingDenied:
                permissionStatus = .denied
            default:
                permissionStatus = .notDetermined
            }
        } else {
            permissionStatus = .unavailable
        }
    }
    
    private var permissionButtonText: String {
        switch permissionStatus {
        case .notDetermined:
            return "Allow Access"
        case .authorized:
            return "Access Granted ✓"
        case .denied:
            return "Open Settings to Allow Access"
        case .unavailable:
            return "Health Data Unavailable"
        case .error:
            return "Try Again"
        }
    }
    
    private var permissionButtonColor: Color {
        switch permissionStatus {
        case .notDetermined, .error:
            return .blue
        case .authorized:
            return .green
        case .denied:
            return .orange
        case .unavailable:
            return .gray
        }
    }
}

// MARK: - Supporting Types

enum HealthKitPermissionStatus {
    case notDetermined
    case authorized
    case denied
    case unavailable
    case error
}

struct HealthDataTypeInfo {
    let title: String
    let description: String
    let icon: String
    let color: Color
}

private let healthDataTypes = [
    HealthDataTypeInfo(
        title: "Heart Rate",
        description: "Monitor your heart health",
        icon: "heart.fill",
        color: .red
    ),
    HealthDataTypeInfo(
        title: "Heart Rate Variability",
        description: "Track stress and recovery",
        icon: "waveform.path.ecg",
        color: .purple
    ),
    HealthDataTypeInfo(
        title: "Steps",
        description: "Count your daily activity",
        icon: "figure.walk",
        color: .green
    ),
    HealthDataTypeInfo(
        title: "Sleep Analysis",
        description: "Understand your rest patterns",
        icon: "bed.double.fill",
        color: .blue
    )
]

struct HealthKitPermissionView_Previews: PreviewProvider {
    static var previews: some View {
        HealthKitPermissionView(isPresented: .constant(true))
    }
}