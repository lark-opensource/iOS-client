//
//  AppLockLauncherDelegate.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2022/11/9.
//

import LarkAccountInterface
import Swinject
import BootManager
import LarkContainer
import LarkSecurityComplianceInfra
import LarkSecurityComplianceInterface

final class AppLockLauncherDelegate: PassportDelegate {
    let name: String = "AppLockLauncherDelegate"

    @Provider private var passportService: PassportService // Global

    let resolver: Resolver

    init(resolver: Resolver) {
        self.resolver = resolver
        NewBootManager.register(AppLockSettingLaunchTask.self)
        NewBootManager.register(CheckAppLockSettingLaunchTask.self)
    }

    func userDidOnline(state: PassportState) {
        let userResolver = self.userResolver(userID: state.user?.userID)
        let appLockSettingService = try? userResolver?.resolve(assert: AppLockSettingService.self)
        Logger.info("user did online: \(String(describing: state.user?.userID))")
        switch state.action {
        case .switch:
            appLockSettingService?.blurService.removeVisibleVCs()
            saveLeanModeInfo(userID: state.user?.userID)
            appLockSettingService?.checkVerification()
            Logger.info("switch account success: check applock verification")

        case .login:
            saveLeanModeInfo(userID: state.user?.userID)
            appLockSettingService?.checkVerification()
            Logger.info("after login success: check applock verification")

        default:
            break
        }
    }

    func userDidOffline(state: PassportState) {
        guard let userID = state.user?.userID else { return } // 避免fastLogin走到这里

        let userResolver = self.userResolver(userID: userID)
        let appLockSettingService = try? userResolver?.resolve(assert: AppLockSettingService.self)
        Logger.info("user did offline: \(userID))")

        switch state.action {
        case .logout:
            appLockSettingService?.blurService.removeVisibleVCs()
            appLockSettingService?.blurService.removeBlurViews()
            Logger.info("after logout: remove blur vc")

            let key = AppLockSettingVerifyViewModel.currentEntryErrKey(userID)
            let storage = SCKeyValue.globalMMKV()
            storage.removeObject(forKey: key)
            Logger.info("applock did clear input error")

        default:
            break
        }
    }

    private func saveLeanModeInfo(userID: String?) {
        Logger.info("will save lean mode info: \(String(describing: userID))")
        let userResolver = self.userResolver(userID: userID)
        let appLockSettingService = try? userResolver?.resolve(assert: AppLockSettingService.self)
        let leanModeService = try? userResolver?.resolve(assert: ExternalDependencyService.self).leanModeService

        guard let leanModeInfo = leanModeService?.leanModeLockScreenInfo() else { return }
        // 更新锁屏密码
        appLockSettingService?.configInfo.updateServerPinCodeIfNeeded(
            encyptPinCode: leanModeInfo.encyptPinCode ?? "",
            isActive: leanModeInfo.isActive,
            updateTime: leanModeInfo.updateTime
        )
        // 更新精简模式数据
        leanModeService?.updateLeanModeStatusAndAuthority()
    }

    private func userResolver(userID: String?) -> UserResolver? {
        guard let userID else { return nil }
        return try? resolver.getUserResolver(userID: userID)
    }
}
