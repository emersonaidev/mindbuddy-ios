import Foundation

// MARK: - Cache Service

class CacheService: CacheServiceProtocol {
    
    // MARK: - Properties
    
    private let cache = NSCache<NSString, CacheItem>()
    private let queue = DispatchQueue(label: "com.mindbuddy.cache", qos: .utility)
    
    // MARK: - Cache Item
    
    private class CacheItem {
        let data: Data
        let timestamp: Date
        
        init(data: Data) {
            self.data = data
            self.timestamp = Date()
        }
    }
    
    // MARK: - Initialization
    
    init() {
        setupCache()
    }
    
    private func setupCache() {
        cache.countLimit = 100 // Maximum number of items
        cache.totalCostLimit = Constants.Cache.memoryLimit // 50MB
    }
    
    // MARK: - Public Methods
    
    func store<T: Codable>(_ object: T, forKey key: String) {
        queue.async { [weak self] in
            do {
                let data = try JSONEncoder().encode(object)
                let item = CacheItem(data: data)
                self?.cache.setObject(item, forKey: key as NSString, cost: data.count)
                
                #if DEBUG
                print("📦 Cached object for key: \(key)")
                #endif
            } catch {
                #if DEBUG
                print("❌ Failed to cache object for key \(key): \(error)")
                #endif
            }
        }
    }
    
    func retrieve<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        return queue.sync { [weak self] in
            guard let item = self?.cache.object(forKey: key as NSString) else {
                return nil
            }
            
            do {
                let object = try JSONDecoder().decode(type, from: item.data)
                
                #if DEBUG
                print("📦 Retrieved cached object for key: \(key)")
                #endif
                
                return object
            } catch {
                #if DEBUG
                print("❌ Failed to decode cached object for key \(key): \(error)")
                #endif
                
                // Remove corrupted item
                self?.cache.removeObject(forKey: key as NSString)
                return nil
            }
        }
    }
    
    func remove(forKey key: String) {
        queue.async { [weak self] in
            self?.cache.removeObject(forKey: key as NSString)
            
            #if DEBUG
            print("🗑️ Removed cached object for key: \(key)")
            #endif
        }
    }
    
    func clearAll() {
        queue.async { [weak self] in
            self?.cache.removeAllObjects()
            
            #if DEBUG
            print("🗑️ Cleared all cached objects")
            #endif
        }
    }
    
    func isExpired(forKey key: String, maxAge: TimeInterval) -> Bool {
        return queue.sync { [weak self] in
            guard let item = self?.cache.object(forKey: key as NSString) else {
                return true // If not cached, consider it expired
            }
            
            let age = Date().timeIntervalSince(item.timestamp)
            return age > maxAge
        }
    }
    
    // MARK: - Advanced Cache Methods
    
    func getCacheInfo() -> (count: Int, totalSize: Int) {
        return queue.sync { [weak self] in
            guard let cache = self?.cache else {
                return (0, 0)
            }
            
            // Note: NSCache doesn't provide direct access to total size
            // This is an approximation
            return (cache.countLimit, cache.totalCostLimit)
        }
    }
    
    func removeExpiredItems(maxAge: TimeInterval) {
        queue.async {
            // Note: NSCache doesn't provide enumeration
            // In a production app, you might want to use a custom cache implementation
            // or track keys separately for expiration management
        }
    }
}

// MARK: - URL Cache Configuration

extension CacheService {
    
    static func configureURLCache() {
        let memoryCapacity = 20 * 1024 * 1024 // 20MB
        let diskCapacity = 100 * 1024 * 1024 // 100MB
        
        let cache = URLCache(
            memoryCapacity: memoryCapacity,
            diskCapacity: diskCapacity,
            diskPath: "mindbuddy_url_cache"
        )
        
        URLCache.shared = cache
        
        #if DEBUG
        print("🔧 Configured URL cache: Memory(\(memoryCapacity/1024/1024)MB), Disk(\(diskCapacity/1024/1024)MB)")
        #endif
    }
}

// MARK: - Mock Cache Service

class MockCacheService: CacheServiceProtocol {
    private var storage: [String: Data] = [:]
    private var timestamps: [String: Date] = [:]
    
    func store<T: Codable>(_ object: T, forKey key: String) {
        do {
            let data = try JSONEncoder().encode(object)
            storage[key] = data
            timestamps[key] = Date()
        } catch {
            print("Mock cache store error: \(error)")
        }
    }
    
    func retrieve<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = storage[key] else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
    
    func remove(forKey key: String) {
        storage.removeValue(forKey: key)
        timestamps.removeValue(forKey: key)
    }
    
    func clearAll() {
        storage.removeAll()
        timestamps.removeAll()
    }
    
    func isExpired(forKey key: String, maxAge: TimeInterval) -> Bool {
        guard let timestamp = timestamps[key] else { return true }
        return Date().timeIntervalSince(timestamp) > maxAge
    }
}