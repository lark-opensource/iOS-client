//
//  PerfMonitorDependencyImpl.swift
//  ByteViewMod
//
//  Created by ByteDance on 2023/10/31.
//

import Foundation
import LarkDowngrade
import LarkContainer
import ByteView
import ByteViewCommon
import ByteViewSetting

final class PerfMonitorDependencyImpl: PerfMonitorDependency {
    private let logger = Logger.getLogger("PerfAdjust.LarkMonitor")

    private static let FirstTask = "FirstRtcAdjustTask"
    private static let ContinueTask = "ContinueRtcAdjustTask"
    private static let RTCStrategyKey = "RTCPerformanceStrategy"

    private static let queueKey = DispatchSpecificKey<Void>()
    private static let queue: DispatchQueue = {
        let queue = DispatchQueue(label: "lark.byteview.perfadjustmonitor")
        queue.setSpecific(key: PerfMonitorDependencyImpl.queueKey, value: ())
        return queue
    }()

    static func runOnQueue(action: @escaping () -> Void) {
        if DispatchQueue.getSpecific(key: Self.queueKey) != nil {
            action()
        } else {
            queue.async(execute: action)
        }
    }

    private let listeners = Listeners<PerfMonitorDelegate>()

    private var monitorConfig: FeaturePerformanceDynamicDetection?

    private var startJob: DispatchWorkItem?

    enum MonitorState {
        case clear
        case started
        case firstTime
        case monitoring
        case pause
        case end
    }

    private var state: MonitorState = .clear {
        didSet {
            if state == oldValue {
                return
            }
            self.setDowngradeTaskFor(state)
        }
    }

    private var firstCPUPerformanceStrategy: LarkPerformanceStrategy?
    private var continueCPUPerformanceStrategy: LarkPerformanceStrategy?

    func setupMonitor(monitorConfig: FeaturePerformanceDynamicDetection) {
        logger.info("MonitorConfig: \(monitorConfig)")
        if let overloadRule = monitorConfig.overloadRules.first, let normalRule = monitorConfig.normalRules.first {
            let appCPURule = LarkPerformanceCPURule(cpuDowngradeValue: overloadRule.appCpu,
                                                    cpuUpgradeValue: normalRule.appCpu,
                                                    times: Double(monitorConfig.firstMonitorDuration))
            let deviceCPURule = LarkPerformanceDeviceCPURule(deviceDowngradeCpuValue: overloadRule.systemCpu,
                                                             deviceUpgradeCpuValue: normalRule.systemCpu,
                                                             times: Double(monitorConfig.firstMonitorDuration))

            let continueAppCPURule = LarkPerformanceCPURule(cpuDowngradeValue: overloadRule.appCpu,
                                                            cpuUpgradeValue: normalRule.appCpu,
                                                            times: Double(monitorConfig.continueMonitorDuration))
            let continueDeviceCPURule = LarkPerformanceDeviceCPURule(deviceDowngradeCpuValue: overloadRule.systemCpu,
                                                                     deviceUpgradeCpuValue: normalRule.systemCpu,
                                                                     times: Double(monitorConfig.continueMonitorDuration))

            firstCPUPerformanceStrategy = LarkPerformanceStrategy(strategyKey: Self.RTCStrategyKey, strategys: deviceCPURule |&| appCPURule, needPrivateData: true)
            continueCPUPerformanceStrategy = LarkPerformanceStrategy(strategyKey: Self.RTCStrategyKey, strategys: continueDeviceCPURule |&| continueAppCPURule, needPrivateData: true)
        }

        self.monitorConfig = monitorConfig
    }

    func addListener(_ listener: PerfMonitorDelegate) {
        listeners.addListener(listener)
    }

    func removeListener(_ listener: PerfMonitorDelegate) {
        listeners.removeListener(listener)
    }

    func startMonitor() {
        Self.runOnQueue {
            self._startMonitor()
        }
    }

    private func _startMonitor() {
        guard let monitorConfig = monitorConfig else { return }
        if state != .clear, startJob != nil {
            return
        }

        state = .started

        let job = DispatchWorkItem { [weak self] in
            self?.startJob = nil
            self?.state = .firstTime
        }

        Self.queue.asyncAfter(deadline: .now() + .seconds(monitorConfig.entryMeetingDuration), execute: job)
        startJob = job
    }

    private func setDowngradeTaskFor(_ state: MonitorState) {
        self.logger.info("setDowngradeTaskForState: \(state)")
        LarkUniversalDowngradeService.shared.removeDynamicDowngradeTask(key: Self.FirstTask)
        LarkUniversalDowngradeService.shared.removeDynamicDowngradeTask(key: Self.ContinueTask)

        guard let firstCPUPerformanceStrategy = firstCPUPerformanceStrategy,
              let continueCPUPerformanceStrategy = continueCPUPerformanceStrategy else {
            return
        }

        guard state == .firstTime || state == .monitoring else {
            return
        }

        if state == .firstTime {
            LarkUniversalDowngradeService.shared.dynamicDowngrade(key: Self.FirstTask,
                                                                  needConsecutive: false,
                                                                  strategys: [firstCPUPerformanceStrategy.strategyKey: firstCPUPerformanceStrategy],
                                                                  timeInterval: 2) { [weak self] _ in
                guard let self = self else { return }
                self.logger.info("doFristDownagrade")
                self.listeners.forEach { $0.reportPerformanceOverload() }
                self.state = .monitoring
                self.firstCPUPerformanceStrategy?.clearPrivateDataIfNeeded()
            } doNormal: { [weak self] _ in
                guard let self = self else { return }
                self.logger.info("doFristNormal")
                self.firstCPUPerformanceStrategy?.clearPrivateDataIfNeeded()
            }
        } else if state == .monitoring {
            LarkUniversalDowngradeService.shared.dynamicDowngrade(key: Self.ContinueTask,
                                                                  needConsecutive: true,
                                                                  strategys: [continueCPUPerformanceStrategy.strategyKey: continueCPUPerformanceStrategy],
                                                                  timeInterval: 2) { [weak self] _ in
                guard let self = self else { return }
                self.logger.info("doDownagrade")
                self.listeners.forEach { $0.reportPerformanceOverload() }
                self.continueCPUPerformanceStrategy?.clearPrivateDataIfNeeded()
            } doNormal: { [weak self] _ in
                guard let self = self else { return }
                self.logger.info("doNormal")
                self.listeners.forEach { $0.reportPerformanceUnderuse() }
                self.continueCPUPerformanceStrategy?.clearPrivateDataIfNeeded()
            }
        }
    }

    func restartMonitor() {
        logger.debug("restart monitor")
        Self.runOnQueue {
            if self.state == .end {
                return
            }
            self.state = .firstTime
        }
    }

    func stopMonitor() {
        Self.runOnQueue {
            self._stopMonitor()
        }
    }

    private func _stopMonitor() {
        startJob?.cancel()
        startJob = nil
        state = .clear
    }
}
