//
//  LarkAudioSession+Scenario.swift
//  LarkMedia
//
//  Created by FakeGourmet on 2023/7/27.
//

import Foundation

extension LarkAudioSession {

    /// - Returns: 是否执行过 setCategory 相关方法
    @discardableResult
    func _updateScenario(_ scenario: AudioSessionScenario) -> Bool {
        let shouldUpdateCategory = scenario.category != avAudioSession.category || scenario.options != avAudioSession.categoryOptions
        let shouldUpdateMode = scenario.mode != avAudioSession.mode
        let shouldUpdatePolicy = scenario.policy != avAudioSession.routeSharingPolicy
        do {
            switch (shouldUpdateCategory, shouldUpdateMode) {
            case (_, true):
                if #available(iOS 11.0, *), shouldUpdatePolicy {
                    try setCategory(scenario.category, mode: scenario.mode, policy: scenario.policy, options: scenario.options)
                } else if #available(iOS 10.0, *) {
                    try setCategory(scenario.category, mode: scenario.mode, options: scenario.options)
                } else {
                    try setCategory(scenario.category, options: scenario.options)
                    try setMode(scenario.mode)
                    // setMode: would reset options so it should be set again.
                    try setCategory(scenario.category, options: scenario.options)
                }
                return true
            case (true, false):
                try setCategory(scenario.category, options: scenario.options)
                return true
            default:
                logger.info("Skip update scenario: \(scenario), current is the same setting")
                return false
            }
        } catch {
            let current = AudioSessionScenario("",
                                               category: avAudioSession.category,
                                               mode: avAudioSession.mode,
                                               options: avAudioSession.categoryOptions,
                                               policy: avAudioSession.routeSharingPolicy,
                                               isNeedActive: true)
            logger.error("Entry Audio Session Scenario \(scenario.name) failed with error \(error), current is: \(current)")
            return true
        }
    }

    func _setActive(_ active: Bool,
                    options: AVAudioSession.SetActiveOptions = [.notifyOthersOnDeactivation],
                    enableResetSessionWhenDeactivating: Bool = true) {
        do {
            logger.info("AVAudioSession set active: \(active), with options: \(options.rawValue)")
            try setActive(active, options: options)
            if enableResetSessionWhenDeactivating && !active {
                logger.info("AVAudioSession reset session")
                try setCategory(.soloAmbient, mode: .default, options: [])
            }
        } catch let error {
            logger.error("AVAudioSession set active: \(active) error: \(error.localizedDescription)")
        }
    }

    /// check enableSpeakerIfNeeded，仅用于execute线程
    private static var enableSpeakerCheckKey: UUID?

    func _enableSpeakerIfNeeded(enable: Bool, force: Bool, file: String = #fileID, function: String = #function, line: Int = #line) {
        do {
            if !force, enable, LarkAudioSession.shared.isHeadsetConnected {
                return
            } else {
                try overrideOutputAudioPort(enable ? .speaker : .none, file: file, function: function, line: line)
            }
        } catch let error {
            logger.error("enableSpeakerIfNeeded(\(enable)) error: \(error.localizedDescription)", file: file, function: function, line: line)
            AudioTracker.shared.trackAudioEvent(key: .overrideOutputAudioPortFailed, params: ["isSpeaker": enable, "error": error.localizedDescription])
        }
        #if DEBUG || ALPHA
        logger.info("enableSpeakerIfNeeded(\(enable)) done and current output is \(currentRoute.audioOutput)", file: file, function: function, line: line)
        #endif
        let key = UUID()
        Self.enableSpeakerCheckKey = key
        AudioQueue.execute.async("check enableSpeaker result", delay: .milliseconds(500)) { [weak self] in
            guard let self = self, Self.enableSpeakerCheckKey == key else { return }
            if !enable && self.currentRoute.audioOutput == .speaker {
                AudioTracker.shared.trackAudioEvent(key: .overrideOutputAudioPortFailed, params: ["isSpeaker": enable, "error": "invalid"])
                self.logger.warn("override false but still speaker, maybe the audio session is not active", file: file, function: function, line: line)
            }
        }
    }
}

public extension LarkAudioSession {

    /// 开启扬声器
    func enableSpeakerIfNeeded(_ enable: Bool, force: Bool = false,
                               file: String = #fileID, function: String = #function, line: Int = #line) {
        AudioQueue.execute.async("enableSpeakerIfNeeded", file: file, function: function, line: line) {
            self._enableSpeakerIfNeeded(enable: enable, force: force, file: file, function: function, line: line)
        }
    }
}
