//
//  LarkAudioSession+Hook.swift
//  LarkMedia
//
//  Created by FakeGourmet on 2023/8/2.
//

import Foundation
import MachO

extension LarkAudioSession {
    @RwAtomic
    private(set) static var isHooked = false

    private static var hookers: [Hooker] = {
        let enableRuntime: Bool = LarkMediaManager.shared.mediaMutex.dependency?.enableRuntime == true
#if swift(>=5.9)
        let enableLock: Bool = true
#else
        let enableLock: Bool
        if #available(iOS 17.0, *) {
            enableLock = enableRuntime
        } else {
            enableLock = false
        }
#endif
        var hookers: [Hooker] = [
            AVAudioNotificationHooker(),
            AVAudioSessionHooker(),
            AVAudioRecorderHooker(),
            AVCaptureSessionHooker(),
            AVAudioEngineHooker(),
            AVAssetWriterInputHooker(),
            AudioUnitHooker(enableLock: enableLock)
        ]
        if #available(iOS 17.0, *) {
            hookers.append(AVAudioApplicationHooker(enabled: enableLock))
            if enableRuntime {
                // trigger 需要提前初始化
                // 否则会有读写问题
                _ = LarkAudioSession.trigger
            }
        }
        return hookers
    }()

    private func getLoadAddress() -> Int {
        for i in 0..<_dyld_image_count() {
            if _dyld_get_image_header(i).pointee.filetype == MH_EXECUTE {
                return _dyld_get_image_vmaddr_slide(i)
            }
        }
        return 0
    }

    public func hookAudioSession() {
        if Self.isHooked { return }
        Self.isHooked = true
        Self.logger.info("hook start, load address: \(String(format: "0x%2X", getLoadAddress()))")
        Self.hookers.filter { $0.enabled }.forEach {
            $0.willHook()
            $0.hook()
            $0.didHook()
        }
    }
}

// MARK: - Hook Log
extension LarkAudioSession {

    static func hook(_ values: Any...,
                     function: String = #function,
                     block: () throws -> Void,
                     completion: (Result<Void, Error>) -> Void) rethrows {
        let callAddress = AVAudioSession.callReturnAddress()
        let start = CACurrentMediaTime()
        do {
            try block()
            logger.info("\(function), values: \(values), address: \(callAddress) duration = \(round((CACurrentMediaTime() - start) * 1e6) / 1e3)ms")
            completion(.success(Void()))
        } catch {
            completion(.failure(error))
            throw error
        }
    }

    static func hook(_ values: Any?...,
                     function: String = #function,
                     block: () throws -> Void,
                     completion: (Result<Void, Error>) -> Void) rethrows {
        let callAddress = AVAudioSession.callReturnAddress()
        let start = CACurrentMediaTime()
        do {
            try block()
            logger.info("\(function), values: \(values), address: \(callAddress) duration = \(round((CACurrentMediaTime() - start) * 1e6) / 1e3)ms")
            completion(.success(Void()))
        } catch {
            completion(.failure(error))
            throw error
        }
    }

    static func hook<T>(_ values: Any?...,
                     function: String = #function,
                     block: () -> T) -> T {
        let callAddress = AVAudioSession.callReturnAddress()
        let start = CACurrentMediaTime()
        let result = block()
        logger.info("\(function), values: \(values), address: \(callAddress) duration = \(round((CACurrentMediaTime() - start) * 1e6) / 1e3)ms")
        return result
    }
}

// MARK: - Trigger
@available(iOS 17.0, *)
extension LarkAudioSession {
    @RwAtomic
    private(set) static var trigger = AudioInputTrigger(isMuted: LarkMicrophoneManager.isInputMuted, isMock: true)

    static func startTrigger(isMuted: Bool) {
        Self.trigger.cancel()
        Self.trigger = AudioInputTrigger(isMuted: isMuted)
    }
}

// MARK: - Lock Input Mute
@available(iOS 17.0, *)
extension LarkAudioSession {
    /// 激活时其他业务无法设置硬件静音
    static var isLockingInputMute: Bool {
        lockingInputMuteScene.reduce(false) { $0 || $1.isActive }
    }

    static let lockingInputMuteScene: [MediaMutexScene] = [.vcMeeting, .ultrawave]
}
