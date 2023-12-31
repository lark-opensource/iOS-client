//
//  AudioSessionFixer.swift
//  LarkMedia
//
//  Created by kiri on 2022/12/1.
//

import Foundation

extension LarkAudioSession {
    public enum FixOptions: String, CustomStringConvertible {
        /// 处理闹钟打断后没有声音的问题
        case activeOnAlarmEnd
        /// 因为预览页没有播放音频，此时进后台会在1s后失效，因此需要监听前台通知手动激活
        case activeOnForeground

        public var description: String { rawValue }
    }
}

final class AudioSessionFixer {
    let fixOptions: Set<LarkAudioSession.FixOptions>
    let onFixed: ((LarkAudioSession.FixOptions) -> Void)?

    init(options: Set<LarkAudioSession.FixOptions>, onFixed: ((LarkAudioSession.FixOptions) -> Void)?) {
        self.fixOptions = options
        self.onFixed = onFixed
        if options.isEmpty { return }
        if fixOptions.contains(.activeOnAlarmEnd) {
            NotificationCenter.default.addObserver(self, selector: #selector(didInterruptAudioSession(_:)),
                                                   name: AVAudioSession.interruptionNotification,
                                                   object: LarkAudioSession.shared.avAudioSession)
        }
        if fixOptions.contains(.activeOnForeground) {
            NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground(_:)),
                                                   name: UIApplication.willEnterForegroundNotification,
                                                   object: LarkAudioSession.shared.avAudioSession)
        }
    }

    @objc private func didInterruptAudioSession(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let t0 = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: t0),
              let o0 = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else {
            return
        }
        let opt = AVAudioSession.InterruptionOptions(rawValue: o0)
        if type == .ended, opt == .shouldResume {
            // 处理闹钟打断后没有声音的问题
            LarkAudioSession.logger.info("AudioSession will active when interruption resume")
            AudioQueue.execute.async("setActive(true) on interruptionEnd") { [weak self] in
                LarkAudioSession.shared._setActive(true)
                AudioQueue.callback.async("fix callback on interruptionEnd") {
                    self?.onFixed?(.activeOnAlarmEnd)
                }
            }
        }
    }

    @objc private func applicationWillEnterForeground(_ notification: Notification) {
        // 因为预览页没有播放音频，此时进后台会在1s后失效，因此需要监听前台通知手动激活
        LarkAudioSession.logger.info("AudioSession will active when enter foreground")
        AudioQueue.execute.async("setActive(true) on willEnterForeground") { [weak self] in
            LarkAudioSession.shared._setActive(true)
            AudioQueue.callback.async("fix callback on willEnterForeground") {
                self?.onFixed?(.activeOnForeground)
            }
        }
    }
}
