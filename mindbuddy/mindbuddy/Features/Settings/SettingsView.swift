import SwiftUI

struct SettingsView: View {
    @StateObject private var authManager = AuthManager.shared
    @State private var showingLogoutAlert = false
    @State private var showingProfile = false
    @State private var showingNotifications = false
    @State private var showingPrivacy = false
    @State private var showingHelp = false
    @State private var showingAbout = false
    @AppStorage("appTheme") private var appTheme = "system"
    @AppStorage("hapticFeedback") private var hapticFeedback = true
    
    var body: some View {
        NavigationView {
            List {
                // Profile Section
                Section {
                    Button(action: { showingProfile = true }) {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                                .frame(width: 60, height: 60)
                            
                            VStack(alignment: .leading) {
                                Text(authManager.currentUser?.fullName ?? "Unknown User")
                                    .font(.headline)
                                    .foregroundColor(.primary)
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
                }
                
                // Account Section
                Section("Account") {
                    Button(action: { showingNotifications = true }) {
                        SettingsRow(
                            icon: "bell.badge.fill",
                            title: "Notifications",
                            subtitle: "Manage your alerts"
                        )
                    }
                    
                    Button(action: { showingPrivacy = true }) {
                        SettingsRow(
                            icon: "lock.shield.fill",
                            title: "Privacy & Security",
                            subtitle: "Control your data"
                        )
                    }
                    
                    NavigationLink(destination: WalletSettingsView()) {
                        SettingsRow(
                            icon: "bitcoinsign.circle.fill",
                            title: "Wallet",
                            subtitle: "Connect your crypto wallet"
                        )
                    }
                }
                
                // Preferences Section
                Section("Preferences") {
                    HStack {
                        Image(systemName: "moon.fill")
                            .font(.title2)
                            .foregroundColor(.indigo)
                            .frame(width: 32, height: 32)
                        
                        Text("Theme")
                        
                        Spacer()
                        
                        Picker("Theme", selection: $appTheme) {
                            Text("System").tag("system")
                            Text("Light").tag("light")
                            Text("Dark").tag("dark")
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 150)
                    }
                    
                    Toggle(isOn: $hapticFeedback) {
                        HStack {
                            Image(systemName: "hand.tap.fill")
                                .font(.title2)
                                .foregroundColor(.purple)
                                .frame(width: 32, height: 32)
                            
                            Text("Haptic Feedback")
                        }
                    }
                }
                
                // Health Section
                Section("Health") {
                    NavigationLink(destination: HealthPermissionsView()) {
                        SettingsRow(
                            icon: "heart.text.square.fill",
                            title: "Health Permissions",
                            subtitle: "Manage HealthKit access"
                        )
                    }
                    
                    NavigationLink(destination: AppleWatchSettingsView()) {
                        SettingsRow(
                            icon: "applewatch",
                            title: "Apple Watch",
                            subtitle: "Sync settings"
                        )
                    }
                }
                
                // Support Section
                Section("Support") {
                    Button(action: { showingHelp = true }) {
                        SettingsRow(
                            icon: "questionmark.circle.fill",
                            title: "Help & Support",
                            subtitle: "Get help with MindBuddy"
                        )
                    }
                    
                    Button(action: { showingAbout = true }) {
                        SettingsRow(
                            icon: "info.circle.fill",
                            title: "About",
                            subtitle: "Version 1.0"
                        )
                    }
                    
                    Button(action: openAppStore) {
                        SettingsRow(
                            icon: "star.fill",
                            title: "Rate MindBuddy",
                            subtitle: "Share your feedback"
                        )
                    }
                }
                
                // Logout Section
                Section {
                    Button(action: {
                        showingLogoutAlert = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.right.door.fill")
                                .foregroundColor(.red)
                            Text("Sign Out")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Sign Out", isPresented: $showingLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    authManager.logout()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .sheet(isPresented: $showingProfile) {
                ProfileView()
            }
            .sheet(isPresented: $showingNotifications) {
                NotificationSettingsView()
            }
            .sheet(isPresented: $showingPrivacy) {
                PrivacySettingsView()
            }
            .sheet(isPresented: $showingHelp) {
                HelpAndSupportView()
            }
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
        }
    }
    
    private func openAppStore() {
        if let url = URL(string: "https://apps.apple.com/app/mindbuddy/id123456789") {
            UIApplication.shared.open(url)
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

// MARK: - Placeholder Views

struct WalletSettingsView: View {
    var body: some View {
        Text("Wallet Settings - Coming Soon")
            .navigationTitle("Wallet")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct HealthPermissionsView: View {
    var body: some View {
        Text("Health Permissions Settings")
            .navigationTitle("Health Permissions")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct AppleWatchSettingsView: View {
    var body: some View {
        Text("Apple Watch Settings")
            .navigationTitle("Apple Watch")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct AboutView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // App Icon and Version
                    VStack(spacing: 12) {
                        Image(systemName: "heart.circle.fill")
                            .resizable()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.red)
                        
                        Text("MindBuddy")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Version 1.0.0")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)
                    
                    // Description
                    Text("MindBuddy is your personal wellness companion that helps you track health metrics, manage stress, and earn rewards for healthy habits.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // Links
                    VStack(spacing: 12) {
                        Link("Terms of Service", destination: URL(string: "https://mindbuddy.health/terms")!)
                        Link("Privacy Policy", destination: URL(string: "https://mindbuddy.health/privacy")!)
                        Link("Website", destination: URL(string: "https://mindbuddy.health")!)
                    }
                    .font(.subheadline)
                    
                    // Credits
                    VStack(spacing: 8) {
                        Text("Made with ❤️ in San Francisco")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("© 2025 MindBuddy Inc.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        // Dismiss handled by sheet
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}