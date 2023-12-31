//
//  DiskCache.swift
//  LarkSetting
//
//  Created by 王元洵 on 2023/3/9.
//

import Foundation
import LarkCache
import LKCommonsLogging
import EEAtomic

enum DiskCache {
    private static let cache = CacheManager.shared.cache(relativePath: "setting", directory: .library)
    private static let logger = Logger.log(DiskCache.self, category: "LarkSetting")
    private static let lock = UnfairLock()
    
    private static var memoryCache = [String: Codable]()

    private static func readCache<T: Codable>(of type: T.Type, key: String) -> T? {
        memoryCache[key] as? T ?? {
            logger.info("[setting] fetch cache from disk, key: \(key) ")
            if let data = cache.diskCache?.object(forKey: key) as? NSData {
                do {
                    let result = try JSONDecoder().decode(type, from: data as Data)
                    memoryCache[key] = result
                    return result
                } catch {
                    logger.error("[setting] deserialize failed",
                                 additionalData: ["data": "\(data)"],
                                 error: error)
                    cache.diskCache?.removeObject(forKey: key)
                    return nil
                }
            } else {
                logger.warn("[setting] no cache from disk, key: \(key)")
                return nil
            }
        }()
    }

    private static func writeCache<T: Codable>(of source: T, key: String) {
        memoryCache[key] = source
        DispatchQueue.global(qos: .background).async {
            do {
                let data = (try JSONEncoder().encode(source)) as NSData
                cache.diskCache?.setObject(data, forKey: key)
                logger.info("[setting] update disk cache with key: \(key)")
            } catch {
                logger.error("[setting] serialize failed with key: \(key)",
                             additionalData: ["data": "\(source)"], error: error)
            }
        }
    }
}

// MARK: internal interfaces
extension DiskCache {
    static func object<T: Codable>(of type: T.Type, key: String) -> T? { lock.withLocking { readCache(of: type, key: key) } }
    
    static func setObject<T: Codable>(of source: T, key: String) { lock.withLocking { writeCache(of: source, key: key) } }
}
