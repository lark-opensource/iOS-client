//
//  SetupCanvasCacheTask.swift
//  LarkBaseService
//
//  Created by Saafo on 2021/3/3.
//

import Foundation
import AppContainer
import BootManager
import LKCommonsLogging
import LarkAccountInterface
import LarkCache
import LarkCanvas

/// 设置全局缓存默认配置
final class SetupCanvasCacheTask: FlowBootTask, Identifiable { // Global
    static var identify = "SetupCanvasCacheTask"

    override var runOnlyOnce: Bool { return true }

    override func execute(_ context: BootContext) {
        // 修改 LarkCanvas 全局缓存配置
        if #available(iOS 13.0, *) {
            LKCanvasConfig.cacheProvider = GlobalCanvasCacheProvider()
        }
    }
}

// MARK: - 画板全局缓存实现

/// 基于 LarkCache 实现的全局画板缓存
@available(iOS 13.0, *)
private final class GlobalCanvasCacheProvider: LKCanvasCacheProvider {

    static let logger = Logger.log(GlobalCanvasCacheProvider.self,
                                   category: "Module.LarkCanvas.GlobalCacheProvider")
    enum LarkCanvas: Biz {
        static var parent: Biz.Type?
        static var path: String = "LarkCanvas"
    }

    enum UserDirectory: Biz {
        static var parent: Biz.Type? = LarkCanvas.self
        static var path: String {
            "LarkUser_" + AccountServiceAdapter.shared.currentChatterId // TODO: 用户隔离: @zhangwei.wy 移除当前用户依赖
        }
    }

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
    }}
