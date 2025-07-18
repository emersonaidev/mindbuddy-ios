import Foundation

// MARK: - Dependency Container Protocol

protocol DependencyContainerProtocol {
    // Core Services
    var authService: AuthenticationServiceProtocol { get }
    var networkService: NetworkServiceProtocol { get }
    var keychainService: KeychainServiceProtocol { get }
    var healthService: HealthServiceProtocol { get }
    var rewardsService: RewardsServiceProtocol { get }
    var cacheService: CacheServiceProtocol { get }
    var configuration: ConfigurationProtocol { get }
    var apiClient: APIClientProtocol { get }
    var firebaseAuthManager: FirebaseAuthManagerProtocol { get }
}

// MARK: - Main Dependency Container

class DependencyContainer: DependencyContainerProtocol {
    static let shared = DependencyContainer()
    
    // MARK: - Lazy Service Initialization
    
    private lazy var _configuration: ConfigurationProtocol = {
        return AppConfiguration.shared
    }()
    
    private lazy var _cacheService: CacheServiceProtocol = {
        return CacheService()
    }()
    
    private lazy var _keychainService: KeychainServiceProtocol = {
        return KeychainService.shared
    }()
    
    private lazy var _apiClient: APIClientProtocol = {
        return APIClient.shared
    }()
    
    private lazy var _firebaseAuthManager: FirebaseAuthManagerProtocol = {
        return FirebaseAuthManager.shared
    }()
    
    private lazy var _networkService: NetworkServiceProtocol = {
        return NetworkService(cacheService: _cacheService)
    }()
    
    private lazy var _healthService: HealthServiceProtocol = {
        return HealthManager.shared
    }()
    
    private lazy var _rewardsService: RewardsServiceProtocol = {
        return RewardsManager.shared
    }()
    
    private lazy var _authService: AuthenticationServiceProtocol = {
        return AuthManager.shared
    }()
    
    // MARK: - Public Interface
    
    var authService: AuthenticationServiceProtocol { _authService }
    var networkService: NetworkServiceProtocol { _networkService }
    var keychainService: KeychainServiceProtocol { _keychainService }
    var healthService: HealthServiceProtocol { _healthService }
    var rewardsService: RewardsServiceProtocol { _rewardsService }
    var cacheService: CacheServiceProtocol { _cacheService }
    var configuration: ConfigurationProtocol { _configuration }
    var apiClient: APIClientProtocol { _apiClient }
    var firebaseAuthManager: FirebaseAuthManagerProtocol { _firebaseAuthManager }
    
    // MARK: - Private Initializer (Singleton)
    
    private init() {}
}

// MARK: - Mock Dependency Container for Testing

class MockDependencyContainer: DependencyContainerProtocol {
    var authService: AuthenticationServiceProtocol
    var networkService: NetworkServiceProtocol
    var keychainService: KeychainServiceProtocol
    var healthService: HealthServiceProtocol
    var rewardsService: RewardsServiceProtocol
    var cacheService: CacheServiceProtocol
    var configuration: ConfigurationProtocol
    var apiClient: APIClientProtocol
    var firebaseAuthManager: FirebaseAuthManagerProtocol
    
    init(
        authService: AuthenticationServiceProtocol = MockAuthService(),
        networkService: NetworkServiceProtocol = MockNetworkService(),
        keychainService: KeychainServiceProtocol = MockKeychainService(),
        healthService: HealthServiceProtocol = MockHealthService(),
        rewardsService: RewardsServiceProtocol = MockRewardsService(),
        cacheService: CacheServiceProtocol = MockCacheService(),
        configuration: ConfigurationProtocol = MockConfiguration(),
        apiClient: APIClientProtocol = MockAPIClient(),
        firebaseAuthManager: FirebaseAuthManagerProtocol = MockFirebaseAuthManager()
    ) {
        self.authService = authService
        self.networkService = networkService
        self.keychainService = keychainService
        self.healthService = healthService
        self.rewardsService = rewardsService
        self.cacheService = cacheService
        self.configuration = configuration
        self.apiClient = apiClient
        self.firebaseAuthManager = firebaseAuthManager
    }
}