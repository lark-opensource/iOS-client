//
//  PerfAdjustorProtocol.swift
//  ByteView
//
//  Created by ZhangJi on 2023/6/8.
//

import Foundation
import ByteViewSetting

protocol PerfAdjustorProtocol: AnyObject {
    init(meeting: InMeetMeeting)

    func addListener(_ listener: PerfAdjustorListener)
    func removeListener(_ listener: PerfAdjustorListener)

    func reportNeedDegrade(type: AdjustType)
    func reportNeedUpgrade(type: AdjustType)
}

enum AdjustType: Equatable {
    case performance
    case thermal(ProcessInfo.ThermalState)
    case battery
}

extension AdjustType: CustomStringConvertible {
    var description: String {
        switch self {
        case .performance:
            return "performance"
        case .thermal(let state):
            return "thermal(\(state.rawValue))"
        case .battery:
            return "battery"
        }
    }
}

protocol PerfAdjustorListener: AnyObject {
    func willBeginPerfDegrade()
    func didEndPerfDegrade()

    func sholdEnableVoiceMode(enable: Bool)

    func willBeginPerfUpgrade()
    func didEndPerfUpgrade()

    func reportAdjustLevels(_ levels: [String: Int])
}

extension PerfAdjustorListener {
    func willBeginPerfDegrade() {}
    func didEndPerfDegrade() {}

    func sholdEnableVoiceMode(enable: Bool) {}

    func willBeginPerfUpgrade() {}
    func didEndPerfUpgrade() {}

    func reportAdjustLevels(_ levels: [String: Int]) {}
}

public protocol PerfMonitorDependency: AnyObject {
    func addListener(_ listener: PerfMonitorDelegate)
    func removeListener(_ listener: PerfMonitorDelegate)

    func setupMonitor(monitorConfig: FeaturePerformanceDynamicDetection)
    func startMonitor()
    func restartMonitor()

    func stopMonitor()
}

public protocol PerfMonitorDelegate: AnyObject {
    func reportPerformanceOverload()
    func reportPerformanceUnderuse()
}
