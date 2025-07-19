import SwiftUI

struct PrivacySettingsView: View {
    @State private var shareHealthData = true
    @State private var shareAnonymousData = true
    @State private var allowPersonalizedRecommendations = true
    @State private var allowDataForResearch = false
    @State private var enableFaceID = true
    @State private var requireAuthForRewards = true
    @State private var showingDeleteAccountAlert = false
    @State private var showingExportDataSheet = false
    @State private var exportFormat = ExportFormat.json
    @State private var isExporting = false
    
    enum ExportFormat: String, CaseIterable {
        case json = "JSON"
        case csv = "CSV"
        case pdf = "PDF"
        
        var description: String {
            switch self {
            case .json: return "Machine-readable format"
            case .csv: return "Spreadsheet compatible"
            case .pdf: return "Human-readable report"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Data Sharing Section
                Section {
                    PrivacyToggleRow(
                        title: "Share Health Data",
                        description: "Allow MindBuddy to access and store your health data",
                        icon: "heart.text.square.fill",
                        iconColor: .red,
                        isOn: $shareHealthData
                    )
                    
                    PrivacyToggleRow(
                        title: "Anonymous Analytics",
                        description: "Help improve MindBuddy with anonymous usage data",
                        icon: "chart.bar.xaxis",
                        iconColor: .purple,
                        isOn: $shareAnonymousData
                    )
                    
                    PrivacyToggleRow(
                        title: "Personalized Insights",
                        description: "Get tailored health recommendations",
                        icon: "brain",
                        iconColor: .blue,
                        isOn: $allowPersonalizedRecommendations
                    )
                    
                    PrivacyToggleRow(
                        title: "Research Contribution",
                        description: "Allow anonymized data for health research",
                        icon: "graduationcap.fill",
                        iconColor: .green,
                        isOn: $allowDataForResearch
                    )
                } header: {
                    Text("Data Sharing")
                } footer: {
                    Text("Control how your health data is used and shared. Your data is always encrypted and protected.")
                }
                
                // Security Section
                Section {
                    PrivacyToggleRow(
                        title: "Face ID / Touch ID",
                        description: "Require authentication to open app",
                        icon: "faceid",
                        iconColor: .green,
                        isOn: $enableFaceID
                    )
                    
                    PrivacyToggleRow(
                        title: "Secure Rewards",
                        description: "Require authentication for token transactions",
                        icon: "lock.fill",
                        iconColor: .orange,
                        isOn: $requireAuthForRewards
                    )
                } header: {
                    Text("Security")
                }
                
                // Data Management Section
                Section {
                    // View Privacy Policy
                    Button(action: openPrivacyPolicy) {
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .foregroundColor(.blue)
                                .frame(width: 28)
                            
                            Text("Privacy Policy")
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // View Terms of Service
                    Button(action: openTermsOfService) {
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .foregroundColor(.blue)
                                .frame(width: 28)
                            
                            Text("Terms of Service")
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Export Data
                    Button(action: { showingExportDataSheet = true }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up.fill")
                                .foregroundColor(.green)
                                .frame(width: 28)
                            
                            VStack(alignment: .leading) {
                                Text("Export My Data")
                                    .foregroundColor(.primary)
                                Text("Download all your health and reward data")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if isExporting {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                    }
                    .disabled(isExporting)
                    
                    // Delete Account
                    Button(action: { showingDeleteAccountAlert = true }) {
                        HStack {
                            Image(systemName: "trash.fill")
                                .foregroundColor(.red)
                                .frame(width: 28)
                            
                            Text("Delete Account")
                                .foregroundColor(.red)
                        }
                    }
                } header: {
                    Text("Data Management")
                }
                
                // Information Section
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Your Privacy Matters", systemImage: "lock.shield.fill")
                            .font(.headline)
                            .foregroundColor(.blue)
                        
                        Text("MindBuddy is committed to protecting your privacy. All health data is encrypted end-to-end and stored securely. We never sell your personal information to third parties.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Image(systemName: "checkmark.shield.fill")
                                .foregroundColor(.green)
                            Text("HIPAA Compliant")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        
                        HStack {
                            Image(systemName: "checkmark.shield.fill")
                                .foregroundColor(.green)
                            Text("End-to-End Encryption")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        
                        HStack {
                            Image(systemName: "checkmark.shield.fill")
                                .foregroundColor(.green)
                            Text("GDPR Compliant")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Privacy")
            .alert("Delete Account", isPresented: $showingDeleteAccountAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deleteAccount()
                }
            } message: {
                Text("Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently removed.")
            }
            .sheet(isPresented: $showingExportDataSheet) {
                ExportDataSheet(
                    exportFormat: $exportFormat,
                    isExporting: $isExporting,
                    onExport: exportData
                )
            }
        }
    }
    
    private func openPrivacyPolicy() {
        if let url = URL(string: "https://mindbuddy.health/privacy") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openTermsOfService() {
        if let url = URL(string: "https://mindbuddy.health/terms") {
            UIApplication.shared.open(url)
        }
    }
    
    private func exportData() {
        isExporting = true
        
        // Simulate export process
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isExporting = false
            showingExportDataSheet = false
            // In real app, would trigger actual export
        }
    }
    
    private func deleteAccount() {
        // In real app, would trigger account deletion
        print("Account deletion requested")
    }
}

// MARK: - Privacy Toggle Row

struct PrivacyToggleRow: View {
    let title: String
    let description: String
    let icon: String
    let iconColor: Color
    @Binding var isOn: Bool
    
    var body: some View {
        Toggle(isOn: $isOn) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.title3)
                    .frame(width: 28)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - Export Data Sheet

struct ExportDataSheet: View {
    @Binding var exportFormat: PrivacySettingsView.ExportFormat
    @Binding var isExporting: Bool
    let onExport: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Image(systemName: "square.and.arrow.up.fill")
                        .font(.largeTitle)
                        .foregroundColor(.green)
                    
                    Text("Export Your Data")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Choose a format to download all your health data and reward history")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top)
                
                // Format Selection
                VStack(spacing: 12) {
                    ForEach(PrivacySettingsView.ExportFormat.allCases, id: \.self) { format in
                        Button(action: { exportFormat = format }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(format.rawValue)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text(format.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if exportFormat == format {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(exportFormat == format ? Color.blue.opacity(0.1) : Color(.systemGray6))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(exportFormat == format ? Color.blue : Color.clear, lineWidth: 2)
                            )
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Export Button
                Button(action: onExport) {
                    if isExporting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Export Data")
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(isExporting)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    PrivacySettingsView()
}