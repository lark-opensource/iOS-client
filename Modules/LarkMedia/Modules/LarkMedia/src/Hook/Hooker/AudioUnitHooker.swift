//
//  AudioUnitHooker.swift
//  LarkMedia
//
//  Created by FakeGourmet on 2023/7/27.
//

import AVFAudio

public extension LarkAudioSession {
    static let lkAudioOutputUnitDidStart = Notification.Name("LarkAudioSession.lkAudioOutputUnitDidStart")
    static let lkAudioOutputUnitDidStop = Notification.Name("LarkAudioSession.lkAudioOutputUnitDidStop")
    // OSStatus
    static let audioUnitStatusKey = "LarkAudioSession.audioUnitStatusKey"
}

class AudioUnitHooker: Hooker {

    private var hookResult: Int32 = 1

    private let enableLock: Bool

    /// - Parameter enableLock: 是否锁定 MuteOutput 调用
    init(enableLock: Bool) {
        self.enableLock = enableLock
    }

    func willHook() {
        AVAudioSession.setLogHandler { info in
            LarkAudioSession.logger.info(info)
        }
        AVAudioSession.setWillStartHandler { _ in } didStartHandler: { status in
            if status != noErr {
                AudioTracker.shared.trackAudioEvent(key: .audioUnitStartFailed, params: ["error": status])
            }
            NotificationCenter.default.post(name: LarkAudioSession.lkAudioOutputUnitDidStart, object: LarkAudioSession.shared, userInfo: [LarkAudioSession.audioUnitStatusKey: status])
        }

        AVAudioSession.setWillStopHandler { _ in } didStopHandler: { status in
            if status != noErr {
                AudioTracker.shared.trackAudioEvent(key: .audioUnitStopFailed, params: ["error": status])
            }
            NotificationCenter.default.post(name: LarkAudioSession.lkAudioOutputUnitDidStop, object: LarkAudioSession.shared, userInfo: [LarkAudioSession.audioUnitStatusKey: status])
        }

        if #available(iOS 17.0, *), enableLock {
            AVAudioSession.setWillMuteOutputHandler { isMuted in
                if LarkAudioSession.isLockingInputMute, Self.isLockingAUInputMute {
                    LarkAudioSession.logger.warn("AudioUnit.kAUVoiceIOProperty_MuteOutput is locked")
                    return false
                } else {
                    LarkAudioSession.startTrigger(isMuted: isMuted)
                    return true
                }
            } didMuteOutputHandler: { _, _ in
                if !Self.isLockingAUInputMute {
                    Self.isLockingAUInputMute = true
                }
            }
        }
    }

    func hook() {
        hookResult = AVAudioSession.hookAudioUnit()
    }

    func didHook() {
        if hookResult == 0 {
            LarkAudioSession.logger.info("AVAudioSession audio unit hook start")
        } else {
            LarkAudioSession.logger.error("AVAudioSession audio unit hook failed")
        }
    }
}

// MARK: - Lock Input Mute
@available(iOS 17.0, *)
extension AudioUnitHooker {

    static func unlockAUInputMute() {
        isLockingAUInputMute = false
    }

    /// 激活时其他业务无法通过 AudioUnit 设置硬件静音
    @RwAtomic
    private static var isLockingAUInputMute: Bool = true {
        didSet {
            LarkAudioSession.logger.info("isLockingAUInputMute did change: \(isLockingAUInputMute)")
        }
    }
}
