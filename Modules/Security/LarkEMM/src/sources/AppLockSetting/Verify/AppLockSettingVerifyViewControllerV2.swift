//
//  AppLockSettingVerifyViewControllerV2.swift
//  LarkEMM
//
//  Created by chenjinglin on 2023/11/3.
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
import UniverseDesignIcon
import ByteWebImage
import LarkBizAvatar
import UniverseDesignFont
import UniverseDesignButton

extension AppLockSettingV2 {
    final class AppLockSettingVerifyViewController: BaseUIViewController, UserResolverWrapper, UIScrollViewDelegate {
        private var viewModel: AppLockSettingVerifyViewModel
        // isReversedPin：true表示是逆向密码，false表示正向密码，nil表示不是通过输入密码解锁的（生物识别）
        private var dismissCallback: ((_ pinType: AppLockSettingPinType) -> Void)?
        private var disposeBag = DisposeBag()
        
        @ScopedProvider private var appLockSettingService: AppLockSettingService?
        @ScopedProvider private var userService: PassportUserService?
        @Provider private var passportService: PassportService // Global
        
        let userResolver: UserResolver
        
        init(resolver: UserResolver,
             viewModel: AppLockSettingVerifyViewModel,
             dismissCallback: ((_ pinType: AppLockSettingPinType) -> Void)? = nil) {
            self.userResolver = resolver
            self.viewModel = viewModel
            self.dismissCallback = dismissCallback
            super.init(nibName: nil, bundle: nil)
            modalPresentationStyle = .fullScreen
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        // MARK: LifeCycle
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
            
            setUp()
            bindViewModel()
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
        
        override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
            super.viewWillTransition(to: size, with: coordinator)
            remakeSubviewConstraint(to: size)
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
                if !self.numberPadView.handlePressCancelled(key: key) {
                    super.pressesCancelled(presses, with: event)
                }
            } else {
                // 低版本系统不响应
                super.pressesCancelled(presses, with: event)
            }
        }
        
