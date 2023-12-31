//
//  AppLockSettingModules.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2022/11/11.
//

import LarkContainer
import LarkOpenSetting
import LarkSettingUI
import UniverseDesignToast
import UniverseDesignActionPanel
import LKCommonsTracker
import Homeric
import LarkSecurityComplianceInfra
import LarkSensitivityControl
import RxRelay
import RxSwift
import LarkSecurityComplianceInterface

class AppLockBaseModule: BaseModule, UserResolverWrapper {

}

// 锁屏保护总开关
final class AppLockTriggerModule: AppLockBaseModule {

    @ScopedInjectedLazy private var appLockSettingService: AppLockSettingService?
    @ScopedInjectedLazy private var appLockSettingModuleService: AppLockSettingModuleService?
    private var leanModeService: LeanModeSecurityService?

    private let bag = DisposeBag()
    private let switchChange = PublishRelay<Bool>()

    override init(userResolver: UserResolver) {
        self.leanModeService = try? userResolver.resolve(assert: ExternalDependencyService.self).leanModeService
        super.init(userResolver: userResolver)
        // 防止快速连续点击时开关需要频繁更新，改为最后一次点击后0.3s后生效
        switchChange
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isOn in
                guard let self = self else { return }
                self.handleSwitchChange(isOn)
            })
            .disposed(by: bag)
    }

    override func createSectionProp(_ key: String) -> SectionProp? {
        let item = SwitchNormalCellProp(title: BundleI18n.AppLock.Lark_Screen_LockScreenProtectionButton,
                                        isOn: appLockSettingService?.configInfo.isActive ?? false,
                                        onSwitch: { [weak self] _, isOn in
            self?.switchChange.accept(isOn)
        })
        let isActive = appLockSettingService?.configInfo.isActive ?? false
        let footer: HeaderFooterType = isActive ? .empty : .title(BundleI18n.AppLock.Lark_Screen_AutoLockDigitalFigerprint())

        return SectionProp(items: [item], footer: footer)
    }

    private func handleSwitchChange(_ isOn: Bool) {
        Tracker.post(TeaEvent(Homeric.SCS_LOCK_SCREEN_PROTECTION_CLICK, params: [
            "click": "lock_screen_protection",
            "action": isOn ? "open" : "close"
        ]))

        guard let from = self.context?.vc else { return }

        // 首次开启开关
        let isEmpty = appLockSettingService?.configInfo.pinCode.isEmpty ?? true
        if isOn, isEmpty {
            appLockSettingModuleService?.triggerPINCodeFlow(mode: .entry, fromVC: from) { [weak self] (_, isSuccess) in
                guard let `self` = self else { return }
                SCMonitor.info(business: .app_lock, eventName: "open_app_lock_trigger_first_entry", category: ["status": isSuccess])

                if isSuccess {
                    if let window = from.view?.window {
                        UDToast.showTips(with: BundleI18n.AppLock.Lark_Screen_ScreenProtectionOn, on: window)
                    }
                    self.appLockSettingService?.configInfo.isActive = isOn
                    self.appLockSettingService?.start()
                    self.appLockSettingModuleService?.updateModuleStatus(fromVC: from)
                    // 如果有权限使用精简模式，发送请求
                    let canUseLeanMode = self.leanModeService?.canUseLeanMode() ?? false
                    if canUseLeanMode {
                        let password = self.appLockSettingService?.configInfo.pinCode ?? ""
                        self.leanModeService?.patchLockScreenConfig(password: password, isEnabled: isOn)
                            .subscribe(onError: { error in
                                SCMonitor.error(business: .app_lock, eventName: "open_app_lock_trigger_first_entry_error", error: error)
                            })
                            .disposed(by: self.bag)
                    }
                } else {
                    // 更新开关状态
                    self.appLockSettingModuleService?.updateModuleStatus(fromVC: from)
                }
            }
        } else {
            // 非首次开启开关（包括关闭开关）
            SCMonitor.info(business: .app_lock, eventName: "switch_app_lock_trigger", category: ["status": isOn])

            if isOn, let window = from.view?.window {
                UDToast.showTips(with: BundleI18n.AppLock.Lark_Screen_ScreenProtectionOn, on: window)
            }
            appLockSettingService?.configInfo.isActive = isOn
            appLockSettingService?.start()
            appLockSettingModuleService?.updateModuleStatus(fromVC: from)
            // 如果有权限使用精简模式，发送请求更改开关状态
            let canUseLeanMode = self.leanModeService?.canUseLeanMode() ?? false
            if canUseLeanMode {
                self.leanModeService?.patchLockScreenConfig(password: nil, isEnabled: isOn)
                    .subscribe(onError: { error in
                        SCMonitor.error(business: .app_lock, eventName: "switch_app_lock_trigger_error", error: error)
                    })
                    .disposed(by: self.bag)
            }
        }
    }
}

// 锁屏密码设置入口
final class PINCodeModule: AppLockBaseModule {

    @ScopedInjectedLazy private var appLockSettingService: AppLockSettingService?
    @ScopedInjectedLazy private var appLockSettingModuleService: AppLockSettingModuleService?
    private var leanModeService: LeanModeSecurityService?

    private let bag = DisposeBag()
    
    override init(userResolver: UserResolver) {
        leanModeService = try? userResolver.resolve(assert: ExternalDependencyService.self).leanModeService
        super.init(userResolver: userResolver)
    }

