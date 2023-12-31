//
//  ThermalAdjustMonitor.swift
//  ByteView
//
//  Created by ZhangJi on 2023/6/9.
//

import Foundation
import ByteViewSetting
import RxSwift

protocol ThermalAdjustMonitorDelegate: AnyObject {
    func thermalAdjustMonitor(_ monitor: ThermalAdjustMonitor, reportThermalHigh state: ProcessInfo.ThermalState, voiceMode: Bool)
    func thermalAdjustMonitor(_ monitor: ThermalAdjustMonitor, reportThermalNominal state: ProcessInfo.ThermalState)
}

final class ThermalAdjustMonitor {
    private let logger = Logger.getLogger("ThermalAdjust.Monitor")
    private let disposeBag = DisposeBag()
    private let queue = DispatchQueue(label: "lark.byteview.thermaladjustmonitor")

    private let thermalAdjustConfig: ThermalAdjustConfig
    private let thermalStateConfig: ThermalStateConfig

    private var isThermalAdjustEnabled: Bool { setting.isThermalAdjustEnabled }

    private let listeners = Listeners<ThermalAdjustMonitorDelegate>()


    @RwAtomic
    private var seriousMonitorJob: Timer?
    @RwAtomic
    private var criticalMonitorJob: Timer?
    @RwAtomic
    private var upgradeMonitorJob: Timer?

    private var thermalState: ProcessInfo.ThermalState = .nominal

    private let setting: MeetingSettingManager

    init(meeting: InMeetMeeting) {
        self.setting = meeting.setting
        self.thermalAdjustConfig = setting.voiceModeConfig.thermalAdjustConfig
        self.thermalStateConfig = setting.voiceModeConfig.thermalState

        DispatchQueue.global().async { [weak self] in
            self?.bindRx()
        }
    }

    func addListener(_ listener: ThermalAdjustMonitorDelegate) {
        listeners.addListener(listener)
    }

    func removeListener(_ listener: ThermalAdjustMonitorDelegate) {
        listeners.removeListener(listener)
    }


    func bindRx() {
        ThermalStateMonitor.shared.thermalStateObservable.subscribe(onNext: { [weak self] thermalState in
            self?.logger.info("ThermalState change to \(thermalState.rawValue)")
            self?.queue.async {
                self?.thermalState = thermalState
                self?.startMonitorJobFor(state: thermalState)
            }
        }).disposed(by: self.disposeBag)
    }

    private func startMonitorJobFor(state: ProcessInfo.ThermalState) {
        self.logger.info("start monior job for state: \(state.rawValue)")
        switch state {
        case .nominal, .fair:
            guard state.rawValue <= thermalAdjustConfig.upgradeConfig.upgradeState else {
                return
            }

            guard upgradeMonitorJob == nil else {
                return
            }
            cancelMonitorJobFor(state: .critical)
            cancelMonitorJobFor(state: .serious)
            startUpgradeMonitorJobFor(state: state)
        case .serious:
            guard seriousMonitorJob == nil else {
                return
            }
            cancelMonitorJobFor(state: .critical)
            cancelMonitorJobFor(state: .fair)
            startDegradeMonitorJobFor(state: state)
        case .critical:
            guard criticalMonitorJob == nil else {
                return
            }
            cancelMonitorJobFor(state: .serious)
            cancelMonitorJobFor(state: .fair)
            startDegradeMonitorJobFor(state: state)
        @unknown default:
            break
        }
    }

    private func startDegradeMonitorJobFor(state: ProcessInfo.ThermalState) {
        var adjustConfig: DegradeConfig?
        var duration: Int
        var voiceMode: Bool = true
        var degradeImmediately: Bool
        switch state {
        case .serious:
            adjustConfig = thermalAdjustConfig.seriousDegradeConfig
            duration = thermalStateConfig.seriousInterval
            degradeImmediately = false
        case .critical:
            adjustConfig = thermalAdjustConfig.criticalDegradeConfig
            duration = thermalStateConfig.criticalInterval
            degradeImmediately = true
        default:
            return
        }

        if isThermalAdjustEnabled {
            guard let adjustConfig = adjustConfig else { return }
            duration = adjustConfig.degradeDuration
            degradeImmediately = adjustConfig.degradeImmediately
            voiceMode = adjustConfig.voiceMode
        }

        let timer = Timer(timeInterval: TimeInterval(duration), repeats: true) { [weak self] _ in
            self?.queue.async {
                guard let self = self else { return }
                self.logger.info("report thermal high: \(self.thermalState.rawValue), voiceMode: \(voiceMode)")
                self.listeners.forEach { $0.thermalAdjustMonitor(self, reportThermalHigh: self.thermalState, voiceMode: voiceMode) }
            }
        }

        RunLoop.main.add(timer, forMode: .common)
        switch state {
        case .serious:
            self.seriousMonitorJob = timer
        case .critical:
            self.criticalMonitorJob = timer
        default:
            timer.invalidate()
        }

        self.logger.info("start degrade monior job for state: \(state.rawValue)")

        if degradeImmediately {
            self.listeners.forEach { $0.thermalAdjustMonitor(self, reportThermalHigh: state, voiceMode: voiceMode) }
        }
    }

    private func startUpgradeMonitorJobFor(state: ProcessInfo.ThermalState) {
        guard isThermalAdjustEnabled else { return }
        var adjustConfig: UpgradeConfig?
        switch state {
        case .fair, .nominal:
            adjustConfig = thermalAdjustConfig.upgradeConfig
        default:
            return
        }

        guard let adjustConfig = adjustConfig else { return }

        let timer = Timer(timeInterval: TimeInterval(adjustConfig.duration), repeats: true) { [weak self] _ in
            self?.queue.async {
                guard let self = self else { return }
                self.logger.info("report thermal nominal: \(self.thermalState.rawValue)")
                self.listeners.forEach { $0.thermalAdjustMonitor(self, reportThermalNominal: self.thermalState) }
            }
        }

        RunLoop.main.add(timer, forMode: .common)
        self.upgradeMonitorJob = timer
        self.logger.info("start upgrade monior job for state: \(state.rawValue)")
    }

    private func cancelMonitorJobFor(state: ProcessInfo.ThermalState) {
        self.logger.info("cancel thermal monitor job for state: \(state.rawValue)")
        switch state {
        case .nominal, .fair:
            if upgradeMonitorJob != nil {
                upgradeMonitorJob?.invalidate()
                upgradeMonitorJob = nil
            }
        case .serious:
            if seriousMonitorJob != nil {
                seriousMonitorJob?.invalidate()
                seriousMonitorJob = nil
            }
        case .critical:
            if criticalMonitorJob != nil {
                criticalMonitorJob?.invalidate()
                criticalMonitorJob = nil
            }
        @unknown default:
            break
        }
    }
}
