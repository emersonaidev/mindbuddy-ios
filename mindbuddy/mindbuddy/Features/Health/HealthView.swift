import SwiftUI
import HealthKit

struct HealthView: View {
    @StateObject private var healthManager = HealthManager.shared
    @State private var isRequestingPermission = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isSubmittingData = false
    @State private var lastSubmissionResult: HealthDataBatchResponse?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Health Authorization Status
                    HealthAuthorizationCard()
                    
                    // Health Data Overview
                    if healthManager.authorizationStatus == .sharingAuthorized {
                        HealthDataOverview()
                        
                        // Submit Data Button
                        Button(action: submitHealthData) {
                            HStack {
                                if isSubmittingData {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "cloud.fill")
                                    Text("Submit Health Data")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(isSubmittingData)
                        .padding(.horizontal)
                        
                        // Last submission result
                        if let result = lastSubmissionResult {
                            SubmissionResultCard(result: result)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.top)
            }
            .navigationTitle("Health Data")
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func submitHealthData() {
        isSubmittingData = true
        
        Task {
            do {
                let endDate = Date()
                let startDate = Calendar.current.date(byAdding: .hour, value: -1, to: endDate) ?? endDate
                
                // Fetch recent health data
                let heartRateData = try await healthManager.fetchHeartRateData(from: startDate, to: endDate)
                let hrvData = try await healthManager.fetchHRVData(from: startDate, to: endDate)
                let stepsData = try await healthManager.fetchStepsData(from: startDate, to: endDate)
                
                // Submit all health data
                let allHealthData = heartRateData + hrvData + stepsData
                
                // Submit to backend
                if !allHealthData.isEmpty {
                    try await healthManager.submitHealthDataBatch(allHealthData)
                }
                
                await MainActor.run {
                    self.lastSubmissionResult = HealthDataBatchResponse(
                        submitted: allHealthData.count,
                        tokensEarned: "10",
                        errors: nil
                    )
                    self.isSubmittingData = false
                }
                
            } catch {
                await MainActor.run {
                    self.isSubmittingData = false
                    self.errorMessage = error.localizedDescription
                    self.showingError = true
                }
            }
        }
    }
}

struct HealthAuthorizationCard: View {
    @StateObject private var healthManager = HealthManager.shared
    @State private var isRequestingPermission = false
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "heart.fill")
                    .font(.title2)
                    .foregroundColor(.red)
                
                VStack(alignment: .leading) {
                    Text("Health Data Access")
                        .font(.headline)
                    
                    Text(statusText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            if healthManager.authorizationStatus != .sharingAuthorized {
                Button(action: requestPermission) {
                    HStack {
                        if isRequestingPermission {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Text("Request Access")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(isRequestingPermission)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private var statusText: String {
        switch healthManager.authorizationStatus {
        case .notDetermined:
            return "Tap to request access to your health data"
        case .sharingAuthorized:
            return "Access granted - Ready to sync data"
        case .sharingDenied:
            return "Access denied - Please enable in Settings"
        @unknown default:
            return "Unknown status"
        }
    }
    
    private func requestPermission() {
        isRequestingPermission = true
        
        Task {
            do {
                try await healthManager.requestAuthorization()
                await MainActor.run {
                    self.isRequestingPermission = false
                }
            } catch {
                await MainActor.run {
                    self.isRequestingPermission = false
                }
            }
        }
    }
}

struct HealthDataOverview: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Available Data Types")
                .font(.headline)
                .padding(.horizontal)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                HealthDataTypeCard(
                    title: "Heart Rate",
                    icon: "heart.fill",
                    color: .red,
                    isAvailable: true
                )
                
                HealthDataTypeCard(
                    title: "HRV",
                    icon: "waveform.path.ecg",
                    color: .orange,
                    isAvailable: true
                )
                
                HealthDataTypeCard(
                    title: "Steps",
                    icon: "figure.walk",
                    color: .blue,
                    isAvailable: true
                )
                
                HealthDataTypeCard(
                    title: "Sleep",
                    icon: "bed.double.fill",
                    color: .purple,
                    isAvailable: false
                )
            }
            .padding(.horizontal)
        }
    }
}

struct HealthDataTypeCard: View {
    let title: String
    let icon: String
    let color: Color
    let isAvailable: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(isAvailable ? color : .gray)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isAvailable ? .primary : .secondary)
            
            Text(isAvailable ? "Available" : "Coming Soon")
                .font(.caption)
                .foregroundColor(isAvailable ? .green : .orange)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct SubmissionResultCard: View {
    let result: HealthDataBatchResponse
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Submission Result")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Data Points Submitted")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(result.submitted)")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Tokens Earned")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(result.tokensEarned) MNDY")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
            }
            
            if let errors = result.errors, !errors.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Errors:")
                        .font(.caption)
                        .foregroundColor(.red)
                    
                    ForEach(errors.prefix(3), id: \.index) { error in
                        Text("• \(error.error)")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

#Preview {
    HealthView()
}