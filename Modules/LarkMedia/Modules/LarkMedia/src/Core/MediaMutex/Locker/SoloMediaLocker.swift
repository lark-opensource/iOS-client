//
//  SoloMediaLocker.swift
//  LarkMedia
//
//  Created by FakeGourmet on 2023/8/4.
//

import Foundation

class SoloMediaLocker: MediaLocker<SceneMediaConfig?> {

    convenience init(mediaType: MediaMutexType) {
        self.init(current: nil, mediaType: mediaType)
    }

    override func tryLock(config: SceneMediaConfig, tag: String) -> Completion {
        if let priority = config.mediaConfig[mediaType] {
            if let currentConfig = current,
               let currentPriority = currentConfig.mediaConfig[mediaType] {
               if priority < currentPriority {
                   let e: MediaMutexError = .occupiedByOther(currentConfig.scene, currentConfig.scene.errorMsg(type: mediaType))
                   logger.debug(with: tag, "tryLock scene: \(config.scene) \(mediaType.rawValue) failed with error: \(e)")
                   return .failure(e)
               } else {
                   logger.debug(with: tag, "tryLock scene: \(config.scene) \(mediaType.rawValue)")
                   current = config
                   if currentConfig != config {
                       logger.debug(with: tag, "tryLock scene: \(config.scene) \(mediaType.rawValue) and interrupt \(currentConfig.scene)")
                       cache[config] = currentConfig
                       return .success(.begin([currentConfig]))
                   }
               }
            } else {
                logger.debug(with: tag, "tryLock scene: \(config.scene) \(mediaType.rawValue)")
                current = config
            }
        }
        return .success(.default)
    }

    override func unlock(config: SceneMediaConfig, tag: String) -> Completion {
        var end: [SceneMediaConfig] = []
        if current == config {
            // 如果正在激活中，则取打断队列中的scene并发送恢复通知
            current = cache.first(where: { $0.key == config })?.value
            if let currentConfig = current {
                end.append(currentConfig)
            }
            logger.debug(with: tag, "unlock scene: \(config.scene) \(mediaType.rawValue) config and current: \(String(describing: current))")
        }

        for (interrputer, interrputee) in cache where interrputer == config || interrputee == config {
            logger.debug(with: tag, "unlock scene: \(config.scene) \(mediaType.rawValue) remove from cache")
            cache.removeValue(forKey: interrputer)
        }
        return .success(.end(end))
    }

    override func update(config: SceneMediaConfig, tag: String) -> Completion {
        if let currentConfig = current {
            // 若当前有scene激活中
            if currentConfig == config {
                // 当前自己激活中
                if config.mediaConfig[mediaType] != nil {
                    // 有权限, 直接更新
                    current = config.merge(with: currentConfig)
                } else {
                    // 无权限，通知打断scene
                    current = cache[config] as? SceneMediaConfig
                    if let currentConfig = current {
                        logger.debug(with: tag, "update scene: \(config.scene) restore scene: \(currentConfig.scene)")
                        return .success(.end([currentConfig]))
                    }
                }
            } else {
                // 若当前其他scene激活中，tryLock
                return tryLock(config: config, tag: tag)
            }
        } else if config.mediaConfig[mediaType] != nil {
            // 如果当前没有scene激活，但是需要增加权限时，直接更新
            current = config
        }
        return .success(.default)
    }

    override func remove(config: SceneMediaConfig) {
        if current == config {
            current = nil
        }
    }

    override func pk(with config: SceneMediaConfig) -> Int {
        let r1: Int = Int(config.mediaConfig[mediaType]?.rawValue ?? 0)
        let r2: Int = Int(current?.mediaConfig[mediaType]?.rawValue ?? 0)
        return r1 - r2
    }

    override func contains(config: SceneMediaConfig) -> Bool {
        current == config
    }

    override func contains(scene: MediaMutexScene) -> Bool {
        current?.scene == scene
    }

    override func isInterrupted(scene: MediaMutexScene) -> Bool {
        cache.contains { _, interrputee in
            interrputee?.scene == scene
        }
    }
}
