import Foundation

// MARK: - Network Service

class NetworkService: NetworkServiceProtocol {
    private let session = URLSession.shared
    private let cacheService: CacheServiceProtocol
    
    init(cacheService: CacheServiceProtocol) {
        self.cacheService = cacheService
    }
    
    func request<T: Codable>(
        endpoint: String,
        method: HTTPMethod,
        body: Data?,
        headers: [String: String],
        responseType: T.Type,
        requiresAuth: Bool,
        isRetry: Bool
    ) async throws -> T {
        // This is a simplified implementation
        // In production, this would handle the actual network requests
        // For now, we'll delegate to APIClient.shared
        return try await APIClient.shared.request(
            endpoint: endpoint,
            method: method,
            body: body,
            headers: headers,
            responseType: responseType,
            requiresAuth: requiresAuth
        )
    }
}