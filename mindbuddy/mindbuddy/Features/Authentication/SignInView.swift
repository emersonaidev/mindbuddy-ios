import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @StateObject private var authManager = AuthManager.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var sizeClass
    
    // Form State
    @State private var email = ""
    @State private var password = ""
    @State private var isPasswordVisible = false
    
    // Validation State
    @State private var emailError: String?
    @State private var passwordError: String?
    @State private var generalError: String?
    
    // UI State
    @State private var isSigningIn = false
    @State private var isSocialSigningIn = false
    @State private var showingForgotPassword = false
    @State private var showingPasswordResetAlert = false
    @State private var passwordResetMessage = ""
    @State private var keyboardHeight: CGFloat = 0
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email
        case password
    }
    
    // MARK: - Computed Properties
    private var horizontalPadding: CGFloat {
        sizeClass == .compact ? 24 : 48
    }
    
    private var maxContentWidth: CGFloat {
        sizeClass == .compact ? .infinity : 600
    }
    
    private var isFormValid: Bool {
        !email.isEmpty && 
        !password.isEmpty && 
        emailError == nil &&
        passwordError == nil
    }
    
    var body: some View {
        ZStack {
            // Background
            backgroundGradient
            
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    headerSection
                        .padding(.top, 60)
                    
                    // Social Login Section
                    socialLoginSection
                        .padding(.top, 40)
                    
                    // Divider
                    dividerSection
                        .padding(.top, 32)
                    
                    // Form Fields
                    formSection
                        .padding(.top, 32)
                    
                    // Forgot Password
                    forgotPasswordButton
                        .padding(.top, 16)
                    
                    // Sign In Button
                    signInButton
                        .padding(.top, 40)
                    
                    // Sign Up Link
                    signUpLink
                        .padding(.top, 24)
                        .padding(.bottom, max(40, keyboardHeight))
                }
                .padding(.horizontal, horizontalPadding)
                .frame(maxWidth: maxContentWidth)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
        .navigationBarHidden(true)
        .alert("Password Reset", isPresented: $showingPasswordResetAlert) {
            Button("OK") { }
        } message: {
            Text(passwordResetMessage)
        }
        .alert("Sign In Error", isPresented: .constant(generalError != nil)) {
            Button("OK") {
                generalError = nil
            }
        } message: {
            Text(generalError ?? "An error occurred")
        }
        .sheet(isPresented: $showingForgotPassword) {
            ForgotPasswordView()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                withAnimation(.easeOut(duration: 0.3)) {
                    keyboardHeight = keyboardFrame.height
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeOut(duration: 0.3)) {
                keyboardHeight = 0
            }
        }
    }
    
    // MARK: - Background
    private var backgroundGradient: some View {
        ZStack {
            Color.MindBuddy.background
                .ignoresSafeArea()
            
            GeometryReader { geometry in
                // Top purple gradient
                Circle()
                    .fill(Color.MindBuddy.primaryAccent.opacity(0.30))
                    .frame(width: min(520, geometry.size.width * 1.3))
                    .blur(radius: 64)
                    .offset(x: -33, y: -geometry.size.height * 0.34)
                
                // Bottom pink gradient
                Circle()
                    .fill(Color.MindBuddy.secondaryAccent.opacity(0.25))
                    .frame(width: min(620, geometry.size.width * 1.5))
                    .blur(radius: 64)
                    .offset(x: -34, y: geometry.size.height * 0.29)
            }
        }
    }
    
    // MARK: - View Components
    private var headerSection: some View {
        Text("Sign In")
            .font(.system(size: 30, weight: .semibold))
            .foregroundColor(Color.MindBuddy.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }
    
    private var socialLoginSection: some View {
        VStack(spacing: 16) {
            // Google Sign In
            Button(action: signInWithGoogle) {
                HStack(spacing: 12) {
                    // Google Icon - Replace with actual Google logo from Assets
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 24, height: 24)
                        
                        Text("G")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 0.26, green: 0.52, blue: 0.96))
                    }
                    .accessibilityHidden(true)
                    
                    Text("Continue with Google")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.black)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.white)
                .cornerRadius(28)
                .mindBuddyCardShadow()
            }
            .disabled(isSocialSigningIn)
            .accessibilityLabel("Sign in with Google")
            
            // Apple Sign In
            Button(action: signInWithApple) {
                HStack(spacing: 8) {
                    Image(systemName: "apple.logo")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                    
                    Text("Continue with Apple")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color(red: 0.10, green: 0.10, blue: 0.10))
                .cornerRadius(28)
                .mindBuddyCardShadow()
            }
            .disabled(isSocialSigningIn)
            .accessibilityLabel("Sign in with Apple")
        }
    }
    
    private var dividerSection: some View {
        HStack(spacing: 16) {
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1)
            
            Text("or continue with")
                .font(.system(size: 12))
                .foregroundColor(Color.MindBuddy.textSecondary)
                .fixedSize()
            
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1)
        }
    }
    
    private var formSection: some View {
        VStack(spacing: 24) {
            // Email Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(.system(size: 14))
                    .foregroundColor(Color.MindBuddy.textPrimary)
                
                TextField("Enter your email", text: $email)
                    .textFieldStyle(MindBuddyTextFieldStyle())
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .focused($focusedField, equals: .email)
                    .onChange(of: email) { _ in
                        validateEmail()
                    }
                    .onSubmit {
                        focusedField = .password
                    }
                    .accessibilityLabel("Email input field")
                
                if let error = emailError {
                    Text(error)
                        .font(.system(size: 12))
                        .foregroundColor(Color.MindBuddy.error)
                        .transition(.opacity)
                }
            }
            
            // Password Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Password")
                    .font(.system(size: 14))
                    .foregroundColor(Color.MindBuddy.textPrimary)
                
                HStack {
                    if isPasswordVisible {
                        TextField("Enter your password", text: $password)
                            .textFieldStyle(MindBuddyTextFieldStyle(showBackground: false))
                            .textContentType(.password)
                            .focused($focusedField, equals: .password)
                    } else {
                        SecureField("Enter your password", text: $password)
                            .textFieldStyle(MindBuddyTextFieldStyle(showBackground: false))
                            .textContentType(.password)
                            .focused($focusedField, equals: .password)
                    }
                    
                    Button(action: {
                        isPasswordVisible.toggle()
                    }) {
                        Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(Color.MindBuddy.textSecondary)
                            .frame(width: 24, height: 24)
                    }
                    .accessibilityLabel(isPasswordVisible ? "Hide password" : "Show password")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.MindBuddy.cardBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .onChange(of: password) { _ in
                    validatePassword()
                }
                .onSubmit {
                    signIn()
                }
                
                if let error = passwordError {
                    Text(error)
                        .font(.system(size: 12))
                        .foregroundColor(Color.MindBuddy.error)
                        .transition(.opacity)
                }
            }
        }
    }
    
    private var forgotPasswordButton: some View {
        HStack {
            Spacer()
            Button(action: {
                showingForgotPassword = true
            }) {
                Text("Forgot password?")
                    .font(.system(size: 12))
                    .foregroundColor(Color.MindBuddy.textSecondary)
            }
        }
    }
    
    private var signInButton: some View {
        Button(action: signIn) {
            HStack {
                if isSigningIn {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Text("Sign In")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .foregroundColor(Color.MindBuddy.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                isFormValid && !isSigningIn ? 
                Color.black : 
                Color.black.opacity(0.5)
            )
            .cornerRadius(28)
            .mindBuddyButtonShadow()
        }
        .disabled(!isFormValid || isSigningIn)
        .accessibilityLabel("Sign in button")
        .accessibilityHint(isFormValid ? "Double tap to sign in" : "Fill in all fields to enable")
    }
    
    private var signUpLink: some View {
        HStack(spacing: 4) {
            Text("Don't have an account?")
                .font(.system(size: 14))
                .foregroundColor(Color.MindBuddy.textSecondary)
            
            NavigationLink(destination: CreateAccountView()) {
                Text("Sign Up")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.MindBuddy.textPrimary)
            }
        }
    }
    
    // MARK: - Actions
    private func signIn() {
        guard isFormValid else { return }
        
        isSigningIn = true
        generalError = nil
        focusedField = nil
        
        Task {
            do {
                _ = try await authManager.login(email: email, password: password)
                
                // Navigation will be handled by the AuthManager's published properties
            } catch {
                await MainActor.run {
                    isSigningIn = false
                    handleSignInError(error)
                }
            }
        }
    }
    
    private func signInWithGoogle() {
        isSocialSigningIn = true
        generalError = nil
        
        Task {
            do {
                _ = try await authManager.signInWithGoogle()
                
                // Handle successful sign in
            } catch {
                await MainActor.run {
                    isSocialSigningIn = false
                    generalError = "Failed to sign in with Google. Please try again."
                }
            }
        }
    }
    
    private func signInWithApple() {
        isSocialSigningIn = true
        generalError = nil
        
        Task {
            do {
                _ = try await authManager.signInWithApple()
                
                // Handle successful sign in
            } catch {
                await MainActor.run {
                    isSocialSigningIn = false
                    generalError = "Failed to sign in with Apple. Please try again."
                }
            }
        }
    }
    
    private func handleSignInError(_ error: Error) {
        // Handle specific Firebase/Auth errors
        if let nsError = error as NSError? {
            switch nsError.code {
            case 17009: // Wrong password
                passwordError = "Incorrect password"
            case 17011: // User not found
                emailError = "No account found with this email"
            case 17008: // Invalid email
                emailError = "Please enter a valid email address"
            default:
                generalError = "Failed to sign in. Please try again."
            }
        } else {
            generalError = error.localizedDescription
        }
    }
    
    // MARK: - Validation
    private func validateEmail() {
        if !email.isEmpty {
            let result = ValidationUtilities.validateEmail(email)
            emailError = result.errorMessage
        } else {
            emailError = nil
        }
    }
    
    private func validatePassword() {
        if !password.isEmpty && password.count < 6 {
            passwordError = "Password must be at least 6 characters"
        } else {
            passwordError = nil
        }
    }
}

