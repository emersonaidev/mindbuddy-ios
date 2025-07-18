import Foundation

class APIClient: APIClientProtocol {
    static let shared = APIClient()
    
    private let baseURL = "https://mindbuddy-api.onrender.com/api/v1"
    private let session = URLSession.shared
    private let keychainService: KeychainServiceProtocol
    
    init(keychainService: KeychainServiceProtocol = KeychainService.shared) {
        self.keychainService = keychainService
    }
    
    func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod,
        body: Data?,
        headers: [String: String],
        responseType: T.Type,
        requiresAuth: Bool
    ) async throws -> T {
        return try await requestInternal(
            endpoint: endpoint,
            method: method,
            body: body,
            headers: headers,
            responseType: responseType,
            requiresAuth: requiresAuth,
            isRetry: false
        )
    }
    
    private func requestInternal<T: Decodable>(
        endpoint: String,
        method: HTTPMethod,
        body: Data?,
        headers: [String: String],
        responseType: T.Type,
        requiresAuth: Bool,
        isRetry: Bool
    ) async throws -> T {
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body
        
        // Set default headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Add JWT authentication header (except for auth endpoints)
        if requiresAuth && !endpoint.contains("/auth/") {
            if let accessToken = keychainService.getAccessToken() {
                request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            }
        }
        
        // Add custom headers
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        do {
            #if DEBUG
            print("🌐 Making request to: \(url)")
            print("🌐 Method: \(method.rawValue)")
            // Never log request body - may contain sensitive data
            #endif
            
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                #if DEBUG
                print("❌ Invalid HTTP response")
                #endif
                throw APIError.invalidResponse
            }
            
            #if DEBUG
            print("🌐 Response status: \(httpResponse.statusCode)")
            // Never log response body - may contain sensitive data
            #endif
            
            switch httpResponse.statusCode {
            case 200...299:
                return try JSONDecoder().decode(T.self, from: data)
            case 401:
                // Try to refresh token and retry once
                if requiresAuth && !endpoint.contains("/auth/") && !isRetry {
                    do {
                        try await refreshTokenAndRetry()
                        // Retry the request with new token
                        return try await self.requestInternal(endpoint: endpoint, method: method, body: body, headers: headers, responseType: responseType, requiresAuth: requiresAuth, isRetry: true)
                    } catch {
                        throw APIError.unauthorized
                    }
                } else {
                    throw APIError.unauthorized
                }
            case 429:
                // Try to parse rate limit error message
                if let errorResponse = try? JSONDecoder().decode(RateLimitError.self, from: data) {
                    throw APIError.rateLimited(errorResponse.message, retryAfter: errorResponse.retryAfter)
                } else {
                    throw APIError.rateLimited("Rate limit exceeded", retryAfter: nil)
                }
            case 400...499:
                // Try to parse error response
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    throw APIError.clientErrorWithMessage(httpResponse.statusCode, errorResponse.message)
                } else {
                    // Fallback: try to extract any message from the response
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let message = json["message"] as? String {
                        throw APIError.clientErrorWithMessage(httpResponse.statusCode, message)
                    }
                    throw APIError.clientError(httpResponse.statusCode)
                }
            case 500...599:
                // Try to parse error response
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    throw APIError.serverErrorWithMessage(httpResponse.statusCode, errorResponse.message)
                } else {
                    // Fallback: try to extract any message from the response
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let message = json["message"] as? String {
                        throw APIError.serverErrorWithMessage(httpResponse.statusCode, message)
                    }
                    throw APIError.serverError(httpResponse.statusCode)
                }
            default:
                throw APIError.unknown
            }
        } catch {
            if error is APIError {
                throw error
            } else {
                throw APIError.networkError(error)
            }
        }
    }
    
    // MARK: - Token Refresh
    
    private func refreshTokenAndRetry() async throws {
        guard let refreshToken = keychainService.getRefreshToken() else {
            throw APIError.unauthorized
        }
        
        let refreshRequest = RefreshTokenRequest(refreshToken: refreshToken)
        let requestData = try JSONEncoder().encode(refreshRequest)
        
        let response: RefreshTokenResponse = try await request(
            endpoint: "/auth/refresh",
            method: .POST,
            body: requestData,
            headers: [:],
            responseType: RefreshTokenResponse.self,
            requiresAuth: false
        )
        
        // Update stored tokens
        _ = keychainService.saveTokens(accessToken: response.accessToken, refreshToken: response.refreshToken)
    }
}

enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
}

enum APIError: Error {
    case invalidURL
    case invalidResponse
    case unauthorized
    case clientError(Int)
    case clientErrorWithMessage(Int, String)
    case serverError(Int)
    case serverErrorWithMessage(Int, String)
    case rateLimited(String, retryAfter: Int?)
    case networkError(Error)
    case unknown
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .unauthorized:
            return "Authentication failed"
        case .clientError(let code):
            return "Request error (Code: \(code))"
        case .clientErrorWithMessage(let code, let message):
            return "\(message) (Code: \(code))"
        case .serverError(let code):
            return "Server error (Code: \(code))"
        case .serverErrorWithMessage(let code, let message):
            return "\(message) (Code: \(code))"
        case .rateLimited(let message, let retryAfter):
            if let retryAfter = retryAfter {
                return "\(message). Please wait \(retryAfter) seconds."
            }
            return message
        case .networkError(let error):
            return "Connection error: \(error.localizedDescription)"
        case .unknown:
            return "An unexpected error occurred"
        }
    }
}

// Error response structures
struct ErrorResponse: Codable {
    let code: String
    let message: String
}

struct RateLimitError: Codable {
    let error: String
    let message: String
    let retryAfter: Int
}