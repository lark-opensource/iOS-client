//
//  VideoCacheCleanTask.swift
//  LarkBaseService
//
//  Created by 李晨 on 2021/8/30.
//

import UIKit
import Foundation
import LarkCache
import LKCommonsLogging
import LKCommonsTracker
import TTVideoEngine
import LarkStorage
import LarkSetting
import LarkReleaseConfig

// swiftlint:disable empty_count
final class VideoCacheCleanTask: CleanTask {
    var name: String = "TTVideo Cache Clean Task"

    static let logger = Logger.log(VideoCacheCleanTask.self, category: "VideoCacheCleanTask")

    func clean(config: CleanConfig, completion: @escaping Completion) {
        let startTime = CACurrentMediaTime()
        TTVideoEngine.ls_getAllCacheSize { size in
            TTVideoEngine.ls_clearAllCaches()
            if TTVideoEngine.ls_isStarted() {
                TTVideoEngine.ls_cancelAllTasks()
            }
            let endTime = CACurrentMediaTime()
            VideoCacheCleanTask.logger.info("clean video size success \(size)")
            let result = TaskResult(
                completed: true,
                costTime: Int((endTime - startTime) * 1_000),
                size: .bytes(Int(size))
            )
            completion(result)
        }
    }

    func size(config: CleanConfig, completion: @escaping Completion) {
        let startTime = CACurrentMediaTime()
        /// 优先使用缓存路径计算 cache size
        /// TTVideoEngine 计算 cache 方法存在不准的情况
        if let cachePath = TTVideoEngine.ls_localServerConfigure().cachDirectory {
            let cacheSize = Int(truncatingIfNeeded: AbsPath(cachePath).recursiveFileSize())
            VideoCacheCleanTask.logger.info("get video size from path success \(cacheSize)")
            let endTime = CACurrentMediaTime()
            completion(
                TaskResult(
                    completed: true,
                    costTime: Int((endTime - startTime) * 1_000),
                    size: .bytes(cacheSize)
                )
            )
        } else {
            TTVideoEngine.ls_getAllCacheSize { size in
                VideoCacheCleanTask.logger.info("get video size success \(size)")
                let endTime = CACurrentMediaTime()
                let result = TaskResult(
                    completed: true,
                    costTime: Int((endTime - startTime) * 1_000),
                    size: .bytes(Int(size))
                )
                completion(result)
            }
        }
    }

    func cancel() {
    }

    func allCacheTaskDidCompleted() {
        VideoEngineSetupManager.setupTTVideoEnginePath()
    }
}
// swiftlint:enable empty_count
