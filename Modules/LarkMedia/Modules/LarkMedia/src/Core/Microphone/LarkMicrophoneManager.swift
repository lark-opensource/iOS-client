//
//  LarkMicrophoneManager.swift
//  LarkMedia
//
//  Created by fakegourmet on 2023/6/14.
//

import Foundation
import LKCommonsLogging
import AVFoundation
import AudioUnit
import EEAtomic

final class LarkMicrophoneManager {

    static let logger = Logger.log(LarkMicrophoneManager.self, category: "LarkMedia.LarkMicrophoneManager")

    static let queueTag = DispatchSpecificKey<MediaMutexScene>()
    private static let queue = DispatchQueue(label: "LarkMedia.LarkMicrophoneManager.Queue")
    /// 回调线程
    private static let dispatchQueue = DispatchQueue.global(qos: .userInteractive)

    private let observerManager = ObserverManager<LarkMicrophoneObserver>()

    @RwAtomic
    private static var audioApplication: NSObject?

    private lazy var service: MicrophoneService = {
#if swift(>=5.9)
        if #available(iOS 17.0, *) {
            return AVMicrophoneServiceImpl()
        }
#else
        if #available(iOS 17.0, *), enableRuntime {
            return RTMicrophoneServiceImpl()
        }
#endif
        return AUMicrophoneServiceImpl()
    }()

    let scene: MediaMutexScene
    let enableRuntime: Bool
    init(scene: MediaMutexScene, enableRuntime: Bool) {
        self.scene = scene
        self.enableRuntime = enableRuntime
        Self.queue.setSpecific(key: Self.queueTag, value: scene)

        if #available(iOS 17.0, *) {
            registerNotification()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private static func sync<T>(execute work: () throws -> T) rethrows -> T {
        // 确保不发生死锁
        if DispatchQueue.getSpecific(key: Self.queueTag) == nil {
            return try Self.queue.sync {
                try work()
            }
        } else {
            return try work()
        }
    }

    func _requestMute(_ mute: Bool, observer: LarkMicrophoneObserver?, tag: String) -> Result<Void, MicrophoneMuteError> {
        Self.logger.info(with: tag, "[\(scene)] will set mute: \(mute)")

        switch checkMutex() {
        case .success(let config):
            // 标记 thread local
            Self.queue.setSpecific(key: Self.queueTag, value: scene)
            // VC 特化逻辑
            // AudioUnit 硬件静音临时解锁
            if #available(iOS 17.0, *), LarkAudioSession.isLockingInputMute, service is AUMicrophoneServiceImpl {
                if scene == .vcMeeting {
                    AudioUnitHooker.unlockAUInputMute()
                    // VC 会执行 RTC 硬件静音
                    return .success(Void())
                }
                if scene == .ultrawave {
                    // 会前超声波在调用 AudioUnit 接口时需要临时解锁
                    AudioUnitHooker.unlockAUInputMute()
                }
            }
            switch service.setMute(mute) {
            case .success:
                observerManager.addObserver(observer, for: config)
                Self.logger.info(with: tag, "[\(scene)] set mute: \(mute) success")
                return .success(Void())
            case .failure(let error):
                Self.logger.warn(with: tag, "[\(scene)] set mute: \(mute) fail: \(error)")
                return .failure(.systemError(error))
            }
        case .failure(let error):
            Self.logger.warn(with: tag, "[\(scene)] set mute: \(mute) fail: \(error)")
            return .failure(error)
        }
    }

    func _addObserver(_ observer: LarkMicrophoneObserver, tag: String) -> Result<Void, MicrophoneMuteError> {
        Self.logger.info(with: tag, "[\(scene)] will add observer")

        switch checkMutex() {
        case .success(let config):
            observerManager.addObserver(observer, for: config)
            Self.logger.info(with: tag, "[\(scene)] did add observer")
            return .success(Void())
        case .failure(let error):
            Self.logger.info(with: tag, "[\(scene)] add observer failed: \(error)")
            return .failure(error)
        }
    }

    private func checkMutex() -> Result<SceneMediaConfig, MicrophoneMuteError> {
        guard let config = scene.mediaConfig else {
            return .failure(.sceneNotFound)
        }

        guard let priority = config.mediaConfig[.record] else {
            return .failure(.mediaTypeInvalid)
        }

        guard config.isActive else {
            return .failure(.noMediaLock)
        }

        // mix 状态，且存在高优先级 scene 时，无法开启硬件静音
        if let locker = LarkMediaManager.shared.mediaMutex.lockers[.record] as? SoloMediaLocker,
           let otherPriority = locker.current?.mediaConfig[.record] {
            if priority < otherPriority {
                return .failure(.operationNotAllowed)
            }
        } else if let locker = LarkMediaManager.shared.mediaMutex.lockers[.record] as? MixMediaLocker {
            for config in locker.current {
                if let otherPriority = config.mediaConfig[.record], priority < otherPriority {
                    return .failure(.operationNotAllowed)
                }
            }
        }

        return .success(config)
    }
}

