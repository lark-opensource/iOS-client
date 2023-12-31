//
//  UDTrackerDependency.swift
//  UniverseDesignTheme
//
//  Created by 白镜吾 on 2023/9/8.
//

import Foundation

public protocol UDTrackerDependency {
    func logger(component: UDComponentType, loggerType: UDLoggerType, msg: String)

    func getIconFailTracker(iconName: String?)
}

// 仅限 UDIcon 日志用
public enum UDLoggerType {
    case info
    case error
}

// 仅限 UDIcon 日志用
public enum UDComponentType: String {
    case UDIcon
    case UDColor
    case UDFont
}
