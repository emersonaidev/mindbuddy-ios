import Foundation

// MARK: - Validation Result

enum ValidationResult {
    case valid
    case invalid(message: String)
    
    var isValid: Bool {
        switch self {
        case .valid:
            return true
        case .invalid:
            return false
        }
    }
    
    var errorMessage: String? {
        switch self {
        case .valid:
            return nil
        case .invalid(let message):
            return message
        }
    }
}

// MARK: - Validation Utilities

class ValidationUtilities {
    
    // MARK: - Email Validation
    
    static func validateEmail(_ email: String) -> ValidationResult {
        guard !email.isEmpty else {
            return .invalid(message: "Email is required")
        }
        
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        guard emailPredicate.evaluate(with: email) else {
            return .invalid(message: "Please enter a valid email address")
        }
        
        return .valid
    }
    
    // MARK: - Password Validation
    
    static func validatePassword(_ password: String) -> ValidationResult {
        guard !password.isEmpty else {
            return .invalid(message: "Password is required")
        }
        
        guard password.count >= 6 else {
            return .invalid(message: "Password must be at least 6 characters")
        }
        
        // Optional: Add more complex password requirements
        if password.count >= 8 {
            // Check for at least one uppercase, one lowercase, and one number
            let hasUppercase = password.rangeOfCharacter(from: .uppercaseLetters) != nil
            let hasLowercase = password.rangeOfCharacter(from: .lowercaseLetters) != nil
            let hasNumber = password.rangeOfCharacter(from: .decimalDigits) != nil
            
            if hasUppercase && hasLowercase && hasNumber {
                return .valid // Strong password
            }
        }
        
        return .valid // Minimum requirements met
    }
    
    // MARK: - Name Validation
    
    static func validateName(_ name: String, fieldName: String = "Name") -> ValidationResult {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .invalid(message: "\(fieldName) is required")
        }
        
        guard name.count >= 2 else {
            return .invalid(message: "\(fieldName) must be at least 2 characters")
        }
        
        guard name.count <= 50 else {
            return .invalid(message: "\(fieldName) must be less than 50 characters")
        }
        
        return .valid
    }
    
    // MARK: - Health Data Validation
    
    static func validateHeartRate(_ heartRate: Double) -> ValidationResult {
        guard heartRate > 0 else {
            return .invalid(message: "Heart rate must be greater than 0")
        }
        
        guard heartRate >= 30 && heartRate <= 250 else {
            return .invalid(message: "Heart rate must be between 30 and 250 BPM")
        }
        
        return .valid
    }
    
    static func validateBloodPressure(systolic: Double, diastolic: Double) -> ValidationResult {
        guard systolic > 0 && diastolic > 0 else {
            return .invalid(message: "Blood pressure values must be greater than 0")
        }
        
        guard systolic >= 70 && systolic <= 250 else {
            return .invalid(message: "Systolic pressure must be between 70 and 250 mmHg")
        }
        
        guard diastolic >= 40 && diastolic <= 150 else {
            return .invalid(message: "Diastolic pressure must be between 40 and 150 mmHg")
        }
        
        guard systolic > diastolic else {
            return .invalid(message: "Systolic pressure must be higher than diastolic pressure")
        }
        
        return .valid
    }
    
    static func validateSteps(_ steps: Int) -> ValidationResult {
        guard steps >= 0 else {
            return .invalid(message: "Steps cannot be negative")
        }
        
        guard steps <= 100000 else {
            return .invalid(message: "Steps seem unrealistic (max 100,000)")
        }
        
        return .valid
    }
    
    // MARK: - General Validation
    
    static func validateRequired(_ value: String, fieldName: String) -> ValidationResult {
        guard !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .invalid(message: "\(fieldName) is required")
        }
        return .valid
    }
    
    static func validateLength(_ value: String, min: Int, max: Int, fieldName: String) -> ValidationResult {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard trimmed.count >= min else {
            return .invalid(message: "\(fieldName) must be at least \(min) characters")
        }
        
        guard trimmed.count <= max else {
            return .invalid(message: "\(fieldName) must be less than \(max) characters")
        }
        
        return .valid
    }
}

// MARK: - String Extensions for Validation

extension String {
    
    var isValidEmail: Bool {
        return ValidationUtilities.validateEmail(self).isValid
    }
    
    var emailValidationMessage: String? {
        return ValidationUtilities.validateEmail(self).errorMessage
    }
    
    var isValidPassword: Bool {
        return ValidationUtilities.validatePassword(self).isValid
    }
    
    var passwordValidationMessage: String? {
        return ValidationUtilities.validatePassword(self).errorMessage
    }
    
    func isValidName(fieldName: String = "Name") -> Bool {
        return ValidationUtilities.validateName(self, fieldName: fieldName).isValid
    }
    
    func nameValidationMessage(fieldName: String = "Name") -> String? {
        return ValidationUtilities.validateName(self, fieldName: fieldName).errorMessage
    }
}

// MARK: - Password Strength Indicator

enum PasswordStrength {
    case weak
    case medium
    case strong
    
    var description: String {
        switch self {
        case .weak:
            return "Weak"
        case .medium:
            return "Medium"
        case .strong:
            return "Strong"
        }
    }
    
    var color: String {
        switch self {
        case .weak:
            return "red"
        case .medium:
            return "orange"
        case .strong:
            return "green"
        }
    }
}

extension ValidationUtilities {
    
    static func passwordStrength(_ password: String) -> PasswordStrength {
        guard password.count >= 6 else { return .weak }
        
        let hasUppercase = password.rangeOfCharacter(from: .uppercaseLetters) != nil
        let hasLowercase = password.rangeOfCharacter(from: .lowercaseLetters) != nil
        let hasNumber = password.rangeOfCharacter(from: .decimalDigits) != nil
        let hasSpecial = password.rangeOfCharacter(from: CharacterSet.punctuationCharacters.union(.symbols)) != nil
        
        let criteriaCount = [hasUppercase, hasLowercase, hasNumber, hasSpecial].filter { $0 }.count
        
        if password.count >= 12 && criteriaCount >= 3 {
            return .strong
        } else if password.count >= 8 && criteriaCount >= 2 {
            return .medium
        } else {
            return .weak
        }
    }
}