//
//  ProximityMonitor.swift
//  ByteView
//
//  Created by kiri on 2020/8/7.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import AVFoundation
import ByteViewMeeting
import LarkMedia

final class ProximityMonitor {
    static let logger = Logger.util

    private static var isMonitoring = false

    static var isSharingScreen = false {
        didSet {
            logger.info("proximity monitoring update isSharingScreen:\(isSharingScreen), and old value:\(oldValue)")
            if isSharingScreen != oldValue {
                updateProximityMonitorEnabled()
            }
        }
    }

    // return isPortrait && !isFloating && audioOutput == .receiver && !iAmSharingScreen && scene != .follow
    @RwAtomic
    private static var isPortrait = true {
        didSet {
            logger.info("proximity monitoring update isPortrait:\(isPortrait), and old value:\(oldValue)")
            if isPortrait != oldValue {
                updateProximityMonitorEnabled()
            }
        }
    }

    private static var isAudioOutputReceiver = false {
        didSet {
            logger.info("proximity monitoring update isAudioOutputReceiver:\(isAudioOutputReceiver), and old value:\(oldValue)")
            if isAudioOutputReceiver != oldValue {
                updateProximityMonitorEnabled()
            }
        }
    }

    static func start(isPortrait: Bool) {
        logger.info("start proximity monitoring")
        Self.isPortrait = isPortrait
        NotificationCenter.default.addObserver(Self.self, selector: #selector(updateProximityMonitorEnabled),
                                               name: UIApplication.didBecomeActiveNotification, object: nil)
        isMonitoring = true
        updateProximityMonitorEnabled()
    }

    static func stop() {
        isMonitoring = false
        NotificationCenter.default.removeObserver(Self.self)
        DispatchQueue.global(qos: .default).async {
            logger.info("AVAudioSession mode is \(LarkAudioSession.shared.mode)")
        }
        Util.runInMainThread {
            do {
                logger.info("stop proximity monitoring")
                try DeviceSncWrapper.setProximityMonitoringEnabled(for: .proximityMonitor, device: .current, isEnabled: false)
            } catch {
                logger.warn("Cannot stop proximity monitor, UIDevice Proximity APIs are disabled by LarkSensitivityControl")
            }
        }
    }

    @objc
    private static func updateProximityMonitorEnabled() {
        if !isMonitoring {
            return
        }

        let isEnabled: Bool
        let isCallKit = MeetingManager.shared.currentSession?.isCallKit ?? false
        if isCallKit {
            isEnabled = isPortrait && isAudioOutputReceiver
        } else {
            isEnabled = isPortrait && isAudioOutputReceiver && !isSharingScreen
        }

        Util.runInMainThread {
            do {
                let currentEnabled = try DeviceSncWrapper.isProximityMonitoringEnabled(for: .proximityMonitor, device: .current)
                if isEnabled != currentEnabled {
                    logger.info("switch proximity, isEnabled = \(isEnabled), isCallKit = \(isCallKit)")
                    try DeviceSncWrapper.setProximityMonitoringEnabled(for: .proximityMonitor, device: .current, isEnabled: isEnabled)
                }
            } catch {
                logger.warn("Cannot update proximity monitor to \(isEnabled), UIDevice Proximity APIs are disabled by LarkSensitivityControl")
            }
        }
    }

    static func updateAudioOutput(route: AudioOutput, isMuted: Bool) {
        logger.info("proximity monitoring update AudioOutput: isMuted = \(isMuted), route = \(route)")
        isAudioOutputReceiver = route == .receiver && !isMuted
    }

    static func updateOrientation(isPortrait: Bool) {
        Self.isPortrait = isPortrait
    }
}
