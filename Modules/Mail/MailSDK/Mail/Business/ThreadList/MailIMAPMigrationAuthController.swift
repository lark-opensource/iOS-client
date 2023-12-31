//
//  MailIMAPMigrationAuthController.swift
//  MailSDK
//
//  Created by ByteDance on 2023/9/26.
//

import Foundation
import UIKit
import LarkAlertController
import RxSwift
import RustPB
import LarkSplitViewController
import EENavigator
import UniverseDesignColor
import LarkUIKit
import FigmaKit
import UniverseDesignIcon
import UniverseDesignInput
import UniverseDesignButton

struct MailIMAPMigrationInfo {
    let provider: IMAPMigrationProvider
    let authType: Email_Client_V1_MigrationAuthType
    let migrationID: Int64
}

class MailIMAPMigrationAuthController: MailBaseViewController, UDTextFieldDelegate {
    // MARK: data
    private var cancelAble: Bool // 是否可取消搬家
    private var migrationInfo: MailIMAPMigrationInfo
    private var accountContext: MailAccountContext
    private var pwdPreview = false
    private let disposeBag = DisposeBag()
    var cancelBlock: ((UIViewController) -> Void)?
    var preStepBlock: ((UIViewController) -> Void)?
    override var serviceProvider: MailSharedServicesProvider? {
        accountContext
    }

