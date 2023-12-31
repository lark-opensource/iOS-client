//
//  WorkplaceTrackProcess.swift
//  LarkWorkplace
//
//  Created by Meng on 2023/6/10.
//

import Foundation

/// 用于控制埋点进程及记录埋点状态。
protocol WorkplaceTrackProcess {
    /// 开始埋点，所有的工作台 EventName 已经做了语法封装，可以直接用点语法找到自己需要埋点的 EventName。
    func start(_ name: WorkplaceTrackEventName) -> WorkplaceTrackable
}
