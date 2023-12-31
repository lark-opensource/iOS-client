//
//  GlobalCanvasCacheProvider.swift
//  LarkCanvasDev
//
//  Created by Saafo on 2021/2/27.
//

import Foundation
import LarkCache
import LarkCanvas
import LKCommonsLogging

// This part of code is copied from LarkBaseService/Core/LaunchTask/SetupCacheTask.swift
// This class is as the default implementation of LKCanvasCacheProvider in Lark

// MARK: - 画板全局缓存实现

/// 基于 LarkCache 实现的全局画板缓存
@available(iOS 13.0, *)
class GlobalCanvasCacheProvider: LKCanvasCacheProvider {

    static let logger = Logger.log(GlobalCanvasCacheProvider.self,
                                    category: "Module.LarkCanvas.GlobalCacheProvider")
    enum LarkCanvas: Biz {
        static var parent: Biz.Type?
        static var path: String = "LarkCanvas"
    }

    enum UserDirectory: Biz {
        static var parent: Biz.Type? = LarkCanvas.self
        static var path: String {
            "LarkUser_" + "demo_id" // use demo_id in demo projects
        }
    }
    // FIXME: () -> Cache vs Cache
    var canvasCache: () -> Cache = {
        CacheManager.shared.cache(
            biz: UserDirectory.self, directory: .cache,
            cleanIdentifier: "library/Caches/LarkCanvas/user_id"
        )
    }
    func loadCache(identifier: String) -> Data? {
        if let data: Data = canvasCache().object(forKey: identifier) {
            Self.logger.info("Loaded data successfully with id: \(identifier)")
            return data
        } else {
            Self.logger.debug("Failed to load data in cache with id: \(identifier)")
            return nil
        }
    }

    func saveCache(identifier: String, data: Data?) -> Bool {
        guard let data = data else {
            // remove
            canvasCache().removeObject(forKey: identifier)
            Self.logger.info("Removed data successfully with id: \(identifier)")
            return true
        }
        // save
        if canvasCache().set(object: data, forKey: identifier) != nil {
            Self.logger.info("Saved data successfully with id: \(identifier)")
            return true
        } else {
            Self.logger.debug("Failed to save data with id: \(identifier)")
            return false
        }
    }

    func checkCache(identifier: String) -> Bool {
        if let _: Data = canvasCache().object(forKey: identifier) {
            Self.logger.info("Checked exist cache with id: \(identifier)")
            return true
        } else {
            Self.logger.debug("Checked non-exist cache with id: \(identifier)")
            return false
        }
    }
}

/// Only used in demo to show size of data (for debug only)
@available(iOS 13.0, *)
extension GlobalCanvasCacheProvider {
    func checkCacheSize(identifier: String) -> String {
        if let data: Data = canvasCache().object(forKey: identifier) {
            let bcf = ByteCountFormatter()
            bcf.allowedUnits = [.useAll]
            bcf.countStyle = .file
            return bcf.string(fromByteCount: Int64(data.count))
        } else {
            return "0 Byte"
        }
    }
}
