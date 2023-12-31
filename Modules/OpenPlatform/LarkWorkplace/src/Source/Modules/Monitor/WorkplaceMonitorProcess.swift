//
//  WorkplaceMonitorProcess.swift
//  LarkWorkplace
//
//  Created by Meng on 2023/6/8.
//

import Foundation
import ECOProbeMeta

/// 用于控制埋点进程及记录埋点状态。
protocol WorkplaceMonitorProcess {
    /// 开始埋点，所有的工作台 EventName 已经做了语法封装，可以直接用点语法找到自己需要埋点的 EventName。
    ///
    /// 业务应当直接使用不带下划线的 start 方法。
    func _start(_ code: OPMonitorCodeProtocol) -> WorkplaceMonitorable
}

extension WorkplaceMonitorProcess {
    /// EPMClientOpenPlatformAppCenterApplinkCode convenience
    func start(_ code: EPMClientOpenPlatformAppCenterApplinkCode) -> WorkplaceMonitorable {
        return _start(code)
    }

    /// EPMClientOpenPlatformAppCenterBackgroundCode convenience
    func start(_ code: EPMClientOpenPlatformAppCenterBackgroundCode) -> WorkplaceMonitorable {
        return _start(code)
    }

    /// EPMClientOpenPlatformAppCenterCacheCode convenience
    func start(_ code: EPMClientOpenPlatformAppCenterCacheCode) -> WorkplaceMonitorable {
        return _start(code)
    }

    /// EPMClientOpenPlatformAppCenterEventCode convenience
    func start(_ code: EPMClientOpenPlatformAppCenterEventCode) -> WorkplaceMonitorable {
        return _start(code)
    }

    /// EPMClientOpenPlatformAppCenterRouterCode convenience
    func start(_ code: EPMClientOpenPlatformAppCenterRouterCode) -> WorkplaceMonitorable {
        return _start(code)
    }

    /// EPMClientOpenPlatformAppCenterWorkplaceCode convenience
    func start(_ code: EPMClientOpenPlatformAppCenterWorkplaceCode) -> WorkplaceMonitorable {
        return _start(code)
    }
}
