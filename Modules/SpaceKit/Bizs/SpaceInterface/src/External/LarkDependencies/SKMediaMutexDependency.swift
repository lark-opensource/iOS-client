//
//  SKMediaMutexDependency.swift
//  SpaceInterface
//
//  Created by ByteDance on 2022/11/24.
//

import Foundation

public enum SKMediaScene: String {
    /// 文档语音录制
    /// e.g. 语音评论
    case ccmRecord
    /// 文档音视频播放
    case ccmPlay
}

public enum SKMediaInterruptResult {
    case success
    case occupiedByOther(msg: String?)
    case sceneNotFound
    case unknown
}

public protocol SKMediaMutexDependency {
    /// scene: 当前场景， 语音评论、音视频播放
    /// mixWithOthers: 用于让播放共存, 当且仅当播放池中所有 scene 都开启该选项时才能共存
    /// mute: 麦克风硬件静音开关，true为默认值，需要录音时传false
    func tryLock(scene: SKMediaScene,
                 mixWithOthers: Bool,
                 mute: Bool,
                 observer: SKMediaResourceInterruptionObserver,
                 interruptResult: @escaping (SKMediaInterruptResult) -> Void)
    func unlock(scene: SKMediaScene, observer: SKMediaResourceInterruptionObserver)
    func enterDriveAudioSessionScenario(scene: SKMediaScene, id: String)
    func leaveDriveAudioSessionScenario(scene: SKMediaScene, id: String)
}

public protocol SKMediaResourceInterruptionObserver: AnyObject {
    func mediaResourceInterrupted(with msg: String?)
    func meidaResourceInterruptionEnd()
}
