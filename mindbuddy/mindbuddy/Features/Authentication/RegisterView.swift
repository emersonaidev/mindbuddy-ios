import SwiftUI

struct RegisterView: View {
    @StateObject private var authManager = AuthManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        
                        Text("Create Account")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Join MindBuddy and start earning rewards for your health data")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.bottom, 32)
                    
                    // Registration Form
                    VStack(spacing: 16) {
                        HStack(spacing: 12) {
                            TextField("First Name", text: $firstName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .textContentType(.givenName)
                            
                            TextField("Last Name", text: $lastName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .textContentType(.familyName)
                        }
                        
                        TextField("Email", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                        
                        SecureField("Password", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textContentType(.newPassword)
                        
                        SecureField("Confirm Password", text: $confirmPassword)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textContentType(.newPassword)
                        
                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                        
                        // Password Requirements
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Password Requirements:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Image(systemName: password.count >= 8 ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(password.count >= 8 ? .green : .gray)
                                Text("At least 8 characters")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Image(systemName: password.rangeOfCharacter(from: .uppercaseLetters) != nil ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(password.rangeOfCharacter(from: .uppercaseLetters) != nil ? .green : .gray)
                                Text("One uppercase letter")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Image(systemName: password.rangeOfCharacter(from: .lowercaseLetters) != nil ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(password.rangeOfCharacter(from: .lowercaseLetters) != nil ? .green : .gray)
                                Text("One lowercase letter")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Image(systemName: password.rangeOfCharacter(from: .decimalDigits) != nil ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(password.rangeOfCharacter(from: .decimalDigits) != nil ? .green : .gray)
                                Text("One number")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                let specialChars = CharacterSet(charactersIn: "!@#$%^&*(),.?\":{}|<>")
                                Image(systemName: password.rangeOfCharacter(from: specialChars) != nil ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(password.rangeOfCharacter(from: specialChars) != nil ? .green : .gray)
                                Text("One special character (!@#$%^&*(),.?\":{}|<>)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 8)
                        
                        Button(action: register) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Text("Create Account")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(isLoading || !isFormValid)
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Sign Up")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !firstName.isEmpty &&
        !lastName.isEmpty &&
        !email.isEmpty &&
        password.count >= 8 &&
        password == confirmPassword &&
        isPasswordValid
    }
    
    private var isPasswordValid: Bool {
        let specialChars = CharacterSet(charactersIn: "!@#$%^&*(),.?\":{}|<>")
        return password.count >= 8 &&
               password.rangeOfCharacter(from: .uppercaseLetters) != nil &&
               password.rangeOfCharacter(from: .lowercaseLetters) != nil &&
               password.rangeOfCharacter(from: .decimalDigits) != nil &&
               password.rangeOfCharacter(from: specialChars) != nil
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

#Preview {
    RegisterView()
}