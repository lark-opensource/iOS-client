//
//  V4LoginVerifyViewController.swift
//  LarkAccount
//
//  Created by au on 2021/6/3.
//

import Foundation
import RxSwift
import Homeric
import EENavigator
import UniverseDesignToast

class V4LoginVerifyViewController: BaseViewController {
    
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
    
    lazy var verifySpareCodeControl: V3VerifyCodeControl = {
        return createVerifyControl(
            verifyCodeState: vm.verifyState.verifySpareCodeState,
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
    
    //验证短信上行的视图
    lazy var verifyMoView: VerifyMoBoxView = {
        return createVerifyMoItemView(
            verifyMoState: vm.verifyState.verifyMoState,
            verifyInfo: vm.verifyInfo
        )
    }()

    //Fido2验证视图
    private lazy var verifyFidoView: UIView = {
        return createFidoVerifyView(
            verifyFidoState: vm.verifyState.verifyFidoState
        )
    }()
    
    private lazy var codeVierfyTipLabel: LinkClickableLabel = {
        let lbl = LinkClickableLabel.default(with: self)
        lbl.textContainerInset = .zero
        lbl.textContainer.lineFragmentPadding = 0
        return lbl
    }()
    
    private lazy var passwordVierfyTipLabel: LinkClickableLabel = {
        let lbl = LinkClickableLabel.default(with: self)
        lbl.textContainerInset = .zero
        lbl.textContainer.lineFragmentPadding = 0
        return lbl
    }()
    
    private lazy var recoverAccountLabel: LinkClickableLabel = {
        let lbl = LinkClickableLabel.default(with: self)
        lbl.textContainerInset = .zero
        lbl.textContainer.lineFragmentPadding = 0
        return lbl
    }()
    
    private lazy var skipToMessageButton: NextButton = {
        let button = NextButton(title: "", style: .roundedRectBlue)
        return button
    }()

    private lazy var verifyFidoButton: NextButton = {
        let button = NextButton(title: "")
        return button
    }()

    let vm: V4LoginVerifyViewModel

    init(vm: V4LoginVerifyViewModel) {
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
//            vm.postToMagicLink()
//                .subscribe(onError: { [weak self](error) in
//                    self?.handle(error)
//                }).disposed(by: disposeBag)
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

    override func clickBackOrClose(isBack: Bool) {
        vm.monitorBackOrClose()
        //创建企业输入验证码后进入切换流程并打开了输入密码页面：https://bits.bytedance.net/meego/larksuite/issue/detail/2768937#detail
        if vm.backToFeed,
           let tabVC = Navigator.shared.tabProvider?().tabbarController, // user:checked (navigator)
           let presentedVC = tabVC.presentedViewController {
            tabVC.navigationController?.popToRootViewController(animated: false)
            presentedVC.dismiss(animated: true, completion: nil)
        } else {
            super.clickBackOrClose(isBack: isBack)
        }
    }
}

// MARK: - lifecycle
extension V4LoginVerifyViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        vm.updateRecordVerifyType()
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
        setupVerifyCodeView(
            verifyCodeControl: verifySpareCodeControl,
            tipLabel: codeVierfyTipLabel,
            recoverAccountLabel: recoverAccountLabel
        )
        setupVerifyMoView(
            verifyMoView: verifyMoView,
            skipToMessageButton: skipToMessageButton
        )
        setupVerifyFidoView(
            verifyFidoView: verifyFidoView,
            verifyButton: verifyFidoButton
        )
        updateView(animate: true, beginEdit: false)
        setupBindPwd()
        setupBindVerifyCode(
            verifyCodeState: vm.verifyState.verifyCodeState,
            verifyControl: verifyCodeControl
        )
        setupBindMessageView(
            pageInfo: vm.verifyInfo.verifyMo,
            skipToMessageButton: skipToMessageButton,
            openMessageFunc: openMessagePage
        )
        setupBindCopyButton(
            pageInfo: self.vm.verifyInfo.verifyMo,
            verifyBoxView: self.verifyMoView
        )
        setupFidoVerifyButton(
            pageInfo: self.vm.verifyInfo.verifyFido,
            usePackageDomain: self.vm.verifyInfo.usePackageDomain,
            verifyFidoButton: self.verifyFidoButton,
            context: self.vm.context
        )
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        beginEdit()
        if let pageName = pageName() {
            SuiteLoginTracker.track(pageName, params: [TrackConst.path: vm.trackPath])
        }
        let isPwdEnable = vm.needSwitchBtn ? "true" : "false"
        let verifyType: String
        let flowType: String?
        switch vm.verifyType {
        case .code:
            verifyType = "verify_code"
            flowType = vm.verifyInfo.verifyCode?.flowType
        case .forgetVerifyCode:
            verifyType = "verify_forget_code"
            flowType = vm.verifyInfo.forgetVerifyCode?.flowType
        case .spareCode:
            verifyType = "verify_spare"
            flowType = vm.verifyInfo.verifyCodeSpare?.flowType
        case .otp:
            verifyType = "verify_otp"
            flowType = vm.verifyInfo.verifyOtp?.flowType
        case .mo:
            verifyType = "verify_mo"
            flowType = vm.verifyInfo.verifyMo?.flowType
        case .pwd:
            verifyType = "verify_pwd"
            flowType = vm.verifyInfo.verifyPwd?.flowType
        case .fido:
            verifyType = "verify_fido"
            flowType = vm.verifyInfo.verifyFido?.flowType

        }
        
        let params = SuiteLoginTracker.makeCommonViewParams(flowType: flowType ?? "", data: ["is_pwd_enable": isPwdEnable,
                                                                                             "verify_type": verifyType,
                                                                                             "enable_client_login_method_memory": vm.enableClientLoginMethodMemory,
                                                                                             "last_login_type": vm.verifyState.recordVerifyType?.rawValue])
        switch self.vm.verifyType {
        case .pwd:
            SuiteLoginTracker.track(Homeric.PASSPORT_PWD_VERIFY_VIEW, params: params)
        case .code:
            SuiteLoginTracker.track(Homeric.PASSPORT_VERIFY_CODE_VIEW, params: params)
        case .mo:
            SuiteLoginTracker.track(Homeric.PASSPORT_INDENTITY_VERIFY_PHONE_MSG_SEND_VIEW, params: params)
        case .fido:
            SuiteLoginTracker.track(Homeric.PASSPORT_FIDO_VERIFY_VIEW, params: params)
        default:
            break
        }

        logger.info("n_page_verify_code_start", method: .local)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // 当用户在验证安全密码进行重置时，如果返回上一页需要取消安全密码验证，并返回给 JSAPI 调用方
        // 因为 navigationController 可能支持右滑返回，所以取消逻辑放在这里，而不能放在关闭按钮的回调中
        // needSkipWhilePopStub 为 true 表示验证已经进入下一步，就不需要取消验证
        if !vm.needSkipWhilePopStub {
            vm.cancelVerify()
        }
    }
}

extension V4LoginVerifyViewController {
    @objc
    override func handleClickLink(_ URL: URL, textView: UITextView) {
        switch URL {
        case Link.recoverAccountCarrierURL, Link.resetPwdURL:
            showLoading()
            vm.retrieveAction()
                .subscribe(onNext: { [weak self] _ in
                    self?.stopLoading()
                }, onError: { [weak self](error) in
                    self?.handle(error)
                }).disposed(by: disposeBag)
        default:
            super.handleClickLink(URL, textView: textView)
        }
    }

