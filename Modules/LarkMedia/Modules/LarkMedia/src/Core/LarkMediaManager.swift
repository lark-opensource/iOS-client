//
//  LarkMediaManager.swift
//  LarkMedia
//
//  Created by fakegourmet on 2023/6/14.
//

import Foundation
import EEAtomic

public final class LarkMediaManager {
    public static let shared = LarkMediaManager()

    let mediaMutex = MediaMutexManager()

    private init() {}
}

public extension LarkMediaManager {
    /// 由 VC 提供依赖
    func setDependency(_ dependency: MediaMutexDependency) {
        mediaMutex.dependency = dependency
        dependency.fetchSettings { [weak mediaMutex] map in
            mediaMutex?.configMap = map
        }
    }
}

extension LarkMediaManager: MediaMutexService {

    public func getMediaResource(for scene: MediaMutexScene) -> LarkMediaResource? {
        mediaMutex.getMediaResource(for: scene)
    }

    public func tryLock(scene: MediaMutexScene, options: MediaMutexOptions = [], observer: MediaResourceInterruptionObserver? = nil, completion: @escaping (MediaMutexCompletion) -> Void) {
        mediaMutex.tryLock(scene: scene, options: options, observer: observer, completion: completion)
    }

    public func tryLock(scene: MediaMutexScene, options: MediaMutexOptions = [], observer: MediaResourceInterruptionObserver? = nil) -> MediaMutexCompletion {
        mediaMutex.tryLock(scene: scene, options: options, observer: observer)
    }

    public func unlock(scene: MediaMutexScene, options: MediaMutexOptions = []) {
        mediaMutex.unlock(scene: scene, options: options)
    }

    public func update(scene: MediaMutexScene, mediaType: MediaMutexType, priority: MediaMutexPriority?) {
        mediaMutex.update(scene: scene, mediaType: mediaType, priority: priority)
    }
}
