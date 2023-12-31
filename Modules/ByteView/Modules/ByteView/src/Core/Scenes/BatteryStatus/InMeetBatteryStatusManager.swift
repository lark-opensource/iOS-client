//
//  InMeetBatteryStatusManager.swift
//  ByteView
//
//  Created by ZhangJi on 2022/6/1.
//

import Foundation
import RxSwift
import RxRelay
import ByteViewCommon
import ByteViewSetting

enum VoiceModeReason: CustomStringConvertible {
    case performance
    case battery(Int)
    case thermal(ProcessInfo.ThermalState)

    var description: String {
        switch self {
        case .performance:
            return "performance"
        case .battery(let level):
            return "battery(\(level))"
        case .thermal(let state):
            return "thermal(\(state.rawValue))"
        }
    }
}

enum BatteryToastType {
    // 语音模式
    case voiceMode(VoiceModeReason)
    // 节能模式
    case ecoMode(Double)
}

protocol InMeetBatteryStatusListener: AnyObject {
    func shouldShowBatteryToast(_ type: BatteryToastType)
}

extension InMeetBatteryStatusListener {
    func shouldShowBatteryToast(_ type: BatteryToastType) {}
}

final class InMeetBatteryStatusManager {
    private let logger = Logger.getLogger("BatteryStatus.Manger")

    private var hasShowPerfToast: Bool = false
    private var hasShowBatteryToast: Bool = false

    /// 语音模式
    private var isVoiceModeOn: Bool { setting.isVoiceModeOn }
    private var isThermalAdjustEnabled: Bool { setting.isThermalAdjustEnabled }
    private let voiceModeConfig: VoiceModeConfig
    private var thermalState: ProcessInfo.ThermalState?
    // 温度降级语音模式引导
    private var shouldShowThermalToast: Bool = false {
        didSet {
            if shouldShowThermalToast {
                checkShouldShowBatteryToast()
            }
        }
    }
    // 性能降级语音模式引导
    private var shouldShowPerfToast: Bool = false {
        didSet {
            if shouldShowPerfToast {
                checkShouldShowBatteryToast()
            }
        }
    }

    private var lastBatteryToastTime: TimeInterval? {
        get { meeting.storage.value(forKey: .lastBatteryToastTime) }
        set { meeting.storage.setValue(newValue, forKey: .lastBatteryToastTime) }
    }

    private var lastThermalToastTime: TimeInterval?

    /// 节能模式
    private let ecoModeConfig: PowerSaveConfig
    private var isEcoModeEnabled: Bool { setting.isEcoModeEnabled }
    private var isEcoModeOn: Bool { setting.isEcoModeOn }
    private var batteyInfos = [BatteyInfo]()
    // 电池节能模式引导
    private var shouldShowEcoModeToast: Bool = false {
        didSet {
            if shouldShowEcoModeToast {
                checkShouldShowBatteryToast()
            }
        }
    }
    private var powerConsumptionRate: Double = 0
    private var isTurnOnEcoModeFromToast: Bool = false

    private var timer: Timer?
    private let queue = DispatchQueue(label: "lark.byteview.battery_manager")

    private let listeners = Listeners<InMeetBatteryStatusListener>()

    private let meeting: InMeetMeeting
    private let setting: MeetingSettingManager
    private let rtc: InMeetRtcEngine

    private let isCalendarMeeting: Bool
    private var meetingEndTime: TimeInterval?

    init(resolver: InMeetViewModelResolver) {
        self.meeting = resolver.meeting
        self.setting = meeting.setting
        self.rtc = meeting.rtc.engine
        self.voiceModeConfig = setting.voiceModeConfig
        self.ecoModeConfig = setting.featurePerformanceConfig.powerSaveConfig
        self.isCalendarMeeting = meeting.isCalendarMeeting
        setting.addListener(self, for: [.isEcoModeOn, .isVoiceModeOn])
        meeting.data.addListener(self)
        logger.info("voice mode config: \(voiceModeConfig) eco mode config: \(ecoModeConfig)")

        self.startScheduledCheck()
    }

