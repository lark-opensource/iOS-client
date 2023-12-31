//
//  NewPerfAdjustor.swift
//  ByteView
//
//  Created by ZhangJi on 2023/6/1.
//

import Foundation
import ByteViewSetting


class NewPerfAdjustor: PerfAdjustorProtocol {
    private let logger = Logger.getLogger("PerfAdjust.Manager.New")

    private let perfAdjustEnable: Bool
    private let thermalAdjustEnable: Bool

    // MARK: 性能
    // 性能降级档位
    private let perfDegradeLevels: [Int]
    // 性能降级等级
    private var currentPerDegradeLevel: Int = 0

    private var lastPerToastTime: TimeInterval?

    // MARK: 温度
    // 温度降级档位
    // serious档位
    private let thermalSeriousDegradeLevels: [Int]
    // critical档位
    private let thermalCriticalDegradeLevels: [Int]
    // 温度升级档位
    private let thermalUpgradeLevels: [Int]
    // 温度降级等级
    private var currentThermalDegradeLevel: Int = 0

    private var lastThermalToastTime: TimeInterval?
    private var hasShowThermalToast: Bool = false

    // MARK: 节能
    // 节能模式降级档位
    private let powerDegradeLevel: Int
    // 节能模式降级等级
    private var currentPowerDegradeLevel: Int = 0

    // 综合降级等级
    private var currentDegradeLevel: Int = 0
    // 性能降级最大等级
    private var maxDegradeLevel: Int = 19

    private let meeting: InMeetMeeting
    private let setting: MeetingSettingManager
    private weak var engine: InMeetRtcEngine?
    private let listeners = Listeners<PerfAdjustorListener>()

    private var trackId: PerfAdjustTrackId = {
        PerfAdjustTrackId(actionId: UUID().uuidString, lastAdjustDirection: .down, adjustType: .performance)
    }()

    required init(meeting: InMeetMeeting) {
        self.meeting = meeting
        self.engine = meeting.rtc.engine
        self.setting = meeting.setting
        // 性能
        self.perfAdjustEnable = setting.featurePerformanceConfig.isPerformanceAdjustEnable
        self.perfDegradeLevels = setting.featurePerformanceConfig.dynamicDegradeLevels.sorted(by: <)

        // 温度
        let thermalAdjustConfig = setting.voiceModeConfig.thermalAdjustConfig
        self.thermalAdjustEnable = setting.isThermalAdjustEnabled && thermalAdjustConfig.isThermalAdjustEnable
        self.thermalSeriousDegradeLevels = thermalAdjustConfig.seriousDegradeConfig.degradeLevels
        self.thermalCriticalDegradeLevels = thermalAdjustConfig.criticalDegradeConfig.degradeLevels
        self.thermalUpgradeLevels = thermalAdjustConfig.upgradeConfig.upgradeLevels

        // 节能
        self.powerDegradeLevel = setting.featurePerformanceConfig.powerSaveConfig.degradeLevel
    }

    func addListener(_ listener: PerfAdjustorListener) {
        listeners.addListener(listener)
    }

    func removeListener(_ listener: PerfAdjustorListener) {
        listeners.removeListener(listener)
    }

    func reportNeedDegrade(type: AdjustType) {
        switch type {
        case .performance:
            self.triggerPerfDegrade()
        case .thermal(let state):
            self.triggerThermalDegrade(for: state)
        case .battery:
            self.enableEcoMode(true)
        }
    }

    func reportNeedUpgrade(type: AdjustType) {
        switch type {
        case .performance:
            self.triggerPerfUpgrade()
        case .thermal(let state):
            self.triggerThermalUpgrade(for: state)
        case .battery:
            self.enableEcoMode(false)
        }
    }

    private func nextDegradeLevel(currentLevel: Int, levels: [Int]) -> Int? {
        let levels = levels.sorted(by: <)
        return levels.first(where: { $0 > currentLevel })
    }

