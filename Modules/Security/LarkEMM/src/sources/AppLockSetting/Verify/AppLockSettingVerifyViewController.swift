//
//  AppLockSettingVerifyViewController.swift
//  LarkMine
//
//  Created by thinkerlj on 2021/12/29.
//

import Foundation
import LarkUIKit
import RxSwift
import RxCocoa
import UniverseDesignToast
import LarkContainer
import EENavigator
import LarkActionSheet
import FigmaKit
import UIKit
import LarkAlertController
import LarkAccountInterface
import LKCommonsTracker
import Homeric
import UniverseDesignColor
import LarkSecurityComplianceInfra
import LarkSensitivityControl

protocol AppLockSettingVerifyViewControllerProtocol: UIViewController {
    func startVerify()
    init(resolver: UserResolver,
         viewModel: AppLockSettingVerifyViewModel,
         dismissCallback: ((_ pinType: AppLockSettingPinType) -> Void)?)
}

typealias AppLockSettingPinType = LarkEMM.AppLockSettingVerifyViewController.PinType

final class AppLockSettingVerifyViewController: BaseUIViewController, UserResolverWrapper, AppLockSettingVerifyViewControllerProtocol {
    enum PinType {
        // 正向密码，逆向密码，生物识别
        case forward, backward, biometry
    }

    private var viewModel: AppLockSettingVerifyViewModel
    // isReversedPin：true表示是逆向密码，false表示正向密码，nil表示不是通过输入密码解锁的（生物识别）
    private var dismissCallback: ((_ pinType: PinType) -> Void)?
    private var disposeBag = DisposeBag()

    @ScopedProvider private var appLockSettingService: AppLockSettingService?
    @Provider private var passportService: PassportService // Global

