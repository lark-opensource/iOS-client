//
//  LoginVerifyViewController.swift
//  SuiteLogin
//
//  Created by Miaoqi Wang on 2019/9/18.
//

import Foundation
import RxSwift
import Homeric

class V3LoginVerifyViewController: BaseViewController {

    lazy var verifyCodeControl: V3VerifyCodeControl = {
        return createVerifyControl(
            verifyCodeState: vm.verifyState.verifyCodeState,
            tipLabel: codeVierfyTipLabel,
            source: .login
        )
    }()

    lazy var verifyOTPCodeControl: V3VerifyCodeControl = {
        return createVerifyControl(
            needCountDown: false,
            verifyCodeState: vm.verifyState.verifyOtpState,
            tipLabel: codeVierfyTipLabel,
            source: .login
        )
    }()

    lazy var passwordField: ALPasswordTextField = {
        return createPwdTextField(
            verifyPwdState: vm.verifyState.verifyPwdState,
            placeholder: I18N.Lark_Login_V3_InputPasswordPlaceholder
        )
    }()

    private lazy var codeVierfyTipLabel: LinkClickableLabel = {
        return LinkClickableLabel.default(with: self)
    }()

    private lazy var passwordVierfyTipLabel: LinkClickableLabel = {
        return LinkClickableLabel.default(with: self)
    }()

    private lazy var recoverAccountLabel: LinkClickableLabel = {
        return LinkClickableLabel.default(with: self)
    }()

    let vm: V3LoginVerifyViewModel

    init(vm: V3LoginVerifyViewModel) {
        self.vm = vm
        super.init(viewModel: vm)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func needSwitchButton() -> Bool {
        return vm.needSwitchBtn
    }

    override var needSkipWhilePop: Bool {
        return vm.needSkipWhilePop
    }

    override func switchAction(sender: UIButton) {
        vm.trackSwitchLoginWay()
        if vm.verifyInfo.enableChange.contains(.magicLink) {
            vm.postToMagicLink()
                .subscribe(onError: { [weak self](error) in
                    self?.handle(error)
                }).disposed(by: disposeBag)
        } else {
            vm.switchLoginWay()
            updateView()
            if let pageName = pageName() {
                SuiteLoginTracker.track(pageName, params: [TrackConst.path: vm.trackPath])
            }
        }
    }

    override func pageName() -> String? {
        return vm.pageName
    }

    //灰度升级的弹窗提示,关闭弹窗的时候,如果是验证码页面需要关闭页面 https://bits.bytedance.net/meego/larksuite/issue/detail/2769497#detail
    override func handle(_ error: Error) {
        super.handle(error)

        guard let eventBusError =  error as? EventBusError, vm.verifyType != .pwd else {
            return
        }

        switch eventBusError {
        case let .internalError(loginError):
            if loginError.errorCode == V3LoginError.errorCodeAccountAppeal {
                if let _ = self.navigationController {
                    clickBackOrClose(isBack: true)
                } else {
                    clickBackOrClose(isBack: false)
                }
            }
        default:break
        }
    }
}

// MARK: - lifecycle
extension V3LoginVerifyViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupPwdView(textField: passwordField, tipLabel: passwordVierfyTipLabel)
        setupVerifyCodeView(
            verifyCodeControl: verifyCodeControl,
            tipLabel: codeVierfyTipLabel,
            recoverAccountLabel: recoverAccountLabel
        )
        setupVerifyCodeView(
            verifyCodeControl: verifyOTPCodeControl,
            tipLabel: codeVierfyTipLabel,
            recoverAccountLabel: recoverAccountLabel
        )
        updateView(animate: false, beginEdit: false)
        setupBindPwd()
        setupBindVerifyCode(verifyCodeState: vm.verifyState.verifyCodeState, verifyControl: verifyCodeControl)

        logger.info("n_page_old_verify_code_start")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        beginEdit()
        if let pageName = pageName() {
            SuiteLoginTracker.track(pageName, params: [TrackConst.path: vm.trackPath])
        }
    }
}

