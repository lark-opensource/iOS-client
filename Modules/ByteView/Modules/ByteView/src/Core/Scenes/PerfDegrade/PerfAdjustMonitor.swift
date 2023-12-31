//
//  PerfAdjustMonitor.swift
//  ByteView
//
//  Created by ZhangJi on 2021/8/5.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewSetting
import ByteViewRtcBridge

final class PerfAdjustMonitor: PerfMonitorDependency {
    private let logger = Logger.getLogger("PerfAdjust.Monitor")

    private static let queueKey = DispatchSpecificKey<Void>()
    private static let queue: DispatchQueue = {
        let queue = DispatchQueue(label: "lark.byteview.perfadjustmonitor")
        queue.setSpecific(key: PerfAdjustMonitor.queueKey, value: ())
        return queue
    }()

    static func runOnQueue(action: @escaping () -> Void) {
        if DispatchQueue.getSpecific(key: Self.queueKey) != nil {
            action()
        } else {
            queue.async(execute: action)
        }
    }

    static let ncpu = PerfAdjustMonitor.deviceCpuCount()

    private let listeners = Listeners<PerfMonitorDelegate>()

    private let monitorConfig: FeaturePerformanceDynamicDetection
    private let consecutiveCount: Int
    private let firstConsecutiveCount: Int

    private var startJob: DispatchWorkItem?
    private var monitorInfos = [RtcSysStats]()

    enum MonitorState {
        case clear
        case started
        case firstTime
        case monitoring
        case pause
        case end
    }

    enum PerfState {
        case normal
        case overload
        case underuse
    }

    private var state: MonitorState = .clear
    private var perfState: PerfState = .normal

    /// 获取cpu核数类型
    private static func deviceCpuCount() -> Int {
        var ncpu: UInt = UInt(0)
        var len: size_t = MemoryLayout.size(ofValue: ncpu)
        sysctlbyname("hw.ncpu", &ncpu, &len, nil, 0)
        return Int(ncpu)
    }

    init(meeting: InMeetMeeting) {
        monitorConfig = meeting.setting.featurePerformanceConfig.adjustConfig
        firstConsecutiveCount = monitorConfig.firstMonitorDuration / 2
        consecutiveCount = monitorConfig.continueMonitorDuration / 2
        logger.info("MonitorConfig: \(monitorConfig), firstConsecutiveCount: \(firstConsecutiveCount), ConsecutiveCount: \(consecutiveCount)")
    }

    func setupMonitor(monitorConfig: ByteViewSetting.FeaturePerformanceDynamicDetection) {
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

    func restartMonitor() {
        logger.debug("restart monitor")
        Self.runOnQueue {
            if self.state == .end {
                return
            }
            self.state = .firstTime
        }

    }

    func addSystemUsageInfo(_ info: RtcSysStats) {
        Self.runOnQueue {
            self._addSystemUsageInfo(info)
        }
    }

    private func _addSystemUsageInfo(_ info: RtcSysStats) {
        guard state == .monitoring || state == .firstTime else {
            return
        }

        var infoState: PerfState = .normal
        for rule in monitorConfig.overloadRules where rule.isOverload(info) {
            infoState = .overload
            break
        }

        if state == .monitoring, infoState == .normal {
            infoState = .underuse
            for rule in monitorConfig.normalRules where !rule.isUnderuse(info) {
                infoState = .normal
                break
            }
        }

        if infoState != perfState {
            perfState = infoState
            if !monitorInfos.isEmpty {
                logger.debug("restart monitor due to state change")
                monitorInfos.removeAll()
            }
        }

        if infoState != .normal {
            if (state == .firstTime && infoState == .overload) || state == .monitoring {
                logger.debug("add monitor info: \(info) count: \(monitorInfos.count) state: \(infoState): is first time: \(self.state == .firstTime)")
                monitorInfos.append(info)

                if monitorInfos.count >= (self.state == .firstTime ? self.firstConsecutiveCount : self.consecutiveCount) {
                    self.reportState(perfState)
                }
            }
        }
    }

    private func reportState(_ state: PerfState) {
        defer {
            monitorInfos.removeAll()
            self.state = .monitoring
            self.perfState = .normal
        }

        let reportInfo = monitorInfos.reduce(into: RtcSysStats(cpuAppUsage: 0, cpuTotalUsage: 0, cpuCoreCount: 0)) { result, info in
            result.cpuAppUsage += info.cpuAppUsage / Double(monitorInfos.count)
            result.cpuTotalUsage += info.cpuTotalUsage / Double(monitorInfos.count)
        }

        if state == .overload {
            self.listeners.forEach { $0.reportPerformanceOverload() }
        } else if state == .underuse {
            self.listeners.forEach { $0.reportPerformanceUnderuse() }
        }

        logger.debug("ReportState info: \(reportInfo), state: \(state), is first time: \(self.state == .firstTime)")
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
        perfState = .normal
        monitorInfos.removeAll()
    }
}

extension FeatureRule {
    func isOverload(_ info: RtcSysStats) -> Bool {
        return (info.cpuAppUsage >= appCpu) && (info.cpuTotalUsage >= systemCpu)
    }

    func isUnderuse(_ info: RtcSysStats) -> Bool {
        return (info.cpuAppUsage < appCpu) && (info.cpuTotalUsage < systemCpu)
    }
}
