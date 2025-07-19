import SwiftUI
import HealthKit

struct HealthView: View {
    @StateObject private var viewModel = HealthViewModel()
    @State private var showingHealthKitPermission = false
    
    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading && viewModel.collectedData.isEmpty {
                    ProgressView("Loading health data...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Health Authorization Status
                            HealthAuthorizationCard(
                                viewModel: viewModel,
                                showingHealthKitPermission: $showingHealthKitPermission
                            )
                            
                            // Health Data Overview
                            if viewModel.authorizationStatus == .sharingAuthorized {
                                HealthDataTypesSection(viewModel: viewModel)
                                
                                // Collected Data Summary
                                if !viewModel.collectedData.isEmpty {
                                    CollectedDataSummary(viewModel: viewModel)
                                }
                                
                                // Action Buttons
                                VStack(spacing: 12) {
                                    Button(action: {
                                        Task {
                                            await viewModel.collectHealthData()
                                        }
                                    }) {
                                        Label("Collect Health Data", systemImage: "arrow.down.circle.fill")
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color.blue)
                                            .foregroundColor(.white)
                                            .cornerRadius(12)
                                    }
                                    .disabled(viewModel.isLoading || viewModel.selectedDataTypes.isEmpty)
                                    
                                    Button(action: {
                                        Task {
                                            await viewModel.submitHealthData()
                                        }
                                    }) {
                                        HStack {
                                            if viewModel.isSubmitting {
                                                ProgressView()
                                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                    .scaleEffect(0.8)
                                            } else {
                                                Label("Submit to Earn Rewards", systemImage: "cloud.fill")
                                            }
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(viewModel.collectedData.isEmpty ? Color.gray : Color.green)
                                        .foregroundColor(.white)
                                        .cornerRadius(12)
                                    }
                                    .disabled(viewModel.isSubmitting || viewModel.collectedData.isEmpty)
                                }
                                .padding(.horizontal)
                                
                                // Last submission result
                                if let result = viewModel.submissionResult {
                                    SubmissionResultCard(result: result)
                                }
                            } else {
                                // Not authorized state
                                EmptyStateView(
                                    icon: "heart.text.square",
                                    title: "Health Access Required",
                                    description: "Grant access to your health data to start earning rewards"
                                )
                                .padding()
                            }
                            
                            Spacer()
                        }
                        .padding(.top)
                    }
                    .navigationTitle("Health Data")
                    .refreshable {
                        await viewModel.refreshData()
                    }
                }
            }
            .alert("Error", isPresented: $viewModel.hasError) {
                Button("OK") {}
            } message: {
                Text(viewModel.errorMessage)
            }
            .sheet(isPresented: $showingHealthKitPermission) {
                HealthKitPermissionView(isPresented: $showingHealthKitPermission)
                    .onDisappear {
                        viewModel.checkAuthorizationStatus()
                    }
            }
        }
    }
}

// MARK: - Health Authorization Card

struct HealthAuthorizationCard: View {
    @ObservedObject var viewModel: HealthViewModel
    @Binding var showingHealthKitPermission: Bool
    
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
                
                if viewModel.authorizationStatus == .sharingAuthorized {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                }
            }
            
            if viewModel.authorizationStatus != .sharingAuthorized {
                Button(action: {
                    showingHealthKitPermission = true
                }) {
                    Text("Request Access")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private var statusText: String {
        switch viewModel.authorizationStatus {
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
}

// MARK: - Health Data Types Section

struct HealthDataTypesSection: View {
    @ObservedObject var viewModel: HealthViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Select Data Types")
                    .font(.headline)
                
                Spacer()
                
                Text("\(viewModel.selectedDataTypes.count) selected")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(viewModel.availableDataTypes) { dataTypeInfo in
                    HealthDataTypeCard(
                        dataTypeInfo: dataTypeInfo,
                        isSelected: viewModel.selectedDataTypes.contains(dataTypeInfo.type),
                        action: {
                            viewModel.toggleDataType(dataTypeInfo.type)
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
}

struct HealthDataTypeCard: View {
    let dataTypeInfo: HealthDataTypeInfo
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: dataTypeInfo.icon)
                        .font(.title2)
                        .foregroundColor(dataTypeInfo.isAvailable ? dataTypeInfo.color : .gray)
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(dataTypeInfo.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(dataTypeInfo.isAvailable ? .primary : .secondary)
                    
                    Text(dataTypeInfo.description)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .disabled(!dataTypeInfo.isAvailable)
    }
}

// MARK: - Collected Data Summary

struct CollectedDataSummary: View {
    @ObservedObject var viewModel: HealthViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Collected Data")
                .font(.headline)
                .padding(.horizontal)
            
            // Summary cards
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(summarizedData, id: \.type) { summary in
                        DataSummaryCard(
                            type: summary.type,
                            count: summary.count,
                            icon: summary.icon,
                            color: summary.color
                        )
                    }
                }
                .padding(.horizontal)
            }
            
            // Estimated rewards
            HStack {
                Label("Estimated Rewards", systemImage: "bitcoinsign.circle.fill")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("+\(String(format: "%.2f", estimatedRewards)) MNDY")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
        }
    }
    
    private var summarizedData: [(type: String, count: Int, icon: String, color: Color)] {
        let grouped = Dictionary(grouping: viewModel.collectedData) { $0.type }
        return grouped.map { (key, value) in
            let dataType = HealthDataType(rawValue: key) ?? .heartRate
            return (
                type: dataType.displayName,
                count: value.count,
                icon: dataType.icon,
                color: dataType.color
            )
        }
    }
    
    private var estimatedRewards: Double {
        let rewards: [String: Double] = [
            "heartRate": 0.1,
            "hrv": 0.15,
            "steps": 0.05,
            "sleep": 1.0,
            "bloodPressure": 0.2,
            "calories": 0.05
        ]
        
        return viewModel.collectedData.reduce(0) { total, data in
            total + (rewards[data.type] ?? 0.1)
        }
    }
}

struct DataSummaryCard: View {
    let type: String
    let count: Int
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text("\(count)")
                .font(.headline)
                .fontWeight(.bold)
            
            Text(type)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(width: 100)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// MARK: - Submission Result Card

struct SubmissionResultCard: View {
    let result: SubmissionResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(result.success ? .green : .red)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.success ? "Success!" : "Failed")
                        .font(.headline)
                    
                    Text(result.message)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            if result.success && result.tokensEarned > 0 {
                HStack {
                    Text("Tokens Earned")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("+\(String(format: "%.2f", result.tokensEarned)) MNDY")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(result.success ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(result.success ? Color.green : Color.red, lineWidth: 1)
        )
        .padding(.horizontal)
    }
}

// MARK: - Supporting Views

struct EmptyStateView: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

#Preview {
    HealthView()
}