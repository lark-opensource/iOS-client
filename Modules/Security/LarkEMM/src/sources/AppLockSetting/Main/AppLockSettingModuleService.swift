//
//  AppLockSettingModuleService.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2022/11/11.
//

import LarkContainer
import EENavigator
import UniverseDesignToast
import UniverseDesignActionPanel
import LarkOpenSetting
import LKCommonsTracker
import Homeric
import LarkSecurityComplianceInfra
import LarkSensitivityControl
import AppContainer

struct AppLock {
    static let appLockTrigger = PatternPair("appLockTrigger", "")
    static let pinCode = PatternPair("pinCode", "")
    static let lockTime = PatternPair("lockTime", "")
    static let lockTimeFooter = PatternPair("lockTimeFooter", "")
    static let biometryAuthentication = PatternPair("biometryAuthentication", "")
}

protocol AppLockSettingModuleService {
    func triggerPINCodeFlow(mode: AppLockSettingPINCodeMode, fromVC: UIViewController, completion: @escaping AppLockSettingPINCodeCompletion)
    func triggerTimerSelectAction(fromVC: UIViewController)
    func triggerBiometrySwitchAction(fromVC: UIViewController, isOn: Bool, token: Token)
    func updateModuleStatus(fromVC: UIViewController)
    func generateAppLockSettingVC() -> SettingViewController
}

final class AppLockSettingModuleServiceImp: AppLockSettingModuleService, UserResolverWrapper {

    let userResolver: UserResolver

    init(resolver: UserResolver) {
        self.userResolver = resolver
    }

    @ScopedProvider private var appLockSettingService: AppLockSettingService?

    public init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    func triggerPINCodeFlow(mode: AppLockSettingPINCodeMode, fromVC: UIViewController, completion: @escaping AppLockSettingPINCodeCompletion) {
        if mode == .entry {
            let viewModel = AppLockSettingPINCodeViewModel(resolver: userResolver, mode: mode, completion: completion)
            let vc = AppLockSettingPINCodeViewController(resolver: userResolver, viewModel: viewModel)
            navigator.push(vc, from: fromVC)
        } else if mode == .modify {
            let actionsheet = UDActionSheet(config: UDActionSheetUIConfig(isShowTitle: true))
            let tenantName = appLockSettingService?.formatTenantNameDesc ?? ""
            actionsheet.setTitle(BundleI18n.AppLock.Lark_Screen_NewDigitalCodeUnlockTenant(tenantName))
            actionsheet.addItem(.init(title: BundleI18n.AppLock.Lark_Screen_ModifyButtion, titleColor: UIColor.ud.textTitle, action: { [weak self, weak fromVC] in
                guard let self, let `fromVC` = fromVC else { return }
                let viewModel = AppLockSettingPINCodeViewModel(resolver: self.userResolver, mode: mode, completion: completion)
                let vc = AppLockSettingPINCodeViewController(resolver: self.userResolver, viewModel: viewModel)
                self.navigator.push(vc, from: fromVC)
            }))
            actionsheet.setCancelItem(text: BundleI18n.AppLock.Lark_Screen_CancelButton) {
                completion(mode, false)
            }
            navigator.present(actionsheet, from: fromVC)
        }
    }

    func triggerTimerSelectAction(fromVC: UIViewController) {
        // 跳转到锁定时间设置页面
        let vc = AppLockSettingTimerSelectVC(resolver: self.userResolver, handler: { [weak self] (timerFlag) in
            SCMonitor.info(business: .app_lock, eventName: "lock_time_modify", metric: ["time_flag": timerFlag])

            guard let `self` = self else { return }
            self.appLockSettingService?.configInfo.timerFlag = timerFlag
            self.appLockSettingService?.start()
            self.updateModuleStatus(fromVC: fromVC)
        })
        navigator.push(vc, from: fromVC)
    }

