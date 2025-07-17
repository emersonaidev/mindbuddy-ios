import SwiftUI

struct LoginView: View {
    @StateObject private var authManager = AuthManager.shared
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showingRegister = false
    @State private var isGoogleLoading = false
    @State private var isAppleLoading = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    Spacer()
                    
                    // Logo and Title
                    VStack(spacing: 16) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.red)
                        
                        Text("MindBuddy")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Your stress monitoring companion")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.bottom, 32)
                    
                    // SSO Section (moved to top)
                    VStack(spacing: 16) {
                        VStack(spacing: 12) {
                            SSOButton(
                                provider: .google,
                                action: signInWithGoogle,
                                isLoading: isGoogleLoading
                            )
                            
                            SSOButton(
                                provider: .apple,
                                action: signInWithApple,
                                isLoading: isAppleLoading
                            )
                        }
                        
                        HStack {
                            VStack { Divider() }
                            Text("OR")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                            VStack { Divider() }
                        }
                        .padding(.vertical, 8)
                    }
                    .padding(.horizontal, 24)
                    
                    // Email/Password Login Form (moved to bottom)
                    VStack(spacing: 16) {
                        TextField("Email", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                        
                        SecureField("Password", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textContentType(.password)
                        
                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                        
                        Button(action: login) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Text("Login")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(isLoading || email.isEmpty || password.isEmpty)
                    }
                    .padding(.horizontal, 24)
                    
                    // Register Link
                    Button(action: { showingRegister = true }) {
                        Text("Don't have an account? Sign up")
                            .foregroundColor(.blue)
                    }
                    .padding(.top, 16)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Welcome Back")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingRegister) {
            RegisterView()
        }
    }
    
    private func login() {
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                _ = try await authManager.login(email: email, password: password)
                await MainActor.run {
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func signInWithGoogle() {
        isGoogleLoading = true
        errorMessage = ""
        
        Task {
            do {
                _ = try await authManager.signInWithGoogle()
                await MainActor.run {
                    isGoogleLoading = false
                }
            } catch {
                await MainActor.run {
                    isGoogleLoading = false
                    errorMessage = "Google Sign In failed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func signInWithApple() {
        isAppleLoading = true
        errorMessage = ""
        
        Task {
            do {
                _ = try await authManager.signInWithApple()
                await MainActor.run {
                    isAppleLoading = false
                }
            } catch {
                await MainActor.run {
                    isAppleLoading = false
                    errorMessage = "Apple Sign In failed: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    LoginView()
}