    func startVerify() {

        let isActive = appLockSettingService?.configInfo.isActive ?? false
        if !isActive {
            return
        }

        let isPINExceedLimit = appLockSettingService?.configInfo.isPINExceedLimit ?? false
        if isPINExceedLimit {
            showPINExceedLimitTips()
            return
        }

        let isBiometryEnable = appLockSettingService?.configInfo.isBiometryEnable ?? false
        let shouldUsePinCode = appLockSettingService?.configInfo.shouldUsePinCode() ?? false
        let isAutoVerify = appLockSettingService?.biometryAuth.isAutoVerify() ?? false

        // 自动触发Face ID/Touch ID检测，需要满足以下条件
        // 1. 不是营私保护模式； 2. 没有超过时间限制，可以使用人脸识别； 3. 人脸识别打开； 4. 设置为自动人脸识别
        if !viewModel.privacyModeEnable(),
            !shouldUsePinCode,
            isBiometryEnable,
            isAutoVerify {
            biometricAction()
        }
    }

    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.text = viewModel.title
        titleLabel.numberOfLines = 2
        titleLabel.font = UIFont.systemFont(ofSize: 28)
        UIFont.systemFont(ofSize: 28, weight: .medium)
        titleLabel.textColor = UIColor.ud.primaryOnPrimaryFill
        titleLabel.textAlignment = .center
        return titleLabel
    }()

    private lazy var pinCodeVerifyView: AppLockSettingPINCodeVerifyView = {
        let p = AppLockSettingPINCodeVerifyView()
        return p
    }()

    private lazy var infoLabel: UILabel = {
        let infoLabel = UILabel()
        infoLabel.text = BundleI18n.AppLock.Lark_Screen_EnterDigitalCode
        infoLabel.numberOfLines = 3 // 最多显示三行
        infoLabel.lineBreakMode = .byWordWrapping
        infoLabel.textAlignment = .center
        infoLabel.textColor = UIColor.ud.primaryOnPrimaryFill
        infoLabel.font = UIFont.systemFont(ofSize: 14)
        return infoLabel
    }()

    private lazy var numberPadView: AppLockSettingNumberPadView = {
        let n = AppLockSettingNumberPadView()
        n.action = { [weak self] (text) in
            guard let `self` = self else { return }
            let isPINExceedLimit = self.appLockSettingService?.configInfo.isPINExceedLimit ?? false
            if isPINExceedLimit {
                self.showPINExceedLimitTips()
                return
            }

            if let t = text {
                self.pinCodeVerifyView.focusIndex += 1
                self.viewModel.tmpPINCode += t
            } else {
                self.pinCodeVerifyView.focusIndex -= 1
                if self.pinCodeVerifyView.focusIndex < 0 {
                    self.pinCodeVerifyView.focusIndex = 0
                }
                if !self.viewModel.tmpPINCode.isEmpty {
                    self.viewModel.tmpPINCode.removeLast()
                }
            }

            if self.viewModel.tmpPINCode.count == 4 {
                let isPinCode = self.appLockSettingService?.configInfo.comparePinCode(pinCode: self.viewModel.tmpPINCode) ?? false
                if isPinCode {
                    SCMonitor.info(business: .app_lock, eventName: "verify_completed", category: ["result": true, "action": "pin_code"])
                    self.appLockSettingService?.configInfo.renewUsePinCodeTimeStamp()
                    self.viewModel.curEntryErrCount = 0 // 重置本地记录错误次数
                    if #available(iOS 13.0, *) {
                        self.dismiss(animated: true) { [weak self] in
                            // 验证成功
                            self?.dismissCallback?(.forward)
                        }
                    } else {
                        self.dismissCallback?(.forward)
                    }
                    return
                }

                // 如果开了隐私模式才响应逆向密码
                let isReversedPinCode = self.appLockSettingService?.configInfo.comparePinCode(pinCode: String(self.viewModel.tmpPINCode.reversed())) ?? false
                let privacyModeEnable = self.viewModel.privacyModeEnable()
                if privacyModeEnable && isReversedPinCode {
                    SCMonitor.info(business: .app_lock, eventName: "enter_lean_mode")
                    // 验证成功
                    self.appLockSettingService?.configInfo.renewUsePinCodeTimeStamp()
                    self.viewModel.curEntryErrCount = 0 // 重置本地记录错误次数
                    if #available(iOS 13.0, *) {
                        self.dismiss(animated: true) { [weak self] in
                            self?.dismissCallback?(.backward)
                        }
                    } else {
                        self.dismissCallback?(.backward)
                    }
                    return
                }

                self.viewModel.curEntryErrCount += 1
                self.viewModel.tmpPINCode = ""
                self.pinCodeVerifyView.focusIndex = 0
                SCMonitor.info(business: .app_lock, eventName: "current_entry_count", metric: ["count": self.viewModel.curEntryErrCount])

                if self.viewModel.curEntryErrCount < self.viewModel.maxEntryCount {
                    let count = self.viewModel.maxEntryCount - self.viewModel.curEntryErrCount
                    self.infoLabel.text = BundleI18n.AppLock.Lark_Screen_IncorrectCodeRetryLogInAgain(count)
                    self.shakeInfoLabel()
                } else {
                    self.appLockSettingService?.configInfo.isPINExceedLimit = true
                    self.showPINExceedLimitTips()
                }
            }
        }
        return n
    }()

    private lazy var forgetPINCodeButton: UIButton = {
        let f = UIButton(type: .custom)
        f.setTitle(BundleI18n.AppLock.Lark_Screen_ForgotDigitalCode, for: .normal)
        f.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        f.addTarget(self, action: #selector(forgetPINCodeAction), for: .touchUpInside)
        return f
    }()

    private lazy var biometricButton: UIButton = {
        let b = UIButton(type: .custom)
        let type = appLockSettingService?.biometryAuth.deviceBiometryType ?? .none
        switch type {
        case .faceID:
            b.setTitle(BundleI18n.AppLock.Lark_Screen_UseFaceIdUnlock, for: .normal)
        case .touchID:
            b.setTitle(BundleI18n.AppLock.Lark_Screen_UseFingerprintUnlock, for: .normal)
        default:
            b.isHidden = true
        }
        // 设置页开关关闭 || 用户关闭了飞书使用Face ID/Touch ID权限
        let isBiometryEnable = appLockSettingService?.configInfo.isBiometryEnable ?? false
        let isBiometryButtonHidden = appLockSettingService?.biometryAuth.isBiometryButtonHidden() ?? false
        b.isHidden = !isBiometryEnable || isBiometryButtonHidden
        b.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        b.addTarget(self, action: #selector(biometricAction), for: .touchUpInside)
        return b
    }()

    let userResolver: UserResolver

    init(resolver: UserResolver,
         viewModel: AppLockSettingVerifyViewModel,
         dismissCallback: ((_ pinType: PinType) -> Void)? = nil) {
        self.userResolver = resolver
        self.viewModel = viewModel
        self.dismissCallback = dismissCallback
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // 处理键盘弹出
        endAllWindowsEditing()

        NotificationCenter.default.rx
            .notification(UIResponder.keyboardWillShowNotification)
            .subscribe(onNext: { [weak self] _ in
                self?.endAllWindowsEditing()
            }).disposed(by: self.disposeBag)

        viewModel.targetViewController = self
        
        let bgView = AppLockBackgroundView(frame: view.bounds)
        view.addSubview(bgView)
        bgView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.right.equalTo(-16)
            make.top.equalTo(123)
        }

        view.addSubview(pinCodeVerifyView)
        pinCodeVerifyView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(80)
            make.centerX.equalToSuperview()
        }

        view.addSubview(infoLabel)
        infoLabel.snp.makeConstraints { make in
            make.top.equalTo(pinCodeVerifyView.snp.bottom).offset(25)
            make.left.greaterThanOrEqualToSuperview().offset(32)
            make.right.greaterThanOrEqualToSuperview().offset(32)
            make.centerX.equalToSuperview()
        }

        view.addSubview(numberPadView)
        numberPadView.snp.makeConstraints { make in
            make.top.lessThanOrEqualTo(infoLabel.snp.bottom).offset(84)
            make.centerX.equalToSuperview()
        }

        // 打开隐私权限模式时，按钮透明，不可点击
        if self.viewModel.privacyModeEnable() {
            forgetPINCodeButton.setTitleColor(.clear, for: .normal)
            forgetPINCodeButton.isEnabled = false
        }

        view.addSubview(forgetPINCodeButton)
        forgetPINCodeButton.snp.makeConstraints { make in
            make.top.greaterThanOrEqualTo(numberPadView.snp.bottom).offset(10)
            make.top.lessThanOrEqualTo(numberPadView.snp.bottom).offset(30)
            make.bottom.lessThanOrEqualTo(-36)
            if biometricButton.isHidden {
                make.centerX.equalToSuperview()
            } else {
                make.left.equalTo(numberPadView)
            }
        }

        // 打开隐私权限模式时，按钮透明
        if self.viewModel.privacyModeEnable() {
            biometricButton.setTitleColor(.clear, for: .normal)
        }
        view.addSubview(biometricButton)
        biometricButton.snp.makeConstraints { make in
            make.right.equalTo(numberPadView)
            make.top.bottom.equalTo(forgetPINCodeButton)
            make.width.greaterThanOrEqualTo(80) // 设定最小宽度，防止热区小
        }

        SCMonitor.info(business: .app_lock, eventName: "verify_page")
    }

    override func viewDidAppear(_ animated: Bool) {
        self.nodeWindow?.makeKey()
        super.viewDidAppear(animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        self.nodeWindow?.resignKey()
        super.viewDidDisappear(animated)
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard let key = presses.first?.key else {
            super.pressesBegan(presses, with: event)
            return
        }

        if #available(iOS 13.4, *) {
            if !self.numberPadView.handlePressBegan(key: key) {
                super.pressesBegan(presses, with: event)
            }
        } else {
            // 低版本系统不响应
            super.pressesBegan(presses, with: event)
        }
    }

    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard let key = presses.first?.key else {
            super.pressesEnded(presses, with: event)
            return
        }

        if #available(iOS 13.4, *) {
            if !self.numberPadView.handlePressesEnded(key: key) {
                super.pressesEnded(presses, with: event)
            }
        } else {
            // 低版本系统不响应
            super.pressesEnded(presses, with: event)
        }
    }

    override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard let key = presses.first?.key else {
            super.pressesCancelled(presses, with: event)
            return
        }

        if #available(iOS 13.4, *) {
            if !self.numberPadView.handlePressCancled(key: key) {
                super.pressesCancelled(presses, with: event)
            }
        } else {
            // 低版本系统不响应
            super.pressesCancelled(presses, with: event)
        }
    }

    private func endAllWindowsEditing() {
        guard view.window != nil else { return }
        if #available(iOS 13.0, *) {
            UIApplication.shared.connectedScenes.forEach { scene in
                (scene as? UIWindowScene)?.windows.forEach({ $0.endEditing(true) })
            }
        } else {
            UIApplication.shared.windows.forEach { $0.endEditing(true) }
        }
    }

    // 锁屏密码尝试次数过多
    private func showPINExceedLimitTips() {
        let alertController = LarkAlertController()
        alertController.setTitle(text: BundleI18n.AppLock.Lark_Screen_Hint, font: UIFont.systemFont(ofSize: 17))
        alertController.setContent(text: BundleI18n.AppLock.Lark_Screen_ExceedLimitLogInAgain, font: UIFont.systemFont(ofSize: 16))
        alertController.addPrimaryButton(text: BundleI18n.AppLock.Lark_Screen_LogInAgain, dismissCompletion: { [weak self] in
            guard let `self` = self else { return }
            self.triggerLogout()
        })
        userResolver.navigator.present(alertController, from: self)
    }

    private func triggerLogout() {

        var category = [String: Any]()
        let tenantName = appLockSettingService?.formatTenantNameDesc ?? ""
        let logoutConf = LogoutConf.foreground
        logoutConf.forceLogout = true
        let configInfoKey = self.appLockSettingService?.configInfo.appLockSettingConfigInfoKey ?? ""
        appLockSettingService?.blurService.addVisibleBlurVCs()
        logoutConf.destination = passportService.userList.filter({ $0.userStatus == .normal }).count > 1 ? .switchUser : .launchGuide
        // 退出前保存该值
        let privacyModeEnable = self.viewModel.privacyModeEnable()
        let configInfo = self.appLockSettingService?.configInfo
        let blurService = self.appLockSettingService?.blurService
        LarkSecurityComplianceInfra.SCLogger.info("logout will begin")
        passportService.logout(conf: logoutConf) { [weak self] in
            if let window = self?.view.window {
                UDToast().showFailure(with: BundleI18n.AppLock.Lark_Accounts_CantLogOutCompanyRetry(tenantName), on: window)
            }
            blurService?.removeVisibleVCs()
            blurService?.removeBlurViews()
            LarkSecurityComplianceInfra.SCLogger.info("logout interruptted")
            category["result"] = false
            category["error"] = "interruptted"
            SCMonitor.info(business: .app_lock, eventName: "trigger_logout", category: category)
        } onError: { [weak self] error in
            if let window = self?.view.window {
                UDToast().showFailure(with: BundleI18n.AppLock.Lark_Accounts_CantLogOutCompanyRetry(tenantName), on: window)
            }
            blurService?.removeVisibleVCs()
            blurService?.removeBlurViews()
            LarkSecurityComplianceInfra.SCLogger.info("logout error: \(error)")
            category["result"] = false
            category["error"] = error
            SCMonitor.info(business: .app_lock, eventName: "trigger_logout", category: category)
        } onSuccess: { _, _ in
            // 精简模式有权限时，只清理密码超限，不清除数据
            if !privacyModeEnable {
                AppLockSettingConfigInfo.clean(configInfoKey: configInfoKey, userID: configInfo?.userID)
            } else {
                configInfo?.isPINExceedLimit = false
            }
            LarkSecurityComplianceInfra.SCLogger.info("logout success")
            blurService?.removeBlurViews()
        } onSwitch: { success in
            LarkSecurityComplianceInfra.SCLogger.info("logout switch: \(success)")
            category["result"] = true
            SCMonitor.info(business: .app_lock, eventName: "trigger_logout", category: category)
        }
    }

    @objc
    private func forgetPINCodeAction(sender: UIButton) {
        SCMonitor.info(business: .app_lock, eventName: "forget_pincode")

        let alertController = LarkAlertController()
        alertController.setTitle(text: BundleI18n.AppLock.Lark_Screen_ForgotDigitalCode, font: UIFont.systemFont(ofSize: 17))
        let tenantName = appLockSettingService?.formatTenantNameDesc ?? ""
        alertController.setContent(text: BundleI18n.AppLock.Lark_Screen_ForgotDigitalCodeScreenOff(tenantName), font: UIFont.systemFont(ofSize: 16))
        alertController.addCancelButton(newLine: false, weight: 1, numberOfLines: 1, dismissCheck: { true }) {
            Tracker.post(TeaEvent(Homeric.SCS_FORGET_DIGITAL_CODE_CLICK, params: [
                "click": "cancel"
            ]))
        }
        alertController.addPrimaryButton(text: BundleI18n.AppLock.Lark_Screen_LogInAgain, dismissCompletion: { [weak self] in
            guard let `self` = self else { return }

            Tracker.post(TeaEvent(Homeric.SCS_FORGET_DIGITAL_CODE_CLICK, params: [
                "click": "confirm"
            ]))
            self.triggerLogout()
        })
        userResolver.navigator.present(alertController, from: self)
    }

    @objc
    private func biometricAction(sender: UIButton = UIButton()) {
        SCMonitor.info(business: .app_lock, eventName: "biometric_action")
        let shouldUsePinCode = appLockSettingService?.configInfo.shouldUsePinCode() ?? false
        if shouldUsePinCode {
            self.infoLabel.text = BundleI18n.PrivacyMode.Lark_Core_PrivacyProtectionMode_EnterDigitPasscodeToUnlock_Error
            self.shakeInfoLabel()
            return
        }

        self.appLockSettingService?.blurService.isRequestBiometric = true
        let token = Token("LARK-PSDA-biometryAuth_unlock_appLock_evaluatePolicy")
        appLockSettingService?.biometryAuth.triggerBiometryAuthAction(token: token) { [weak self] (isSuccess, _) in
            guard let `self` = self else { return }
            if isSuccess {
                let type = self.appLockSettingService?.biometryAuth.deviceBiometryType == .faceID ? "face_id" : "touch_id"
                SCMonitor.info(business: .app_lock, eventName: "verify_completed", category: ["result": true, "action": type])
                if #available(iOS 13.0, *) {
                    self.dismiss(animated: true) { [weak self] in
                        // 人脸识别解锁，不匹配正向or逆向密码
                        self?.dismissCallback?(.biometry)
                    }
                } else {
                    self.dismissCallback?(.biometry)
                }
            } else {
                let type = self.appLockSettingService?
                    .biometryAuth.deviceBiometryType == .faceID ? "face_id" : "touch_id"
                SCMonitor.info(business: .app_lock, eventName: "verify_completed", category: ["result": false, "action": type])
                // 如果有相关的biometry状态问题
                if self.appLockSettingService?.biometryAuth.biometryFailureType != nil {
                    let failureType = self.appLockSettingService?.biometryAuth.biometryFailureType
                    self.appLockSettingService?.biometryAuth
                        .showAlertTipsWhenEvaluateFail(from: self,
                                                       biometryFailureType: failureType,
                                                       at: .lockScreen)
                }
            }
            self.appLockSettingService?.blurService.isRequestBiometric = false
        }
    }

    private func shakeInfoLabel() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        animation.repeatCount = 2
        animation.duration = 0.05
        animation.autoreverses = true
        animation.values = [10, -10]
        infoLabel.layer.add(animation, forKey: "shake")
    }
}