    deinit {
        timer?.invalidate()
    }

    private func startScheduledCheck() {
        let interval = Double(voiceModeConfig.thermalAdjustConfig.scheduledCheckDuration)
        let timer = Timer(timeInterval: interval, repeats: true, block: { [weak self] _ in
            self?.queue.async {
                self?.checkShouldShowBatteryToast()
            }
        })
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func addListener(_ listener: InMeetBatteryStatusListener) {
        listeners.addListener(listener)
    }

    func removeListener(_ listener: InMeetBatteryStatusListener) {
        listeners.removeListener(listener)
    }

    func reportShouldShowVoiceToastFor(type: AdjustType, enable: Bool) {
        switch type {
        case .performance:
            self.shouldShowPerfToast = enable
        case .thermal(let state):
            self.shouldShowThermalToast = enable
            self.thermalState = state
        default:
            return
        }
    }

    func checkShouldShowBatteryToast() {
        checkShouldShowBatteryToast { [weak self] toastType in
            guard let self = self, let toastType = toastType else { return }
            self.logger.info("Should show battery toast: \(toastType)")
            self.listeners.forEach { $0.shouldShowBatteryToast(toastType) }
        }
    }

    func checkShouldShowBatteryToast(completion: @escaping (BatteryToastType?) -> Void) {
        if isVoiceModeOn {
            completion(nil)
            return
        }

        if !isEcoModeEnabled {
            guard (shouldShowPerfToast && !hasShowPerfToast)
                    || (UIDevice.current.batteryState == .unplugged && UIDevice.current.batteryLevel <= Float(self.voiceModeConfig.batteryValue))
                    || shouldShowThermalToast else {
                completion(nil)
                return
            }
            // 非节能模式,判断顺序: 降级->电量->温度
            rtc.fetchVideoStreamInfo { [weak self] info in
                var batteryToastType: BatteryToastType?
                defer { completion(batteryToastType) }
                guard let self = self, info.hasSubscribeCameraStream else {
                    return
                }

                if self.shouldShowPerfToast, !self.hasShowPerfToast {
                    batteryToastType = .voiceMode(.performance)
                    return
                }

                let lateBatteryToastTime = self.lastBatteryToastTime ?? 0
                let time = Date().timeIntervalSince1970 - lateBatteryToastTime
                if time > Double(self.batteryToastInterval), !self.hasShowBatteryToast,
                   UIDevice.current.batteryState == .unplugged,
                   UIDevice.current.batteryLevel <= Float(self.voiceModeConfig.batteryValue) {
                    batteryToastType = .voiceMode(.battery(Int(self.voiceModeConfig.batteryValue * 100)))
                } else {
                    if let reason = self.checkThermalStateShouldShowReason() {
                        batteryToastType = .voiceMode(reason)
                    }
                }
            }
        } else {
            guard (shouldShowPerfToast && !hasShowPerfToast)
                    || shouldShowThermalToast
                    || shouldShowEcoModeToast else {
                completion(nil)
                return
            }
            // 节能模式,判断顺序: 降级->温度->节能
            rtc.fetchVideoStreamInfo { [weak self] info in
                var batteryToastType: BatteryToastType?
                defer { completion(batteryToastType) }
                guard let self = self, (info.hasSubscribeCameraStream || info.hasScreenShare || !self.meeting.camera.isMuted || self.meeting.shareData.isMySharingScreen) else {
                    return
                }

                if info.hasSubscribeCameraStream, self.shouldShowPerfToast, !self.hasShowPerfToast {
                    batteryToastType = .voiceMode(.performance)
                    return
                }

                if let reason = self.checkThermalStateShouldShowReason() {
                    batteryToastType = .voiceMode(reason)
                    return
                }

                if !self.isEcoModeOn, canShowEcoToast() {
                    self.logger.info("shouldShowEcoModeToast: hasSubscribeCameraStream \(info.hasSubscribeCameraStream), hasScreenShare: \(info.hasScreenShare), isMuted: \(self.meeting.camera.isMuted)")
                    batteryToastType = .ecoMode(self.powerConsumptionRate)
                }
            }
        }
    }

    private func canShowEcoToast() -> Bool {
        let lastBatteryToastTime = self.lastBatteryToastTime ?? 0
        let lastIntervalTime = Date().timeIntervalSince1970 - lastBatteryToastTime
        if lastIntervalTime > Double(self.batteryToastInterval), !self.hasShowBatteryToast,
           UIDevice.current.batteryState == .unplugged,
           self.shouldShowEcoModeToast {
            if isCalendarMeeting, let meetingEndTime = meetingEndTime, self.ecoModeConfig.tipsIntervalBeforeCalendarEnd > 0 {
                // https://bytedance.feishu.cn/docx/AhSEdSdMBoM87fxOfQ0cNjqsnyc
                let beforeCalendarEnd = meetingEndTime - Date().timeIntervalSince1970
                if beforeCalendarEnd > self.ecoModeConfig.tipsIntervalBeforeCalendarEndSeconds {
                    // 日程会议剩余时间大于设定阈值
                    return true
                } else if beforeCalendarEnd < -(self.ecoModeConfig.tipsIntervalAfterCalendarEndSeconds),
                          UIDevice.current.batteryLevel < Float(self.ecoModeConfig.powerLastResortThresholdPercent) {
                    // 日程会议拖延时间大于设定阈值，且电量阈值小于兜底值
                    return true
                } else {
                    return false
                }
            }
            return true
        }
        return false
    }

    func enableVoiceMode(_ enabled: Bool, reason: VoiceModeReason) {
        logger.info("enableVoiceMode: \(enabled), reason: \(reason)")
        self.setting.updateSettings({ $0.dataMode = enabled ? .voiceMode : .standardMode })
    }

    func enableEcoMode(_ enabled: Bool) {
        logger.info("enableEcoMode: \(enabled)")
        self.setting.updateSettings({ $0.dataMode = enabled ? .ecoMode : .standardMode})
        self.isTurnOnEcoModeFromToast = enabled
        if !enabled {
            Toast.show(I18n.View_G_Setting_LowPowerModeOff_Toast)
        }
    }

    func didShowBatteryToast(_ type: BatteryToastType) {
        switch type {
        case .voiceMode(let reason):
            switch reason {
            case .performance:
                self.hasShowPerfToast = true
            case .battery:
                self.hasShowBatteryToast = true
                lastBatteryToastTime = Date().timeIntervalSince1970
            case .thermal:
                lastThermalToastTime = Date().timeIntervalSince1970
            }
        case .ecoMode:
            self.hasShowBatteryToast = true
            lastBatteryToastTime = Date().timeIntervalSince1970
        }
    }
}

// MARK: 电量
extension InMeetBatteryStatusManager: BatteyMonitor {
    struct BatteyInfo {
        var level: Float
        var isPlugging: Bool
        var time: Double
    }