    override func handle(_ error: Error) {
        /// 解决在密码或验证码输入错误时 toast 会从左上角飘进来的问题
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.errorHandler.handle(error)
        }
        stopLoading()
    }

    func openMessagePage(url: URL?) {

        if let url = url, UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
            SuiteLoginTracker.track(Homeric.PASSPORT_INDENTITY_VERIFY_PHONE_MSG_SEND_CLICK, params: [
                "flow_type": self.vm.verifyInfo.verifyMo?.flowType,
                "target": "none",
                "click": "open_msg_app"
            ])
        } else {
            logger.info("n_page_verify_mo_skipToMessager_fail")
            UDToast.showWarning(with: I18N.Lark_Passport_SendTextToVerify_ManualCopyPaste_Toast, on: self.view)
        }

    }

}

extension V4LoginVerifyViewController: VerifyViewControllerProtocol {
    enum VerifyViewType {
        case pwd
        case code
        case otp
        case spareCode
        case mo
        case fido
    }

    func updateVerifyView() {
        let verifyType = vm.verifyType
        self.logger.info("switch verify method verifyType: \(verifyType)", method: .local)
        let verifyViewType: VerifyViewType
        switch verifyType {
        case .pwd:
            verifyViewType = .pwd
            self.logger.info("n_page_verify_pwd_start")
        case .code:
            verifyViewType = .code
        case .forgetVerifyCode:
            verifyViewType = .code
            self.logger.info("n_page_verify_pwd_reset")
        case .otp:
            verifyViewType = .otp
        case .spareCode:
            verifyViewType = .spareCode
        case .mo:
            verifyViewType = .mo
            self.logger.info("n_page_verify_mo_start")
        case .fido:
            verifyViewType = .fido
            self.logger.info("n_page_verify_fido_start")
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
        
        updateVerifyCodeView(
            show: verifyViewType == .spareCode,
            verifyControl: verifySpareCodeControl,
            tipLabel: codeVierfyTipLabel,
            recoverAccountLabel: recoverAccountLabel,
            pageInfo: vm.verifyState.pageInfo,
            verifyCodeState: vm.verifyState.verifySpareCodeState
        )
        
        updateVerifyMoView(
            show: verifyViewType == .mo,
            verifyMoView: verifyMoView,
            skipToMessageButton: skipToMessageButton,
            pageInfo: vm.verifyInfo.verifyMo,
            verifyMoState: vm.verifyState.verifyMoState
        )

        updateVerifyFidoView(
            show: verifyViewType == .fido,
            verifyFidoView: verifyFidoView,
            verifyButton: verifyFidoButton,
            pageInfo: vm.verifyState.pageInfo,
            verifyFidoState: vm.verifyState.verifyFidoState
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
        if let _ = vm.verifyState.pageInfo?.retrieveButton, PassportSwitch.shared.value(.recoverAccount) {
            showRecoverAccount = true
        }
        
        if verifyViewType == .pwd{
            recoverAccountLabel.alpha = 0;
        }else{
            recoverAccountLabel.alpha = showRecoverAccount ? 1: 0
        }
        
        if showRecoverAccount {
            switch verifyType {
            case .code:
                SuiteLoginTracker.track(Homeric.LOGIN_ACCOUNT_RECOVERY_ENTRY_VIEW)
            case .forgetVerifyCode:
                SuiteLoginTracker.track(Homeric.PASSWORD_RESET_ACCOUNT_RECOVERY_ENTRY_VIEW)
            case .otp, .pwd,.spareCode, .mo, .fido:
                break
            }
        }
        recoverAccountLabel.isHidden = !showRecoverAccount

        if needSwitchButton(), let control = currentVerifyControl {
            switchButton.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(control.needCountDown ? 0 : CL.itemSpace)
                make.left.equalTo(moveBoddyView).offset(CL.itemSpace)
                make.bottom.equalToSuperview()
            }
        }
    }

    var currentVC: BaseViewController { self }

    var verifyState: VerifyStateProtocol { vm }

    var verifyAPI: VerifyProtocol { vm }

    var webAuthNAPI: WebauthNServiceProtocol { vm }

    var currentVerifyControl: V3VerifyCodeControl? {
        switch vm.verifyType {
        case .pwd, .mo, .fido:
            return nil
        case .code, .forgetVerifyCode:
            return verifyCodeControl
        case .otp:
            return verifyOTPCodeControl
        case .spareCode:
            return verifySpareCodeControl
        }
    }

    var currentPwdTextField: ALPasswordTextField? {
        switch vm.verifyType {
        case .pwd:
            return passwordField
        case .code, .forgetVerifyCode, .otp, .spareCode, .mo, .fido:
            return nil
        }
    }
    

}
