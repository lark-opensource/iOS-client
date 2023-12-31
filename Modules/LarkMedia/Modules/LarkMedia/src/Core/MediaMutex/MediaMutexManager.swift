//
//  MediaMutexManager.swift
//  LarkMedia
//
//  Created by FakeGourmet on 2023/8/3.
//

import Foundation
import LKCommonsLogging

/// MediaMutex 设计方案
/// https://bytedance.feishu.cn/docx/doxcnCWWyShNCEQVhfzl27UcL7f
final class MediaMutexManager {
    static let logger = Logger.log(MediaMutexManager.self, category: "LarkMedia.MediaMutexManager")

    let queueTag = DispatchSpecificKey<Void>()
    @RwAtomic
    private(set) var queue = DispatchQueue(label: "LarkMedia.MediaMutexManager.Queue")

    /// 回调线程
    let dispatchQueue = DispatchQueue.global(qos: .userInteractive)

    /// settings 优先级配置
    @RwAtomic
    var configMap: [MediaMutexScene: SceneMediaConfig] = [:]

    @RwAtomic
    var resourceMap: [SceneMediaConfig: LarkMediaResource] = [:]

    let lockers: [MediaMutexType: MediaLockerProtocol] = [
        .camera : CameraLocker(),
        .record : RecordLocker(),
        .play   : PlayLocker(),
    ]

    let observerManager = ObserverManager<MediaResourceInterruptionObserver>()

    let monitor = HeartBeatMonitor<SceneMediaConfig>(interval: 30, duration: 7200)

    var dependency: MediaMutexDependency?

    init() {
        queue.setSpecific(key: queueTag, value: ())
    }

    func getMediaResource(for scene: MediaMutexScene) -> LarkMediaResource? {
        if let config = scene.mediaConfig, let resource = resourceMap[config] {
            return resource
        } else {
            Self.logger.warn("getMediaResource for scene: \(scene) failed")
            return nil
        }
    }
}

extension MediaMutexScene {
    /// 媒体场景描述
    public var sceneDescription: String? {
        mediaConfig?.sceneDescription
    }

    /// scene 激活中
    /// 包含打断状态
    public var isActive: Bool {
        isRunning || isInterrupted
    }

    /// scene 工作中
    /// 不包含打断状态
    public var isRunning: Bool {
        LarkMediaManager.shared.mediaMutex.lockers.map { $0.value }.reduce(false) { $0 || $1.contains(scene: self) }
    }

    /// scene 被打断
    public var isInterrupted: Bool {
        LarkMediaManager.shared.mediaMutex.lockers.map { $0.value }.reduce(false) { $0 || $1.isInterrupted(scene: self) }
    }

    public var isEnabled: Bool {
        mediaConfig?.isEnabled ?? false
    }

    func errorMsg(type: MediaMutexType) -> String? {
        LarkMediaManager.shared.mediaMutex.dependency?.makeErrorMsg(scene: self, type: type)
    }
}
