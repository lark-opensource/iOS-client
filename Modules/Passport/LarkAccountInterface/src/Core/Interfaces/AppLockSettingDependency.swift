//
//  AppLockSettingDependency.swift
//  LarkAccountInterface
//
//  Created by ByteDance on 2023/11/2.
//

import Foundation


public protocol AppLockSettingDependency: AnyObject {
    /// 返回锁屏保护是否开启
    func checkAppLockSettingStatus(completed: ((Bool) -> Void)?)
    /// 返回锁屏保护UI优化是否开启
    var enableAppLockSettingsV2: Bool { get }
}