        // MARK: Internal
        func startVerify() {
            guard let isActive = appLockSettingService?.configInfo.isActive,
                  isActive else { return }
            
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
                startBiometricVerify()
            }
        }
        
        // MARK: Lazy Init
        private lazy var scrollView: UIScrollView = {
            let scrollView = UIScrollView()
            scrollView.delegate = self
            scrollView.showsVerticalScrollIndicator = false
            return scrollView
        }()
        
        private lazy var containerView = UIView()
        
        private lazy var profileView = AppLockSettingVerifyProfileView()
        
        private lazy var inputBoxView = AppLockSettingPINCodeVerifyInputBoxView()
        
        private lazy var numberPadView: AppLockSettingSquareNumberPadView = {
            let padView = AppLockSettingSquareNumberPadView()
            padView.action = { [weak self] (text) in
                guard let `self` = self else { return }
                self.handleNumberPadInput(text: text)
            }
            return padView
        }()
        
        private func isForwardVerified() -> Bool {
            let verifyResult = self.appLockSettingService?.configInfo.comparePinCode(pinCode: self.viewModel.tmpPINCode) ?? false
            if verifyResult {
                // 验证成功
                SCMonitor.info(business: .app_lock, eventName: "verify_completed", category: ["result": true, "action": "pin_code"])
            }
            return verifyResult
        }
        
        private func isBackwardVerified() -> Bool {
            // 如果开了隐私模式才响应逆向密码
            guard self.viewModel.privacyModeEnable() else { return false }
            let verifyResult = self.appLockSettingService?.configInfo.comparePinCode(pinCode: String(self.viewModel.tmpPINCode.reversed())) ?? false
            if verifyResult {
                // 验证成功
                SCMonitor.info(business: .app_lock, eventName: "enter_lean_mode")
            }
            return verifyResult
        }
        
        private func pincodeVerifySuccess(pinType: AppLockSettingPinType) {
            self.appLockSettingService?.configInfo.renewUsePinCodeTimeStamp()
            self.viewModel.curEntryErrCount = 0 // 重置本地记录错误次数
            if #available(iOS 13.0, *) {
                self.dismiss(animated: true) { [weak self] in
                    self?.dismissCallback?(pinType)
                }
            } else {
                self.dismissCallback?(pinType)
            }
        }
        
        private func pincodeVerifyFail() {
            self.viewModel.curEntryErrCount += 1
            self.viewModel.tmpPINCode = ""
            self.inputBoxView.focusIndex = 0
            SCMonitor.info(business: .app_lock, eventName: "current_entry_count", metric: ["count": self.viewModel.curEntryErrCount])
            
            if self.viewModel.curEntryErrCount < self.viewModel.maxEntryCount {
                let count = self.viewModel.maxEntryCount - self.viewModel.curEntryErrCount
                self.profileView.updateTextAndShakeLabel(text: BundleI18n.AppLock.Lark_Screen_IncorrectCodeRetryLogInAgain(count))
            } else {
                self.appLockSettingService?.configInfo.isPINExceedLimit = true
                self.showPINExceedLimitTips()
            }
        }
        
        private lazy var assistantInfoView: AppLockSettingVerifyAssistantInfoView = {
            let privacyModeEnable = self.viewModel.privacyModeEnable()
            let deviceBiometryType = appLockSettingService?.biometryAuth.deviceBiometryType ?? .none
            let isBiometryEnable = appLockSettingService?.configInfo.isBiometryEnable ?? false
            let isBiometryShouldHidden = appLockSettingService?.biometryAuth.isBiometryButtonHidden() ?? false
            let forgetPINCodeButtonAction: ((UDButton) -> Void)? = { [weak self] _ in self?.showForgetPINCodeDialog() }
            let biometricButtonAction: ((UDButton) -> Void)? = { [weak self] _ in self?.startBiometricVerify() }
            let viewModel = AppLockSettingVerifyAssistantInfoViewModel(privacyModeEnable: privacyModeEnable,
                                                                       deviceBiometryType: deviceBiometryType,
                                                                       isBiometryEnable: isBiometryEnable,
                                                                       isBiometryShouldHidden: isBiometryShouldHidden,
                                                                       forgetPINCodeButtonAction: forgetPINCodeButtonAction,
                                                                       biometricButtonAction: biometricButtonAction)
            return AppLockSettingVerifyAssistantInfoView(viewModel: viewModel)
        }()
        
        // MARK: Layout
        private func setUp() {
            let bgView = AppLockBackgroundView(frame: view.bounds)
            view.addSubview(bgView)
            view.addSubview(scrollView)
            scrollView.addSubview(containerView)
            containerView.addSubview(profileView)
            containerView.addSubview(inputBoxView)
            containerView.addSubview(numberPadView)
            containerView.addSubview(assistantInfoView)
            
            bgView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            
            scrollView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            
            remakeSubviewConstraint(to: view.frame.size)
        }
        
        private func remakeSubviewConstraint(to size: CGSize) {
            let width = size.width
            let height = size.height
            // 水平、垂直方向重新布局
            scrollView.isScrollEnabled = height < AppLockSettingVerifyConstKey.safeBaseHeight
            
            containerView.snp.remakeConstraints { make in
                make.top.equalToSuperview().inset(LayoutConfig.safeAreaInsets.top)
                make.bottom.equalToSuperview().inset(LayoutConfig.safeAreaInsets.bottom)
                make.centerX.equalToSuperview()
                make.width.equalTo(min(width, AppLockSettingVerifyConstKey.padDisplayMaxContainerWidth))
            }
            // 垂直方向重新布局
            let spaceSizes = AppLockSettingSpacesSizeCalculator.calculateSpaceSizes(currentHeight: height)
            SCLogger.info("app lock settings get sorted size: \(spaceSizes), current height: \(height)")
            profileView.snp.remakeConstraints {
                let topOffset = spaceSizes.safelyAccessElement(at: AppLockSettingVerifyConstKey.profileViewTopOffsetSizeIndex) ?? 20
                $0.top.equalToSuperview().offset(topOffset)
                $0.left.right.equalToSuperview().inset(16)
                $0.height.equalTo(192)
            }
            inputBoxView.snp.remakeConstraints {
                $0.top.equalTo(profileView.snp.bottom).offset(20)
                $0.left.right.equalToSuperview().inset(14)
                $0.height.equalTo(50)
            }
            numberPadView.snp.remakeConstraints {
                let topOffset = spaceSizes.safelyAccessElement(at: AppLockSettingVerifyConstKey.padViewTopOffsetSizeIndex) ?? 20
                $0.top.equalTo(inputBoxView.snp.bottom).offset(topOffset)
                $0.left.right.equalToSuperview().inset(16)
                $0.height.equalTo(210)
            }
            assistantInfoView.snp.remakeConstraints {
                let topOffset = spaceSizes.safelyAccessElement(at: AppLockSettingVerifyConstKey.assistantInfoViewTopOffsetSizeIndex) ?? 20
                let bottomOffset = spaceSizes.safelyAccessElement(at: AppLockSettingVerifyConstKey.assistantInfoViewBottomOffsetSizeIndex) ?? 20
                $0.top.equalTo(numberPadView.snp.bottom).offset(topOffset)
                $0.bottom.equalToSuperview().offset(-bottomOffset)
                $0.left.right.equalToSuperview().inset(20)
                $0.height.equalTo(22)
            }
        }
        
        private func bindViewModel() {
            profileView.updateUIs(avatarKey: userService?.user.avatarKey ?? "",
                                  userName: userService?.user.localizedName ?? "",
                                  userID: userService?.user.userID ?? "",
                                  info: BundleI18n.AppLock.Lark_Lock_Toast_EnterPassword)
        }
        
        // MARK: Private
        private func handleNumberPadInput(text: String?) {
            let isPINExceedLimit = appLockSettingService?.configInfo.isPINExceedLimit ?? false
            if isPINExceedLimit {
                showPINExceedLimitTips()
                return
            }
            
            if let t = text {
                inputBoxView.focusIndex += 1
                viewModel.tmpPINCode += t
            } else {
                inputBoxView.focusIndex -= 1
                if inputBoxView.focusIndex < 0 {
                    inputBoxView.focusIndex = 0
                }
                if !viewModel.tmpPINCode.isEmpty {
                    viewModel.tmpPINCode.removeLast()
                }
            }
            
            if viewModel.tmpPINCode.count == 4 {
                SCLogger.info("app lock setting start pincode verify")
                if isForwardVerified() {
                    pincodeVerifySuccess(pinType: .forward)
                    SCLogger.info("app lock setting pincode forward verify success")
                    return
                }
                if isBackwardVerified() {
                    pincodeVerifySuccess(pinType: .backward)
                    SCLogger.info("app lock setting pincode backward verify success")
                    return
                }
                pincodeVerifyFail()
                SCLogger.info("app lock setting pincode backward verify fail, current fail count: \(self.viewModel.curEntryErrCount)")
            }
        }
        
        private func showForgetPINCodeDialog() {
            SCMonitor.info(business: .app_lock, eventName: "forget_pincode")
            
            let alertController = LarkAlertController()
            alertController.setTitle(text: BundleI18n.AppLock.Lark_LockScreen_DialogueTitle_ForgotLockScreenPassword, font: UIFont.systemFont(ofSize: 17))
            let tenantName = appLockSettingService?.formatTenantNameDesc ?? ""
            alertController.setContent(text: BundleI18n.AppLock.Lark_LockScreen_DialogueDesc_ReloginToDisableLockScreenPassword(tenantName), font: UIFont.systemFont(ofSize: 16))
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
        
        private func startBiometricVerify() {
            SCMonitor.info(business: .app_lock, eventName: "biometric_action")
            let shouldUsePinCode = appLockSettingService?.configInfo.shouldUsePinCode() ?? false
            if shouldUsePinCode {
                self.profileView.updateTextAndShakeLabel(text: BundleI18n.PrivacyMode.Lark_Core_PrivacyProtectionMode_EnterDigitPasscodeToUnlock_Error)
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
            alertController.setContent(text: BundleI18n.AppLock.Lark_LockScreen_WarningDialogue_TooManyFailedAttemptsRelogin, font: UIFont.systemFont(ofSize: 16))
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
                SCMonitor.error(business: .app_lock, eventName: "trigger_logout", extra: category)
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
    }
}

extension AppLockSettingV2.AppLockSettingVerifyViewController: AppLockSettingVerifyViewControllerProtocol {}

fileprivate extension Array where Element == CGFloat {
    func safelyAccessElement(at index: Int) -> Element? {
        guard index >= 0 && index < count else {
            return nil
        }
        return self[index]
    }
}
