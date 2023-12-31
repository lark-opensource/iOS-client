//
//  OPPerformanceSamplingController.swift
//  OPFoundation
//
//  Created by 尹清正 on 2021/3/10.
//

import Foundation
import LarkFeatureGating
import LarkSetting

/// 采样控制器，用于控制性能指标事件的采样率
public struct OPPerformanceSamplingController {
    /// 是否对采样逻辑进行放行，仅在Debug模式下有效
    public static var passingControl = true
    private static var passSampling: Bool {
        #if DEBUG
        return passingControl
        #else
        return false
        #endif
    }

    /// 根据用户采样率确定一次事件是否应该执行
    /// - Parameter event: 事件
    /// - Returns: 该事件此次是否需要执行
    static func ifNeedRun(event: OPPerformanceMonitorEvent) -> Bool {
        if passSampling { return true }
        // 获取当前用户的UserID
        guard let userID = OPPerformanceMonitorConfigProvider.currentUserID else {
            return false
        }
        // 借助用户的UserID生成一个0-1的散列浮点值
        // 如果该值位于 offset ～ offset+rate之间则说明命中了用户采样
        let userValue = Double(abs(userID.md5().hash)) / Double(Int.max)
        // 根据远端配置的offset与rate来确定一个范围，userValue位于此范围内就认为命中了采样
        var lowBound = event.samplingOffset
        var upBound = event.samplingOffset + event.samplingRate
        // 下边界不能小于0
        lowBound = lowBound<0 ? 0 : lowBound
        // 上边界不能大于1
        upBound = upBound>1 ? 1 : upBound
        // 下边界不能大于上边界
        upBound = upBound<lowBound ? lowBound : upBound

        // 判断是否命中采样
        let targetValueRange = lowBound...upBound
        if targetValueRange.contains(userValue) {
            return true
        }

        return false
    }

}

