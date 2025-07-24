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
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email, password
    }
    
    var body: some View {
        ZStack {
            // Background color from design
            Color(hex: "#FAFAFA")
                .ignoresSafeArea()
                .onTapGesture {
                    focusedField = nil
                }
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 32) {
                    // Top spacing
                    Spacer()
                        .frame(height: 60)
                    
                    // Logo and Title
                    VStack(spacing: 20) {
                        // Logo from design
                        ZStack {
                            RoundedRectangle(cornerRadius: 19.35)
                                .fill(Color(hex: "#682960"))
                                .frame(width: 72, height: 72)
                            
                            RoundedRectangle(cornerRadius: 24.94)
                                .stroke(Color(hex: "#EBEBEB").opacity(0.5), lineWidth: 11.18)
                                .frame(width: 83.34, height: 83.34)
                            
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 36))
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: 8) {
                            Text("Welcome Back")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(Color(hex: "#050F19"))
                            
                            Text("Track your stress. Earn rewards. Own your data.")
                                .font(.system(size: 16))
                                .foregroundColor(Color(hex: "#666666"))
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
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(hex: "#E5E5E7"), lineWidth: 1)
                                )
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
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(hex: "#E5E5E7"), lineWidth: 1)
                                )
                            }
                            .disabled(isAppleLoading)
                        }
                        
                        // Divider
                        HStack(spacing: 16) {
                            Rectangle()
                                .fill(Color(hex: "#E5E5E7"))
                                .frame(height: 1)
                            
                            Text("OR")
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "#999999"))
                            
                            Rectangle()
                                .fill(Color(hex: "#E5E5E7"))
                                .frame(height: 1)
                        }
                        
                        // Email/Password Form
                        VStack(spacing: 16) {
                            // Email field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color(hex: "#333333"))
                                
                                TextField("Enter your email", text: $email)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .padding(16)
                                    .background(Color(hex: "#EEF0F4"))
                                    .cornerRadius(28.5)
                                    .textContentType(.emailAddress)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .focused($focusedField, equals: .email)
                                    .submitLabel(.next)
                                    .onSubmit {
                                        focusedField = .password
                                    }
                            }
                            
                            // Password field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color(hex: "#333333"))
                                
                                SecureField("Enter your password", text: $password)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .padding(16)
                                    .background(Color(hex: "#EEF0F4"))
                                    .cornerRadius(28.5)
                                    .textContentType(.password)
                                    .focused($focusedField, equals: .password)
                                    .submitLabel(.go)
                                    .onSubmit {
                                        if !email.isEmpty && !password.isEmpty {
                                            login()
                                        }
                                    }
                            }
                            
                            // Forgot password link
                            HStack {
                                Spacer()
                                Button(action: {}) {
                                    Text("Forgot password?")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color(hex: "#682960"))
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
                                .background(Color(hex: "#682960"))
                                .foregroundColor(.white)
                                .cornerRadius(28.5)
                            }
                            .disabled(isLoading || email.isEmpty || password.isEmpty)
                            .opacity((isLoading || email.isEmpty || password.isEmpty) ? 0.6 : 1.0)
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Register Link
                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "#666666"))
                        
                        Button(action: { showingRegister = true }) {
                            Text("Sign up")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(hex: "#682960"))
                        }
                    }
                    .padding(.top, 8)
                    
                    // Bottom spacing
                    Spacer()
                        .frame(height: 40)
                }
                .padding(.horizontal, 20)
            }
            .scrollDismissesKeyboard(.interactively)
            .ignoresSafeArea(.keyboard, edges: .bottom)
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