import XCTest
@testable import mindbuddy

final class KeychainServiceTests: XCTestCase {
    
    var keychainService: KeychainService!
    
    override func setUpWithError() throws {
        keychainService = KeychainService.shared
        // Clean up any existing test data
        _ = keychainService.clearAll()
    }
    
    override func tearDownWithError() throws {
        // Clean up test data
        _ = keychainService.clearAll()
        keychainService = nil
    }
    
    // MARK: - Keychain Tests
    
    func testSaveAndRetrieveTokens() throws {
        let accessToken = "test-access-token"
        let refreshToken = "test-refresh-token"
        
        // Test saving tokens
        let saveResult = keychainService.saveTokens(accessToken: accessToken, refreshToken: refreshToken)
        XCTAssertTrue(saveResult, "Should successfully save tokens")
        
        // Test retrieving tokens
        let retrievedAccessToken = keychainService.getAccessToken()
        let retrievedRefreshToken = keychainService.getRefreshToken()
        
        XCTAssertEqual(retrievedAccessToken, accessToken, "Retrieved access token should match saved token")
        XCTAssertEqual(retrievedRefreshToken, refreshToken, "Retrieved refresh token should match saved token")
    }
    
    func testHasValidTokens() throws {
        // Initially should have no tokens
        XCTAssertFalse(keychainService.hasValidTokens(), "Should not have valid tokens initially")
        
        // After saving tokens, should have valid tokens
        let saveResult = keychainService.saveTokens(accessToken: "test-token", refreshToken: "test-refresh")
        XCTAssertTrue(saveResult, "Should save tokens successfully")
        XCTAssertTrue(keychainService.hasValidTokens(), "Should have valid tokens after saving")
    }
    
    func testClearAllTokens() throws {
        // Save some tokens first
        let saveResult = keychainService.saveTokens(accessToken: "test-token", refreshToken: "test-refresh")
        XCTAssertTrue(saveResult, "Should save tokens successfully")
        XCTAssertTrue(keychainService.hasValidTokens(), "Should have valid tokens")
        
        // Clear all tokens
        let clearResult = keychainService.clearAll()
        XCTAssertTrue(clearResult, "Should clear tokens successfully")
        XCTAssertFalse(keychainService.hasValidTokens(), "Should not have valid tokens after clearing")
        
        // Verify tokens are actually gone
        XCTAssertNil(keychainService.getAccessToken(), "Access token should be nil after clearing")
        XCTAssertNil(keychainService.getRefreshToken(), "Refresh token should be nil after clearing")
    }
    
    func testOverwriteExistingTokens() throws {
        // Save initial tokens
        let initialAccessToken = "initial-access-token"
        let initialRefreshToken = "initial-refresh-token"
        
        let saveResult1 = keychainService.saveTokens(accessToken: initialAccessToken, refreshToken: initialRefreshToken)
        XCTAssertTrue(saveResult1, "Should save initial tokens")
        
        // Overwrite with new tokens
        let newAccessToken = "new-access-token"
        let newRefreshToken = "new-refresh-token"
        
        let saveResult2 = keychainService.saveTokens(accessToken: newAccessToken, refreshToken: newRefreshToken)
        XCTAssertTrue(saveResult2, "Should overwrite tokens")
        
        // Verify new tokens are retrieved
        XCTAssertEqual(keychainService.getAccessToken(), newAccessToken, "Should retrieve new access token")
        XCTAssertEqual(keychainService.getRefreshToken(), newRefreshToken, "Should retrieve new refresh token")
    }
}