    private func nextUpgradeLevel(currentLevel: Int, levels: [Int]) -> Int? {
        let levels = levels.sorted(by: >)
        return levels.first(where: { $0 < currentLevel })
    }

    @discardableResult
    private func setPerformanceLevel(_ type: AdjustType) -> Bool {
        let level = max(currentPerDegradeLevel, currentPowerDegradeLevel, currentThermalDegradeLevel)
        guard level != currentDegradeLevel else {
            self.logger.info("skip set performance level for type: \(type), \(currentPerDegradeLevel)|\(currentThermalDegradeLevel)|\(currentPowerDegradeLevel)")
            return false
        }
        currentDegradeLevel = level
        engine?.setPerformanceLevel(level)
        listeners.forEach { $0.reportAdjustLevels(["ongoing_strategy_level": currentDegradeLevel,
                                                   "cpu_strategy_level": currentPerDegradeLevel,
                                                   "thermal_strategy_level": currentThermalDegradeLevel,
                                                   "battery_strategy_level": currentPowerDegradeLevel]) }
        self.logger.info("set performance level for type: \(type), \(currentPerDegradeLevel)|\(currentThermalDegradeLevel)|\(currentPowerDegradeLevel)")
        return true
    }

    private func trackPerfAdjustStatus(level: Int, direction: RtcPerfAdjustDirection, type: AdjustType) {
        self.trackId.updateForDirection(direction, type: type)
        PerfDegradeTracks.trackPerfAdjustStatus(apiType: .new, direction: direction, requestType: PerfDegradeTracks.requestTypeReq, actionId: trackId.actionId, type: type, level: level)
    }

    private var degradeToastDuration: Double {
        Double(setting.voiceModeConfig.thermalAdjustConfig.degradeToastShowDuration)
    }

    private var hasContentAdjust: Bool {
        // 是否有可以升降级的内容
        return !setting.isVoiceModeOn || !meeting.camera.isMuted || meeting.shareData.isSharingScreen
    }

    private func showDegradToastIfNeedFor(type: AdjustType) {
        guard !meeting.router.isFloating, hasContentAdjust else {
            // 小窗不显示，没有可降级的内容不显示
            return
        }
        var lastShowToastTime: TimeInterval = 0
        var needShowDegradeToast = false
        var toast: String
        switch type {
        case .performance:
            lastShowToastTime = self.lastPerToastTime ?? 0
            toast = I18n.View_G_DeviceLowerVideoQuality_Toast
        case .thermal(let state):
            if state == .critical {
                return
            }
            lastShowToastTime = self.lastThermalToastTime ?? 0
            toast = I18n.View_G_DeviceHeatNeedCool
            needShowDegradeToast = needShowDegradeToast || meeting.shareData.isSharingScreen || !meeting.camera.isMuted
        case .battery:
            return
        }

        guard Date().timeIntervalSince1970 - lastShowToastTime > Double(setting.voiceModeConfig.thermalAdjustConfig.degradeToastInterval) else {
            return
        }

        engine?.fetchVideoStreamInfo { [weak self] info in
            guard let self = self else { return }
            needShowDegradeToast = (info.hasSubscribeCameraStream || info.hasScreenShare || needShowDegradeToast)
            if needShowDegradeToast {
                Toast.show(toast, duration: self.degradeToastDuration)
                if case .performance = type {
                    self.lastPerToastTime = Date().timeIntervalSince1970
                } else if case .thermal = type {
                    self.lastThermalToastTime = Date().timeIntervalSince1970
                    self.hasShowThermalToast = true
                }
                PerfDegradeTracks.trackDegradeToastFor(type: type)
            }
            self.logger.info("\(needShowDegradeToast ? "" : "Skip") Show Sub degrade toast for type: \(type), hasSubscribeStream: \(info.hasSubscribeCameraStream), hasScreenSharing: \(info.hasScreenShare)")
        }
    }

