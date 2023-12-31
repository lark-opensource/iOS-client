//
//  OPMonitoredObjectState.swift
//  OPFoundation
//
//  Created by 尹清正 on 2021/3/8.
//

import Foundation

/// 当前待检测对象所处的状态
@objc public enum OPMonitoredObjectState: UInt {
    /// 预期持有状态，该对象在业务使用方的预期中是要被持有的
    case expectedRetain
    /// 预期销毁状态，该对象在业务使用方的预期中是要被销毁的
    case expectedDestroy
}