    var address: String? {
        return Store.settingData.getCachedCurrentAccount()?.accountAddress
    }
    // MARK: UI elements
    // 跳转外部浏览器弹窗
    weak var currentGuideVC: MailClientOAuthGuideViewController?
    private lazy var gradientView = LinearGradientView()
    private lazy var iconView = UIImageView()
    private lazy var titleLabel =  {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 26, weight: .semibold)
        label.textColor = UIColor.ud.textTitle
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()
    private lazy var migrationDescLabel: UILabel = {
        let label = UILabel()
        let text = BundleI18n.MailSDK.Mail_EmailMigration_Mobile_MigrationConfirmationLoginPage_LoginDesc()
        let font = UIFont.systemFont(ofSize: 14)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 8 - (font.lineHeight - font.pointSize)
        let attributes = [NSAttributedString.Key.foregroundColor: UIColor.ud.textCaption,
                          NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14),
                          NSAttributedString.Key.paragraphStyle: paragraphStyle]
        let attributedString = NSMutableAttributedString(string: text,
                                                         attributes: attributes)
        label.attributedText = attributedString
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var addressLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        label.textColor = UIColor.ud.textTitle
        label.textAlignment = .left
        label.numberOfLines = 0
        label.text = address
        return label
    }()
    private var getPasswordButton: UIButton?
    private lazy var pwdPreviewButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UDIcon.invisibleOutlined.withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = UIColor.ud.iconN2
        button.addTarget(self, action: #selector(pwdPreviewClick), for: .touchUpInside)
        return button
    }()

    private var passwordInput: UDTextField?
    private lazy var loginButton: UDButton = {
        let config = UDButtonUIConifg.makeLoginButtonConfig()
        let loginButton = UDButton()
        loginButton.layer.cornerRadius = 10
        loginButton.layer.masksToBounds = true
        loginButton.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        if migrationInfo.authType == .basic {
            loginButton.setTitle(BundleI18n.MailSDK.Mail_EmailMigration_Mobile_MigrationConfirmationLoginPage_LogIn_Button,
                                 for: .normal)
        } else {
            loginButton.setTitle(BundleI18n.MailSDK.Mail_EmailMigration_Mobile_MigrationConfirmationPage_LogInAndAuthorize_Button,
                                 for: .normal)
        }
        loginButton.config = config
        loginButton.isEnabled = false
        loginButton.addTarget(self, action: #selector(didClickLoginButton), for: .touchUpInside)
        return loginButton
    }()

    private lazy var preStepButton: UDButton = {
        let normalColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.clear,
                                                      backgroundColor: UIColor.clear,
                                                      textColor: UIColor.ud.primaryContentDefault)
        let pressedColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.clear,
                                                       backgroundColor: UIColor.clear,
                                                       textColor: UIColor.ud.primaryContentPressed)
        let disableColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.clear,
                                                       backgroundColor: UIColor.clear,
                                                       textColor: UIColor.ud.textDisabled)
        let config = UDButtonUIConifg(normalColor: normalColor,
                                      pressedColor: pressedColor,
                                      disableColor: disableColor,
                                      loadingColor: disableColor,
                                      loadingIconColor: nil,
                                      type: .middle)
        let button = UDButton()
        button.setTitle(BundleI18n.MailSDK.Mail_EmailMigration_Mobile_MigrationConfirmationLoginPage_Previous_TextButton, for: .normal)
        button.config = config
        return button
    }()
    
    // MARK: life cycle
    
    init(migrationInfo: MailIMAPMigrationInfo, accountContext: MailAccountContext, cancelAble: Bool) {
        self.migrationInfo = migrationInfo
        self.accountContext = accountContext
        self.cancelAble = cancelAble
        super.init(nibName: nil, bundle: nil)
        self.isNavigationBarHidden = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateNavAppearanceIfNeeded()
        setupViews()
        configLoginButtonStatus()
    }
    
    private func configLoginButtonStatus() {
        if let passwordInput = passwordInput {
            let passwordValid = passwordInput.input.rx.text.map{ ( $0?.count ?? 0) > 0 && ($0?.count ?? 0) < 100 }.share(replay: 1)
            passwordValid.map { valid in
                return !passwordInput.text.isEmpty && valid
            }.bind(to: loginButton.rx.isEnabled).disposed(by: disposeBag)
        } else {
            loginButton.isEnabled = true
        }
    }
    private func setupViews() {
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
        
        // icon
        let configInfo = migrationInfo.provider.info
        iconView.image = configInfo.1
        iconView.contentMode = .scaleAspectFit
        view.addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(52)
            make.width.height.equalTo(55)
            make.left.equalTo(16)
        }
        // title
        view.addSubview(titleLabel)
        titleLabel.text = BundleI18n.MailSDK.Mail_EmailMigration_Mobile_MigrationConfirmationPage_Title
        titleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(iconView)
            make.left.equalTo(iconView.snp.right)
            make.right.equalToSuperview().offset(-16)
        }

        // migration login decription
        view.addSubview(migrationDescLabel)
        migrationDescLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(24)
            make.right.equalToSuperview().offset(-16)
            make.top.equalTo(iconView.snp.bottom).offset(8)
        }
        view.addSubview(addressLabel)
        addressLabel.snp.makeConstraints { make in
            make.top.equalTo(migrationDescLabel.snp.bottom).offset(24)
            make.left.equalTo(migrationDescLabel)
            make.right.equalTo(migrationDescLabel)
        }
        setupPasswordInputIfNeed()
        setupGetPasswordBtnIfNeed()
        let topView = getPasswordButton ?? passwordInput ?? addressLabel
        
        view.addSubview(loginButton)
        loginButton.snp.makeConstraints { make in
            make.top.equalTo(topView.snp.bottom).offset(16)
            make.height.equalTo(48)
            make.centerX.equalToSuperview()
            make.left.equalToSuperview().offset(24)
            make.right.equalToSuperview().offset(-24)
        }
        
        setupPreStepButtonIfNeed()
    }
    
    private func makeDefaultTipsConfig() -> UDTextFieldUIConfig {
        UDTextFieldUIConfig(isShowBorder: true,
                            clearButtonMode: .whileEditing,
                            textColor: UIColor.ud.textTitle,
                            font: UIFont.systemFont(ofSize: 16.0, weight: .regular))
    }
    
    // 是否展示"如何获取密码"
    private func needShowHowToGetPassword() -> Bool {
        switch migrationInfo.provider {
        case .exmail, .alimail, .qiye163:
            return true
        case .chineseO365, .exchange, .gmail, .office365, .internationO365, .zoho, .other:
            return false
        }
    }

    private func setupGetPasswordBtnIfNeed() {
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
        view.addSubview(button)
        let topView = passwordInput ?? addressLabel
        button.snp.makeConstraints { make in
            make.height.equalTo(20)
            make.top.equalTo(topView.snp.bottom).offset(7)
            make.left.equalTo(topView)
        }
        button.hitTestEdgeInsets = UIEdgeInsets(edges: -10)
        self.getPasswordButton = button
    }
    
    private func setupPasswordInputIfNeed() {
        guard migrationInfo.authType == .basic else { return }
        var config = makeDefaultTipsConfig()
        config.borderColor = UIColor.ud.lineBorderComponent
        let textField = UDTextField(config: config)
        textField.tintColor = UIColor.ud.functionInfoContentDefault
        let rightView = UIImageView(image: UDIcon.activityColorful.ud.resized(to: CGSize(width: 20, height: 20)))
        rightView.isHidden = true
        textField.setRightView(rightView)
        textField.placeholder = BundleI18n.MailSDK.Mail_EmailMigration_Mobile_MigrationConfirmationLoginPage_EnterPassword_Placeholder
        textField.input.isSecureTextEntry = true
        textField.input.returnKeyType = .done
        textField.input.keyboardType = .alphabet
        textField.input.autocorrectionType = .no
        textField.delegate = self
        view.addSubview(textField)
        
        textField.snp.makeConstraints { make in
            make.top.equalTo(addressLabel.snp.bottom).offset(16)
            make.height.equalTo(48)
            make.centerX.equalToSuperview()
            make.left.equalToSuperview().offset(24)
            make.right.equalToSuperview().offset(-24)
        }
        textField.addSubview(pwdPreviewButton)
        pwdPreviewButton.snp.makeConstraints { make in
            make.right.equalTo(-14)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(20)
        }
        self.passwordInput = textField
    }

    // 是否展示暂不搬家
    private func needShowCancelButton() -> Bool {
        return !needShowPreStepButton() && cancelAble
    }
    // 是否展示上一步
    private func needShowPreStepButton() -> Bool {
        guard accountContext.featureManager.open(.imapMigrationShowSettingView, openInMailClient: false) else {
            MailLogger.info("[mail_client] [imap_migration] settingview disable")
            return false
        }
        switch migrationInfo.provider {
        case .exmail, .qiye163:
            return true
        case .exchange, .gmail, .alimail, .zoho, .internationO365, .chineseO365, .office365, .other:
            return false
        }
    }
    
    // 搬家鉴权流程有两种场景
    // 1. 腾讯和网易邮箱会先展示设置提示界面，下一步后开始登录鉴权界面，此时会出现上一步按钮
    // 2. 其他邮箱直接进入登录鉴权界面， 此时不展示上一步按钮，如果是公共账号弹出可取消鉴权，需要展示“暂不搬家”按钮
    private func setupPreStepButtonIfNeed() {
        guard needShowPreStepButton() || needShowCancelButton() else {
            return
        }
        view.addSubview(preStepButton)
        preStepButton.snp.makeConstraints { make in
            make.height.equalTo(22)
            make.width.equalTo(view.frame.width - 48)
            make.centerX.equalTo(loginButton)
            make.top.equalTo(loginButton.snp.bottom).offset(12)
        }

        if needShowPreStepButton() {
            preStepButton.setTitle(BundleI18n.MailSDK.Mail_EmailMigration_Mobile_MigrationConfirmationLoginPage_Previous_TextButton,
                                   for: .normal)
            preStepButton.addTarget(self, action: #selector(didClickPreStep), for: .touchUpInside)

        } else if needShowCancelButton() {
            preStepButton.setTitle(BundleI18n.MailSDK.Mail_EmailMigration_Mobile_LoginPage_NotNow_Button,
                                   for: .normal)
            preStepButton.addTarget(self, action: #selector(didClickCancel), for: .touchUpInside)
        }
    }
    
    func updateInputsWhenLogin(start: Bool) {
        if start {
            loginButton.showLoading()
        } else {
            loginButton.hideLoading()
        }
        passwordInput?.input.isEnabled = !start
        passwordInput?.input.textColor = start ? .ud.textPlaceholder : .ud.textTitle
        passwordInput?.setStatus(start ? .disable : .normal )
        preStepButton.isEnabled = !start
    }
    
    // MARK: actions
    @objc
    func openGetPassword() {
        MailTracker.log(event: "email_mail_mig_account_click",
                        params: ["mail_service": migrationInfo.provider.rawValue,
                                 "mail_account_type": Store.settingData.getMailAccountType(), "click": "how_to_get_pwd"])
        guard let localLink = serviceProvider?.provider.settingConfig?.linkConfig?.passwordHelp.localLink else {
            MailLogger.info("no link config")
            return
        }
        guard let url = URL(string: localLink) else {
            MailLogger.info("initialize url failed")
            return
        }
        UIApplication.shared.open(url)
    }
    
    @objc
    func pwdPreviewClick() {
        guard let passwordInput = self.passwordInput else { return }
        guard passwordInput.input.isUserInteractionEnabled else { return }
        pwdPreview.toggle()
        let icon = pwdPreview ? UDIcon.visibleOutlined : UDIcon.invisibleOutlined
        pwdPreviewButton.setImage(icon.withRenderingMode(.alwaysTemplate), for: .normal)
        passwordInput.input.isSecureTextEntry = !pwdPreview
    }
    
    @objc
    func didClickLoginButton() {
        MailTracker.log(event: "email_mail_mig_account_click",
                        params: ["mail_service": migrationInfo.provider.rawValue,
                                 "mail_account_type": Store.settingData.getMailAccountType(), "click": "login"])
        if migrationInfo.authType == .basic {
            if let address = address, let pass = passwordInput?.text {
                login(address: address, password: pass)
            } else {
                MailLogger.error("[mail_client] [imap_migration] no password")
            }
        } else {
            loginWithAuth()
        }
    }

    @objc
    func didClickPreStep() {
        MailLogger.info("[mail_client] [imap_migration] click prestep")
        preStepBlock?(self)
    }
    
    @objc
    func didClickCancel() {
        MailLogger.info("[mail_client] [imap_migration] click cancel")
        cancelBlock?(self)
    }
}

// MARK: AUTH
extension MailIMAPMigrationAuthController {
    func loginWithAuth() {
        guard let address = address else {
            MailLogger.info("[mail_client] [imap_migration] no account address")
            return
        }
        self.updateInputsWhenLogin(start: true)
        accountContext.sharedServices.dataService.getIMAPMigrationAuthURL(migrationID: migrationInfo.migrationID,
                                                                          emailAddress: address)
        .observeOn(MainScheduler.instance).subscribe(onNext:{[weak self] response in
            guard let self = self else { return }
            guard let oauthURL = URL(string: response.oauthURL) else {
                MailLogger.error("[mail_client] [imap_migration] request auth url invalid \(response.oauthURL)")
                self.updateInputsWhenLogin(start: false)
                return
            }
            UIApplication.shared.open(oauthURL)
            MailTracker.log(event: "email_mail_mig_o365_waiting_view",
                            params: ["mail_service": self.migrationInfo.provider.rawValue,
                                     "mail_account_type": Store.settingData.getMailAccountType()])
            let model = MailClientOAuthGuideViewModel.imapMigrationModel(url: oauthURL, provider: self.migrationInfo.provider)
            let vc = MailClientOAuthGuideViewController(model: model, dismissBlock: {
                [weak self] in
                   self?.currentGuideVC = nil
            })
            vc.modalPresentationStyle = .overFullScreen
            self.navigator?.present(vc, from: self, animated: false)
            self.currentGuideVC = vc
            self.updateInputsWhenLogin(start: false)
        }, onError: {[weak self] error in
            guard let self = self else { return }
            MailLogger.error("[mail_client] [imap_migration] Fail to get OAuth URL, error: \(error)")
            self.updateInputsWhenLogin(start: false)
        }).disposed(by: self.disposeBag)
        
    }
    
    func login(address: String, password: String) {
        self.updateInputsWhenLogin(start: true)
        accountContext.sharedServices.dataService.migartionLogin(account: address, password: password)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] result in
                guard let self = self else { return }
                self.updateInputsWhenLogin(start: false)
                switch result {
                case .success:
                    MailLogger.info("[mail_client] [imap_migration] login success")
                case .accountError:
                    MailLogger.info("[mail_client] [imap_migration] login error")
                    self.alertHelper?.showImapCannotLoginAlert(from: self, pageType: self.migrationInfo.provider.rawValue)
                case .successButNotUpload:
                    MailLogger.info("[mail_client] [imap_migration] login successButNotUpload")
                @unknown default:
                    MailLogger.error("[mail_client] [imap_migration] unknown error")
                }
            }, onError: {[weak self] error in
                guard let self = self else { return }
                MailLogger.error("[mail_client] [imap_migration] Fail to login with account and password, error: \(error)")
                self.updateInputsWhenLogin(start: false)
            }).disposed(by: self.disposeBag)
    }
}
