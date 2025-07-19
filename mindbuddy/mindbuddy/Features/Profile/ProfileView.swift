import SwiftUI

struct ProfileView: View {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var userService = UserService.shared
    @State private var isEditing = false
    @State private var editedProfile = UserProfile(id: 0, firebaseUID: "", email: "", firstName: "", lastName: "")
    @State private var showingImagePicker = false
    @State private var showingLogoutAlert = false
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showingError = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    ProfileHeaderSection(
                        profile: userService.currentUserProfile ?? editedProfile,
                        isEditing: isEditing,
                        showingImagePicker: $showingImagePicker
                    )
                    
                    // User Information Section
                    UserInformationSection(
                        profile: $editedProfile,
                        isEditing: isEditing
                    )
                    
                    // Account Statistics
                    if !isEditing {
                        AccountStatisticsSection()
                    }
                    
                    // Connected Services
                    if !isEditing {
                        ConnectedServicesSection()
                    }
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        if isEditing {
                            HStack(spacing: 12) {
                                Button(action: cancelEditing) {
                                    Text("Cancel")
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color(.systemGray5))
                                        .foregroundColor(.primary)
                                        .cornerRadius(12)
                                }
                                
                                Button(action: saveProfile) {
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .frame(maxWidth: .infinity)
                                    } else {
                                        Text("Save Changes")
                                            .frame(maxWidth: .infinity)
                                    }
                                }
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .disabled(isLoading)
                            }
                        } else {
                            Button(action: { isEditing = true }) {
                                Label("Edit Profile", systemImage: "pencil")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                        }
                        
                        if !isEditing {
                            Button(action: { showingLogoutAlert = true }) {
                                Label("Sign Out", systemImage: "arrow.right.door.fill")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(.systemGray5))
                                    .foregroundColor(.red)
                                    .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    Spacer(minLength: 50)
                }
                .padding(.top)
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isEditing {
                        Button("Cancel") {
                            cancelEditing()
                        }
                    }
                }
            }
            .alert("Sign Out", isPresented: $showingLogoutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    authManager.logout()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showingImagePicker) {
                // Image picker implementation would go here
                Text("Image Picker")
                    .onTapGesture {
                        showingImagePicker = false
                    }
            }
            .onAppear {
                loadUserProfile()
            }
        }
    }
    
    private func loadUserProfile() {
        if let profile = userService.currentUserProfile {
            editedProfile = profile
        } else if let user = authManager.currentUser {
            editedProfile = UserProfile(
                id: 0,
                firebaseUID: user.uid,
                email: user.email ?? "",
                firstName: user.firstName ?? "",
                lastName: user.lastName ?? ""
            )
        }
    }
    
    private func cancelEditing() {
        isEditing = false
        loadUserProfile()
    }
    
    private func saveProfile() {
        isLoading = true
        
        Task {
            do {
                try await userService.updateProfile(editedProfile)
                await MainActor.run {
                    isEditing = false
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Profile Header Section

struct ProfileHeaderSection: View {
    let profile: UserProfile
    let isEditing: Bool
    @Binding var showingImagePicker: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Profile Image
            ZStack(alignment: .bottomTrailing) {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .foregroundColor(.gray)
                
                if isEditing {
                    Button(action: { showingImagePicker = true }) {
                        Image(systemName: "camera.fill")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.blue)
                            .clipShape(Circle())
                    }
                    .offset(x: -10, y: -10)
                }
            }
            
            // Name and Email
            VStack(spacing: 4) {
                Text("\(profile.firstName) \(profile.lastName)")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(profile.email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - User Information Section

struct UserInformationSection: View {
    @Binding var profile: UserProfile
    let isEditing: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Personal Information")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                ProfileInfoRow(
                    label: "First Name",
                    value: $profile.firstName,
                    isEditing: isEditing,
                    icon: "person.fill"
                )
                
                ProfileInfoRow(
                    label: "Last Name",
                    value: $profile.lastName,
                    isEditing: isEditing,
                    icon: "person.fill"
                )
                
                ProfileInfoRow(
                    label: "Email",
                    value: .constant(profile.email),
                    isEditing: false, // Email is not editable
                    icon: "envelope.fill"
                )
            }
            .padding(.horizontal)
        }
    }
}

struct ProfileInfoRow: View {
    let label: String
    @Binding var value: String
    let isEditing: Bool
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(label, systemImage: icon)
                .font(.caption)
                .foregroundColor(.secondary)
            
            if isEditing && label != "Email" {
                TextField(label, text: $value)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            } else {
                Text(value.isEmpty ? "-" : value)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
        }
    }
}

// MARK: - Account Statistics Section

struct AccountStatisticsSection: View {
    @StateObject private var rewardsManager = RewardsManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Account Statistics")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    StatisticCard(
                        title: "Total Earned",
                        value: "\(rewardsManager.formatTokenAmount(rewardsManager.totalEarned))",
                        unit: "MNDY",
                        icon: "bitcoinsign.circle.fill",
                        color: .orange
                    )
                    
                    StatisticCard(
                        title: "Member Since",
                        value: membershipDuration,
                        unit: "",
                        icon: "calendar",
                        color: .blue
                    )
                    
                    StatisticCard(
                        title: "Streak",
                        value: "7",
                        unit: "days",
                        icon: "flame.fill",
                        color: .red
                    )
                    
                    StatisticCard(
                        title: "Health Score",
                        value: "85",
                        unit: "%",
                        icon: "heart.fill",
                        color: .green
                    )
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var membershipDuration: String {
        // Calculate based on user creation date
        return "3 months"
    }
}

struct StatisticCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(width: 120)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Connected Services Section

struct ConnectedServicesSection: View {
    @StateObject private var authManager = AuthManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Connected Services")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                ConnectedServiceRow(
                    service: "Apple Health",
                    icon: "heart.fill",
                    color: .red,
                    isConnected: true
                )
                
                if let provider = authManager.currentUser?.providerID {
                    if provider.contains("apple") {
                        ConnectedServiceRow(
                            service: "Sign in with Apple",
                            icon: "applelogo",
                            color: .black,
                            isConnected: true
                        )
                    } else if provider.contains("google") {
                        ConnectedServiceRow(
                            service: "Google Account",
                            icon: "g.circle.fill",
                            color: .red,
                            isConnected: true
                        )
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct ConnectedServiceRow: View {
    let service: String
    let icon: String
    let color: Color
    let isConnected: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40)
            
            Text(service)
                .font(.body)
            
            Spacer()
            
            if isConnected {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                    Text("Connected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                Button("Connect") {
                    // Handle connection
                }
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(6)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

#Preview {
    ProfileView()
}