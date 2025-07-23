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
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.98, green: 0.98, blue: 0.98),
                    Color(red: 0.95, green: 0.95, blue: 0.95)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    // Top spacing
                    Spacer()
                        .frame(height: 60)
                    
                    // Logo and Title
                    VStack(spacing: 20) {
                        // Logo circle
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 0.5, green: 0.4, blue: 1.0),
                                            Color(red: 0.7, green: 0.5, blue: 1.0)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)
                                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                            
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: 8) {
                            Text("Welcome Back")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(Color(red: 0.05, green: 0.06, blue: 0.1))
                            
                            Text("Track your stress. Earn rewards. Own your data.")
                                .font(.system(size: 16))
                                .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.45))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                    }
                    
                    // Main content card
                    VStack(spacing: 24) {
                        // SSO Buttons
                        VStack(spacing: 16) {
                            // Google Sign In
                            Button(action: signInWithGoogle) {
                                HStack(spacing: 12) {
                                    if isGoogleLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "globe")
                                            .font(.system(size: 18))
                                            .foregroundColor(.black)
                                    }
                                    
                                    Text("Continue with Google")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.black)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
                            }
                            .disabled(isGoogleLoading)
                            
                            // Apple Sign In
                            Button(action: signInWithApple) {
                                HStack(spacing: 12) {
                                    if isAppleLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "applelogo")
                                            .font(.system(size: 18))
                                            .foregroundColor(.white)
                                    }
                                    
                                    Text("Continue with Apple")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(Color.black)
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
                            }
                            .disabled(isAppleLoading)
                        }
                        
                        // Divider
                        HStack(spacing: 16) {
                            Rectangle()
                                .fill(Color(red: 0.85, green: 0.85, blue: 0.85))
                                .frame(height: 1)
                            
                            Text("OR")
                                .font(.system(size: 14))
                                .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.65))
                            
                            Rectangle()
                                .fill(Color(red: 0.85, green: 0.85, blue: 0.85))
                                .frame(height: 1)
                        }
                        
                        // Email/Password Form
                        VStack(spacing: 16) {
                            // Email field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.25))
                                
                                TextField("Enter your email", text: $email)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .padding(16)
                                    .background(Color.white)
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color(red: 0.9, green: 0.9, blue: 0.92), lineWidth: 1)
                                    )
                                    .textContentType(.emailAddress)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                            }
                            
                            // Password field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.25))
                                
                                SecureField("Enter your password", text: $password)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .padding(16)
                                    .background(Color.white)
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color(red: 0.9, green: 0.9, blue: 0.92), lineWidth: 1)
                                    )
                                    .textContentType(.password)
                            }
                            
                            // Forgot password link
                            HStack {
                                Spacer()
                                Button(action: {}) {
                                    Text("Forgot password?")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color(red: 0.5, green: 0.4, blue: 1.0))
                                }
                            }
                            .padding(.top, -8)
                            
                            // Error message
                            if !errorMessage.isEmpty {
                                Text(errorMessage)
                                    .font(.system(size: 14))
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                            }
                            
                            // Sign in button
                            Button(action: login) {
                                HStack {
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    } else {
                                        Text("Sign In")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 0.5, green: 0.4, blue: 1.0),
                                            Color(red: 0.7, green: 0.5, blue: 1.0)
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .shadow(color: Color(red: 0.5, green: 0.4, blue: 1.0).opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                            .disabled(isLoading || email.isEmpty || password.isEmpty)
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Register Link
                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .font(.system(size: 16))
                            .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.45))
                        
                        Button(action: { showingRegister = true }) {
                            Text("Sign up")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(red: 0.5, green: 0.4, blue: 1.0))
                        }
                    }
                    .padding(.top, 8)
                    
                    // Bottom spacing
                    Spacer()
                        .frame(height: 40)
                }
                .padding(.horizontal, 20)
            }
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