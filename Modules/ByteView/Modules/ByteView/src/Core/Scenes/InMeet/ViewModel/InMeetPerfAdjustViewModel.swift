//
//  InMeetPerfAdjustViewModel.swift
//  ByteView
//
//  Created by ZhangJi on 2022/4/11.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import ByteViewTracker
import ByteViewSetting
import ByteViewRtcBridge

final class InMeetPerfAdjustViewModel: NSObject {
    private let resolver: InMeetViewModelResolver
    let meeting: InMeetMeeting

    private lazy var perfAdjustEnable = meeting.setting.featurePerformanceConfig.isPerformanceAdjustEnable
    private lazy var larkMonitorEnable = meeting.setting.larkDowngradeConfig.enableDowngrade && meeting.setting.featurePerformanceConfig.isLarkDowngrade
    private lazy var isNewPrefAdjustEnbaled = meeting.setting.isNewPrefAdjustEnbaled

    private lazy var perfAdjustMonitor: PerfMonitorDependency? = {
        guard perfAdjustEnable else { return nil }
        if larkMonitorEnable {
            return meeting.service.perfMonitor
        } else {
            return PerfAdjustMonitor(meeting: meeting)
        }
    }()

    private lazy var thermalAdjustEnable = meeting.setting.isThermalAdjustEnabled

    private lazy var thermalAdjustMonitor: ThermalAdjustMonitor = {
        return ThermalAdjustMonitor(meeting: meeting)
    }()

    private lazy var perfAdjustor: PerfAdjustorProtocol? = {
        if isNewPrefAdjustEnbaled {
            return NewPerfAdjustor(meeting: meeting)
        }
        return nil
    }()

    let batteryManager: InMeetBatteryStatusManager?

    init(resolver: InMeetViewModelResolver) {
        self.resolver = resolver
        self.meeting = resolver.meeting
        self.batteryManager = resolver.resolve()
        super.init()
        setupMonitor()
        setupAdjustor()
        Logger.getLogger("PerfAdjust").info("init InMeetPerfAdjustViewModel perfAdjustEnable: \(perfAdjustEnable), larkMonitorEnable: \(larkMonitorEnable)")
    }

    func addAdjustListener(_ listener: PerfAdjustorListener) {
        self.perfAdjustor?.addListener(listener)
    }

    private func setupMonitor() {
        self.perfAdjustMonitor?.setupMonitor(monitorConfig: meeting.setting.featurePerformanceConfig.adjustConfig)
        self.perfAdjustMonitor?.addListener(self)
        self.perfAdjustMonitor?.startMonitor()
        self.thermalAdjustMonitor.addListener(self)
        self.meeting.rtc.engine.addListener(self)
        self.meeting.setting.addListener(self, for: .isEcoModeOn)
        self.meeting.addListener(self)
    }

    private func setupAdjustor() {
        self.perfAdjustor?.addListener(self)
    }
}

extension InMeetPerfAdjustViewModel: PerfMonitorDelegate {
    func reportPerformanceOverload() {
        self.perfAdjustor?.reportNeedDegrade(type: .performance)
    }

    func reportPerformanceUnderuse() {
        self.perfAdjustor?.reportNeedUpgrade(type: .performance)
    }

    func perfAdjustMonitor(_ monitor: PerfAdjustMonitor, reportOverload info: RtcSysStats) {
        self.perfAdjustor?.reportNeedDegrade(type: .performance)
    }

    func perfAdjustMonitor(_ monitor: PerfAdjustMonitor, reportUnderuse info: RtcSysStats) {
        self.perfAdjustor?.reportNeedUpgrade(type: .performance)
    }
}

extension InMeetPerfAdjustViewModel: ThermalAdjustMonitorDelegate {
    func thermalAdjustMonitor(_ monitor: ThermalAdjustMonitor, reportThermalHigh state: ProcessInfo.ThermalState, voiceMode: Bool) {
        self.perfAdjustor?.reportNeedDegrade(type: .thermal(state))
        self.batteryManager?.reportShouldShowVoiceToastFor(type: .thermal(state), enable: voiceMode)

    }

    func thermalAdjustMonitor(_ monitor: ThermalAdjustMonitor, reportThermalNominal state: ProcessInfo.ThermalState) {
        self.perfAdjustor?.reportNeedUpgrade(type: .thermal(state))
        self.batteryManager?.reportShouldShowVoiceToastFor(type: .thermal(state), enable: false)
    }
}

extension InMeetPerfAdjustViewModel: MeetingSettingListener {
    func didChangeMeetingSetting(_ settings: ByteViewSetting.MeetingSettingManager, key: ByteViewSetting.MeetingSettingKey, isOn: Bool) {
        if key == .isEcoModeOn {
            if isOn {
                self.perfAdjustor?.reportNeedDegrade(type: .battery)
            } else {
                self.perfAdjustor?.reportNeedUpgrade(type: .battery)
            }
        }
    }
}

extension InMeetPerfAdjustViewModel: PerfAdjustorListener {
    func sholdEnableVoiceMode(enable: Bool) {
        self.batteryManager?.reportShouldShowVoiceToastFor(type: .performance, enable: enable)
    }

    func didEndPerfUpgrade() {
        self.perfAdjustMonitor?.restartMonitor()
    }
}

extension InMeetPerfAdjustViewModel: RtcListener {
    func reportSysStats(_ stats: RtcSysStats) {
        guard let perfAdjustMonitor = self.perfAdjustMonitor as? PerfAdjustMonitor else {
            return
        }
        perfAdjustMonitor.addSystemUsageInfo(stats)
    }
}

extension InMeetPerfAdjustViewModel: InMeetMeetingListener {
    func willReleaseInMeetMeeting(_ meeting: InMeetMeeting) {
        self.perfAdjustMonitor?.stopMonitor()
    }
}
