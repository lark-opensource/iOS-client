//
//  MixMediaLocker.swift
//  LarkMedia
//
//  Created by FakeGourmet on 2023/8/4.
//

import Foundation

class MixMediaLocker: MediaLocker<Set<SceneMediaConfig>> {

    convenience init(mediaType: MediaMutexType) {
        self.init(current: Set(), mediaType: mediaType)
    }

    override func tryLock(config: SceneMediaConfig, tag: String) -> Completion {
        if let priority = config.mediaConfig[mediaType] {
            if current.isEmpty {
                logger.debug(with: tag, "tryLock scene: \(config.scene) \(mediaType.rawValue)")
                current.insert(config)
            } else {
                if config.mixWithOthers(mediaType), current.map({ $0.mixWithOthers(mediaType) }).reduce(true, { l, r in l && r }) {
                    current.insert(config)
                } else {
                    let removedScene = Array(current.filter { config in
                        guard let p = config.mediaConfig[mediaType] else { return false }
                        return p <= priority
                    })
                    if removedScene.isEmpty, let firstScene = current.first {
                        let e: MediaMutexError = .occupiedByOther(firstScene.scene, firstScene.scene.errorMsg(type: mediaType))
                        logger.debug(with: tag, "tryLock scene: \(config.scene) \(mediaType.rawValue) failed with error: \(e)")
                        return .failure(e)
                    } else {
                        logger.debug(with: tag, "tryLock scene: \(config.scene) \(mediaType.rawValue)")
                        current.removeAll()
                        current.insert(config)
                        if !removedScene.isEmpty {
                            logger.debug(with: tag, "tryLock scene: \(config.scene) \(mediaType.rawValue) and interrupt \(removedScene.map { $0.scene })")
                        }
                        cache[config] = Set(removedScene)
                        return .success(.begin(removedScene))
                    }
                }
            }
        }
        return .success(.default)
    }

    override func unlock(config: SceneMediaConfig, tag: String) -> Completion {
        var end: [SceneMediaConfig] = []
        if let conf = current.first(where: { $0 == config }) {
            current.remove(conf)
            // 如果非mix模式，则需要取打断队列中的scenes并发送恢复通知
            if !conf.mixWithOthers(mediaType), let interruptees = cache.first(where: { $0.key == config })?.value {
                interruptees.forEach {
                    current.insert($0)
                    end.append($0)
                }
            }
            logger.debug(with: tag, "unlock scene: \(config.scene) \(mediaType.rawValue) config and current: \(current)")
        }

        for (interrputer, _) in cache where interrputer == config {
            logger.debug(with: tag, "unlock scene: \(config.scene) \(mediaType.rawValue) remove from cache")
            cache.removeValue(forKey: interrputer)
        }

        for (key, interrputees) in cache where interrputees.contains(where: { $0 == config }) {
            logger.debug(with: tag, "unlock scene: \(config.scene) \(mediaType.rawValue) remove from cache")
            cache[key] = interrputees.filter { $0 != config }
        }

        return .success(.end(end))
    }

    override func remove(config: SceneMediaConfig) {
        if current.contains(config) {
            current.remove(config)
        }
    }

    override func pk(with config: SceneMediaConfig) -> Int {
        let r1: Int = Int(config.mediaConfig[mediaType]?.rawValue ?? 0)
        let r2: Int
        if current.map({ $0.mixWithOthers(mediaType) }).reduce(true, { $0 && $1 }) {
            r2 = 0
        } else {
            r2 = Int(current.max(by: { lhs, rhs in
                let lp = lhs.mediaConfig[mediaType]?.rawValue ?? 0
                let rp = rhs.mediaConfig[mediaType]?.rawValue ?? 0
                return lp < rp
            })?.mediaConfig[mediaType]?.rawValue ?? 0)
        }
        return r1 - r2
    }

    override func contains(config: SceneMediaConfig) -> Bool {
        current.contains(config)
    }

    override func contains(scene: MediaMutexScene) -> Bool {
        current.contains(where: { $0.scene == scene })
    }

    override func isInterrupted(scene: MediaMutexScene) -> Bool {
        cache.flatMap { $0.value }.contains { interrputee in
            interrputee.scene == scene
        }
    }
}
