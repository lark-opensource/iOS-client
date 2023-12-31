//
//  MailClientLoginViewController.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2021/11/25.
//

import Foundation
import UIKit
import SnapKit
import UniverseDesignIcon
import UniverseDesignInput
import UniverseDesignButton
import UniverseDesignNotice
import Reachability
import RxSwift
import RxRelay
import EENavigator
import FigmaKit
import LarkFoundation
import LarkUIKit
import RustPB
import LarkAlertController
import LarkReleaseConfig
import LarkLocalizations
import UniverseDesignColor
import UniverseDesignActionPanel
import UniverseDesignCheckBox

protocol MailClientLoginDelegate: AnyObject {
    func loginSuccess()
}

struct MailImapAccount {
    var mailAddress: String
    var password: String
    var imapAddress: String?
    var imapPort: Int32 = 993
    var smtpAddress: String?
    var smtpPort: Int32 = 465
    var bindType: Email_Client_V1_MailImapUserBindAccountRequest.ImapBindType
}

class MailClientLoginViewController: MailBaseViewController, UDTextFieldDelegate, MailClientAdvanceSettingDelegate {
    
    enum LoginScene {
        case imap
        case eas
        case freeBind
        case freeBindInvaild

        var isFreeBind: Bool {
            switch self {
            case .freeBind, .freeBindInvaild:
                return true
            case .imap, .eas:
                return false
            }
        }
    }

    // 跳转外部浏览器弹窗
    weak var currentGuideVC: MailClientOAuthGuideViewController?
    private var isRequestingPermit = false

    // Data
    weak var delegate: MailClientLoginDelegate?
    private var type: MailTripartiteProvider = .other
    private let disposeBag = DisposeBag()
    var tripartiteAccount: Email_Client_V1_TripartiteAccount?
    var imapAccount: MailImapAccount?
    var dismissCompletion: ((Bool) -> Void)?
    private var loginDisposeBag = DisposeBag()
    var protocolConfig: Email_Client_V1_ProtocolConfig.ProtocolEnum = .imap {
        didSet {
            if oldValue != protocolConfig {
                MailLogger.info("[mail_client_eas] refreshLoginPage oldValue: \(oldValue) protocolConfig: \(protocolConfig)")
                refreshLoginPage()
                helpButton?.isHidden = protocolConfig == .exchange
            }
        }
    }

    private var reachability: Reachability? = Reachability()
    private var connection: Reachability.Connection?
    private var taskID: String = ""
    private var scene: LoginScene
    func easO365() -> Bool {
        return scene == .eas && (type == .o365 || type == .office365 || type == .office365Cn || type == .outlook)
    }
    func easExchange() -> Bool {
        return scene == .eas && (type == .exchange || type == .exchangeOnPrem)
    }
    func easProtoExchange() -> Bool {
        return easExchange() && protocolConfig == .exchange
    }
    func imapExchange() -> Bool {
        return easExchange() && protocolConfig == .imap
    }

    // feishu租户 绑定企业邮箱 office365 支持填写邮件地址获取authURL进行鉴权登录
    func authURLLogin() -> Bool {
        return scene.isFreeBind && type == .office365
    }
    // Const
    private let navHeight: CGFloat = 44
    private var firstLoad: Bool = true

    // UI
    override var navigationBarTintColor: UIColor {
        return UIColor.ud.bgBody
    }
    private lazy var gradientView = LinearGradientView()
    private lazy var iconView = UIImageView()
    private lazy var titleLabel = self.makeTitleLabel()
    private lazy var tipsLabel = self.makeTipsLabel()
    private var contentView = UIScrollView()
    private var helpButton: UIButton?
    private var getPasswordButton: UIButton?

