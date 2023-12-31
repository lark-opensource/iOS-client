//
//  InMeetAudioSessionTracker.swift
//  ByteView
//
//  Created by kiri on 2022/11/8.
//

import Foundation
import RxSwift
import AVFoundation
import LarkMedia
import ByteViewTracker

final class InMeetAudioSessionTracker: NSObject {

    private let service: MeetingBasicService
    private let logger: Logger
    private let tracker = AudioAppreciableTracker()

    init(service: MeetingBasicService) {
        let sessionId = service.sessionId
        self.service = service
        self.logger = Logger.audioSession.withContext(sessionId).withTag("[InMeetAudioSessionTracker(\(sessionId))]")
        super.init()
        let t0 = CACurrentMediaTime()
        NotificationCenter.default.addObserver(self, selector: #selector(activeDidChange(_:)),
                                               name: LarkAudioSession.activeHasChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(categoryDidChange(_:)),
                                               name: LarkAudioSession.categoryHasChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(modeDidChange(_:)),
                                               name: LarkAudioSession.modeHasChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(audioUnitDidStart(_:)),
                                               name: LarkAudioSession.lkAudioOutputUnitDidStart, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(audioUnitDidStop(_:)),
                                               name: LarkAudioSession.lkAudioOutputUnitDidStop, object: nil)

        LarkAudioSession.rx.routeChangeObservable
            .map { reason in (reason, AVAudioSession.sharedInstance().currentRoute) }
            .scan((nil, nil)) { ($0.1, $1) }
            .subscribe(onNext: { [weak self] (previousRouteInfo, currentRouteInfo) in
                let reason = currentRouteInfo?.0
                self?.routeDidChange(reason: reason, currentRoute: currentRouteInfo?.1, previousRoute: previousRouteInfo?.1)
            })
            .disposed(by: rx.disposeBag)

        LarkAudioSession.rx.interruptionObservable
            .subscribe(onNext: { [weak self] info in
                if info.options.contains(.shouldResume) {
                    self?.tracker.end(.interrupt_resume_time)
                } else {
                    let params = ["reason": info.reason]
                    self?.tracker.start(.interrupt_resume_time, params: params)
                    self?.tracker.start(.interrupt_start_time, params: params)
                }
                if info.reason == .appWasSuspended {
                    DevTracker.post(.audio(.app_was_suspend))
                } else if info.reason == .builtInMicMuted {
                    DevTracker.post(.audio(.built_in_mic_muted))
                }
            }).disposed(by: rx.disposeBag)

        LarkAudioSession.rx.mediaServicesLostObservable
            .subscribe(onNext: { [weak self] _ in
                DevTracker.post(.audio(.media_service_lost))
                self?.tracker.start(.media_lost_reset_time)
                self?.tracker.start(.media_lost_start_time)
            }).disposed(by: rx.disposeBag)

        LarkAudioSession.rx.mediaServicesResetObservable
            .subscribe(onNext: { [weak self] _ in
                self?.tracker.end(.media_lost_reset_time)
                DevTracker.post(.audio(.media_service_reset))
            }).disposed(by: rx.disposeBag)

        let bluetoothDeviceSet: Set<AVAudioSession.Port> = [.bluetoothA2DP, .bluetoothLE, .bluetoothHFP]
        /// 会中蓝牙耳机相关状态上报
        if let device = AVAudioSession.sharedInstance().currentRoute.outputs.first, bluetoothDeviceSet.contains(device.portType) {
            VCTracker.post(name: .vc_bluetooth_status, params: [
                "status": "onthecall",
                "bluetooth_device_name": device.portName,
                "bluetooth_connect_protocol": device.portType.rawValue
            ])
        }
        AVAudioSession.sharedInstance().addObserver(self, forKeyPath: "outputVolume", options: [.old, .new], context: nil)
        let duration = CACurrentMediaTime() - t0
        logger.info("init InMeetAudioSessionTracker, duration = \(Util.formatTime(duration))")
    }

    deinit {
        tracker.cancel(.media_lost_start_time)
        tracker.cancel(.interrupt_start_time)
        AVAudioSession.sharedInstance().removeObserver(self, forKeyPath: "outputVolume")
        logger.info("deinit InMeetAudioSessionTracker")
    }

    @objc private func activeDidChange(_ notification: Notification) {
        guard let isActive = notification.userInfo?[LarkAudioSession.activeValue] as? Bool, !isActive else {
            return
        }
        logger.info("Audio session is deactivated in meeting by other module")
        VCTracker.shared.trackUserException("audio_session_deactivating_not_in_vc")
        DevTracker.post(.audio(.deactived_in_vc))
    }

