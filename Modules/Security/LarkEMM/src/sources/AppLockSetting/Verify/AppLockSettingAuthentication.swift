//
//  AppLockSettingAuthentication.swift
//  LarkMine
//
//  Created by thinkerlj on 2021/12/12.
//

import UIKit
import LocalAuthentication
import LarkAlertController
import LarkSensitivityControl
import EENavigator
import LarkSecurityComplianceInfra
import LarkContainer

enum AppLockSettingBiometryAuthType {
    case none
    case faceID
    case touchID
}

enum AlertTipsPageType {
    case lockScreen
    case setting
}

final class AppLockSettingBiometryAuthentication: UserResolverWrapper {

    let userResolver: UserResolver

    init(resolver: UserResolver) {
        self.userResolver = resolver
    }

    // 设备本身具备能力，和 App 的授权状态无关
    var deviceBiometryType: AppLockSettingBiometryAuthType {
        let context = generateContext()
        switch context.biometryType {
        case .faceID: return .faceID
        case .touchID: return .touchID
        default: return .touchID
        }
    }

    var biometryFailureType: LAError.Code? {
        let context = generateContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            return nil
        }
        guard let code = error?.code else {
            return nil
        }
        Logger.info("biometry error code: \(code)")

        return LAError.Code(rawValue: code)
    }

    private lazy var laContext: LAContext = {
        let context = LAContext()
        context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        return context
    }()

    private func generateContext() -> LAContext {
        var context = laContext // 保证状态访问前，evaluate过
        context = LAContext() // 重新创建，防止缓存状态
        return context
    }

    // 是否在系统设置中允许飞书访问Face ID/Touch ID
    func isBiometryAvailable() -> Bool {
        return biometryFailureType != .biometryNotAvailable
    }
    // 是否允许自动检测
    func isAutoVerify() -> Bool {
        return biometryFailureType == nil
    }
    // 是否在锁屏页面隐藏Face ID/Touch ID解锁按钮
    func isBiometryButtonHidden() -> Bool {
        return biometryFailureType == .biometryNotAvailable
    }

    // 进行Face ID/Touch ID验证
    func triggerBiometryAuthAction(token: Token, reply: @escaping (Bool, Error?) -> Void) {
        DispatchQueue.global(qos: .default).async {
            let context = self.generateContext()
            context.localizedFallbackTitle = ""
            var reason = ""
            if self.deviceBiometryType == .touchID {
                reason = BundleI18n.AppLock.Lark_Screen_UnlockFingerprint
            } else {
                reason = BundleI18n.AppLock.Lark_Screen_AllowFaceIdUnlock()
            }
            do {
                try DeviceInfoEntry.evaluatePolicy(forToken: token,
                                                   laContext: context,
                                                   policy: .deviceOwnerAuthenticationWithBiometrics,
                                                   localizedReason: reason,
                                                   reply: { status, error in
                    DispatchQueue.main.async {
                        reply(status, error)
                    }
                })
            } catch {
                DispatchQueue.main.async {
                    reply(false, error)
                }
                Logger.error(error.localizedDescription)
            }
        }
    }

    func showAlertTipsWhenEvaluateFail(from: UIViewController, biometryFailureType: LAError.Code?, at pageType: AlertTipsPageType) {
        // 不同类型的错误有不同类型的弹窗，在有些页面中不弹窗
        switch biometryFailureType {
        case .biometryNotAvailable:
                showBiometryAuthAccessSetting(from: from)
        case .biometryLockout:
            if pageType == .lockScreen {
                showBiometryLockoutAlert(from: from)
            }
        case .biometryNotEnrolled:
            showBiometryNotEnrolled(from: from)
        case nil:
            Logger.info("no error occurs")
        default:
            Logger.error("not supported biometryFailureType on this device")
            // 遇到其他异常情况时的兜底处理
            showBiometryAuthAccessSetting(from: from)
        }
    }

    // 用户未授权飞书使用Face ID/Touch ID提示
    private func showBiometryAuthAccessSetting(from: UIViewController) {
        let alertController = LarkAlertController()
        var title: String
        var content: String
        if deviceBiometryType == .touchID {
            title = BundleI18n.AppLock.Lark_Screen_NeedTouchIdPermission
            content = BundleI18n.AppLock.Lark_Screen_SettingsTouchIdOn()
        } else {
            title = BundleI18n.AppLock.Lark_Screen_NeedFaceIdPermission
            content = BundleI18n.AppLock.Lark_Screen_SettingsFaceIdOn()
        }
        alertController.setTitle(text: title, font: UIFont.systemFont(ofSize: 17))
        alertController.setContent(text: content, font: UIFont.systemFont(ofSize: 16))
        alertController.addCancelButton()
        alertController.addPrimaryButton(text: BundleI18n.AppLock.Lark_Screen_SetButton, dismissCompletion: {
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        })
        navigator.present(alertController, from: from)
    }

    // Face ID/Touch ID识别次数过多提示
    private func showBiometryLockoutAlert(from: UIViewController) {
        let alertController = LarkAlertController()
        var title: String
        var content: String
        if deviceBiometryType == .touchID {
            title = BundleI18n.AppLock.Lark_LockIOS_Title_TouchIDFailed
            content = BundleI18n.AppLock.Lark_LockIOS_Description_SystemLockTouchID()
        } else {
            title = BundleI18n.AppLock.Lark_LockIOS_Title_UnableToDetectFaceID
            content = BundleI18n.AppLock.Lark_LockIOS_Description_SystemLockFaceID()
        }
        alertController.setTitle(text: title, font: UIFont.systemFont(ofSize: 17))
        alertController.setContent(text: content, font: UIFont.systemFont(ofSize: 16))
        alertController.addPrimaryButton(text: BundleI18n.AppLock.Lark_LockIOS_Button_GotIt)
        navigator.present(alertController, from: from)
    }

    // 系统中未录入Face ID/Touch ID提示
    private func showBiometryNotEnrolled(from: UIViewController) {
        let alertController = LarkAlertController()
        var title: String
        var content: String
        if deviceBiometryType == .touchID {
            title = BundleI18n.AppLock.Lark_LockIOS_Title_NoTouchIDRecord
            content = BundleI18n.AppLock.Lark_LockIOS_Title_NoFingerIDRecord
        } else {
            title = BundleI18n.AppLock.Lark_LockIOS_Title_NoFaceIDRecord
            content = BundleI18n.AppLock.Lark_LockIOS_Description_PleaseSetSystemFaceID
        }
        alertController.setTitle(text: title, font: UIFont.systemFont(ofSize: 17))
        alertController.setContent(text: content, font: UIFont.systemFont(ofSize: 16))
        alertController.addCancelButton()
        alertController.addPrimaryButton(text: BundleI18n.AppLock.Lark_LockIOS_Button_Settings, dismissCompletion: {
            // 跳转到Face ID/Touch ID设置界面；防止审核问题，使用了base64编码
            guard let urlStr = "QXBwLVByZWZzOlBBU1NDT0RF".base64Decoded(), let url = URL(string: urlStr) else { return }
            UIApplication.shared.open(url)
        })
        navigator.present(alertController, from: from)
    }

}