    override func createCellProps(_ key: String) -> [CellProp]? {
        let isActive = appLockSettingService?.configInfo.isActive ?? false
        if !isActive {
            return nil
        }

        let item = NormalCellProp(title: BundleI18n.AppLock.Lark_Screen_SetDigitalCode,
                                  accessories: [.text(BundleI18n.AppLock.Lark_Screen_SetDone), .arrow()]) { [weak self] _ in
            guard let `self` = self, let from = self.context?.vc else { return }

            self.appLockSettingModuleService?.triggerPINCodeFlow(mode: .modify, fromVC: from) { [weak from, weak self] (_, isSuccess) in
                guard let `self` = self else { return }

                SCMonitor.info(business: .app_lock, eventName: "modify_pin_code", category: ["status": isSuccess])

                if isSuccess {
                    Tracker.post(TeaEvent(Homeric.SCS_LOCK_SCREEN_PROTECTION_CLICK, params: [
                        "click": "modify_code_success"
                    ]))

                    if let fromVC = from {
                        UDToast.showTips(with: BundleI18n.AppLock.Lark_Screen_ModifyDigitalCode, on: fromVC.view)
                        self.appLockSettingModuleService?.updateModuleStatus(fromVC: fromVC)
                    }
                    // 如果有权限使用精简模式，发送请求更改密码
                    let canUseLeanMode = self.leanModeService?.canUseLeanMode() ?? false
                    if canUseLeanMode {
                        self.leanModeService?.patchLockScreenConfig(password: self.appLockSettingService?.configInfo.pinCode, isEnabled: nil)
                            .subscribe(onError: { error in
                                SCMonitor.error(business: .app_lock, eventName: "switch_app_lock_trigger_error", error: error)
                            })
                            .disposed(by: self.bag)
                    }
                }
            }
        }
        return [item]
    }
}

// 锁屏时间设置入口
final class LockTimeModule: AppLockBaseModule {

    @ScopedInjectedLazy private var appLockSettingService: AppLockSettingService?
    @ScopedInjectedLazy private var appLockSettingModuleService: AppLockSettingModuleService?

    override func createCellProps(_ key: String) -> [CellProp]? {
        let isActive = appLockSettingService?.configInfo.isActive ?? false
        if !isActive {
            return nil
        }

        let title = appLockSettingService?.configInfo.timerFlagDesc() ?? ""
        let item = NormalCellProp(title: BundleI18n.AppLock.Lark_Screen_LockTime,
                                  accessories: [.text(title), .arrow()]) { [weak self] _ in
            guard let `self` = self, let from = self.context?.vc else { return }
            SCMonitor.info(business: .app_lock, eventName: "modify_lock_time")

            self.appLockSettingModuleService?.triggerTimerSelectAction(fromVC: from)
        }
        return [item]
    }

}

final class LockTimeFooterModule: AppLockBaseModule {

    @ScopedInjectedLazy private var appLockSettingService: AppLockSettingService?

    override func createFooterProp(_ key: String) -> HeaderFooterType? {
        let isActive = appLockSettingService?.configInfo.isActive ?? false
        if !isActive {
            return nil
        }

        let isEmpty = !isActive
        var text = ""
        let timerFlag = appLockSettingService?.configInfo.timerFlag ?? 0
        if timerFlag > 0 {
            text = BundleI18n.AppLock.Lark_Screen_ExceedTimeUnlock("\(timerFlag)")
        } else {
            text = BundleI18n.AppLock.Lark_Screen_UnlockEveryTimeBackground()
        }
        let footer: HeaderFooterType = isEmpty ? .empty : .title(text)
        return footer
    }
}

// Face ID/Touch ID验证识别设置
final class BiometryAuthenticationModule: AppLockBaseModule {

    @ScopedInjectedLazy private var appLockSettingService: AppLockSettingService?
    @ScopedInjectedLazy private var appLockSettingModuleService: AppLockSettingModuleService?

    override func createSectionProp(_ key: String) -> SectionProp? {
        let type = appLockSettingService?.biometryAuth.deviceBiometryType ?? .none
        let isActive = appLockSettingService?.configInfo.isActive ?? false
        guard type != .none, isActive else {
            return nil
        }

        let switchStatus = appLockSettingService?.configInfo.isBiometryEnable == true && appLockSettingService?.biometryAuth.isBiometryAvailable() == true
        let title = appLockSettingService?.biometryAuth.deviceBiometryType == .faceID ? BundleI18n.AppLock.Lark_Screen_FaceIdUnlock : BundleI18n.AppLock.Lark_Screen_UnlockFingerprint

        let item = SwitchNormalCellProp(title: title, isOn: switchStatus) { [weak self] _, isOn in
            guard let `self` = self, let from = self.context?.vc else { return }
            let token = Token("LARK-PSDA-startup_appLock_evaluatePolicy")
            self.appLockSettingModuleService?.triggerBiometrySwitchAction(fromVC: from, isOn: isOn, token: token)
        }

        let isEmpty = self.appLockSettingService?.configInfo.isBiometryEnable ?? false
        var text = ""
        if self.appLockSettingService?.biometryAuth.deviceBiometryType == .faceID {
            text = BundleI18n.AppLock.Lark_Screen_SystemFaceIdUnlock
        } else {
            text = BundleI18n.AppLock.Lark_Screen_SystemFingerprintUnlock
        }
        let footer: HeaderFooterType = isEmpty ? .empty : .title(text)

        return SectionProp(items: [item], footer: footer)
    }
}
