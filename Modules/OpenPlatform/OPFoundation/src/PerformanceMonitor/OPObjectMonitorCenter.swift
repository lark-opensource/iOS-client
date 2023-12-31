//
//  OPObjectMonitorCenter.swift
//  OPFoundation
//
//  Created by 尹清正 on 2021/3/24.
//

import Foundation

/// 开放平台对象性能指标检测机制的统一入口
@objcMembers
public final class OPObjectMonitorCenter: NSObject {

    /// 建立开放平台内存相关所有性能指标监控（包括：泄漏监控、实例数量监控）
    public static func setupMemoryMonitor(with target: OPMemoryMonitoredObjectType?) {
        guard let target = target else { return }

        for event in OPPerformanceMonitorEvent.allCases {
            setupMemoryMonitor(with: target, for: event)
        }
    }

    /// 建立开放平台内存特定性能指标监控，特定指标由event参数确定
    public static func setupMemoryMonitor(
        with target: OPMemoryMonitoredObjectType?,
        for event: OPPerformanceMonitorEvent) {
        guard let target = target else { return }

        // 执行
        switch event {
        case .objectLeak:
            if OPPerformanceSamplingController.ifNeedRun(event: .objectLeak) {
                OPLeakSelfCheckCenter.shared.startSelfCheck(with: target)
            }
        case .objectOvercount:
            if OPPerformanceSamplingController.ifNeedRun(event: .objectOvercount) {
                OPCountDetector.shared.notifyInitWith(object: target)
            }
        case .memoryWave:
            if OPPerformanceSamplingController.ifNeedRun(event: .memoryWave) {
                OPMemWaveDetectCenter.shared.setupMemoryWaveDetect(with: target)
            }
        }
    }

    public static func updateState(_ state: OPMonitoredObjectState, for target: OPMemoryMonitoredObjectType?) {
        // 采样
        guard OPPerformanceSamplingController.ifNeedRun(event: .objectLeak) else {
            return
        }
        guard let target = target else { return }

        OPLeakSelfCheckCenter.shared.setState(state, for: target)
    }

    public static func setMemoryWave(active: Bool, with target: OPMemoryMonitoredObjectType?) {
        guard let target = target else { return }

        if active {
            OPMemWaveDetectCenter.shared.run(with: target)
        } else {
            OPMemWaveDetectCenter.shared.pause(with: target)
        }
    }
}
