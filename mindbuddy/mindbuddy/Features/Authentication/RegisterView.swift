import SwiftUI

struct RegisterView: View {
    @StateObject private var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    
    init(authManager: AuthManager = DependencyContainer.shared.authService as! AuthManager) {
        self._authManager = StateObject(wrappedValue: authManager)
    }
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
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
                            .frame(height: 20)
                        
                        // Header
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
                                
                                Image(systemName: "person.badge.plus")
                                    .font(.system(size: 36))
                                    .foregroundColor(.white)
                            }
                            
                            VStack(spacing: 8) {
                                Text("Create Account")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(Color(red: 0.05, green: 0.06, blue: 0.1))
                                
                                Text("Join MindBuddy and start earning rewards")
                                    .font(.system(size: 16))
                                    .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.45))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            }
                        }
                        
                        // Registration Form
                        VStack(spacing: 16) {
                            // Name fields
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("First Name")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.25))
                                    
                                    TextField("First", text: $firstName)
                                        .textFieldStyle(PlainTextFieldStyle())
                                        .padding(16)
                                        .background(Color.white)
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color(red: 0.9, green: 0.9, blue: 0.92), lineWidth: 1)
                                        )
                                        .textContentType(.givenName)
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Last Name")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.25))
                                    
                                    TextField("Last", text: $lastName)
                                        .textFieldStyle(PlainTextFieldStyle())
                                        .padding(16)
                                        .background(Color.white)
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color(red: 0.9, green: 0.9, blue: 0.92), lineWidth: 1)
                                        )
                                        .textContentType(.familyName)
                                }
                            }
                            
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
                                
                                SecureField("Create a password", text: $password)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .padding(16)
                                    .background(Color.white)
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color(red: 0.9, green: 0.9, blue: 0.92), lineWidth: 1)
                                    )
                                    .textContentType(.newPassword)
                            }
                            
                            // Confirm Password field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Confirm Password")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.25))
                                
                                SecureField("Confirm your password", text: $confirmPassword)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .padding(16)
                                    .background(Color.white)
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color(red: 0.9, green: 0.9, blue: 0.92), lineWidth: 1)
                                    )
                                    .textContentType(.newPassword)
                            }
                            
                            // Password Requirements (compact)
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 16) {
                                    PasswordRequirement(
                                        icon: password.count >= 8 ? "checkmark.circle.fill" : "circle",
                                        text: "8+ characters",
                                        isMet: password.count >= 8
                                    )
                                    
                                    PasswordRequirement(
                                        icon: password.rangeOfCharacter(from: .uppercaseLetters) != nil ? "checkmark.circle.fill" : "circle",
                                        text: "Uppercase",
                                        isMet: password.rangeOfCharacter(from: .uppercaseLetters) != nil
                                    )
                                }
                                
                                HStack(spacing: 16) {
                                    PasswordRequirement(
                                        icon: password.rangeOfCharacter(from: .lowercaseLetters) != nil ? "checkmark.circle.fill" : "circle",
                                        text: "Lowercase",
                                        isMet: password.rangeOfCharacter(from: .lowercaseLetters) != nil
                                    )
                                    
                                    PasswordRequirement(
                                        icon: password.rangeOfCharacter(from: .decimalDigits) != nil ? "checkmark.circle.fill" : "circle",
                                        text: "Number",
                                        isMet: password.rangeOfCharacter(from: .decimalDigits) != nil
                                    )
                                }
                                
                                let specialChars = CharacterSet(charactersIn: "!@#$%^&*(),.?\":{}|<>")
                                PasswordRequirement(
                                    icon: password.rangeOfCharacter(from: specialChars) != nil ? "checkmark.circle.fill" : "circle",
                                    text: "Special character",
                                    isMet: password.rangeOfCharacter(from: specialChars) != nil
                                )
                            }
                            .padding(.vertical, 8)
                            
                            // Error message
                            if !errorMessage.isEmpty {
                                Text(errorMessage)
                                    .font(.system(size: 14))
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                            }
                            
                            // Create Account button
                            Button(action: register) {
                                HStack {
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    } else {
                                        Text("Create Account")
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
                            .disabled(isLoading || !isFormValid)
                            .padding(.top, 8)
                        }
                        .padding(.horizontal, 24)
                        
                        // Bottom spacing
                        Spacer()
                            .frame(height: 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16))
                            .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.45))
                            .padding(8)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    }
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        ValidationUtilities.validateName(firstName, fieldName: "First name").isValid &&
        ValidationUtilities.validateName(lastName, fieldName: "Last name").isValid &&
        ValidationUtilities.validateEmail(email).isValid &&
        ValidationUtilities.validatePassword(password).isValid &&
        password == confirmPassword
    }
    
    private var passwordStrength: PasswordStrength {
        ValidationUtilities.passwordStrength(password)
    }
    
    private func register() {
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                _ = try await authManager.register(
                    email: email,
                    password: password,
                    firstName: firstName,
                    lastName: lastName
                )
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

struct PasswordRequirement: View {
    let icon: String
    let text: String
    let isMet: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(isMet ? Color(red: 0.2, green: 0.7, blue: 0.3) : Color(red: 0.7, green: 0.7, blue: 0.75))
            
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.45))
        }
    }
}

#Preview {
    RegisterView()
}