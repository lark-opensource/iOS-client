//
//  LarkAudioSessionExtension.swift
//  LarkMedia
//
//  Created by FakeGourmet on 2023/8/2.
//

import Foundation

public extension LarkAudioSession {

    static func setup(execute block: @escaping () -> Void) {
        AudioQueue.execute.async("setup LarkAudioSession") {
            let startTime = CACurrentMediaTime()
            _ = Self.shared
            block()
            let duration = round((CACurrentMediaTime() - startTime) * 1e6) / 1e3
            logger.info("setup LarkAudioSession, duration = \(duration)ms")
        }
    }

    /// 等待AudioSession的Tasks完成
    /// - note: completion在callback queue，不会block后续的AudioSession Task执行
    func waitAudioSession(_ reason: String, in queue: DispatchQueue? = nil, completion: @escaping () -> Void) {
        AudioQueue.execute.async(reason) {
            if let queue = queue {
                queue.async(execute: completion)
            } else {
                AudioQueue.callback.async(reason, execute: completion)
            }
        }
    }

    /// 修复一些导致音频无声的问题
    /// - returns: 返回修复器的引用，释放该引用则修复停止
    func fixAudioSession(_ options: Set<FixOptions>, onFixed: ((FixOptions) -> Void)? = nil) -> AnyObject {
        return AudioSessionFixer(options: options, onFixed: onFixed)
    }

    var currentOutput: AudioOutput {
        currentRoute.audioOutput
    }

    var isSpeakerOn: Bool {
        currentOutput == .speaker
    }

    /// 不会耗时很久
    var isHeadsetActive: Bool {
        currentRoute.outputs.contains(where: { $0.portType.isHeadset })
    }

    /// 不会耗时很久
    var isBluetoothActive: Bool {
        currentRoute.outputs.contains(where: { $0.portType.isBluetooth })
    }

    /// 会耗时较久，不宜在主线程使用
    var isHeadsetConnected: Bool {
        if isHeadsetActive { return true }
        assert(!Thread.isMainThread, "isHeadSetConnected maybe take too long!")
        guard let availableInputs = AVAudioSession.sharedInstance().availableInputs else { return false }
        return availableInputs.contains(where: { $0.portType.isHeadset })
    }

    /// 会耗时较久，不宜在主线程使用
    var isBluetoothConnected: Bool {
        if isBluetoothActive { return true }
        assert(!Thread.isMainThread, "isBluetoothConnected maybe take too long!")
        guard let availableInputs = AVAudioSession.sharedInstance().availableInputs else { return false }
        return availableInputs.contains(where: { $0.portType.isBluetooth })
    }
}