// MARK: - Supporting Views
struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var emailError: String?
    @State private var isLoading = false
    @State private var showSuccessAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.MindBuddy.background
                    .ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 24) {
                    Text("Reset your password")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(Color.MindBuddy.textPrimary)
                        .padding(.top, 20)
                    
                    Text("Enter your email address and we'll send you instructions to reset your password.")
                        .font(.system(size: 14))
                        .foregroundColor(Color.MindBuddy.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.system(size: 14))
                            .foregroundColor(Color.MindBuddy.textPrimary)
                        
                        TextField("Enter your email", text: $email)
                            .textFieldStyle(MindBuddyTextFieldStyle())
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .onChange(of: email) { _ in
                                if !email.isEmpty {
                                    let result = ValidationUtilities.validateEmail(email)
                                    emailError = result.errorMessage
                                }
                            }
                        
                        if let error = emailError {
                            Text(error)
                                .font(.system(size: 12))
                                .foregroundColor(Color.MindBuddy.error)
                        }
                    }
                    
                    Button(action: resetPassword) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Text("Send Reset Email")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            !email.isEmpty && emailError == nil ? 
                            Color.black : 
                            Color.black.opacity(0.5)
                        )
                        .cornerRadius(28)
                    }
                    .disabled(email.isEmpty || emailError != nil || isLoading)
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color.MindBuddy.textPrimary)
                }
            }
            .alert("Password Reset", isPresented: $showSuccessAlert) {
                Button("OK") {
                    if alertMessage.contains("sent") {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func resetPassword() {
        guard !email.isEmpty && emailError == nil else { return }
        
        isLoading = true
        
        Task {
            do {
                try await AuthManager.shared.resetPassword(email: email)
                
                await MainActor.run {
                    isLoading = false
                    alertMessage = "Password reset email sent! Check your inbox."
                    showSuccessAlert = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    alertMessage = "Failed to send reset email. Please try again."
                    showSuccessAlert = true
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        SignInView()
    }
}