    @objc private func categoryDidChange(_ notification: Notification) {
        guard let category = notification.userInfo?[LarkAudioSession.categoryValue] as? AVAudioSession.Category, category != .playAndRecord else {
            return
        }
        logger.info("Audio session Category is modified in meeting by other module, category = \(category.rawValue)")
        DevTracker.post(.audio(.category_changed_in_vc))
    }

    @objc private func modeDidChange(_ notification: Notification) {
        guard let mode = notification.userInfo?[LarkAudioSession.modeValue] as? AVAudioSession.Mode, mode != .voiceChat else {
            return
        }
        logger.info("Audio session Mode is modified in meeting by other module, mode = \(mode.rawValue)" )
        DevTracker.post(.audio(.mode_changed_in_vc))
    }

    @objc private func audioUnitDidStart(_ notification: Notification) {
        guard let status = notification.userInfo?[LarkAudioSession.audioUnitStatusKey] as? OSStatus else { return }
        DevTracker.post(.audio(.audio_unit_start).params(["status": status]))
        if status == 0 {
            tracker.end(.media_lost_start_time)
            tracker.end(.interrupt_start_time)
        }
    }

    @objc private func audioUnitDidStop(_ notification: Notification) {
        guard let status = notification.userInfo?[LarkAudioSession.audioUnitStatusKey] as? OSStatus else { return }
        DevTracker.post(.audio(.audio_unit_stop).params(["status": status]))
    }

    private func routeDidChange(reason: AVAudioSession.RouteChangeReason?, currentRoute: AVAudioSessionRouteDescription?, previousRoute: AVAudioSessionRouteDescription?) {
        guard let reason = reason, let currentOutput = currentRoute?.outputs.first, let currentAudioOutput = currentRoute?.audioOutput, let currentInput = currentRoute?.inputs.first, let previousOutput = previousRoute?.outputs.first, let previousAudioOutput = previousRoute?.audioOutput, let previousInput = previousRoute?.inputs.first else {
            return
        }

        // 输入输出有变动
        if currentInput.portType != previousInput.portType {
            /// 输入设备变动
            VCTracker.post(name: .vc_bluetooth_status,
                           params: ["status": "input_change",
                                    "input_name_before_switch": previousInput.portName,
                                    "input_name_after_switch": currentInput.portName,
                                    "bluetooth_connect_protocol": currentInput.portType.rawValue])
        }
        if currentOutput.portType != previousOutput.portType {
            /// 输出设备变动
            VCTracker.post(name: .vc_bluetooth_status,
                           params: ["status": "output_change",
                                    "output_name_before_switch": previousOutput.portName,
                                    "output_name_after_switch": currentOutput.portName,
                                    "bluetooth_connect_protocol": currentOutput.portType.rawValue])
        }

        switch reason {
        case .newDeviceAvailable:
            if currentAudioOutput == .bluetooth {

                /// 连接新蓝牙耳机
                VCTracker.post(name: .vc_bluetooth_status,
                               params: ["status": "connect_bluetooth", "device_name": currentOutput.portName])
            }
        case .oldDeviceUnavailable:
            if previousAudioOutput == .bluetooth {
                /// 断开蓝牙耳机
                VCTracker.post(name: .vc_bluetooth_status,
                               params: ["status": "disconnect_bluetooth", "device_name": previousOutput.portName])
            }
        case .categoryChange:
            if currentAudioOutput == .bluetooth, AVAudioSession.sharedInstance().category == AVAudioSession.Category.playAndRecord {
                /// 蓝牙耳机只有输入没有输出
                VCTracker.post(name: .vc_bluetooth_status,
                               params: ["status": "bluetooth_is_output_invalid", "device_name": currentOutput.portName])
            }
        case .override:
            if currentAudioOutput == .speaker {
                /// 强制切换成扬声器
                VCTracker.post(name: .vc_bluetooth_status,
                               params: ["status": "force_switch_to_speaker", "output_name_before_switch": previousOutput.portName])
            }
        case .wakeFromSleep:
            if currentAudioOutput == .bluetooth {
                /// 蓝牙耳机从睡眠中唤醒
                VCTracker.post(name: .vc_bluetooth_status, params: ["status": "bluetooth_wake_up", "device_name": currentOutput.portName])
            }
        case .noSuitableRouteForCategory:
            /// 系统不支持当前的音频配置
            VCTracker.post(name: .vc_bluetooth_status,
                           params: ["status": "not_support_current_audio_configuration",
                                    "current_input_name": currentInput.portName,
                                    "current_output_name": currentOutput.portName])
        default:
            break
        }
    }

    // swiftlint:disable:next block_based_kvo
    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        if keyPath == "outputVolume" {
            logger.info("AudioSession outputVolume changed from: \(change?[.oldKey]) to \(change?[.newKey])")
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
}
