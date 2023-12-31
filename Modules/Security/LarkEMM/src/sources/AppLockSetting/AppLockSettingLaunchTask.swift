//
//  AppLockSettingLaunchTask.swift
//  LarkMine
//
//  Created by thinkerlj on 2021/12/31.
//

import Foundation
import BootManager
import RunloopTools
import LarkFeatureGating
import RxSwift
import LarkContainer
import LarkSecurityComplianceInfra

final class AppLockSettingLaunchTask: UserFlowBootTask, Identifiable {

    static var identify = "AppLockSettingLaunchTask"
    override class var compatibleMode: Bool { SCContainerSettings.userScopeCompatibleMode }

    @ScopedProvider private var appLockSettingService: AppLockSettingService?
    
    override var runOnlyOnce: Bool { true }

    override func execute() throws {
        // 为了保证 AppLinkService 尽早注册同时又能取到FG的值。
        appLockSettingService?.checkVerification()
        appLockSettingService?.blurService.syncAppLockSettingConfig()
    }
}

final class CheckAppLockSettingLaunchTask: UserFlowBootTask, Identifiable {
    static var identify = "CheckAppLockSettingLaunchTask"
    override class var compatibleMode: Bool { SCContainerSettings.userScopeCompatibleMode }

    @ScopedProvider private var appLockSettingService: AppLockSettingService?

    override func execute() throws {
        appLockSettingService?.checkAppLockSetting()
    }
}