extension V3LoginVerifyViewController {
    @objc
    override func handleClickLink(_ URL: URL, textView: UITextView) {
        switch URL {
        case Link.resetPwdURL:
            SuiteLoginTracker.track(Homeric.LOGIN_CLICK_PASSWORD_RESET)
            showLoading()
            vm.recoverTypeResetPwd()
                .subscribe(onNext: { [weak self] _ in
                    self?.stopLoading()
                }, onError: { [weak self](error) in
                    self?.handle(error)
                }).disposed(by: disposeBag)
        case Link.recoverAccountCarrierURL:

            SuiteLoginTracker.track(Homeric.PASSPORT_VERIFY_CODE_PAGE_CLICK, params: [
                "click": "find_account",
                "target": "none"
            ])

            let verifyType = vm.verifyType
            var recoverAccountSourceType: RecoverAccountSourceType = .unknown
            switch verifyType {
            case .code, .otp, .spareCode:
                recoverAccountSourceType = .login
                SuiteLoginTracker.track(Homeric.LOGIN_ACCOUNT_RECOVERY_ENTRY_CLICK)
            case .forgetVerifyCode:
                recoverAccountSourceType = .forgetVerifyCode
                SuiteLoginTracker.track(Homeric.PASSWORD_RESET_ACCOUNT_RECOVERY_ENTRY_CLICK)
            case .pwd, .mo, .fido:
                break
            }
            showLoading()
            vm.recoverTypeAccountRecover(from: recoverAccountSourceType)
                .subscribe(onNext: { [weak self] _ in
                    self?.stopLoading()
                }, onError: { [weak self](error) in
                    self?.handle(error)
                }).disposed(by: disposeBag)
        default:
            super.handleClickLink(URL, textView: textView)
        }
    }
}

extension V3LoginVerifyViewController: VerifyViewControllerProtocol {
    enum VerifyViewType {
        case pwd
        case code
        case otp
        case mo
        case fido
    }

    func updateVerifyView() {
        let verifyType = vm.verifyType
        self.logger.info("switch verify method verifyType: \(verifyType)")
        let verifyViewType: VerifyViewType
        switch verifyType {
        case .pwd:
            verifyViewType = .pwd
        case .code, .forgetVerifyCode,.spareCode:
            verifyViewType = .code
        case .otp:
            verifyViewType = .otp
        case .mo:
            verifyViewType = .mo
        case .fido:
            verifyViewType = .fido
        }

        updateVerifyCodeView(
            show: verifyViewType == .code,
            verifyControl: verifyCodeControl,
            tipLabel: codeVierfyTipLabel,
            recoverAccountLabel: recoverAccountLabel,
            pageInfo: vm.verifyState.pageInfo,
            verifyCodeState: vm.verifyState.verifyCodeState
        )

        updateVerifyCodeView(
            show: verifyViewType == .otp,
            verifyControl: verifyOTPCodeControl,
            tipLabel: codeVierfyTipLabel,
            recoverAccountLabel: recoverAccountLabel,
            pageInfo: vm.verifyState.pageInfo,
            verifyCodeState: vm.verifyState.verifyOtpState
        )

        updatePasswordView(
            show: verifyViewType == .pwd,
            textField: passwordField,
            tipLabel: passwordVierfyTipLabel,
            pageInfo: vm.verifyState.pageInfo,
            verifyPwdState: vm.verifyState.verifyPwdState
        )

        if verifyType == .code {
            SuiteLoginTracker.track(
                Homeric.PASSPORT_VERIFY_CODE_PAGE_VIEW,
                params: ["verify_type": "message"]
            )
        }

        if verifyType == .otp {
            SuiteLoginTracker.track(
                Homeric.PASSPORT_VERIFY_CODE_PAGE_VIEW,
                params: ["verify_type": "otp_code"]
            )
        }

        var showRecoverAccount = false
        if let pageInfo = vm.verifyState.pageInfo, PassportSwitch.shared.value(.recoverAccount) {
            showRecoverAccount = pageInfo.showRecoverAccount ?? false
        }
        if showRecoverAccount {
            switch verifyType {
            case .code:
                SuiteLoginTracker.track(Homeric.LOGIN_ACCOUNT_RECOVERY_ENTRY_VIEW)
            case .forgetVerifyCode:
                SuiteLoginTracker.track(Homeric.PASSWORD_RESET_ACCOUNT_RECOVERY_ENTRY_VIEW)
            case .otp, .pwd, .spareCode, .mo, .fido:
                break
            }
        }
        recoverAccountLabel.isHidden = !showRecoverAccount
    }

    var currentVC: BaseViewController { self }

    var verifyState: VerifyStateProtocol { vm }

    var verifyAPI: VerifyProtocol { vm }

    var webAuthNAPI: WebauthNServiceProtocol { vm }

    var currentVerifyControl: V3VerifyCodeControl? {
        switch vm.verifyType {
        case .pwd, .mo, .fido:
            return nil
        case .code, .forgetVerifyCode,.spareCode:
            return verifyCodeControl
        case .otp:
            return verifyOTPCodeControl
        }
    }

    var currentPwdTextField: ALPasswordTextField? {
        switch vm.verifyType {
        case .pwd:
            return passwordField
        case .code, .forgetVerifyCode, .otp,.spareCode, .mo, .fido:
            return nil
        }
    }
}
