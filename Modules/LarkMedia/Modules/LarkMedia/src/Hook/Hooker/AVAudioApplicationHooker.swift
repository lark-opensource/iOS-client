//
//  AVAudioApplicationHooker.swift
//  LarkMedia
//
//  Created by FakeGourmet on 2023/7/27.
//

import AVFAudio

extension LarkAudioSession {
    static let lkInputMuteStateChangeNotification = Notification.Name("LarkAudioSession.lkInputMuteStateChangeNotification")
    static let isTriggeredInApp = Notification.Name("LarkAudioSession.isTriggeredInApp")
    static let lkMuteStateKey: String = {
#if swift(>=5.9)
        if #available(iOS 17.0, *) {
            return AVAudioApplication.muteStateKey
        }
#endif
        return "AVAudioApplicationMuteStateKey"
    }()
}

@available(iOS 17.0, *)
class AVAudioApplicationHooker: NSObject, Hooker {

    let enabled: Bool

    /// - Parameter enabled: 是否启动 Hook
    init(enabled: Bool) {
        self.enabled = enabled
    }

#if swift(>=5.9)
    let swizzleArray: [(Selector, Selector)] = [
        (#selector(AVAudioApplication.setInputMuted(_:)), #selector(AVAudioApplication.lk_setInputMuted(_:)))
    ]

    func willHook() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didChangeInputState(_:)),
                                               name: AVAudioApplication.inputMuteStateChangeNotification,
                                               object: AVAudioApplication.shared)
    }

    func hook() {
        swizzleArray.forEach {
            swizzleInstanceMethod(AVAudioApplication.self, from: $0.0, to: $0.1)
        }
    }
#else
    func willHook() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didChangeInputState(_:)),
                                               name: NSNotification.Name("AVAudioApplicationInputMuteStateChangeNotification"),
                                               object: nil)
    }

    func hook() {
        guard let cls = NSClassFromString("AVAudioApplication") else {
            return
        }
        let sel1 = NSSelectorFromString("setInputMuted:error:")
        swizzleInstanceMethod(from: cls, sel1: sel1, to: Self.self, sel2: #selector(Self.lk_setInputMuted(_:)))
    }
#endif

    func didHook() {
        LarkAudioSession.logger.info("AVAudioApplication swizzle start")
    }

    @objc
    private func didChangeInputState(_ notification: Notification) {
        var userInfo: [AnyHashable: Any] = notification.userInfo ?? [:]
        guard let isInputMuted = userInfo[LarkAudioSession.lkMuteStateKey] as? Bool else {
            LarkAudioSession.logger.warn("\(#function) no mute state value")
            return
        }

        if LarkAudioSession.trigger.isOutDated {
            userInfo[LarkAudioSession.isTriggeredInApp] = LarkAudioSession.trigger.isMuted == isInputMuted
            NotificationCenter.default.post(name: LarkAudioSession.lkInputMuteStateChangeNotification, object: notification.object, userInfo: userInfo)
        } else {
            LarkAudioSession.trigger.update(isMuted: isInputMuted) { isTriggeredInApp in
                userInfo[LarkAudioSession.isTriggeredInApp] = isTriggeredInApp
                NotificationCenter.default.post(name: LarkAudioSession.lkInputMuteStateChangeNotification, object: notification.object, userInfo: userInfo)
            }
        }
    }

    static func hook_setInputMuted(_ isMuted: Bool, origin: @escaping (Bool) throws -> Void, function: String = #function) throws {
        // 线程检测
        if let scene = DispatchQueue.getSpecific(key: LarkMicrophoneManager.queueTag) {
            // 注册业务
            if LarkAudioSession.isLockingInputMute,
               !LarkAudioSession.lockingInputMuteScene.contains(scene) {
                LarkAudioSession.logger.warn("AVAudioApplication.setInputMuted is locked")
                throw MicrophoneMuteError.operationNotAllowed
            }
        } else {
            // 未知业务
            AudioTracker.shared.trackAudioEvent(key: .microphoneMutedUnexpected, params: ["thread": Thread.callStackSymbols.joined(separator: "\n")])
            if LarkAudioSession.isLockingInputMute {
                LarkAudioSession.logger.warn("AVAudioApplication.setInputMuted is locked")
                throw MicrophoneMuteError.operationNotAllowed
            }
        }

        try LarkAudioSession.hook(isMuted, function: function, block: {
            LarkAudioSession.startTrigger(isMuted: isMuted)
            return try origin(isMuted)
        }, completion: { result in
            switch result {
            case .failure(let error):
                AudioTracker.shared.trackAudioEvent(key: .microphoneMutedFailed, params: ["error": error.localizedDescription])
            default:
                break
            }
        })
    }
}

// MARK: - Hook AVAudioApplication
#if swift(>=5.9)
@available(iOS 17.0, *)
private extension AVAudioApplication {
    @objc dynamic func lk_setInputMuted(_ isMuted: Bool) throws {
        try AVAudioApplicationHooker.hook_setInputMuted(isMuted) { isMuted in
            try self.lk_setInputMuted(isMuted)
        }
    }
}

#else
@available(iOS 17.0, *)
private extension AVAudioApplicationHooker {
    @objc dynamic func lk_setInputMuted(_ isMuted: Bool) throws {
        try AVAudioApplicationHooker.hook_setInputMuted(isMuted) { isMuted in
            try self.lk_setInputMuted(isMuted)
        }
    }
}

#endif
