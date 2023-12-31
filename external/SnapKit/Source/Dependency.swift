//
//  Config.swift
//  SnapKit
//
//  Created by Prontera on 2022/1/28.
//

import Foundation

public enum SnapKitErrorType: Int {
    case noSuperView
    case noExistingConstraint
    case noMatchAttributes
    case noCommonAncestor
}

/// 外部依赖：配置
public protocol PreventCrashDependency {
    /// 获取FG的值
    var isFeatureGatingEnable: Bool { get }
    /// 上报slardar自定义异常
    /// - Parameter exceptionType: 自定义异常类型
    func trackUserException(_ exceptionType: String, errorType: SnapKitErrorType, logInfo: String)
    /// 是否可以Debug
    var appCanDebug: Bool { get }
}

extension PreventCrashDependency {
    var isPreventCrashEnable: Bool {
        return !appCanDebug && isFeatureGatingEnable
    }
    func trackSnapKitFatalErrorException(_ errorType: SnapKitErrorType, logInfo: String = "") {
        trackUserException("snapkit", errorType: errorType, logInfo: logInfo)
    }
}

private struct PreventCrashDependencyDefaultImpl: PreventCrashDependency {
    let isFeatureGatingEnable = false
    func trackUserException(_ exceptionType: String, errorType: SnapKitErrorType, logInfo: String) {}
    let appCanDebug = false
}

private var staticPreventCrashDependencyImpl: PreventCrashDependency?
private let defaultPreventCrashDependencyImpl = PreventCrashDependencyDefaultImpl()

public enum Dependency {
    
    /// singleton
    public static var shared: PreventCrashDependency {
        if let dependencyImpl = staticPreventCrashDependencyImpl {
            return dependencyImpl
        } else {
            return defaultPreventCrashDependencyImpl
        }
    }

    /// must call before access shared
    public static func setup(preventCrashDependency: PreventCrashDependency) {
        staticPreventCrashDependencyImpl = preventCrashDependency
    }
}
