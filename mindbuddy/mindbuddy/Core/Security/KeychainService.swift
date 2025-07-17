import Foundation
import Security

class KeychainService {
    static let shared = KeychainService()
    
    private let service = "io.mindbuddy.app"
    
    private init() {}
    
    enum KeychainKey: String {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
    }
    
    // MARK: - Save Methods
    
    func save(_ data: String, for key: KeychainKey) -> Bool {
        return save(data, forKey: key.rawValue)
    }
    
    private func save(_ data: String, forKey key: String) -> Bool {
        guard let data = data.data(using: .utf8) else {
            return false
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        // Delete any existing item
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    // MARK: - Load Methods
    
    func load(for key: KeychainKey) -> String? {
        return load(forKey: key.rawValue)
    }
    
    private func load(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue as Any,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess {
            if let data = dataTypeRef as? Data {
                return String(data: data, encoding: .utf8)
            }
        }
        
        return nil
    }
    
    // MARK: - Delete Methods
    
    func delete(for key: KeychainKey) -> Bool {
        return delete(forKey: key.rawValue)
    }
    
    private func delete(forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    // MARK: - Clear All
    
    func clearAll() -> Bool {
        let success1 = delete(for: .accessToken)
        let success2 = delete(for: .refreshToken)
        return success1 && success2
    }
    
    // MARK: - Token Convenience Methods
    
    func saveTokens(accessToken: String, refreshToken: String) -> Bool {
        let success1 = save(accessToken, for: .accessToken)
        let success2 = save(refreshToken, for: .refreshToken)
        return success1 && success2
    }
    
    func getAccessToken() -> String? {
        return load(for: .accessToken)
    }
    
    func getRefreshToken() -> String? {
        return load(for: .refreshToken)
    }
    
    func hasValidTokens() -> Bool {
        return getAccessToken() != nil && getRefreshToken() != nil
    }
}