    private func showUpgradToastIfNeedFor(type: AdjustType) {
        guard hasContentAdjust else { return }
        if case .thermal = type, self.hasShowThermalToast {
            Toast.show(I18n.View_G_DeviceCoolRestore, duration: degradeToastDuration)
            self.hasShowThermalToast = false
            PerfDegradeTracks.trackUpgradeToastFor(type: type)
        }
    }
}

// MARK: - 性能降级
extension NewPerfAdjustor {
    private func triggerPerfDegrade() {
        guard perfAdjustEnable else { return }
        guard let level = nextDegradeLevel(currentLevel: currentPerDegradeLevel, levels: perfDegradeLevels) else {
            logger.info("there is no level to degrade")
            self.listeners.forEach { $0.sholdEnableVoiceMode(enable: true) }
            return
        }
        logger.info("degrade to level: \(level)")
        currentPerDegradeLevel = level
        if self.setPerformanceLevel(.performance) {
            self.trackPerfAdjustStatus(level: level, direction: .down, type: .performance)
            self.showDegradToastIfNeedFor(type: .performance)
        }
    }

    private func triggerPerfUpgrade() {
        guard perfAdjustEnable else { return }
        if currentDegradeLevel == perfDegradeLevels.max() {
            self.listeners.forEach { $0.sholdEnableVoiceMode(enable: false) }
        }
        guard let level = nextUpgradeLevel(currentLevel: currentPerDegradeLevel, levels: perfDegradeLevels) else {
            logger.info("there is no level to upgrade")
            return
        }
        logger.info("upgrade to level: \(level)")
        currentPerDegradeLevel = level
        self.setPerformanceLevel(.performance)
        if currentDegradeLevel == 0 {
            self.trackPerfAdjustStatus(level: level, direction: .up, type: .performance)
            self.listeners.forEach { $0.didEndPerfUpgrade() }
        }
    }
}

// MARK: - 温度降级
extension NewPerfAdjustor {
    private func triggerThermalDegrade(for state: ProcessInfo.ThermalState) {
        guard thermalAdjustEnable else { return }
        var degradeLevels: [Int]
        switch state {
        case .serious:
            degradeLevels = thermalSeriousDegradeLevels
        case .critical:
            degradeLevels = thermalCriticalDegradeLevels
        default:
            return
        }
        guard let level = nextDegradeLevel(currentLevel: currentThermalDegradeLevel, levels: degradeLevels) else {
            logger.info("there is no level to degrade")
            return
        }
        logger.info("degrade to level: \(level)")
        currentThermalDegradeLevel = level
        if self.setPerformanceLevel(.thermal(state)) {
            self.trackPerfAdjustStatus(level: level, direction: .down, type: .thermal(state))
            self.showDegradToastIfNeedFor(type: .thermal(state))
        }
    }

    private func triggerThermalUpgrade(for state: ProcessInfo.ThermalState) {
        guard thermalAdjustEnable else { return }
        guard let level = nextUpgradeLevel(currentLevel: currentThermalDegradeLevel, levels: thermalUpgradeLevels) else {
            logger.info("there is no level to upgrade")
            return
        }
        logger.info("upgrade to level: \(level)")
        currentThermalDegradeLevel = level
        if self.setPerformanceLevel(.thermal(state)) {
            self.trackPerfAdjustStatus(level: level, direction: .up, type: .thermal(state))
            self.showUpgradToastIfNeedFor(type: .thermal(state))
        }
    }
}

// MARK: - 低电模式
extension NewPerfAdjustor {
    private func enableEcoMode(_ enable: Bool) {
        currentPowerDegradeLevel = enable ? powerDegradeLevel : 0
        if self.setPerformanceLevel(.battery) {
            self.trackPerfAdjustStatus(level: currentPowerDegradeLevel, direction: enable ? .down : .up, type: .battery)
        }
    }
}
