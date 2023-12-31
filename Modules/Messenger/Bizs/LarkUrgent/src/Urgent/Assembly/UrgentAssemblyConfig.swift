//
//  UrgentAssemblyConfig.swift
//  LarkUrgent
//
//  Created by wuwenjian.weston on 2020/3/17.
//

import Foundation

public protocol UrgentAssemblyConfig {
    /// 是否载入加急消息，目前仅在单品内才会关闭
    var shouldLoadUrgent: Bool { get }
}

public extension UrgentAssemblyConfig {
    var shouldLoadUrgent: Bool { return true }
}
