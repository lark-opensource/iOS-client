//
//  LKCanvasCache.swift
//  LarkCanvas
//
//  Created by Saafo on 2021/2/8.
//

import Foundation
import LKCommonsLogging

/// cache protocol to allow canvas save and load from local storage
@available(iOS 13.0, *)
public protocol LKCanvasCacheProvider: AnyObject {

    /// load data for the controller
    /// - Parameters:
    ///   - identifier: cache identifier, identifer of the canvasController
    /// - Returns: the data with identifier from cache, nil when data doesn't exist in cache
    func loadCache(identifier: String) -> Data?

    /// save or remove data for the controller
    /// - Parameters:
    ///   - identifier: cache identifier, identifer of the canvasController
    ///   - data: the data to be cached
    /// - Returns: whether successfully saved / removed the data to cache
    /// - Note: when data is nil, cache should be removed with the identifier
    func saveCache(identifier: String, data: Data?) -> Bool

    /// check whether cache for the controller exist
    /// - Parameter identifier: cache identifier, identifer of the canvasController
    /// - Returns: whether the cache with the identifier exists
    func checkCache(identifier: String) -> Bool
}

/// config of LKCanvasViewController
@available(iOS 13.0, *)
public struct LKCanvasConfig {
    /// the provider of cache implementation
    public static var cacheProvider: LKCanvasCacheProvider = DefaultCacheProvider.shared
}

// MARK: - Private

@available(iOS 13.0, *)
/// the default implementation of cache provider, using the system API
private final class DefaultCacheProvider: LKCanvasCacheProvider {
    // lint:disable lark_storage_check - DefaultCacheProvider 仅用于兜底，不作用于线上

    static var shared = DefaultCacheProvider()
    static let logger = Logger.log(DefaultCacheProvider.self,
                                   category: "Module.LarkCanvas.DefaultCacheProvider")
    func URL(for identifier: String) -> URL {
        Self.logger.warn("DefaultCacheProvider shouldn't be used besides demo project")
        let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        let documentsDirectory = paths.first!
        return documentsDirectory.appendingPathComponent(identifier)
    }

    func loadCache(identifier: String) -> Data? {
        let url = URL(for: identifier)
        if FileManager.default.fileExists(atPath: url.path) {
            do {
                let data = try Data(contentsOf: url)
                Self.logger.info("Loaded data successfully with id: \(identifier)")
                return data
            } catch {
                Self.logger.error("Failed to load data with id: \(identifier): \(error)")
            }
        }
        Self.logger.debug("Loaded empty data with id: \(identifier)")
        return nil
    }

    func saveCache(identifier: String, data: Data?) -> Bool {
        let url = URL(for: identifier)
        if let data = data {
            // save
            do {
                try data.write(to: url)
                Self.logger.info("Saved data successfully with id: \(identifier)")
                return true
            } catch {
                Self.logger.error("Failed to save data with id: \(identifier): \(error)")
                return false
            }
        } else {
            // remove
            if FileManager.default.fileExists(atPath: url.path) {
                do {
                    try FileManager.default.removeItem(at: url)
                    Self.logger.info("Removed data successfully with id: \(identifier)")
                    return true
                } catch {
                    Self.logger.error("Failed to clear data with id: \(identifier): \(error)")
                    return false
                }
            }
            Self.logger.debug("Removed non-exist cache with id: \(identifier)")
            return true
        }
    }

    func checkCache(identifier: String) -> Bool {
        let url = URL(for: identifier)
        if FileManager.default.fileExists(atPath: url.path) {
            Self.logger.info("Checked exist cache with id: \(identifier)")
            return true
        } else {
            Self.logger.debug("Checked non-exist cache with id: \(identifier)")
            return false
        }
    }
    // lint:enable lark_storage_check
}
