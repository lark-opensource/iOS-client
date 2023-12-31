//
//  MediaLocker.swift
//  LarkMedia
//
//  Created by fakegourmet on 2022/11/14.
//

import Foundation
import LKCommonsLogging

protocol MediaLockerProtocol: AnyObject {

    typealias Completion = Result<InterruptResult, MediaMutexError>

    func tryLock(config: SceneMediaConfig, tag: String) -> Completion

    func unlock(config: SceneMediaConfig, tag: String) -> Completion

    func update(config: SceneMediaConfig, tag: String) -> Completion

    func remove(config: SceneMediaConfig)

    func pk(with config: SceneMediaConfig) -> Int

    func contains(config: SceneMediaConfig) -> Bool

    func contains(scene: MediaMutexScene) -> Bool

    func isInterrupted(scene: MediaMutexScene) -> Bool
}

class MediaLocker<T>: MediaLockerProtocol {

    var logger: Log { MediaMutexManager.logger }

    /// 媒体类型
    let mediaType: MediaMutexType

    /// 当前激活中的 scene
    @RwAtomic
    var current: T

    /// 保存打断关系
    /// key: 打断者
    /// value: 被打断者
    @RwAtomic
    var cache: [SceneMediaConfig: T] = [:]

    init(current: T, mediaType: MediaMutexType) {
        self.current = current
        self.mediaType = mediaType
    }

    func tryLock(config: SceneMediaConfig, tag: String) -> Completion { .success(.default) }

    func unlock(config: SceneMediaConfig, tag: String) -> Completion { .success(.default) }

    func update(config: SceneMediaConfig, tag: String) -> Completion { .success(.default) }

    func remove(config: SceneMediaConfig) {}

    func pk(with config: SceneMediaConfig) -> Int { 0 }

    func contains(config: SceneMediaConfig) -> Bool { false }

    func contains(scene: MediaMutexScene) -> Bool { false }

    func isInterrupted(scene: MediaMutexScene) -> Bool { false }
}
