//
//  AppLockSettingPINViewController.swift
//  LarkMine
//
//  Created by thinkerlj on 2021/12/22.
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
import LarkSecurityComplianceInfra
import LarkSecurityComplianceInterface

final class AppLockSettingPINCodeViewController: BaseUIViewController, UITextFieldDelegate, UserResolverWrapper {

    private var viewModel: AppLockSettingPINCodeViewModel
    var userResolver: UserResolver
    @ScopedProvider private var appLockSettingService: AppLockSettingService?
    private var leanModeService: LeanModeSecurityService?

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewModel.completion?(viewModel.mode, viewModel.performStatus)
    }

    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.text = viewModel.title
        titleLabel.numberOfLines = 0
        titleLabel.font = UIFont.systemFont(ofSize: 26)
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.textAlignment = .left
        return titleLabel
    }()

    private lazy var infoLabel: UILabel = {
        let infoLabel = UILabel()
        infoLabel.text = viewModel.info
        infoLabel.numberOfLines = 0
        infoLabel.textAlignment = .left
        infoLabel.textColor = UIColor.ud.textCaption
        infoLabel.font = UIFont.systemFont(ofSize: 14)
        return infoLabel
    }()

    private lazy var showPINCodeButton: UIButton = {
        let showPINCodeButton = UIButton(type: .custom)
        showPINCodeButton.setImage(BundleResources.LarkEMM.hide_pin_code_icon, for: .normal)
        showPINCodeButton.setImage(BundleResources.LarkEMM.show_pin_code_icon, for: .selected)
        showPINCodeButton.addTarget(self, action: #selector(showPINCode), for: .touchUpInside)
        showPINCodeButton.isSelected = !viewModel.isSecurePINCodeEntry
        return showPINCodeButton
    }()

    private lazy var pinCodeTextField: AppLockSettingPINCodeField = {
        let field = AppLockSettingPINCodeField()
        field.isSecurePINCodeEntry = viewModel.isSecurePINCodeEntry
        field.numberOfDigits = 4
        field.spacing = 12
        field.cornerRadius = 6
        field.backgroundColor = view.backgroundColor
        field.activeBorderColor = UIColor.ud.rgb("#3370FF")
        field.filledBorderColor = UIColor.ud.rgb("#BBBFC4")
        field.becomeFirstResponder()
        field.inputCompletion = { [weak self] (pinCode) in
            self?.triggerPINCodeCompletionAction(pinCode: pinCode)
        }
        return field
    }()

    private weak var fromVC: AppLockSettingPINCodeViewController?

    init(resolver: UserResolver, viewModel: AppLockSettingPINCodeViewModel) {
        self.viewModel = viewModel
        self.userResolver = resolver
        self.leanModeService = try? userResolver.resolve(assert: ExternalDependencyService.self).leanModeService
        super.init(nibName: nil, bundle: nil)
        self.updateTitleInfo()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloatBase)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.top.equalTo(32)
        }

        view.addSubview(showPINCodeButton)
        showPINCodeButton.snp.makeConstraints { make in
            make.left.equalTo(titleLabel.snp.right).offset(6)
            make.centerY.equalTo(titleLabel)
            make.height.equalTo(30)
            make.width.equalTo(30)
        }

        view.addSubview(infoLabel)
        infoLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.left.equalTo(titleLabel)
            make.right.equalTo(-16)
        }

        view.addSubview(pinCodeTextField)
        pinCodeTextField.snp.makeConstraints { make in
            make.left.equalTo(titleLabel)
            make.right.equalTo(-16)
            make.top.equalTo(infoLabel.snp.bottom).offset(52)
            make.height.equalTo(50)
        }
    }

    private func updateTitleInfo() {
        viewModel.updateTitleInfo()
        titleLabel.text = viewModel.title
        infoLabel.text = viewModel.info
    }

    private func isPinCodeTooSimple(pinCode: String) -> Bool {
        var simpleCodeSet: Set<String> = ["0123", "1234", "2345", "3456", "4567", "5678", "6789"]
        for index in 0...9 {
            simpleCodeSet.insert(String(repeating: String(index), count: 4))
        }
        return simpleCodeSet.contains(pinCode) || simpleCodeSet.contains(String(pinCode.reversed()))
    }

    // 检查密码是否是回文
    private func isPinCodePalindrome(pinCode: String) -> Bool {
        return pinCode == String(pinCode.reversed())
    }

    private func triggerPINCodeCompletionAction(pinCode: String) {
        viewModel.curEntryCount += 1
        switch viewModel.mode {
        case .entry: // 首次设置
            entry(pinCode: pinCode)
        case .modify: // 修改密码
            modify(pinCode: pinCode)
        case .secondVerify: // 修改密码里的验证密码
            secondVerify(pinCode: pinCode)
        }
    }

    private func entry(pinCode: String) {
        Logger.info("pin_code_modify: type: entry")
        switch viewModel.entryMode {
        case .input:
            // 不允许使用简单密码
            if isPinCodeTooSimple(pinCode: pinCode) {
                pinCodeTextField.reset()
                if let window = view?.window {
                    UDToast.showTipsOnScreenCenter(with: BundleI18n.AppLock.Lark_Screen_LockScreenPassportToast, on: window)
                }
                break
            }

            // 精简模式用户，不允许使用回文密码
            let canUseLeanMode = leanModeService?.canUseLeanMode() ?? false
            if  canUseLeanMode, isPinCodePalindrome(pinCode: pinCode) {
                pinCodeTextField.reset()
                if let window = view?.window {
                    UDToast.showTipsOnScreenCenter(with: BundleI18n.PrivacyMode.Lark_Core_PasscodeNotMeetRequirement_Error, on: window)
                }
                break
            }

            viewModel.tmpPINCode = pinCode
            pinCodeTextField.reset()
            viewModel.entryMode = .verify
            updateTitleInfo()
        case .verify:
            if viewModel.tmpPINCode == pinCode {
                appLockSettingService?.configInfo.updatePinCodeAndPinCodeVersion(pinCode: pinCode)
                appLockSettingService?.configInfo.renewUsePinCodeTimeStamp()
                SCMonitor.info(business: .app_lock, eventName: "pin_code_set", category: ["action": "create"])
                self.dismiss(mode: .entry, status: true)
            } else {
                if let window = view?.window {
                    UDToast.showTipsOnScreenCenter(with: BundleI18n.AppLock.Lark_Screen_InconsistentReenter, on: window)
                }
                pinCodeTextField.reset()
            }
        }
    }

    private func modify(pinCode: String) {
        Logger.info("pin_code_modify: type: modify")
        switch viewModel.modifyMode {
        case .oldCodeVerify:
            // 如果Service不允许修改，则提示一分钟后再尝试
            let isModifyLimitValid = appLockSettingService?.configInfo.isModifyLimitValid() ?? false
            if isModifyLimitValid {
                if let window = view?.window {
                    UDToast.showTipsOnScreenCenter(with: BundleI18n.AppLock.Lark_Screen_IncorrectLimitTryAgain, on: window)
                }
                viewModel.isModifyLimitValid = true
                pinCodeTextField.reset()
                break
            }
            // 如果 Service允许修改 && viewModel不允许修改 说明当前信息需要更新，将修改次数重置
            if !isModifyLimitValid && viewModel.isModifyLimitValid {
                viewModel.curEntryCount = 0
                viewModel.isModifyLimitValid = false
            }
            let isRightPinCode = appLockSettingService?.configInfo.comparePinCode(pinCode: pinCode) ?? false
            if viewModel.curEntryCount > viewModel.maxEntryCount {
                SCMonitor.info(business: .app_lock, eventName: "pin_code_modify", metric: ["old_verify_time": viewModel.curEntryCount])
                if let window = view?.window {
                    UDToast.showTipsOnScreenCenter(with: BundleI18n.AppLock.Lark_Screen_IncorrectLimitTryAgain, on: window)
                    // 防刷:一分钟限制
                    appLockSettingService?.configInfo.modifyLimitTimeStamp = Date(timeIntervalSinceNow: TimeInterval(60)).timeIntervalSince1970
                }
                viewModel.isModifyLimitValid = true
                pinCodeTextField.reset()
            } else if isRightPinCode {
                viewModel.modifyMode = .firstEntry
                viewModel.curEntryCount = 0
                pinCodeTextField.reset()
                updateTitleInfo()
                break
            } else {
                if let window = view?.window {
                    UDToast.showTipsOnScreenCenter(with: BundleI18n.AppLock.Lark_Screen_WrongDigitalCodeReenter, on: window)
                }
                pinCodeTextField.reset()
            }
        case .firstEntry:
            // 不允许使用简单密码
            if isPinCodeTooSimple(pinCode: pinCode) {
                pinCodeTextField.reset()
                if let window = view?.window {
                    UDToast.showTipsOnScreenCenter(with: BundleI18n.AppLock.Lark_Screen_LockScreenPassportToast, on: window)
                }
                break
            }

            // 精简模式用户，不允许使用回文密码
            let canUseLeanMode = leanModeService?.canUseLeanMode() ?? false
            if canUseLeanMode, isPinCodePalindrome(pinCode: pinCode) {
                pinCodeTextField.reset()
                if let window = view?.window {
                    UDToast.showTipsOnScreenCenter(with: BundleI18n.PrivacyMode.Lark_Core_PasscodeNotMeetRequirement_Error, on: window)
                }
                break
            }

            viewModel.tmpPINCode = pinCode
            pinCodeTextField.reset()
            updateTitleInfo()
            pinCodeTextField.resignFirstResponder()
            let verifyViewModel = AppLockSettingPINCodeViewModel(resolver: userResolver, mode: .secondVerify, completion: nil)
            verifyViewModel.tmpPINCode = pinCode
            verifyViewModel.isSecurePINCodeEntry = self.pinCodeTextField.isSecurePINCodeEntry
            let vc = AppLockSettingPINCodeViewController(resolver: userResolver, viewModel: verifyViewModel)
            vc.fromVC = self
            self.userResolver.navigator.push(vc, from: self)
        }
    }

    private func secondVerify(pinCode: String) {
        Logger.info("pin_code_modify: type: modify-secondVerify")
        if viewModel.tmpPINCode == pinCode {
            appLockSettingService?.configInfo.updatePinCodeAndPinCodeVersion(pinCode: pinCode)
            fromVC?.viewModel.performStatus = true
            // 提前将fromVC pop，防止在退出的时候再次出现
            self.appLockSettingService?.configInfo.renewUsePinCodeTimeStamp()
            fromVC?.sendInfoAndPopSelf()
            self.dismiss(mode: .secondVerify, status: true)
            SCMonitor.info(business: .app_lock, eventName: "pin_code_set", category: ["action": "update"])
        } else {
            if let window = view?.window {
                UDToast.showTipsOnScreenCenter(with: BundleI18n.AppLock.Lark_Screen_InconsistentReenter, on: window)
            }
            pinCodeTextField.reset()
        }
    }

    // 返回设置完成信息，同时popself
    private func sendInfoAndPopSelf() {
        dismiss(mode: viewModel.mode, status: true)
        viewModel.completion?(viewModel.mode, viewModel.performStatus)
    }

    private func dismiss(mode: AppLockSettingPINCodeMode, status: Bool) {
        viewModel.performStatus = status
        self.popSelf()
    }

    @objc
    private func dismissAciton() {
        self.dismiss(mode: viewModel.mode, status: false)
    }

    @objc
    private func showPINCode(sender: UIButton) {
        sender.isSelected = !sender.isSelected
        pinCodeTextField.isSecurePINCodeEntry = !sender.isSelected
    }
}