@available(iOS 17.0, *)
extension LarkMicrophoneManager {

    /// 启动时注册系统硬件静音变化通知
    private func registerNotification() {
        initAudioApplicationIfNeeded()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didChangeInputState(_:)),
                                               name: LarkAudioSession.lkInputMuteStateChangeNotification,
                                               object: nil)
    }

    private func initAudioApplicationIfNeeded() {
        guard Self.audioApplication == nil else {
            return
        }
#if swift(>=5.9)
        Self.audioApplication = AVAudioApplication.shared
        Self.logger.info("AVAudioApplication init success")
#else
        guard enableRuntime else {
            Self.logger.info("AVAudioApplication init disabled")
            return
        }
        Self.audioApplication = AVAudioSession.sharedApplication()
#endif
    }

    @objc func didChangeInputState(_ notification: Notification) {
        Self.logger.info("receive AVAudioApplication.inputMuteStateChangeNotification: \(notification)")
        guard let isMuted = notification.userInfo?[LarkAudioSession.lkMuteStateKey] as? Bool else {
            Self.logger.warn("AVAudioApplication.inputMuteStateChangeNotification no AVAudioApplication.muteStateKey")
            return
        }
        let isTriggeredInApp: Bool? = notification.userInfo?[LarkAudioSession.isTriggeredInApp] as? Bool
        observerManager.notifyMicrophoneMuteStateChange(isMuted: isMuted, isTriggeredInApp: isTriggeredInApp)
    }
}

extension LarkMicrophoneManager: LarkMicrophoneService {

    public var isMuted: Bool {
        Self.isInputMuted
    }

    static var isInputMuted: Bool {
#if swift(>=5.9)
        if #available(iOS 17.0, *) {
            return AVAudioApplication.shared.isInputMuted
        }
#else
        if #available(iOS 17.0, *), LarkMediaManager.shared.mediaMutex.dependency?.enableRuntime == true {
            return LarkAudioSession.shared.avAudioSession.isInputMuted()
        }
#endif
        return false
    }

    public func requestMute(_ mute: Bool,
                            observer: LarkMicrophoneObserver?,
                            completion: @escaping ((Result<Void, MicrophoneMuteError>) -> Void)) {
        let tag = Self.logger.getTag()
        Self.queue.async {
            let result = self._requestMute(mute, observer: observer, tag: tag)
            Self.dispatchQueue.async {
                completion(result)
            }
        }
    }

    public func requestMute(_ mute: Bool, observer: LarkMicrophoneObserver?) -> Result<Void, MicrophoneMuteError> {
        let tag = Self.logger.getTag()
        return Self.sync {
            self._requestMute(mute, observer: observer, tag: tag)
        }
    }

    public func addObserver(_ observer: LarkMicrophoneObserver,
                            completion: @escaping ((Result<Void, MicrophoneMuteError>) -> Void)) {
        let tag = Self.logger.getTag()
        Self.queue.async {
            let result = self._addObserver(observer, tag: tag)
            Self.dispatchQueue.async {
                completion(result)
            }
        }
    }
}