    private var batteryToastInterval: Int {
        if isEcoModeEnabled {
            return ecoModeConfig.tipsInterval
        } else {
            return voiceModeConfig.actionInterval
        }
    }

    func reportRealtimePower(level: Float, isPlugging: Bool, time: Double) {
        let info = BatteyInfo(level: level, isPlugging: isPlugging, time: time)
        handleBatteyInfo(info)
    }

    private func handleBatteyInfo(_ info: BatteyInfo) {
        var shouldShowEcoModeToast = false
        defer { self.shouldShowEcoModeToast = shouldShowEcoModeToast }

        if info.isPlugging {
            batteyInfos.removeAll()
            if isEcoModeEnabled,
               isTurnOnEcoModeFromToast,
               info.level >= Float(ecoModeConfig.closeThresholdPercent) {
                enableEcoMode(false)
            }
        } else if isEcoModeEnabled {
            guard !isVoiceModeOn, !isEcoModeOn else {
                batteyInfos.removeAll()
                return
            }
            batteyInfos.append(info)
            if let firstInfo = batteyInfos.first,
               info.time - firstInfo.time >= ecoModeConfig.powerLowMonitorSeconds {
                powerConsumptionRate = Double(firstInfo.level - info.level) / (info.time - firstInfo.time) * 60.0
                if powerConsumptionRate >= ecoModeConfig.powerSpeedThresholdPercent,
                   info.level <= Float(ecoModeConfig.powerLowThresholdPercent) {
                    logger.info("current battery coast is high: \(powerConsumptionRate)/mim, infos: \(batteyInfos)")
                    shouldShowEcoModeToast = true
                    batteyInfos.removeAll()
                } else {
                    batteyInfos.removeFirst()
                }
            }
        } else if info.level <= Float(voiceModeConfig.batteryValue) {
            checkShouldShowBatteryToast()
        }
    }
}

// MARK: 温度
extension InMeetBatteryStatusManager {
    private var thermalToastInterval: Int {
        guard let thermalState = thermalState else { return -1}
        if isThermalAdjustEnabled {
            switch thermalState {
            case .serious:
                guard voiceModeConfig.thermalAdjustConfig.seriousDegradeConfig.voiceMode else { return -1 }
                return max(voiceModeConfig.thermalAdjustConfig.seriousDegradeConfig.degradeDuration, voiceModeConfig.thermalAdjustConfig.voiceModeToastInterval)
            case .critical:
                guard voiceModeConfig.thermalAdjustConfig.criticalDegradeConfig.voiceMode else { return -1 }
                return max(voiceModeConfig.thermalAdjustConfig.criticalDegradeConfig.degradeDuration, voiceModeConfig.thermalAdjustConfig.voiceModeToastInterval)
            default:
                return -1
            }
        } else {
            switch thermalState {
            case .serious:
                return voiceModeConfig.thermalState.seriousInterval
            case .critical:
                return voiceModeConfig.thermalState.criticalInterval
            default:
                return -1
            }
        }
    }

