import Foundation

struct NetworkRetryPolicy {
    let maxRetries: Int
    let initialDelay: TimeInterval
    let maxDelay: TimeInterval
    let exponentialBackoffBase: Double
    let jitterRange: Double
    
    static let `default` = NetworkRetryPolicy(
        maxRetries: 3,
        initialDelay: 1.0,
        maxDelay: 30.0,
        exponentialBackoffBase: 2.0,
        jitterRange: 0.1
    )
    
    static let aggressive = NetworkRetryPolicy(
        maxRetries: 5,
        initialDelay: 0.5,
        maxDelay: 60.0,
        exponentialBackoffBase: 1.5,
        jitterRange: 0.2
    )
    
    static let conservative = NetworkRetryPolicy(
        maxRetries: 2,
        initialDelay: 2.0,
        maxDelay: 10.0,
        exponentialBackoffBase: 2.0,
        jitterRange: 0.05
    )
    
    func delay(for attempt: Int) -> TimeInterval {
        guard attempt > 0 else { return 0 }
        
        // Calculate exponential backoff
        let exponentialDelay = initialDelay * pow(exponentialBackoffBase, Double(attempt - 1))
        
        // Apply max delay cap
        let cappedDelay = min(exponentialDelay, maxDelay)
        
        // Add jitter to prevent thundering herd
        let jitter = cappedDelay * jitterRange * (Double.random(in: -1...1))
        
        return max(0, cappedDelay + jitter)
    }
    
    func shouldRetry(error: Error, attempt: Int) -> Bool {
        guard attempt < maxRetries else { return false }
        
        // Check if error is retryable
        if let apiError = error as? APIError {
            switch apiError {
            case .networkError, .serverError, .serverErrorWithMessage, .unknown:
                return true
            case .rateLimited(_, let retryAfter):
                // Only retry if we have a reasonable retry-after value
                return retryAfter == nil || retryAfter! <= 60
            case .invalidURL, .invalidResponse, .unauthorized, .clientError, .clientErrorWithMessage:
                return false
            }
        }
        
        // For URLError, retry on timeout or connection issues
        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut, .cannotFindHost, .cannotConnectToHost, 
                 .networkConnectionLost, .notConnectedToInternet,
                 .dnsLookupFailed, .resourceUnavailable:
                return true
            default:
                return false
            }
        }
        
        return false
    }
}

// Retry-aware API client extension
extension APIClient {
    func requestWithRetry<T: Decodable>(
        endpoint: String,
        method: HTTPMethod,
        body: Data?,
        headers: [String: String],
        responseType: T.Type,
        requiresAuth: Bool,
        retryPolicy: NetworkRetryPolicy = .default
    ) async throws -> T {
        var lastError: Error?
        
        for attempt in 0...retryPolicy.maxRetries {
            do {
                return try await request(
                    endpoint: endpoint,
                    method: method,
                    body: body,
                    headers: headers,
                    responseType: responseType,
                    requiresAuth: requiresAuth
                )
            } catch {
                lastError = error
                
                // Check if we should retry
                if !retryPolicy.shouldRetry(error: error, attempt: attempt) {
                    throw error
                }
                
                // Check for rate limit with retry-after
                if let apiError = error as? APIError,
                   case .rateLimited(_, let retryAfter) = apiError,
                   let waitTime = retryAfter {
                    // Wait for the specified time
                    try await Task.sleep(nanoseconds: UInt64(waitTime) * 1_000_000_000)
                } else if attempt < retryPolicy.maxRetries {
                    // Wait with exponential backoff
                    let delay = retryPolicy.delay(for: attempt + 1)
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
                
                #if DEBUG
                print("🔄 Retrying request (attempt \(attempt + 1)/\(retryPolicy.maxRetries)): \(endpoint)")
                #endif
            }
        }
        
        throw lastError ?? APIError.unknown
    }
}