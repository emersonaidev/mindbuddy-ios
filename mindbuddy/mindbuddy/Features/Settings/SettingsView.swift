import SwiftUI

struct SettingsView: View {
    @StateObject private var authManager = AuthManager.shared
    @State private var showingLogoutAlert = false
    
    var body: some View {
        NavigationView {
            List {
                // Profile Section
                Section("Profile") {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.title)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading) {
                            Text(authManager.currentUser?.fullName ?? "Unknown User")
                                .font(.headline)
                            Text(authManager.currentUser?.email ?? "")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if authManager.currentUser?.isVerified == true {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // Account Section
                Section("Account") {
                    SettingsRow(
                        icon: "bitcoinsign.circle",
                        title: "Wallet",
                        subtitle: "Connect your crypto wallet"
                    )
                    
                    SettingsRow(
                        icon: "bell",
                        title: "Notifications",
                        subtitle: "Manage your alerts"
                    )
                    
                    SettingsRow(
                        icon: "lock",
                        title: "Privacy & Security",
                        subtitle: "Control your data"
                    )
                }
                
                // Health Section
                Section("Health") {
                    SettingsRow(
                        icon: "heart.circle",
                        title: "Health Permissions",
                        subtitle: "Manage HealthKit access"
                    )
                    
                    SettingsRow(
                        icon: "applewatch",
                        title: "Apple Watch",
                        subtitle: "Sync settings"
                    )
                }
                
                // Support Section
                Section("Support") {
                    SettingsRow(
                        icon: "questionmark.circle",
                        title: "Help & Support",
                        subtitle: "Get help with MindBuddy"
                    )
                    
                    SettingsRow(
                        icon: "info.circle",
                        title: "About",
                        subtitle: "Version 1.0"
                    )
                }
                
                // Logout Section
                Section {
                    Button(action: {
                        showingLogoutAlert = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.right.square")
                                .foregroundColor(.red)
                            Text("Logout")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Logout", isPresented: $showingLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Logout", role: .destructive) {
                    authManager.logout()
                }
            } message: {
                Text("Are you sure you want to logout?")
            }
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    SettingsView()
}