    private func checkThermalStateShouldShowReason() -> VoiceModeReason?  {
        guard shouldShowThermalToast, let thermalState = thermalState else { return nil }

        let lastThermalToastTime = self.lastThermalToastTime ?? 0
        let time = Date().timeIntervalSince1970 - lastThermalToastTime
        if self.thermalToastInterval > 0, time > Double(self.thermalToastInterval) {
            return .thermal(thermalState)
        }

        return nil
    }
}

extension InMeetBatteryStatusManager: MeetingSettingListener {
    func didChangeMeetingSetting(_ settings: MeetingSettingManager, key: MeetingSettingKey, isOn: Bool) {
        if key == .isVoiceModeOn {
            self.logger.info("didChangeVoiceMode: \(isOn)")
            if isOn {
                if !meeting.camera.isMuted {
                    meeting.camera.muteMyself(true, source: .voice_mode, showToastOnSuccess: false, completion: nil)
                }
                Toast.show(I18n.View_G_CameraOff_KeepAudioAndShare)
            }
        }

        if key == .isEcoModeOn {
            if !isOn {
                // 关闭Eco Mode之后重置状态
                self.isTurnOnEcoModeFromToast = false
            }
        }
    }
}

extension InMeetBatteryStatusManager: InMeetDataListener {
    func didChangeCalenderInfo(_ calendarInfo: CalendarInfo?, oldValue: CalendarInfo?) {
        if isCalendarMeeting, let info = calendarInfo {
            meetingEndTime = TimeInterval(info.theEventEndTime / 1000)
        }
    }
}
