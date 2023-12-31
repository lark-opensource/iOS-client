//
//  MediaMutexManager+Lock.swift
//  LarkMedia
//
//  Created by FakeGourmet on 2023/8/3.
//

import Foundation

// MARK: - TryLock
extension MediaMutexManager {
    func tryLock(scene: MediaMutexScene, options: MediaMutexOptions = [], observer: MediaResourceInterruptionObserver? = nil, completion: @escaping (MediaMutexCompletion) -> Void) {
        let tag = Self.logger.getTag()
        queue.async { [weak self] in
            guard let self = self else {
                Self.logger.error(with: tag, "tryLock scene: \(scene) failed with error: \(MediaMutexError.unknown)")
                self?.dispatchQueue.async {
                    completion(.failure(.unknown))
                }
                return
            }
            let result = self._tryLock(scene: scene, tag: tag, options: options, observer: observer)
            self.dispatchQueue.async {
                completion(result)
            }
        }
    }

    func tryLock(scene: MediaMutexScene, options: MediaMutexOptions = [], observer: MediaResourceInterruptionObserver? = nil) -> MediaMutexCompletion {
        let tag = Self.logger.getTag()
        if DispatchQueue.getSpecific(key: queueTag) == nil {
            return queue.sync { [weak self] in
                guard let self = self else {
                    Self.logger.error(with: tag, "tryLock scene: \(scene) failed with error: \(MediaMutexError.unknown)")
                    return .failure(.unknown)
                }
                return self._tryLock(scene: scene, tag: tag, options: options, observer: observer)
            }
        } else {
            return _tryLock(scene: scene, tag: tag, options: options, observer: observer)
        }
    }

    private func _tryLock(scene: MediaMutexScene, tag: String, options: MediaMutexOptions = [], observer: MediaResourceInterruptionObserver? = nil) -> MediaMutexCompletion {
        Self.logger.debug(with: tag, "tryLock scene: \(scene) options: \(options) start")

        guard let config = scene.mediaConfig?.config(options: options) else {
            Self.logger.warn(with: tag, "tryLock scene: \(scene) failed with error: \(MediaMutexError.sceneNotFound)")
            return .failure(.sceneNotFound)
        }

        guard config.isEnabled else {
            Self.logger.debug(with: tag, "tryLock scene: \(scene) disabled, return success by default")
            return .success(getOrCreateMediaResource(config))
        }

        guard config.isActive == false else {
            Self.logger.debug(with: tag, "tryLock scene: \(scene) skip while using")
            return .success(getOrCreateMediaResource(config))
        }

        // 判断执行顺序，优先执行优先级请求失败的 MediaType
        let orderList = lockers.map { ($0.key, $0.value.pk(with: config)) }.sorted(by: { $0.1 < $1.1 }).map { $0.0 }

        for type in orderList {
            if let result = lockers[type]?.tryLock(config: config, tag: tag) {
                if case .failure(let e) = result {
                    // 失败直接结束调用
                    return .failure(e)
                }
                if case .success(let interruptResult) = result {
                    consume(interruptResult: interruptResult, config: config, type: type)
                }
            }
        }

        observerManager.addObserver(observer, for: config)
        monitor.addObservable(config)

        Self.logger.debug(with: tag, "tryLock scene: \(scene) success")
        return .success(getOrCreateMediaResource(config))
    }

    private func getOrCreateMediaResource(_ config: SceneMediaConfig) -> LarkMediaResource {
        if let resource = resourceMap[config] {
            return resource
        } else {
            Self.logger.debug("\(config.scene) create new resource")
            let resource = LarkMediaResource(scene: config.scene, enableRuntime: dependency?.enableRuntime == true)
            resourceMap[config] = resource
            return resource
        }
    }
}

// MARK: - UnLock
extension MediaMutexManager {

    func unlock(scene: MediaMutexScene, options: MediaMutexOptions = []) {
        let tag = Self.logger.getTag()
        queue.async { [weak self] in
            Self.logger.debug(with: tag, "unlock scene: \(scene) options: \(options) start")

            guard let self = self else {
                Self.logger.error(with: tag, "unlock scene: \(scene) failed, instance NOT found")
                return
            }

            guard let config = scene.mediaConfig else {
                Self.logger.warn(with: tag, "unlock scene: \(scene) failed with error: \(MediaMutexError.sceneNotFound)")
                return
            }

            self._unlock(config: config, tag: tag, options: options)

            Self.logger.info(with: tag, "unlock scene: \(scene) success")
        }
    }

    private func _unlock(config: SceneMediaConfig, tag: String, options: MediaMutexOptions) {
        for (type, locker) in lockers {
            switch locker.unlock(config: config, tag: tag) {
            case .success(let interruptResult):
                consume(interruptResult: interruptResult, config: config, type: type)
            default:
                break
            }
        }

        observerManager.removeObserver(for: config)
        monitor.removeObservable(config)

        if options.contains(.leaveScenarios) {
            if let resource = resourceMap[config] {
                resource._audioSession.release()
            } else {
                Self.logger.info(with: tag, "media resource NOT found when unlock scene: \(config.scene)")
            }
        }
        resourceMap.removeValue(forKey: config)
    }
}

// MARK: - Update
extension MediaMutexManager {
    func update(scene: MediaMutexScene, mediaType: MediaMutexType, priority: MediaMutexPriority?) {
        let tag = Self.logger.getTag()
        queue.async { [weak self] in
            Self.logger.debug(with: tag, "update scene: \(scene) mediaType: \(mediaType) priority: \(String(describing: priority)) start")
            guard let self = self else {
                Self.logger.warn("update scene: \(scene) failed, instance NOT found")
                return
            }

            guard scene.isActive else {
                Self.logger.warn(with: tag, "update scene: \(scene) failed, scene NOT using")
                return
            }

            guard let config = scene.mediaConfig?.config(mediaType: mediaType, priority: priority) else {
                Self.logger.warn(with: tag, "update scene: \(scene) failed, scene NOT found")
                return
            }

            guard config.isEnabled else {
                Self.logger.debug(with: tag, "update scene: \(scene) disabled")
                return
            }

            self._update(config: config, tag: tag)

            Self.logger.debug(with: tag, "update scene: \(scene) mediaType: \(mediaType) priority: \(String(describing: priority)) success")
        }
    }

    private func _update(config: SceneMediaConfig, tag: String) {
        for (type, locker) in lockers {
            switch locker.update(config: config, tag: tag) {
            case .success(let interruptResult):
                consume(interruptResult: interruptResult, config: config, type: type)
            default:
                break
            }
        }
    }
}

// MARK: - Interruption
extension MediaMutexManager {
    func consume(interruptResult: InterruptResult, config: SceneMediaConfig, type: MediaMutexType) {
        interruptResult.begin.forEach {
            observerManager.notifyInterruptionBegin(to: $0, by: config, type: type, msg: config.scene.errorMsg(type: type))
            removeConfig($0)
        }
        interruptResult.end.forEach {
            observerManager.notifyInterruptionEnd(to: $0, from: config, type: type)
        }
    }

    private func removeConfig(_ config: SceneMediaConfig) {
        lockers.map { $0.value }.forEach {
            $0.remove(config: config)
        }
    }
}
