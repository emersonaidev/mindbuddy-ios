import SwiftUI
import AuthenticationServices

struct CreateAccountView: View {
    @StateObject private var authManager = AuthManager.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var sizeClass
    
    // Form State
    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isPasswordVisible = false
    @State private var agreedToTerms = false
    
    // Validation State
    @State private var fullNameError: String?
    @State private var emailError: String?
    @State private var passwordError: String?
    @State private var generalError: String?
    
    // UI State
    @State private var isCreatingAccount = false
    @State private var showingTerms = false
    @State private var showingPrivacy = false
    @State private var keyboardHeight: CGFloat = 0
    
    // MARK: - Computed Properties
    private var horizontalPadding: CGFloat {
        sizeClass == .compact ? 24 : 48
    }
    
    private var maxContentWidth: CGFloat {
        sizeClass == .compact ? .infinity : 600
    }
    
    private var firstName: String {
        fullName.components(separatedBy: " ").first ?? ""
    }
    
    private var lastName: String {
        let components = fullName.components(separatedBy: " ")
        return components.count > 1 ? components.dropFirst().joined(separator: " ") : ""
    }
    
    private var isFormValid: Bool {
        !fullName.isEmpty && 
        !email.isEmpty && 
        !password.isEmpty && 
        agreedToTerms &&
        fullNameError == nil &&
        emailError == nil &&
        passwordError == nil
    }
    
    private var passwordStrength: PasswordStrength {
        ValidationUtilities.passwordStrength(password)
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
                    
                    // Terms Agreement
                    termsSection
                        .padding(.top, 24)
                    
                    // Create Account Button
                    createAccountButton
                        .padding(.top, 40)
                    
                    // Sign In Link
                    signInLink
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
        .sheet(isPresented: $showingTerms) {
            TermsOfServiceView()
        }
        .sheet(isPresented: $showingPrivacy) {
            PrivacyPolicyView()
        }
        .alert("Error", isPresented: .constant(generalError != nil)) {
            Button("OK") {
                generalError = nil
            }
        } message: {
            Text(generalError ?? "An error occurred")
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
        Text("Create Account")
            .font(.system(size: 30, weight: .semibold))
            .foregroundColor(Color.MindBuddy.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }
    
    private var socialLoginSection: some View {
        VStack(spacing: 16) {
            // Google Sign In Button
            Button(action: signInWithGoogle) {
                HStack(spacing: 12) {
                    Image("google-logo") // Add Google logo to Assets
                        .resizable()
                        .frame(width: 20, height: 20)
                    
                    Text("Continue with Google")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.black)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.white)
                .cornerRadius(28)
                .mindBuddyCardShadow()
            }
            .disabled(isCreatingAccount)
            
            // Apple Sign In Button with custom image
            Button(action: signInWithApple) {
                Image("apple-signin-button")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 56)
            }
            .disabled(isCreatingAccount)
        }
    }
    
    private var dividerSection: some View {
        HStack(spacing: 16) {
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1)
            
            Text("or create with email")
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
            // Full Name Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Full Name")
                    .font(.system(size: 14))
                    .foregroundColor(Color.MindBuddy.textPrimary)
                
                TextField("Enter your full name", text: $fullName)
                    .textFieldStyle(MindBuddyTextFieldStyle())
                    .textContentType(.name)
                    .autocapitalization(.words)
                    .onChange(of: fullName) { _ in
                        validateFullName()
                    }
                    .accessibilityLabel("Full name input field")
                
                if let error = fullNameError {
                    Text(error)
                        .font(.system(size: 12))
                        .foregroundColor(Color.MindBuddy.error)
                        .transition(.opacity)
                }
            }
            
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
                    .onChange(of: email) { _ in
                        validateEmail()
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
                        TextField("Create a password", text: $password)
                            .textFieldStyle(MindBuddyTextFieldStyle(showBackground: false))
                            .textContentType(.newPassword)
                    } else {
                        SecureField("Create a password", text: $password)
                            .textFieldStyle(MindBuddyTextFieldStyle(showBackground: false))
                            .textContentType(.newPassword)
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
                
                if !password.isEmpty {
                    PasswordStrengthIndicator(strength: passwordStrength)
                        .transition(.opacity)
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
    
    private var termsSection: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: {
                agreedToTerms.toggle()
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.MindBuddy.cardBackground)
                        .frame(width: 20, height: 20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                    
                    if agreedToTerms {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color.MindBuddy.textPrimary)
                            .transition(.scale)
                    }
                }
            }
            .accessibilityLabel("Terms agreement checkbox")
            .accessibilityAddTraits(agreedToTerms ? [.isSelected] : [])
            