    private lazy var protocolSelection: UDTextField = {
        var config = UDTextFieldUIConfig(isShowBorder: true,
                                         clearButtonMode: .never,
                                         textColor: UIColor.ud.textTitle,
                                         font: UIFont.systemFont(ofSize: 16.0, weight: .regular))
        config.borderColor = UIColor.ud.lineBorderComponent
        let textField = UDTextField(config: config)
        textField.input.text = BundleI18n.MailSDK.Mail_Shared_AddEAS_EAS_DropdownList
        let rightView = UIImageView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        rightView.image = UDIcon.downBoldOutlined.ud.resized(to: CGSize(width: 12, height: 12))
        rightView.tintColor = UIColor.ud.iconN2
        textField.setRightView(rightView)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(protocolSelectionClick))
        tapGesture.numberOfTouchesRequired = 1
        tapGesture.numberOfTapsRequired = 1
        textField.addGestureRecognizer(tapGesture)
        textField.input.tag = 999
        textField.input.isEnabled = false
        textField.delegate = self
        return textField
    }()
    private lazy var emailInput: UDTextField = {
        var config = makeDefaultTipsConfig()
        config.borderColor = UIColor.ud.lineBorderComponent
        let textField = UDTextField(config: config)
        textField.tintColor = UIColor.ud.functionInfoContentDefault
        textField.placeholder = scene.isFreeBind
        ? BundleI18n.MailSDK.Mail_LinkAccount_EmailLogin_EmailAccount_Mobile_Placeholder
        : BundleI18n.MailSDK.Mail_ThirdClient_EnterEmailAddress
        textField.input.returnKeyType = .next
        textField.input.keyboardType = .emailAddress
        textField.input.autocorrectionType = .no
        textField.input.autocapitalizationType = .none
        textField.input.spellCheckingType = .no
        textField.input.addTarget(self, action: #selector(handleEmailChange(sender:)), for: .editingChanged)
        textField.input.addTarget(self, action: #selector(handleEmailBeginEditing(sender:)), for: .editingDidBegin)
        textField.input.addTarget(self, action: #selector(handleEmailEndEditing(sender:)), for: .editingDidEnd)
        textField.delegate = self
        return textField
    }()

    private lazy var passwordInput: UDTextField = {
        var config = makeDefaultTipsConfig()
        config.borderColor = UIColor.ud.lineBorderComponent
        let textField = UDTextField(config: config)
        textField.tintColor = UIColor.ud.functionInfoContentDefault
        let rightView = UIImageView(image: UDIcon.activityColorful.ud.resized(to: CGSize(width: 20, height: 20)))
        rightView.isHidden = true
        textField.setRightView(rightView)
        textField.placeholder = BundleI18n.MailSDK.Mail_ThirdClient_EnterPassword
        textField.input.isSecureTextEntry = true
        textField.input.returnKeyType = .done
        textField.input.keyboardType = .alphabet
        textField.input.autocorrectionType = .no
        textField.input.addTarget(self, action: #selector(handlePasswordChange(sender:)), for: .editingChanged)
        textField.input.addTarget(self, action: #selector(handlePasswordBeginEditing(sender:)), for: .editingDidBegin)
        textField.delegate = self
        return textField
    }()
    private lazy var serverDomainInput: UDTextField = {
        var config = UDTextFieldUIConfig(isShowBorder: true,
                                         clearButtonMode: .whileEditing,
                                         textColor: UIColor.ud.textTitle,
                                         font: UIFont.systemFont(ofSize: 16.0, weight: .regular))
        config.borderColor = UIColor.ud.lineBorderComponent
        let textField = UDTextField(config: config)
        textField.tintColor = UIColor.ud.functionInfoContentDefault
        textField.placeholder = BundleI18n.MailSDK.Mail_Shared_AddEAS_ServerDomain_FieldName
        textField.input.returnKeyType = .next
        textField.input.keyboardType = .emailAddress
        textField.input.autocorrectionType = .no
        textField.input.autocapitalizationType = .none
        textField.input.spellCheckingType = .no
        textField.input.addTarget(self, action: #selector(handleServerDomainChange(sender:)), for: .editingChanged)
        textField.input.addTarget(self, action: #selector(handleServerDomainBeginEditing(sender:)), for: .editingDidBegin)
        textField.delegate = self
        return textField
    }()
    private var editingTextField: UDTextField?
    private var originY: CGFloat = 0

    private var pwdPreview = false
    private lazy var pwdPreviewButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UDIcon.invisibleOutlined.withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = UIColor.ud.iconN2
        button.addTarget(self, action: #selector(pwdPreviewClick), for: .touchUpInside)
        return button
    }()

    private lazy var advancedSettingButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle(BundleI18n.MailSDK.Mail_ThirdClient_AdvancedSettings, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.contentHorizontalAlignment = .left
        button.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        button.setTitleColor(UIColor.ud.textDisabled, for: .disabled)
        button.addTarget(self, action: #selector(advancedSettingButtonClick), for: .touchUpInside)
        return button
    }()
    private lazy var sslCheckBox: UDCheckBox = {
        let v = UDCheckBox(boxType: .multiple, config: UDCheckBoxUIConfig(), tapCallBack: nil)
        v.isUserInteractionEnabled = false
        return v
    }()

    private lazy var loginButton: UDButton = {
        let config = UDButtonUIConifg.makeLoginButtonConfig()
        let loginButton = UDButton()
        loginButton.layer.cornerRadius = 10
        loginButton.layer.masksToBounds = true
        loginButton.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        loginButton.setTitle(BundleI18n.MailSDK.Mail_ThirdClient_Login, for: .normal)
        loginButton.config = config
        loginButton.isEnabled = false
        loginButton.rx.tap.subscribe(onNext: { [weak self] in
            guard let `self` = self else { return }
            self.didClickLoginButton()
        }).disposed(by: disposeBag)
        return loginButton
    }()
    let resignKeyboardBGBtn = UIButton()
    let resignKeyboardBtn = UIButton()
    let resignKeyboardBottomBGBtn = UIButton()
    
    private let accountContext: MailAccountContext

    @objc func protocolSelectionClick() {
        editingTextField?.input.resignFirstResponder()
        detectAddressAndUpdateUIIfNeeded()
        showProtocolConfigActionSheet(protocolConfig)
    }

    @objc func sslClick() {
        guard emailInput.input.isEnabled else { return } // 非disable状态下才响应
        sslCheckBox.isSelected = !sslCheckBox.isSelected
    }

    func showProtocolConfigActionSheet(_ type: Email_Client_V1_ProtocolConfig.ProtocolEnum) {
        let pop = UDActionSheet(config: UDActionSheetUIConfig(isShowTitle: true))
        pop.setTitle(BundleI18n.MailSDK.Mail_Shared_AddEAS_Protocol_SelectTitle)
        let serverTypes: [Email_Client_V1_ProtocolConfig.ProtocolEnum] = [.exchange, .imap]
        for protocolConfig in serverTypes {
            pop.addDefaultItem(text: protocolConfig.title()) { [weak self] in
                guard let `self` = self else { return }
                self.protocolConfig = protocolConfig
                self.protocolSelection.input.text = protocolConfig.title()
            }
        }
        pop.setCancelItem(text: BundleI18n.MailSDK.Mail_Alert_Cancel) {
            MailLogger.info("[mail_client_eas] protocolTypeClick Cancel")
        }
        navigator?.present(pop, from: self)
    }

    @objc
    func handleProtocolConfigBeginEditing(sender: UITextField) -> Bool {
        return false
    }

    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        if textField.tag == 999 {
            return false
        }
        return true
    }

    @objc
    func handleEmailEndEditing(sender: UITextField) {
        detectAddressAndUpdateUIIfNeeded()
    }

    @objc
    func handleEmailBeginEditing(sender: UITextField) -> Bool {
        editingTextField = emailInput
        if !firstLoad {
            resetTips()
        }
        if firstLoad {
            firstLoad = false
        }
        return true
    }

    @objc
    func handlePasswordBeginEditing(sender: UITextField) -> Bool {
        editingTextField = passwordInput
        detectAddressAndUpdateUIIfNeeded()
        return true
    }


    @objc
    func handleServerDomainBeginEditing(sender: UITextField) -> Bool {
        editingTextField = serverDomainInput
        if !firstLoad {
            resetTips()
        }
        detectAddressAndUpdateUIIfNeeded()
        return true
    }

    @objc
    func handleEmailChange(sender: UITextField) {
        let content = sender.text ?? ""
        // emailRegex 正则校验
        if content.isEmpty {
            resetTips()
        }
    }

    @objc
    func handlePasswordChange(sender: UITextField) {
        let content = sender.text ?? ""
    }

    @objc
    func handleServerDomainChange(sender: UITextField) {
        let content = sender.text ?? ""
        // emailRegex 正则校验
        if content.isEmpty {
            resetTips()
        }
    }

    @objc
    func pwdPreviewClick() {
        guard passwordInput.input.isUserInteractionEnabled else { return }
        pwdPreview.toggle()
        let icon = pwdPreview ? UDIcon.visibleOutlined : UDIcon.invisibleOutlined
        pwdPreviewButton.setImage(icon.withRenderingMode(.alwaysTemplate), for: .normal)
        passwordInput.input.isSecureTextEntry = !pwdPreview
    }

    @objc
    func advancedSettingButtonClick() {
        if scene.isFreeBind {
            MailTracker.log(event: "email_other_mail_binding_click", params: ["click": "advanced_setting", "page_type": type.pageType])
        } else {
            MailTracker.log(event: "email_tripartite_service_login_click", params: ["mail_account_type": Store.settingData.getMailAccountType(), "click": "login", "protocol": protocolConfig == .exchange ? "eas" : "imap", "target": "none"])
        }

        let advanceSettingVC = MailClientAdvanceSettingViewController(
            scene: self.scene == .freeBindInvaild ? .reVerfiy : .login,
            accountID: "",
            accountContext: accountContext,
            isFreeBind: accountContext.featureManager.realTimeOpen(.newFreeBindMail, openInMailClient: false),
            type: type
        )
        advanceSettingVC.delegate = self
        advanceSettingVC.type = type
        let address = (emailInput.text ?? "").trimmingCharacters(in: .whitespaces)
        let password = (passwordInput.text ?? "").trimmingCharacters(in: .whitespaces)
        if scene.isFreeBind {
            if imapAccount == nil {
                imapAccount = MailImapAccount(mailAddress: address,
                                              password: password,
                                              bindType: scene == .freeBind ? .firstBind : .reBind)
            } else {
                imapAccount?.mailAddress = address
                imapAccount?.password = password
            }
            advanceSettingVC.imapAccount = imapAccount
        } else {
            advanceSettingVC.tripartiteAccount = MailClientTripartiteProviderHelper
                .makeDefaultAccount(type: type, address: address, password: password)
            if protocolConfig == .imap {
                advanceSettingVC.tripartiteAccount?.receiver.protocol = .imap
            } else if protocolConfig == .exchange {
                advanceSettingVC.tripartiteAccount?.receiver.protocol = .exchange
            }
        }
        let navAdvanSettingVC = LkNavigationController(rootViewController: advanceSettingVC)
        navAdvanSettingVC.modalPresentationStyle = Display.pad ? .formSheet : .fullScreen
        navigator?.present(navAdvanSettingVC, from: self)
    }

    func didClickLoginButton() {
        if scene.isFreeBind {
            MailTracker.log(event: "email_other_mail_binding_click", params: ["click": "login", "page_type": type.pageType])
        } else {
            MailTracker.log(event: "email_tripartite_service_login_click", params: ["mail_account_type": Store.settingData.getMailAccountType(), "click": "login", "protocol": protocolConfig == .exchange ? "eas" : "imap", "target": "none"])
        }
        emailInput.resignFirstResponder()
        passwordInput.resignFirstResponder()
        guard let reach = Reachability(), reach.connection != .none else {
            MailRoundedHUD.showTips(with: BundleI18n.MailSDK.Mail_ThirdClient_InternetErrorRetry, on: view)
            return
        }
        guard !detectAddressAndUpdateUIIfNeeded() else {
            return
        }
        let address = (emailInput.text ?? "").trimmingCharacters(in: .whitespaces)
        let password = (passwordInput.text ?? "").trimmingCharacters(in: .whitespaces)
        guard address.isLegalForEmail() else {
            detectAddressAndUpdateUIIfNeeded()
            return
        }
        if scene.isFreeBind {
            if imapAccount == nil {
                imapAccount = MailImapAccount(mailAddress: address,
                                              password: password,
                                              bindType: scene == .freeBind ? .firstBind : .reBind)
            }
            imapAccount?.mailAddress = address
            imapAccount?.password = password
            
            guard let account = imapAccount else { return }
            if authURLLogin() {
                freeBindAuthLogin(address: account.mailAddress, type: .exchange)
            } else {
                freeBindLogin(account)
            }
        } else {
            /// 三方
            if self.tripartiteAccount == nil {
                self.tripartiteAccount = MailClientTripartiteProviderHelper.makeDefaultAccount(type: type,
                                                                                               address: emailInput.text ?? "",
                                                                                               password: passwordInput.text ?? "")
            }
            if easO365() { // eas协议fg开启下，O365统一走oauth登录
                loginButton.showLoading()
                enableAccountInfoEditing(false)
                Store.settingData.tokenRelink(provider: nil, navigator: self.accountContext.navigator, from: self, address: emailInput.text ?? "", protocolConfig: protocolConfig,
                                              completionHandler: { [weak self] in
                    self?.loginButton.hideLoading()
                    self?.enableAccountInfoEditing(true)
                })
                return
            }
            guard !type.loginWithAdvanceSetting(protocolConfig: protocolConfig) else {
                let defaultConfig = MailClientTripartiteProviderHelper.defaultConfig()
                tripartiteAccount?.receiver = defaultConfig.0
                tripartiteAccount?.sender = defaultConfig.1
                advancedSettingButtonClick()
                return
            }
            guard var account = tripartiteAccount else {
                return
            }
            account.address = address
            var pass = Email_Client_V1_LoginPass()
            if type.isTokenLogin() {
                pass.type = .token
            } else {
                pass.type = .password
            }
            pass.authCode = (passwordInput.text ?? "").trimmingCharacters(in: .whitespaces)
            account.pass = pass
            if easProtoExchange() {
                var easConfig = Email_Client_V1_ProtocolConfig()
                easConfig.protocol = .exchange
                easConfig.domain = serverDomainInput.text ?? ""
                easConfig.encryption = sslCheckBox.isSelected ? .ssl : .none
                account.receiver = easConfig
            }
            loginHandler(account)

        }
    }

    func loginHandler(_ account: MailTripartiteAccount) {
        loginButton.showLoading()
        enableAccountInfoEditing(false)
        taskID = UUID().uuidString
        let event = MailAPMEvent.MailClientCreateAccount()
        event.markPostStart()
        apmHolder[MailAPMEvent.MailClientCreateAccount.self] = event
        Store.fetcher?.createTripartiteAccount(taskID: taskID, account: account)
            .subscribe(onNext: { [weak self] (_) in
                guard let `self` = self else { return }
                MailLogger.info("[mail_client] login success")
                self.loginButton.hideLoading()
                self.enableAccountInfoEditing(true)
                self.loginSuccessInSetting()
                self.taskID = ""
                MailTracker.log(event: "email_tripartite_service_login_click", params: ["mail_account_type": Store.settingData.getMailAccountType(), "click": "login",  "protocol": self.protocolConfig == .exchange ? "eas" : "imap", "target": "none", "login_result": "success"])
                self.clientBaseApmInfoFill(account)
                event.endParams.append(MailAPMEventConstant.CommonParam.status_success)
                event.postEnd()
            }, onError: { [weak self] (error) in
                guard let `self` = self else { return }
                MailLogger.error("[mail_client] login fail", error: error)
                MailTracker.log(event: "email_tripartite_service_login_click", params: ["mail_account_type": Store.settingData.getMailAccountType(), "click": "login",  "protocol": self.protocolConfig == .exchange ? "eas" : "imap", "target": "none", "login_result": "failed"])
                self.loginButton.hideLoading()
                self.enableAccountInfoEditing(true)
                self.taskID = ""
                self.clientBaseApmInfoFill(account)
                event.endParams.appendError(error: error)
                event.endParams.append(MailAPMEventConstant.CommonParam.status_rust_fail)
                event.postEnd()
                let alert = LarkAlertController()
                alert.setTitle(text: BundleI18n.MailSDK.Mail_ThirdClient_CantLoginTitle)
                alert.setContent(text: BundleI18n.MailSDK.Mail_ThirdClient_CheckAccountPasswordCorrect, alignment: .center)
                if self.needShowGuide() {
                    alert.addSecondaryButton(text: BundleI18n.MailSDK.Mail_ThirdClient_HelpDocsMobile, dismissCompletion: { [weak self] in
                        self?.openHelpGuide2()
                    })
                }
                alert.addPrimaryButton(text: BundleI18n.MailSDK.Mail_ThirdClient_Retry, dismissCompletion: { [weak self] in })
                self.navigator?.present(alert, from: self)
            }).disposed(by: self.disposeBag)
    }

    func freeBindAuthLogin(address: String, type: MailOAuthURLType) {
        guard !isRequestingPermit else { return }
        isRequestingPermit = true
        updateInputsWhenLogin(start: true)
        MailDataServiceFactory.commonDataService?
            .getGoogleOrExchangeOauthUrl(type: type, emailAddress: address, fromVC: self, showErrToast: false)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (url, denied, errMsg) in
                guard let self = self else { return }
                defer { self.isRequestingPermit = false }
                if denied, let errMsg = errMsg {
                    self.updateEmailInputTips(borderColor: .ud.functionDangerContentDefault, text: errMsg)
                    self.updateInputsWhenLogin(start: false)
                    return
                }
                guard let oauthURL =  URL(string: url) else {
                    MailLogger.error("[mail_client] cannot init url from: \(url)")
                    self.updateInputsWhenLogin(start: false)
                    return
                }
                self.resetTips()
                UIApplication.shared.open(oauthURL)
                let model = MailClientOAuthGuideViewModel.defaultAuthModel(url: oauthURL, type: type)
                let vc = MailClientOAuthGuideViewController(model: model) { [weak self] in
                    self?.currentGuideVC = nil
                }
                vc.modalPresentationStyle = .overFullScreen
                self.navigator?.present(vc, from: self, animated: false)
                self.currentGuideVC = vc
                self.updateInputsWhenLogin(start: false)
                switch type {
                case .google:
                    MailTracker.log(event: "email_google_waiting_binding_view", params: [:])
                case .exchange:
                    MailTracker.log(event: "email_office_365_waiting_binding_view", params: [:])
                @unknown default:
                    break
                }
            }, onError: { [weak self] error in
                guard let self = self else { return }
                self.updateEmailInputTips(borderColor: .ud.functionDangerContentDefault, text: BundleI18n.MailSDK.Mail_Toast_OperationFailed)
                self.isRequestingPermit = false
                MailLogger.error("[mail_client] Fail to get OAuth URL, error: \(error)")
                self.updateInputsWhenLogin(start: false)
            }).disposed(by: disposeBag)
    }
    
    func freeBindLogin(_ account: MailImapAccount) {
        updateInputsWhenLogin(start: true)
        Store.fetcher?.imapUserBindAccount(account)
            .subscribe(onNext: { [weak self] status in
                guard let self = self else { return }
                if status != .success {
                    self.updateInputsWhenLogin(start: false)
                }
                MailLogger.info("[Free-Bind] Imap bind request status: \(status.rawValue)")
                var errorLogType: String?
                switch status {
                case .success:
                    /// 登录成功等推送再退出，避免退出后首页还没有数据
                    break
                case .failForNoDomainConfig:
                    errorLogType = "get_imap_smtp_failed"
                    self.advancedSettingButtonClick()
                case .failForBindByOtherUser:
                    errorLogType = "repetitive_binding"
                    self.updateEmailInputTips(borderColor: .ud.functionDangerContentDefault,
                                              text: BundleI18n.MailSDK.Mail_LinkAccount_AccountUsedTryAnother_Error)
                case .failForPersonalDomain:
                    errorLogType = "personal_mail"
                    self.updateEmailInputTips(borderColor: .ud.functionDangerContentDefault,
                                              text: BundleI18n.MailSDK.Mail_LinkAccount_CantLinkPersonalAccount_Error)
                case .failForLoginCredentialsConflict:
                    errorLogType = "login_failed"
                    self.updateEmailInputTips(borderColor: .ud.functionDangerContentDefault,
                                              text: BundleI18n.MailSDK.Mail_LinkAccount_UnableToLinkOtherLogin_Empty_Desc)
                case .failForBindOtherVerifiedDomain:
                    errorLogType = "domain_already_exists"
                    self.updateEmailInputTips(borderColor: .ud.functionDangerContentDefault,
                                              text: BundleI18n.MailSDK.Mail_LinkEmail_DomainHasBeenUsed_Text)
                case .failForLogin, .failForBindOtherMailAccount, .failForChangeAddressWhenRebind, .unknown:
                    errorLogType = "login_failed"
                    self.alertHelper?.showImapCannotLoginAlert(from: self, pageType: self.type.pageType)
                @unknown default:
                    errorLogType = "login_failed"
                    self.alertHelper?.showImapCannotLoginAlert(from: self, pageType: self.type.pageType)
                }
                if let error = errorLogType {
                    MailTracker.log(event: "email_other_mail_binding_error_view", params: ["error_type": error, "mail_service": "others"])
                } else {
                    MailTracker.log(event: "email_other_mail_binding_success_view", params: ["mail_service": "others"])
                }
            }, onError: { [weak self] error in
                guard let self = self else { return }
                self.updateInputsWhenLogin(start: false)
                MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_LinkAccount_LoginFaileRetry_Toast, on: self.view)
                MailLogger.error("[Free-Bind] Imap bind request error: \(error)")
            }).disposed(by: disposeBag)
    }

    func clientBaseApmInfoFill(_ account: Email_Client_V1_TripartiteAccount) {
        let provider = MailAPMEvent.MailClientCreateAccount.EndParam.provider(account.provider.apmValue() )
        apmHolder[MailAPMEvent.MailClientCreateAccount.self]?.endParams.append(provider)
        let loginPassType = MailAPMEvent.MailClientCreateAccount.EndParam.login_pass_type(account.pass.type.apmValue() )
        apmHolder[MailAPMEvent.MailClientCreateAccount.self]?.endParams.append(loginPassType)
        let protocolType = MailAPMEvent.MailClientCreateAccount.EndParam.client_protocol(account.apmProtocolValue())
        apmHolder[MailAPMEvent.MailClientCreateAccount.self]?.endParams.append(protocolType)
        let receiverEncryptionType = MailAPMEvent.MailClientCreateAccount.EndParam.client_protocol(account.receiver.apmEncryptionValue())
        apmHolder[MailAPMEvent.MailClientCreateAccount.self]?.endParams.append(receiverEncryptionType)
        let senderEncryptionType = MailAPMEvent.MailClientCreateAccount.EndParam.client_protocol(account.sender.apmEncryptionValue())
        apmHolder[MailAPMEvent.MailClientCreateAccount.self]?.endParams.append(senderEncryptionType)
    }

    func enableAccountInfoEditing(_ enable: Bool) {
        var config = UDTextFieldUIConfig(isShowBorder: true,
                                         clearButtonMode: .whileEditing,
                                         textColor: enable ? UIColor.ud.textTitle : UIColor.ud.textPlaceholder,
                                         font: UIFont.systemFont(ofSize: 16.0, weight: .regular))
        config.borderColor = UIColor.ud.lineBorderComponent
        if !enable {
            config.backgroundColor = UIColor.ud.udtokenInputBgDisabled
        }
        protocolSelection.config = config
        protocolSelection.input.isUserInteractionEnabled = enable
        emailInput.config = config
        emailInput.input.isUserInteractionEnabled = enable
        sslCheckBox.isEnabled = enable
        serverDomainInput.config = config
        serverDomainInput.input.isUserInteractionEnabled = enable
        if !enable {
            config.textColor = passwordInput.input.isSecureTextEntry ? UIColor.ud.textTitle : UIColor.ud.textPlaceholder
        }
        passwordInput.config = config
        passwordInput.input.isUserInteractionEnabled = enable
    }

    func loginSuccessInSetting() {
        dismissOrPop(animated: false, success: true, completion: { [weak self] in
            self?.delegate?.loginSuccess()
        })
    }

    func cancel(_ account: Email_Client_V1_TripartiteAccount?) {
        self.tripartiteAccount = account
        emailInput.text = account?.address
        passwordInput.text = account?.pass.authCode
        sslCheckBox.isSelected = (account?.receiver.encryption ?? .ssl) == .ssl
    }
    
    func freeBindCancel(_ account: MailImapAccount?) {
        if let address = account?.mailAddress {
            self.imapAccount?.mailAddress = address
        }
        if let password = account?.password {
            self.imapAccount?.password = password
        }
        emailInput.text = account?.mailAddress
        passwordInput.text = account?.password
        bindLoginValidChecker()
    }

    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        textField.text = nil
        detectAddressAndUpdateUIIfNeeded()
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if emailInput.input.isFirstResponder {
            detectAddressAndUpdateUIIfNeeded()
            passwordInput.input.becomeFirstResponder()
        }
        return true
    }

    @discardableResult
    private func detectAddressAndUpdateUIIfNeeded() -> Bool {
        guard let address = emailInput.input.text else { return false }
        if !(address.isLegalForEmail() || address.isEmpty) { // ux说空字符串不算非法。。
            updateEmailInputTips(borderColor: .ud.functionDangerContentDefault,
                                 text: BundleI18n.MailSDK.Mail_ThirdClient_EnterValidAddress)
            return true
        } else if Store.settingData.checkRepeatAddress(address) {
            updateEmailInputTips(borderColor: .ud.functionDangerContentDefault,
                                 text: BundleI18n.MailSDK.Mail_ThirdClient_EmailAccountExisted)
            return true
        } else {
            resetTips()
            tipsLabel.sizeToFit()
            return false
        }
    }
    
    private func resetTips() {
        guard scene != .freeBindInvaild else { return }
        updateEmailInputTips(borderColor: .ud.lineBorderComponent, text: "")
    }
    
    private func updateEmailInputTips(borderColor: UIColor, text: String) {
        var config = makeDefaultTipsConfig()
        config.borderColor = borderColor
        emailInput.config = config
        tipsLabel.text = text
        tipsLabel.sizeToFit()
    }

    init(type: MailTripartiteProvider, accountContext: MailAccountContext, scene: LoginScene) {
        self.accountContext = accountContext
        self.scene = scene
        super.init(nibName: nil, bundle: nil)
        self.isNavigationBarHidden = true
        self.type = type
        if scene == .imap {
            protocolConfig = .imap
        } else if scene == .eas {
            protocolConfig = .exchange
        }
        MailLogger.info("[mail_client_login] type: \(type)")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var serviceProvider: MailSharedServicesProvider? {
        accountContext
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if scene == .freeBindInvaild {
            updateInputStatus(input: emailInput, enabled: false)
            emailInput.input.text = imapAccount?.mailAddress
            passwordInput.input.becomeFirstResponder()
        } else if !firstLoad {
            emailInput.input.becomeFirstResponder()
            passwordInput.setStatus(.normal)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if scene != .freeBindInvaild, firstLoad {
            emailInput.input.becomeFirstResponder()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // 适配iOS 15 bartintcolor颜色不生效问题
        updateNavAppearanceIfNeeded()
        setupViews()
        bindLoginValidChecker()
        addObservers()

        if scene.isFreeBind {
            MailTracker.log(event: "email_other_mail_binding_view", params: ["page_type": type.pageType])
        } else {
            MailTracker.log(event: "email_tripartite_service_login_view", params: ["mail_account_type": Store.settingData.getMailAccountType()])
        }
    }

    func bindLoginValidChecker() {
        loginDisposeBag = DisposeBag()

        let usernameValid = self.emailInput.input.rx.text.map{ ( ($0?.isLegalForEmail() ?? false)
                                                                 && !Store.settingData.checkRepeatAddress($0) ) }.share(replay: 1)
        let passwordValid = self.passwordInput.input.rx.text.map{ ( $0?.count ?? 0) > 0 && ($0?.count ?? 0) < 100 }.share(replay: 1)
        let serverDomainValid = self.serverDomainInput.input.rx.text.map{ ( $0?.count ?? 0) > 0 && ($0?.count ?? 0) < 100 }.share(replay: 1)
        Observable.combineLatest(usernameValid, passwordValid, serverDomainValid) { [weak self] (_, passwordValid, serverDomainValid) -> Bool in
            guard let `self` = self else { return false }
            if self.easO365() || self.authURLLogin() {
                return !(self.emailInput.input.text?.isEmpty ?? true)
            } else if self.easProtoExchange() {
                return !(self.emailInput.input.text?.isEmpty ?? true) && passwordValid && serverDomainValid
            } else {
                return !(self.emailInput.input.text?.isEmpty ?? true) && passwordValid
            }
        }.bind(to: loginButton.rx.isEnabled)   // 用户名密码都通过验证，才可以点击按钮
            .disposed(by: loginDisposeBag)
    }

    func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(didReceivedKeyboardWillHideNotification(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didReceivedKeyboardDidShowNotification(_:)), name: UIResponder.keyboardDidShowNotification, object: nil)

        EventBus.accountChange
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (push) in
                if case .shareAccountChange(let change) = push {
                    self?.mailSharedAccountChange(change)
                }
                if case .accountChange(let change) = push {
                    self?.mailPrimaryAccountChange(change)
                }
            }).disposed(by: disposeBag)

        if let reach = reachability {
            connection = reach.connection
            reach.notificationCenter.addObserver(self, selector: #selector(networkChanged), name: Notification.Name.reachabilityChanged, object: nil)
            do {
                try reachability?.startNotifier()
            } catch {
                MailLogger.debug("could not start reachability notifier")
            }
        }
    }

    func mailSharedAccountChange(_ change: MailSharedAccountChange) {
        MailLogger.info("[mail_client_eas] change: \(change.account.mailAccountID), isBind: \(change.isBind)")
        if change.isBind {
            navigator?.pop(from: self, animated: false, completion: { [weak self] in
                self?.delegate?.loginSuccess()
            })
        }
    }

    func mailPrimaryAccountChange(_ change: MailAccountChange) {
        guard accountContext.featureManager.realTimeOpen(.newFreeBindMail, openInMailClient: false) else { return }
        let userType = change.account.mailSetting.userType
        MailLogger.info("[Free-Bind]: client login account change, type: \(userType.rawValue)")
        if userType == .oauthClient {
            DispatchQueue.main.asyncAfter(deadline: .now() + timeIntvl.short) { [weak self] in
                self?.dismissOrPop(animated: true, success: true)
            }
        }
    }

    @objc
    func networkChanged() {
        guard let reachablility = reachability else {
            return
        }
        guard connection != reachablility.connection else {
            MailLogger.info("mail network changed repeat at mailClientLogin")
            return
        }
        MailLogger.info("mail network changed at mailClientLogin")
        connection = reachablility.connection
        if reachablility.connection == .none, !taskID.isEmpty {
            // 取消请求 弹toast
            MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_ThirdClient_NetworkErrorTryAgain, on: self.view)
            Store.fetcher?.cancelCreateTripartiteAccount(taskID: taskID)
                .subscribe(onNext: { [weak self] (_) in
                    MailLogger.info("[mail_client] cancel login success")
                    self?.loginButton.hideLoading()
                    self?.taskID = ""
                }, onError: { [weak self] (error) in
                    guard let `self` = self else { return }
                    MailLogger.error("[mail_client] cancel login fail", error: error)
                    self.loginButton.hideLoading()
                }).disposed(by: self.disposeBag)
        }
    }

    @objc
    func didReceivedKeyboardWillHideNotification(_ notify: Notification) {
        setupContentSize()
    }

    @objc
    func didReceivedKeyboardDidShowNotification(_ notify: Notification) {
        guard let userinfo = notify.userInfo else {
            return
        }
        guard let keyboardFrame = userinfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }
        let keyboardHeight = keyboardFrame.size.height
        if let editingTextField = editingTextField {
            let rect = loginButton.convert(loginButton.bounds, to: contentView)
            let y = contentView.bounds.height - rect.origin.y - loginButton.bounds.height - keyboardHeight
            if y < 0 {
                setupContentSize(abs(y))
            }
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        // to update view frame
        coordinator.animate(alongsideTransition: { [weak self] _ in
            // update view along with animation
            self?.gradientView.frame = CGRect(x: 0, y: 0, width: size.width, height: 240)
        }, completion: { _ in             // update view after transition
        })
    }

    func refreshLoginPage() {
        for subview in [contentView.subviews, view.subviews].flatMap({ $0 }) {
            subview.removeFromSuperview()
        }
        gradientView = LinearGradientView()
        setupViews()
        bindLoginValidChecker()
        detectAddressAndUpdateUIIfNeeded()
    }

    func setupViews() {
        view.backgroundColor = UIColor.ud.bgBody

        gradientView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 240)
        gradientView.direction = .topToBottom
        let upColor = UIColor.mail.rgb("#E3EBFC") & UIColor.mail.rgb("#121429")
        let downColor = UIColor.mail.rgb("#FFFFFF") & UIColor.mail.rgb("#191919")
        gradientView.colors = [upColor, downColor]
        view.addSubview(gradientView)

        let imageView = UIImageView()
        imageView.image = Resources.image(named: "bg_light")
        imageView.frame = gradientView.frame
        view.addSubview(imageView)

        setupCustomNavBar()
        setupHelpBtnOnNavIfNeeded()

        contentView.showsVerticalScrollIndicator = false
        contentView.showsHorizontalScrollIndicator = false
        contentView.bounces = true
        contentView.alwaysBounceVertical = true
        setupContentSize()
        view.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).inset(navHeight)
            make.left.right.bottom.equalToSuperview()
        }

        let configInfo = type.config()
        titleLabel.text = configInfo.0
        iconView.image = configInfo.1
        if type.needRenderIcon() {
            iconView.tintColor = UIColor.ud.N400
        }
        iconView.contentMode = .scaleAspectFit
        contentView.addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.top.equalTo(8)
            make.width.height.equalTo(58)
            make.left.equalTo(16)
        }

        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconView.snp.bottom).offset(18)
            make.centerX.equalToSuperview()
            make.width.equalTo(Display.pad ? 400 : view.frame.width - 48)
        }

        if scene == .eas {
            contentView.addSubview(protocolSelection)
            protocolSelection.snp.makeConstraints { make in
                make.top.equalTo(titleLabel.snp.bottom).offset(24)
                make.centerX.equalToSuperview()
                make.width.equalTo(Display.pad ? 400 : view.frame.width - 48)
            }
        }

        contentView.addSubview(emailInput)
        emailInput.snp.makeConstraints { make in
            if scene == .eas {
                make.top.equalTo(protocolSelection.snp.bottom).offset(16)
            } else {
                make.top.equalTo(titleLabel.snp.bottom).offset(24)
            }
            make.centerX.equalToSuperview()
            make.width.equalTo(Display.pad ? 400 : view.frame.width - 48)
        }

        contentView.addSubview(resignKeyboardBGBtn)
        resignKeyboardBGBtn.snp.makeConstraints { make in
            make.width.top.equalToSuperview()
            make.bottom.equalTo(titleLabel.snp.bottom).offset(16)
        }
        resignKeyboardBGBtn.addTarget(self, action: #selector(resignResponse), for: .touchUpInside)

        contentView.addSubview(tipsLabel)
        tipsLabel.snp.makeConstraints { make in
            make.top.equalTo(emailInput.snp.bottom).offset(4)
            make.left.equalTo(emailInput)
            make.width.equalTo(Display.pad ? 400 : view.frame.width - 48)
        }


        if !easO365() && !authURLLogin() {
            contentView.addSubview(passwordInput)
            passwordInput.snp.makeConstraints { make in
                make.top.equalTo(tipsLabel.snp.bottom).offset(12)
                make.height.equalTo(48)
                make.centerX.equalToSuperview()
                make.width.equalTo(Display.pad ? 400 : view.frame.width - 48)
            }

            passwordInput.addSubview(pwdPreviewButton)
            pwdPreviewButton.snp.makeConstraints { make in
                make.right.equalTo(-14)
                make.centerY.equalToSuperview()
                make.width.height.equalTo(20)
            }

            setupGetPasswordBtnIfNeed()

            if scene != .eas {
                contentView.addSubview(advancedSettingButton)
                let topView = getPasswordButton ?? passwordInput
                advancedSettingButton.snp.makeConstraints { make in
                    make.top.equalTo(topView.snp.bottom).offset(8)
                    make.height.equalTo(36)
                    make.left.equalTo(passwordInput)
                    make.right.equalTo(-24)
                }
            }
        }

        /// SSL选项
        let sslContainerView = UIView()
        if easExchange() {
            if easProtoExchange() {
                contentView.addSubview(serverDomainInput)
                serverDomainInput.snp.makeConstraints { make in
                    make.top.equalTo(passwordInput.snp.bottom).offset(16)
                    make.height.equalTo(48)
                    make.centerX.equalToSuperview()
                    make.width.equalTo(Display.pad ? 400 : view.frame.width - 48)
                }

                sslContainerView.clipsToBounds = false
                contentView.addSubview(sslContainerView)
                contentView.addSubview(resignKeyboardBtn)
                sslContainerView.snp.makeConstraints { make in
                    make.top.equalTo(serverDomainInput.snp.bottom).offset(20)
                    make.height.equalTo(22)
                    make.left.equalTo(serverDomainInput)
                    make.width.equalTo(serverDomainInput).dividedBy(3)
                }
                resignKeyboardBtn.snp.makeConstraints { make in
                    make.top.height.equalTo(sslContainerView)
                    make.left.equalTo(sslContainerView.snp.right)
                    make.width.equalToSuperview()
                }
                resignKeyboardBtn.addTarget(self, action: #selector(resignResponse), for: .touchUpInside)
                sslCheckBox.isSelected = (tripartiteAccount?.receiver.encryption ?? .ssl) == .ssl
                sslContainerView.addSubview(sslCheckBox)
                sslCheckBox.snp.makeConstraints { make in
                    make.width.height.equalTo(18)
                    make.left.equalToSuperview()
                    make.centerY.equalToSuperview()
                }
                let sslTips = UILabel()
                sslTips.text = BundleI18n.MailSDK.Mail_Shared_AddEAS_ActivateSSL_Checkbox
                sslTips.textColor = UIColor.ud.textTitle
                sslTips.font = UIFont.systemFont(ofSize: 16.0)
                sslContainerView.addSubview(sslTips)
                sslTips.snp.makeConstraints { make in
                    make.left.equalTo(sslCheckBox.snp.right).offset(12)
                    make.centerY.equalToSuperview()
                }
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(sslClick))
                tapGesture.numberOfTouchesRequired = 1
                tapGesture.numberOfTapsRequired = 1
                sslContainerView.addGestureRecognizer(tapGesture)
            } else {
                contentView.addSubview(advancedSettingButton)
                advancedSettingButton.snp.makeConstraints { make in
                    make.top.equalTo(passwordInput.snp.bottom).offset(8)
                    make.height.equalTo(36)
                    make.left.equalTo(passwordInput)
                    make.right.equalTo(-24)
                }
            }
        }

        contentView.addSubview(loginButton)
        loginButton.snp.makeConstraints { make in
            if easProtoExchange() {
                make.top.equalTo(sslContainerView.snp.bottom).offset(20)
            } else if !easO365() && !authURLLogin() || imapExchange() {
                make.top.equalTo(advancedSettingButton.snp.bottom).offset(8)
            } else {
                make.top.equalTo(tipsLabel.snp.bottom).offset(16)
            }
            make.height.equalTo(48)
            make.left.equalTo(emailInput)
            make.width.equalTo(Display.pad ? 400 : view.frame.width - 48)
        }

        if Display.pad {
            iconView.snp.remakeConstraints { make in
                make.top.equalTo(16)
                make.width.height.equalTo(40)
                make.left.equalTo(emailInput)
            }
        }

        contentView.addSubview(resignKeyboardBottomBGBtn)
        resignKeyboardBottomBGBtn.snp.makeConstraints { make in
            make.top.equalTo(loginButton.snp.bottom)
            make.width.height.equalToSuperview()
        }
        resignKeyboardBottomBGBtn.addTarget(self, action: #selector(resignResponse), for: .touchUpInside)
    }

    func setupContentSize(_ offset: CGFloat = 0) {
        if Display.pad {
            contentView.contentSize = CGSize(width: 400, height: view.frame.size.height + offset)
        } else {
            contentView.contentSize = CGSize(width: view.frame.size.width, height: view.frame.size.height + offset)
        }
    }

    func setupCustomNavBar() {
        let naviBar = UIView()
        view.addSubview(naviBar)
        naviBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.width.left.equalToSuperview()
            make.height.equalTo(navHeight)
        }

        let backButton = UIButton(type: .custom)
        backButton.setImage(UDIcon.leftOutlined.withRenderingMode(.alwaysTemplate), for: .normal)
        backButton.tintColor = UIColor.ud.iconN1
        backButton.addTarget(self, action: #selector(back), for: .touchUpInside)
        naviBar.addSubview(backButton)
        backButton.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.width.height.equalTo(24)
            make.centerY.equalToSuperview()
        }
    }

    func updateInputsWhenLogin(start: Bool) {
        if start {
            loginButton.showLoading()
        } else {
            loginButton.hideLoading()
        }
        advancedSettingButton.isEnabled = !start
        updateInputStatus(input: emailInput, enabled: !start)
        updateInputStatus(input: passwordInput, enabled: !start)
    }

    func updateInputStatus(input: UDTextField, enabled: Bool) {
        if enabled {
            input.input.isEnabled = true
            input.input.textColor = .ud.textTitle
            input.setStatus(.normal)
        } else {
            input.setStatus(.disable)
            input.input.textColor = .ud.textPlaceholder
            input.input.isEnabled = false
        }
    }

    func needShowGuide() -> Bool {
        return true //突然又说什么都展示，但是方法先留着了 type != .other && type != .ali
    }

    // 是否展示"如何获取密码"
    func needShowHowToGetPassword() -> Bool {
        if scene.isFreeBind {
            switch type {
            case .tencent, .ali, .netEase:
                return true
            @unknown default:
                return false
            }
        }
        return false
    }

    func setupHelpBtnOnNavIfNeeded() {
        guard needShowGuide() else {
            return
        }
        let text = BundleI18n.MailSDK.Mail_ThirdClient_HelpDocsMobile
        let font = UIFont.systemFont(ofSize: 14)
        let helpBtn = UIButton(type: .custom)
        helpBtn.setImage(UDIcon.maybeOutlined.withRenderingMode(.alwaysTemplate), for: .normal)
        helpBtn.setTitle(text, for: .normal)
        helpBtn.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        helpBtn.setTitleColor(UIColor.ud.textCaption, for: .normal)
        helpBtn.tintColor = UIColor.ud.iconN2
        helpBtn.addTarget(self, action: #selector(openHelpGuide1), for: .touchUpInside)
        let textWidth = text.getWidth(font: font)
        let btnWidth = 20 + textWidth
        let viewRect = view.frame
        helpBtn.frame = CGRect(x: viewRect.width - 16 - btnWidth, y: Display.realStatusBarHeight() + 12, width: btnWidth, height: 20)
        helpBtn.imageEdgeInsets = UIEdgeInsets(top: 2, left: 0, bottom: 2, right: textWidth + 4)
        helpBtn.titleEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 0)
        helpBtn.isHidden = scene != .imap
        helpButton = helpBtn
        view.addSubview(helpBtn)
        helpBtn.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).inset(12)
            make.width.equalTo(btnWidth)
            make.height.equalTo(20)
            make.right.equalToSuperview().offset(-16)
        }
    }

    func setupGetPasswordBtnIfNeed() {
        guard needShowHowToGetPassword() else { return }
        let button = UIButton(type: .custom)
        let text = BundleI18n.MailSDK.Mail_LinkMail_HowToGetPassword_Title
        let font = UIFont.systemFont(ofSize: 14)
        button.setImage(UDIcon.maybeOutlined.ud.withTintColor(UIColor.ud.textCaption), for: .normal)
        button.setTitle(text, for: .normal)
        button.titleLabel?.font = font
        button.setTitleColor(UIColor.ud.textCaption, for: .normal)
        let textWidth = text.getWidth(font: font)
        button.imageEdgeInsets = UIEdgeInsets(top: 2, left: 0, bottom: 2, right: textWidth + 8)
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: 0)
        button.addTarget(self, action: #selector(openGetPassword), for: .touchUpInside)
        contentView.addSubview(button)
        button.snp.makeConstraints { make in
            make.height.equalTo(20)
            make.top.equalTo(passwordInput.snp.bottom).offset(4)
            make.left.equalTo(passwordInput)
        }
        button.hitTestEdgeInsets = UIEdgeInsets(edges: -10)
        self.getPasswordButton = button
    }

    @objc
    func openGetPassword() {
        guard let localLink = serviceProvider?.provider.settingConfig?.linkConfig?.passwordHelp.localLink else {
            MailLogger.info("no link config")
            return
        }
        guard let url = URL(string: localLink) else {
            MailLogger.info("initialize url failed")
            return
        }
        UIApplication.shared.openURL(url)
    }

    @objc
    func openHelpGuide1() {
        guard let json = ProviderManager.default.commonSettingProvider?.originalSettingValue(configName: .mailClientURLKey),
              let data = json.data(using: .utf8),
              let jsonDict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
              let urlDict = jsonDict["third_client_login_help_center_url"] as? [String: String] else {
            return
        }
        var link: String
        if LanguageManager.currentLanguage == .zh_CN || LanguageManager.currentLanguage == .zh_HK || LanguageManager.currentLanguage == .zh_TW {
            link = urlDict["cn"] ?? ""
        } else {
            link = urlDict["en"] ?? ""
        }
        if !link.isEmpty, let url = URL(string: link) {
            UIApplication.shared.open(url)
        }
    }

    @objc
    func openHelpGuide2() {
        guard let link = ProviderManager.default.commonSettingProvider?.stringValue(key: "open-imap")?.localLink,
              let url = URL(string: link) else { return }
        UIApplication.shared.open(url)
    }

    @objc func resignResponse() {
        editingTextField?.resignFirstResponder()
    }

    @objc
    func back() {
        dismissOrPop()
        logFreeBindCancel()
    }

    func dismissOrPop(animated: Bool = true, success: Bool = false, completion: (() -> Void)? = nil) {
        if scene == .freeBindInvaild {
            navigationController?.dismiss(animated: true) { [weak self] in
                completion?()
                self?.dismissCompletion?(success)
            }
        } else {
            navigator?.pop(from: self)  { [weak self] in
                completion?()
                self?.dismissCompletion?(success)
            }
        }
        MailLogger.info("[Free-Bind] client login dismiss, scene: \(scene)")
    }

    private func makeTipsLabel() -> UILabel {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.functionDangerContentDefault
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }

    private func makeTitleLabel() -> UILabel {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 26, weight: .semibold)
        label.textColor = UIColor.ud.textTitle
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }
    
    private func makeDefaultTipsConfig() -> UDTextFieldUIConfig {
        UDTextFieldUIConfig(isShowBorder: true,
                            clearButtonMode: .whileEditing,
                            textColor: UIColor.ud.textTitle,
                            font: UIFont.systemFont(ofSize: 16.0, weight: .regular))
    }
    
    private func logFreeBindCancel() {
        guard scene.isFreeBind else { return }
        let passwordEmpty = passwordInput.text.isEmpty ? 0 : 1
        let addressEmpty = emailInput.text.isEmpty ? 0 : 1
        MailTracker.log(event: "email_other_mail_binding_click", params: ["click": "close_page",
                                                                          "page_type": type.pageType,
                                                                          "address": addressEmpty,
                                                                          "password": passwordEmpty])

    }
}

extension UDButtonUIConifg {
    static func makeLoginButtonConfig() -> UDButtonUIConifg {
        let normalColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.clear,
                                                      backgroundColor: UIColor.ud.primaryContentDefault,
                                                      textColor: UIColor.ud.primaryOnPrimaryFill)
        let pressedColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.clear,
                                                       backgroundColor: UIColor.ud.primaryContentLoading,
                                                       textColor: UIColor.ud.primaryOnPrimaryFill)
        let disableColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.clear,
                                                       backgroundColor: UIColor.ud.fillDisabled,
                                                       textColor: UIColor.ud.udtokenBtnPriTextDisabled)
        let loadingColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.clear,
                                                       backgroundColor: UIColor.ud.primaryContentLoading,
                                                       textColor: UIColor.ud.udtokenBtnPriTextDisabled)
        let config = UDButtonUIConifg(normalColor: normalColor,
                                      pressedColor: pressedColor,
                                      disableColor: disableColor,
                                      loadingColor: loadingColor,
                                      loadingIconColor: UIColor.ud.primaryOnPrimaryFill,
                                      type: .middle)
        return config
    }
}
