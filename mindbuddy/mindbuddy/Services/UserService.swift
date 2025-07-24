import Foundation
import Combine

@MainActor
class UserService: ObservableObject {
    static let shared = UserService()
    
    @Published var currentUserProfile: UserProfile?
    @Published var isLoading = false
    @Published var error: Error?
    
    private let apiClient = APIClient.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Subscribe to auth changes
        AuthManager.shared.$currentUser
            .sink { [weak self] user in
                if user != nil {
                    Task {
                        await self?.fetchCurrentUserProfile()
                    }
                } else {
                    self?.currentUserProfile = nil
                }
            }
            .store(in: &cancellables)
    }
    
    func fetchCurrentUserProfile() async {
        isLoading = true
        error = nil
        
        do {
            let response = try await apiClient.request(
                endpoint: "/users/profile",
                method: .GET,
                body: nil,
                headers: [:],
                responseType: UserProfile.self,
                requiresAuth: true
            )
            
            await MainActor.run {
                self.currentUserProfile = response
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error
                self.isLoading = false
            }
        }
    }
    
    func updateProfile(_ profile: UserProfile) async throws {
        isLoading = true
        error = nil
        
        do {
            let updateData = UpdateProfileRequest(
                firstName: profile.firstName,
                lastName: profile.lastName
            )
            
            let jsonEncoder = JSONEncoder()
            let body = try jsonEncoder.encode(updateData)
            
            let response = try await apiClient.request(
                endpoint: "/users/profile",
                method: .PUT,
                body: body,
                headers: ["Content-Type": "application/json"],
                responseType: UserProfile.self,
                requiresAuth: true
            )
            
            await MainActor.run {
                self.currentUserProfile = response
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error
                self.isLoading = false
            }
            throw error
        }
    }
}

// MARK: - Request Types

private struct UpdateProfileRequest: Codable {
    let firstName: String
    let lastName: String
}

