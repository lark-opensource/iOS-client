//
//  LarkMicrophoneService.swift
//  LarkMedia
//
//  Created by FakeGourmet on 2023/8/2.
//

import Foundation

/// LarkMedia 对外提供麦克风硬件静音方法
public protocol LarkMicrophoneService {
    /// 麦克风硬件静音是否开启
    /// iOS 17 以下永久返回`false`
    var isMuted: Bool { get }

    /// 请求开关麦克风硬件静音
    /// - Parameter mute: 开关状态
    /// - Parameter observer: 硬件静音状态变化监听者
    /// - Parameter completion: 回调
    /// - 成功，回调 `success`。
    /// - 失败，回调 `failure`。错误类型为 `MicrophoneMuteError`
    /// - 需要先通过 tryLock 获取媒体锁
    /// - 回调线程为 Global 线程
    func requestMute(_ mute: Bool,
                     observer: LarkMicrophoneObserver?,
                     completion: @escaping ((Result<Void, MicrophoneMuteError>) -> Void))

    /// 请求开关麦克风硬件静音
    /// - Parameter mute: 开关状态
    /// - Parameter observer: 硬件静音状态变化监听者
    /// - 需要先通过 tryLock 获取媒体锁
    func requestMute(_ mute: Bool, observer: LarkMicrophoneObserver?) -> Result<Void, MicrophoneMuteError>

    /// 添加观察者
    /// 会覆盖通过 requestMute 注册的观察者
    /// - Parameter observer: 硬件静音状态变化监听者
    /// - Parameter completion: 回调
    /// - 回调线程为 Global 线程
    func addObserver(_ observer: LarkMicrophoneObserver,
                     completion: @escaping ((Result<Void, MicrophoneMuteError>) -> Void))
}

public extension LarkMicrophoneService {
    func requestMute(_ mute: Bool, completion: @escaping ((Result<Void, MicrophoneMuteError>) -> Void)) {
        requestMute(mute, observer: nil, completion: completion)
    }

    func requestMute(_ mute: Bool) -> Result<Void, MicrophoneMuteError> {
        requestMute(mute, observer: nil)
    }

    func addObserver(_ observer: LarkMicrophoneObserver) {
        addObserver(observer, completion: { _ in })
    }
}

public protocol LarkMicrophoneObserver: AnyObject {

    /// 硬件静音变化事件
    /// 用户点击静音提示条事件也会触发该回调
    /// - Parameter isMuted: 开关状态
    /// - Parameter isTriggeredInApp: 是否是由 App 内触发，为空代表不知道
    func applicationMicrophoneMuteStateDidChange(isMuted: Bool, isTriggeredInApp: Bool?)
}

public enum MicrophoneMuteError: Error {
    case unknown
    case mediaTypeInvalid
    case sceneNotFound
    case noMediaLock
    case operationNotAllowed
    case osError(OSStatus)
    case systemError(Error)
}