    func triggerBiometrySwitchAction(fromVC: UIViewController, isOn: Bool, token: Token) {
        let auth = appLockSettingService?.biometryAuth
        // 如果有相关的biometry状态问题 && 用户打开开关时才做提示
        if auth?.biometryFailureType != nil && isOn {
            SCMonitor.info(business: .app_lock, eventName: "modify_biometry_switch", category: ["type": "none", "status": isOn])
            // 这里移除了对 switchControl 的状态设置，最后的 updateData 方法会统一进行更新
            updateModuleStatus(fromVC: fromVC)

            // 只有是Face ID/Touch ID已经锁定的情况，才允许打开开关，其余情况需要用户解决异常之后才能打开
            if auth?.biometryFailureType == .biometryLockout {
                appLockSettingService?.configInfo.isBiometryEnable = true
            }
            auth?.showAlertTipsWhenEvaluateFail(from: fromVC, biometryFailureType: auth?.biometryFailureType, at: .setting)
        } else {
            let isTouchID = appLockSettingService?.biometryAuth.deviceBiometryType == .touchID
            SCMonitor.info(business: .app_lock, eventName: "modify_biometry_switch",
                           category: ["type": appLockSettingService?.biometryAuth.deviceBiometryType == .touchID ? "TouchID" : "FaceID", "status": isOn])

            var tips = ""
            if isTouchID {
                tips = isOn ? BundleI18n.AppLock.Lark_Screen_FingerprintUnlockOn : BundleI18n.AppLock.Lark_Screen_FingerprintUnlockOff
            } else {
                tips = isOn ? BundleI18n.AppLock.Lark_Screen_FaceIdUnlockOn : BundleI18n.AppLock.Lark_Screen_FaceIdUnlockOff
            }

            if isOn {
                // 打开Face ID/Touch ID
                biometricTrigger(token: token) { [weak self] isSuccess in
                    if isSuccess {
                        if let window = fromVC.view?.window {
                            UDToast.showTips(with: tips, on: window)
                        }
                    } else {
                        if let window = fromVC.view?.window {
                            UDToast.showTips(with: BundleI18n.AppLock.Lark_DeviceInfo_Toast_UnableToObtainPerm, on: window)
                        }
                    }
                    self?.appLockSettingService?.configInfo.isBiometryEnable = isSuccess

                    Tracker.post(TeaEvent(Homeric.SCS_LOCK_SCREEN_PROTECTION_CLICK, params: [
                        "click": "quick_unlock",
                        "quick_unlock_way": auth?.deviceBiometryType == .faceID ? "faceid_unlock" : "finger_print_unlcok",
                        "action": isSuccess ? "open" : "close"
                    ]))
                }
            } else {
                Tracker.post(TeaEvent(Homeric.SCS_LOCK_SCREEN_PROTECTION_CLICK, params: [
                    "click": "quick_unlock",
                    "quick_unlock_way": auth?.deviceBiometryType == .faceID ? "faceid_unlock" : "finger_print_unlcok",
                    "action": "close"
                ]))
                appLockSettingService?.configInfo.isBiometryEnable = false

                if let window = fromVC.view?.window {
                    UDToast.showTips(with: tips, on: window)
                }
            }
        }
    }

    private func biometricTrigger(token: Token, _ completion: ((Bool) -> Void)?) {
        let isFirstOpenBiometric = appLockSettingService?.configInfo.isFirstOpenBiometric ?? false
        if isFirstOpenBiometric {
            completion?(true)
            return
        }
        // 第一次打开Face ID/Touch ID验证需要进行验证
        appLockSettingService?.blurService.isRequestBiometric = true
        appLockSettingService?.biometryAuth.triggerBiometryAuthAction(token: token) { [weak self] (isSuccess, error) in
            completion?(isSuccess)
            if isSuccess {
                self?.appLockSettingService?.configInfo.isFirstOpenBiometric = true
            }
            self?.appLockSettingService?.blurService.isRequestBiometric = false
            SCLogger.info("app_lock: biometry auth error: \(error?.localizedDescription ?? "")")
        }
    }

    // 设置页面设置项状态更新
    func updateModuleStatus(fromVC: UIViewController) {
        guard let `fromVC` = fromVC as? SettingViewController else {
            return
        }
        fromVC.reload(false)
    }

    // 生成设置页面
    func generateAppLockSettingVC() -> SettingViewController {
        let appLockSettingViewController = SettingViewController()
        appLockSettingViewController.navTitle = BundleI18n.AppLock.Lark_Screen_LockScreenProtection

        // 设置项 Module 注册
        appLockSettingViewController.registerModule(AppLockTriggerModule(userResolver: userResolver), key: AppLock.appLockTrigger.moduleKey)
        appLockSettingViewController.registerModule(PINCodeModule(userResolver: userResolver), key: AppLock.pinCode.moduleKey)
        appLockSettingViewController.registerModule(LockTimeModule(userResolver: userResolver), key: AppLock.lockTime.moduleKey)
        appLockSettingViewController.registerModule(LockTimeFooterModule(userResolver: userResolver), key: AppLock.lockTimeFooter.moduleKey)
        appLockSettingViewController.registerModule(BiometryAuthenticationModule(userResolver: userResolver), key: AppLock.biometryAuthentication.moduleKey)

        appLockSettingViewController.patternsProvider = { return [
            .wholeSection(pair: AppLock.appLockTrigger),
            .section(
                footer: AppLock.lockTimeFooter,
                items: [AppLock.pinCode, AppLock.lockTime]),
            .wholeSection(pair: AppLock.biometryAuthentication)
        ]}

        SCMonitor.info(business: .app_lock, eventName: "setting_page")
        return appLockSettingViewController
    }
}
