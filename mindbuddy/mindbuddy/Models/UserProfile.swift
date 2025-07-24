import Foundation

struct UserProfile: Codable, Identifiable {
    let id: Int
    var firebaseUID: String
    var email: String
    var firstName: String
    var lastName: String
    var createdAt: Date?
    var updatedAt: Date?
    
    var displayName: String {
        let fullName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespacesAndNewlines)
        return fullName.isEmpty ? email : fullName
    }
}