            HStack(spacing: 0) {
                Text("I agree to the ")
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 0.40, green: 0.40, blue: 0.40))
                
                Button(action: { showingTerms = true }) {
                    Text("Terms of Service")
                        .font(.system(size: 14))
                        .foregroundColor(Color.MindBuddy.primaryAccent)
                        .underline()
                }
                
                Text(" and ")
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 0.40, green: 0.40, blue: 0.40))
                
                Button(action: { showingPrivacy = true }) {
                    Text("Privacy Policy")
                        .font(.system(size: 14))
                        .foregroundColor(Color.MindBuddy.primaryAccent)
                        .underline()
                }
            }
        }
    }
    
    private var createAccountButton: some View {
        Button(action: createAccount) {
            HStack {
                if isCreatingAccount {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Text("Create Account")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .foregroundColor(Color.MindBuddy.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                isFormValid && !isCreatingAccount ? 
                Color.black : 
                Color.black.opacity(0.5)
            )
            .cornerRadius(28)
            .mindBuddyButtonShadow()
        }
        .disabled(!isFormValid || isCreatingAccount)
        .accessibilityLabel("Create account button")
        .accessibilityHint(isFormValid ? "Double tap to create your account" : "Fill in all fields and agree to terms to enable")
    }
    
    private var signInLink: some View {
        HStack(spacing: 4) {
            Text("Already have an account?")
                .font(.system(size: 14))
                .foregroundColor(Color.MindBuddy.textSecondary)
            
            NavigationLink(destination: SignInView()) {
                Text("Sign In")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.MindBuddy.textSecondary)
            }
        }
    }
    
    // MARK: - Actions
    private func signInWithGoogle() {
        isCreatingAccount = true
        generalError = nil
        
        Task {
            do {
                _ = try await authManager.signInWithGoogle()
                // Navigation will be handled by the AuthManager's published properties
            } catch {
                await MainActor.run {
                    isCreatingAccount = false
                    generalError = "Failed to sign up with Google. Please try again."
                }
            }
        }
    }
    
    private func signInWithApple() {
        isCreatingAccount = true
        generalError = nil
        
        Task {
            do {
                _ = try await authManager.signInWithApple()
                // Navigation will be handled by the AuthManager's published properties
            } catch {
                await MainActor.run {
                    isCreatingAccount = false
                    generalError = "Failed to sign up with Apple. Please try again."
                }
            }
        }
    }
    
    
    private func createAccount() {
        guard isFormValid else { return }
        
        isCreatingAccount = true
        generalError = nil
        
        Task {
            do {
                _ = try await authManager.register(
                    email: email,
                    password: password,
                    firstName: firstName,
                    lastName: lastName
                )
                
                // Navigation will be handled by the AuthManager's published properties
            } catch {
                await MainActor.run {
                    isCreatingAccount = false
                    generalError = error.localizedDescription
                    
                    // Show error alert or handle specific errors
                    handleRegistrationError(error)
                }
            }
        }
    }
    
    private func handleRegistrationError(_ error: Error) {
        // Handle specific Firebase/Auth errors
        if let nsError = error as NSError? {
            switch nsError.code {
            case 17007: // Email already in use
                emailError = "This email is already registered"
            case 17008: // Invalid email
                emailError = "Please enter a valid email address"
            case 17026: // Weak password
                passwordError = "Password is too weak"
            default:
                generalError = "Failed to create account. Please try again."
            }
        }
    }
    
    // MARK: - Validation
    private func validateFullName() {
        let result = ValidationUtilities.validateName(fullName, fieldName: "Full name")
        fullNameError = result.errorMessage
    }
    
    private func validateEmail() {
        let result = ValidationUtilities.validateEmail(email)
        emailError = result.errorMessage
    }
    
    private func validatePassword() {
        let result = ValidationUtilities.validatePassword(password)
        passwordError = result.errorMessage
    }
}

// MARK: - Supporting Views
struct MindBuddyTextFieldStyle: TextFieldStyle {
    var showBackground: Bool = true
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .foregroundColor(Color.MindBuddy.textPrimary)
            .background(showBackground ? Color.MindBuddy.cardBackground : Color.clear)
            .cornerRadius(12)
            .overlay(
                showBackground ? 
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1) : nil
            )
    }
}

struct PasswordStrengthIndicator: View {
    let strength: PasswordStrength
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(strengthColor(for: index))
                    .frame(height: 4)
            }
            
            Text(strength.description)
                .font(.system(size: 12))
                .foregroundColor(strengthTextColor)
        }
        .animation(.easeInOut(duration: 0.2), value: strength)
    }
    
    private func strengthColor(for index: Int) -> Color {
        switch strength {
        case .weak:
            return index == 0 ? Color.MindBuddy.error : Color.white.opacity(0.1)
        case .medium:
            return index <= 1 ? Color.MindBuddy.warning : Color.white.opacity(0.1)
        case .strong:
            return Color.MindBuddy.success
        }
    }
    
    private var strengthTextColor: Color {
        switch strength {
        case .weak:
            return Color.MindBuddy.error
        case .medium:
            return Color.MindBuddy.warning
        case .strong:
            return Color.MindBuddy.success
        }
    }
}

// MARK: - Placeholder Views
// SignInView is now in its own file

struct TermsOfServiceView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                Text("Terms of Service content here...")
                    .padding()
            }
            .navigationTitle("Terms of Service")
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

struct PrivacyPolicyView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                Text("Privacy Policy content here...")
                    .padding()
            }
            .navigationTitle("Privacy Policy")
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

// MARK: - Preview
#Preview {
    NavigationStack {
        CreateAccountView()
    }
}