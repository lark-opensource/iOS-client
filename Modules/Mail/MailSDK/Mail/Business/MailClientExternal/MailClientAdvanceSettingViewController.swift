//
//  MailClientAdvanceSettingViewController.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2021/11/25.
//

import Foundation
import UIKit
import FigmaKit
import SnapKit
import UniverseDesignActionPanel
import EENavigator
import RxSwift
import RustPB
import UniverseDesignIcon
import LarkReleaseConfig
import LarkLocalizations
import LarkAlertController
import Reachability
import LarkUIKit
import UniverseDesignNotice
import UniverseDesignFont
import UniverseDesignDialog

enum MailClientProtocol: String {
    case IMAP
    case POP3
    case EXCHANGE
    case SMTP
}

enum MailClientEncryption: String {
    case SSL = "SSL/TLS"
    case STARTLS
    case None
}

typealias MailSettingProtocolHandler = (_ proto: MailClientProtocol) -> Void
typealias MailSettingEncryptionHandler = (_ encryption: MailClientEncryption) -> Void

struct MailClientSettingProtocolModel: MailSettingItemProtocol {
    var accountId: String
    var cellIdentifier: String
    var title: String
    var proto: MailClientProtocol// 枚举protocol
    var protocolHandler: MailSettingProtocolHandler?
}

extension MailClientProtocol {
    func title() -> String {
        if self == .EXCHANGE {
            return BundleI18n.MailSDK.Mail_Shared_AddEAS_EAS_DropdownList
        } else if self == .IMAP {
            return BundleI18n.MailSDK.Mail_Shared_AddEAS_IMAP_DropdownList
        } else {
            return ""
        }
    }
}

struct MailClientSettingEncryptionModel: MailSettingItemProtocol {
    var accountId: String
    var cellIdentifier: String
    var title: String
    var encryption: MailClientEncryption// 枚举加密方式
    var encryptionHandler: MailSettingEncryptionHandler
    var canSelect: Bool
}

protocol MailClientAdvanceSettingDelegate: AnyObject {
    func loginSuccessInSetting()
    func cancel(_ account: Email_Client_V1_TripartiteAccount?)
    func freeBindCancel(_ account: MailImapAccount?)
}

enum MailClientAdSettingScene {
    case login
    case config
    case reVerfiy
}

class MailClientAdvanceSettingViewController: MailBaseViewController, UITableViewDataSource, UITableViewDelegate,
                                              MailClientAdSettingSelectionDelegate, MailClientAdSettingInputDelegate,
                                              MailClientAdSettingFooterViewDelegate {
    typealias TitleType = MailSettingInputModel.TitleType
    weak var delegate: MailClientAdvanceSettingDelegate?

    private var originY: CGFloat = 0
    private var editingField: UITextField?
    private var editingIndexPath: IndexPath?
    private var helpButton: UIButton?
    private lazy var footerView = MailClientAdSettingFooterView(reuseIdentifier: "MailClientAdSettingFooterView",
                                                                scene: self.scene)

    private lazy var tableView: UITableView = {
        let tableView = InsetTableView(frame: .zero)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0,
                                              bottom: (Display.pad ? 0 : Display.bottomSafeAreaHeight) + 16, right: 0)
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 76
        tableView.backgroundColor = ModelViewHelper.bgColor(vc: self)
        tableView.separatorColor = UIColor.ud.lineDividerDefault
        let footerView = footerView
        footerView.frame = CGRect(origin: .zero, size: CGSize(width: self.view?.bounds.width ?? Display.width, height: 56))
        footerView.delegate = self
        tableView.tableFooterView = footerView
        tableView.tableFooterView?.isHidden = true
        tableView.contentInsetAdjustmentBehavior = .never
        if isFreeBind && scene != .config {
            let view = UITableViewHeaderFooterView()
            view.addSubview(configNotice)
            configNotice.snp.makeConstraints { make in
                make.top.left.right.equalToSuperview()
                make.bottom.equalToSuperview().inset(8)
            }
            let width = self.view?.bounds.width ?? Display.width
            let height = configNotice.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude)).height
            view.frame = CGRect(origin: .zero, size: CGSize(width: width, height: height + 8))
            tableView.tableHeaderView = view
        } else {
            tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: self.view?.bounds.width ?? Display.width, height: 8))
        }
        
        tableView.keyboardDismissMode = .onDrag
        /// registerCell
        tableView.lu.register(cellSelf: MailClientAdSettingInputCell.self)
        tableView.lu.register(cellSelf: MailClientAdSettingSelectionCell.self)
        return tableView
    }()
    
    private lazy var configNotice: UIView = {
        let actionText = BundleI18n.MailSDK.Mail_LinkAccount_AdvancedSetting_HelpDoc_Text
        let text = BundleI18n.MailSDK.Mail_LinkAccount_AdvancedSetting_HowToGetServerInfo_Text(actionText)
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 3
        let attributedText = NSMutableAttributedString(string: text, attributes: [
            .font: UIFont.systemFont(ofSize: 14),
            .paragraphStyle: paragraph
        ])
        let linkRange = (text as NSString).range(of: actionText)
        attributedText.addAttributes([.link: ActionableTextView.kURLString], range: linkRange)
        let config = UDNoticeUIConfig(type: .info, attributedText: attributedText)
        let view = UDNotice(config: config)
        view.delegate = self
        return view
    }()

    private lazy var portValidateBlock: ((String) -> String?) = { port in
        if Int(port) == nil {
            return BundleI18n.MailSDK.Mail_LinkAccount_AdvancedSetting_PortIncorrectFormat_Error
        } else {
            return nil
        }
    }

    private lazy var domainValidateBlock: ((String) -> String?) = { domain in
        let domainRegex = "^(?:(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]*[a-zA-Z0-9])?\\.)+[a-zA-Z]{2,}|\\d{1,3}(?:\\.\\d{1,3}){3})$"
        let domainPredicate = NSPredicate(format: "SELF MATCHES %@", domainRegex)
        if !domainPredicate.evaluate(with: domain) {
            return BundleI18n.MailSDK.Mail_LinkAccount_AdvancedSetting_InvalidServerAddress_Error
        }
        return nil
    }

    private var dataSource: [MailSettingSectionModel] = []
    var accountID = ""
    var type: MailTripartiteProvider = .other
    var tripartiteAccount: Email_Client_V1_TripartiteAccount?
    var imapAccount: MailImapAccount?
    private let disposeBag = DisposeBag()
    private var accountContext: MailAccountContext?
    private var scene: MailClientAdSettingScene = .login
    private var didLoadFlag = false
    private var senderTips = ""
    private var receiverTips = ""
    private var reachability: Reachability? = Reachability()
    private var connection: Reachability.Connection?
    private var taskID: String = ""
    private let isFreeBind: Bool
    private weak var mailAddressCell: MailClientAdSettingInputCell?
    
    init(
        scene: MailClientAdSettingScene,
        accountID: String,
        accountContext: MailAccountContext?,
        isFreeBind: Bool,
        type: MailTripartiteProvider = .other
    ) {
        self.scene = scene
        self.accountID = accountID
        self.accountContext = accountContext
        self.isFreeBind = isFreeBind
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var serviceProvider: MailSharedServicesProvider? {
        accountContext
    }

    override var navigationBarTintColor: UIColor {
        return ModelViewHelper.bgColor(vc: self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        showLoading()
        setupViewModel()
        // 适配iOS 15 bartintcolor颜色不生效问题
        updateNavAppearanceIfNeeded()
        addNotification()

        if isFreeBind {
            MailTracker.log(event: "email_other_mail_advanced_setting_view", params: ["page_type": type.pageType])
        } else {
            MailTracker.log(event: "email_tripartite_advanced_setting_view", params: ["mail_account_type": Store.settingData.getMailAccountType()])
        }
    }

    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag, completion: completion)
        if isFreeBind {
            delegate?.freeBindCancel(imapAccount)
        } else {
            delegate?.cancel(tripartiteAccount)
        }
    }

    func addNotification() {
        EventBus
            .accountChange
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (change) in
                guard let self = self else { return }
                switch change {
                case .accountChange(let change):
                    MailLogger.info("[mail_client] adSetting mail account changed from local: \(change.fromLocal) \(String(describing: change.account.mailSetting.emailClientConfigs.first?.configStatus)) ")
                    guard self.accountContext?.featureManager.realTimeOpen(.newFreeBindMail, openInMailClient: false) == true else { return }
                    let userType = change.account.mailSetting.userType
                    if userType == .oauthClient {
                        self.dismiss(animated: false)
                    }
                case .shareAccountChange(let change):
                    MailLogger.info("[mail_client] adSetting shared account changed isBind: \(change.isBind)")
                case .currentAccountChange:
                    // nothing
                    break
                case .unknow:
                    mailAssertionFailure("accountChange .unknow happen")
                }
            }).disposed(by: disposeBag)

        NotificationCenter.default.addObserver(self, selector: #selector(didReceivedKeyboardWillHideNotification(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didReceivedKeyboardDidShowNotification(_:)), name: UIResponder.keyboardDidShowNotification, object: nil)

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

    @objc
    func didReceivedKeyboardWillHideNotification(_ notify: Notification) {
        if Display.pad { // popver view 写死16即可
            tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 16, right: 0)
        } else {
            tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: Display.bottomSafeAreaHeight + 16, right: 0)
        }
        tableView.scrollIndicatorInsets = .zero
    }

    @objc
    func didReceivedKeyboardDidShowNotification(_ notify: Notification) {
        guard let userinfo = notify.userInfo else {
            return
        }
        guard let keyboardFrame = userinfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }
        let keyboardConvertFrame = tableView.window?.convert(keyboardFrame, to: tableView.superview)
        let newBottomInset = tableView.frame.origin.y + tableView.frame.size.height - keyboardFrame.origin.y
        var bottomOffset: CGFloat = 0
        if Display.bottomSafeAreaHeight == 0 {
            bottomOffset = keyboardFrame.size.height + 16
        } else {
            bottomOffset = keyboardFrame.size.height - 16
        }
        tableView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardFrame.size.height, right: 0)
        var bottom = 16 + Display.bottomSafeAreaHeight + keyboardFrame.size.height
        if Display.pad {
            bottom = 16 + keyboardFrame.size.height
        }
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: bottom, right: 0)
    }

    func headerViewDidClickedLogin(_ footerView: MailClientAdSettingFooterView, scene: MailClientAdSettingScene) {
        if scene == .login || isFreeBind {
            didClickLoginButton()
        } else if scene == .config || scene == .reVerfiy {
            updateConfig(sendReq: true)
        }
    }

    func didSelectTextField(_ textField: UITextField, cell: MailClientAdSettingInputCell, editEnable: Bool) {
        if editEnable {
            let previousEditingIndexPath = editingIndexPath
            editingIndexPath = tableView.indexPath(for: cell)
            guard let editingIndexPath = editingIndexPath else {
                editingField = textField
                return
            }
            tableView.visibleCells
                .compactMap({ $0 as? MailClientAdSettingInputCell })
                .filter({ $0.inputModel?.validateInputBlock != nil })
                .forEach { validateCell in
                    if let indexPath = tableView.indexPath(for: validateCell) {
                        if indexPath == editingIndexPath {
                            validateCell.hideErrorTips = true
                            validateCell.detectInputAndUpdateUIIfNeeded()
                        } else if indexPath == previousEditingIndexPath {
                            validateCell.hideErrorTips = false
                            validateCell.detectInputAndUpdateUIIfNeeded()
                        }
                    }
                }

            /// 触发 table view 高度更新
            tableView.beginUpdates()
            tableView.endUpdates()

            editingField = textField
        } else {
            MailRoundedHUD.showTips(with: BundleI18n.MailSDK.Mail_ThirdClient_CantModifyEmailAddress, on: self.view)
        }
    }

    func focusToNextInput() {
        if let cell = tableView.cellForRow(at: IndexPath.init(row: 1, section: 0)) as? MailClientAdSettingInputCell {
            editingIndexPath = IndexPath.init(row: 1, section: 0)
            editingField = cell.textField.input
            DispatchQueue.main.async { [weak self] in
                self?.editingField?.becomeFirstResponder()
            }
        }
    }

    func didClickLoginButton() {
        // login 发起登陆请求
        if isFreeBind {
            MailTracker.log(event: "email_other_mail_advanced_setting_click", params: ["click": "login", "page_type": type.pageType])
        } else {
            MailTracker.log(event: "email_tripartite_advanced_setting_click", params: ["mail_account_type": Store.settingData.getMailAccountType(), "click": "login", "target": "none"])
        }
        guard let reach = Reachability(), reach.connection != .none else {
            MailRoundedHUD.showTips(with: BundleI18n.MailSDK.Mail_ThirdClient_InternetErrorRetry, on: view)
            footerView.hideLoading()
            tableView.tableFooterView = footerView
            return
        }
        toggleFooterLoading(true)
        if let account = imapAccount {
            Store.fetcher?.imapUserBindAccount(account)
                .subscribe(onNext: { [weak self] status in
                    guard let self = self else { return }
                    self.toggleFooterLoading(false)
                    var errorLogType: String?
                    switch status {
                    case .success:
                        self.dismiss(animated: false, completion: {
                            self.delegate?.loginSuccessInSetting()
                        })
                        self.delegate?.loginSuccessInSetting()
                    case .failForBindByOtherUser:
                        errorLogType = "repetitive_binding"
                        self.showInputError(BundleI18n.MailSDK.Mail_LinkAccount_AccountUsedTryAnother_Error)
                    case .failForPersonalDomain:
                        errorLogType = "personal_mail"
                        self.showInputError(BundleI18n.MailSDK.Mail_LinkAccount_CantLinkPersonalAccount_Error)
                    case .failForLoginCredentialsConflict:
                        errorLogType = "login_failed"
                        self.showInputError(BundleI18n.MailSDK.Mail_LinkAccount_UnableToLinkOtherLogin_Empty_Desc)
                    case .failForBindOtherVerifiedDomain:
                        errorLogType = "domain_already_exists"
                        self.showInputError(BundleI18n.MailSDK.Mail_LinkEmail_DomainHasBeenUsed_Text)
                    case .failForNoDomainConfig, .failForLogin, .failForBindOtherMailAccount, .failForChangeAddressWhenRebind, .unknown:
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
                    MailLogger.info("[Free-Bind] Imap bind request status: \(status.rawValue)")
                }, onError: { [weak self] error in
                    guard let self = self else { return }
                    self.toggleFooterLoading(false)
                    MailLogger.error("[Free-Bind] Imap bind request error: \(error)")
                    MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_LinkAccount_LoginFaileRetry_Toast, on: self.view)
                }).disposed(by: disposeBag)
        } else if let account = tripartiteAccount {
            taskID = UUID().uuidString
            let event = MailAPMEvent.MailClientCreateAccount()
            event.markPostStart()
            apmHolder[MailAPMEvent.MailClientCreateAccount.self] = event
            Store.fetcher?.createTripartiteAccount(taskID: taskID, account: account)
                .subscribe(onNext: { [weak self] (_) in
                    guard let `self` = self else { return }
                    MailLogger.info("[mail_client] login success")
                    self.clientCreateBaseApmInfoFill(account)
                    event.endParams.append(MailAPMEventConstant.CommonParam.status_success)
                    event.postEnd()
                    self.taskID = ""
                    self.toggleFooterLoading(false)
                    self.dismiss(animated: false, completion: {
                        self.delegate?.loginSuccessInSetting()
                        MailTracker.log(event: "email_tripartite_advanced_setting_click", params: ["mail_account_type": Store.settingData.getMailAccountType(), "click": "login", "target": "none", "login_result": "success"])
                    })
                }, onError: { [weak self] (error) in
                    guard let `self` = self else { return }
                    self.clientCreateBaseApmInfoFill(account)
                    event.endParams.appendError(error: error)
                    event.endParams.append(MailAPMEventConstant.CommonParam.status_rust_fail)
                    event.postEnd()
                    MailTracker.log(event: "email_tripartite_advanced_setting_click", params: ["mail_account_type": Store.settingData.getMailAccountType(), "click": "login", "target": "none", "login_result": "failed"])
                    self.taskID = ""
                    self.toggleFooterLoading(false)
                    MailLogger.error("[mail_client] login fail", error: error)
                    let alert = LarkAlertController()
                    alert.setTitle(text: BundleI18n.MailSDK.Mail_ThirdClient_CantLoginTitle)
                    alert.setContent(text: BundleI18n.MailSDK.Mail_ThirdClient_CheckAccountPasswordCorrect, alignment: .center)
                    alert.addSecondaryButton(text: BundleI18n.MailSDK.Mail_ThirdClient_HelpDocsMobile, dismissCompletion: { [weak self] in
                        self?.openHelpGuide()
                    })
                    alert.addPrimaryButton(text: BundleI18n.MailSDK.Mail_ThirdClient_Retry, dismissCompletion: { [weak self] in
                        //self?.didClickLoginButton()
                    })
                    self.navigator?.present(alert, from: self)
                }).disposed(by: self.disposeBag)
        } else {
            mailAssertionFailure("account is nil in advanced setting")
        }
    }

    func clientCreateBaseApmInfoFill(_ account: Email_Client_V1_TripartiteAccount) {
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

    func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section < dataSource.count else { return 0 }
        return dataSource[section].items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.section < dataSource.count,
              indexPath.row < dataSource[indexPath.section].items.count else {
            return UITableViewCell()
        }

        /// config different setting item
        let settingItem = dataSource[indexPath.section].items[indexPath.row]
        if settingItem is MailSettingInputModel {
            var cell = tableView.cellForRow(at: indexPath) as? MailClientAdSettingInputCell
            if (cell == nil) {
                cell = MailClientAdSettingInputCell(style: .default, reuseIdentifier: settingItem.cellIdentifier+"\(indexPath.section)\(indexPath.row)")
            }
            guard let cell = cell else {
                return UITableViewCell()
            }
            cell.pwdInput = indexPath.section == 0 && indexPath.row == 1 // 后面再设计好的实现
            cell.addressInput = indexPath.section == 0 && indexPath.row == 0
            cell.numberOnly = indexPath.section != 0 && indexPath.row == 1
            cell.shouldDetectAddress = scene == .login
            cell.editEnable = (scene == .login ||
                               (scene != .login && (indexPath.section != 0 || indexPath.section == 0 && indexPath.row != 0)))
            cell.delegate = self
            cell.item = settingItem
            if indexPath.row != dataSource[indexPath.section].items.count - 1 {
                cell.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
            }
            if cell.addressInput {
                mailAddressCell = cell
            }
            cell.updateErrorTip = { [weak self] errorTip in
                if var model = self?.dataSource[indexPath.section].items[indexPath.row] as? MailSettingInputModel {
                    model.errorTip = errorTip
                    self?.dataSource[indexPath.section].items[indexPath.row] = model
                }
            }
            cell.contentView.backgroundColor = ModelViewHelper.listColor(vc: self)
            return cell
        } else if settingItem is MailClientSettingProtocolModel {
            var cell = tableView.cellForRow(at: indexPath) as? MailClientAdSettingSelectionCell
            if (cell == nil) {
                cell = MailClientAdSettingSelectionCell(style: .default, reuseIdentifier: settingItem.cellIdentifier+"\(indexPath.section)\(indexPath.row)")
            }
            guard let cell = cell else {
                return UITableViewCell()
            }
            cell.delegate = self
            cell.item = settingItem
            if indexPath.row != dataSource[indexPath.section].items.count - 1 {
                cell.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
            }
            cell.contentView.backgroundColor = ModelViewHelper.listColor(vc: self)
            return cell
        } else if settingItem is MailClientSettingEncryptionModel {
            var cell = tableView.cellForRow(at: indexPath) as? MailClientAdSettingSelectionCell
            if (cell == nil) {
                cell = MailClientAdSettingSelectionCell(style: .default, reuseIdentifier: settingItem.cellIdentifier+"\(indexPath.section)\(indexPath.row)")
            }
            guard let cell = cell else {
                return UITableViewCell()
            }
            cell.delegate = self
            if indexPath.section == 1 {
                cell.type = .proto
            } else if indexPath.section == 2 {
                cell.type = .receiver
            } else if indexPath.section == 3 {
                cell.type = .sender
            } else {
                cell.type = .unknown
            }
            cell.item = settingItem
            if indexPath.row != dataSource[indexPath.section].items.count - 1 {
                cell.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
            }
            cell.contentView.backgroundColor = ModelViewHelper.listColor(vc: self)
            return cell
        } else {

        }
        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 8
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.01
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }

    func setupViews() {
        self.title = scene == .login ? BundleI18n.MailSDK.Mail_ThirdClient_AccountSettings : BundleI18n.MailSDK.Mail_ThirdClient_AdvancedSettings

        if isFreeBind {
            let cancelBtn = UIBarButtonItem(image: UDIcon.closeSmallOutlined,
                                            style: .plain, target: self, action: #selector(cancel))
            navigationItem.leftBarButtonItem = cancelBtn
        } else {
       	    let cancelBtn = LKBarButtonItem(title: BundleI18n.MailSDK.Mail_Common_Cancel)
        	cancelBtn.button.tintColor = UIColor.ud.textTitle
        	cancelBtn.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        	navigationItem.leftBarButtonItem = cancelBtn
        }

        if !type.isTokenLogin() {
            configHelpNavItem()
        }

        /// 添加表格视图
        view.backgroundColor = ModelViewHelper.bgColor(vc: self)
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.leading.trailing.top.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }
    }
    
    func configHelpNavItem() {
        guard !isFreeBind else { return }
        let text = BundleI18n.MailSDK.Mail_ThirdClient_HelpDocsMobile
        let font = UIFont.systemFont(ofSize: 14)
        let helpBtn = UIButton(type: .custom)
        helpBtn.setImage(UDIcon.maybeOutlined.withRenderingMode(.alwaysTemplate), for: .normal)
        helpBtn.imageView?.tintColor = UIColor.ud.iconN2
        helpBtn.setTitle(text, for: .normal)
        helpBtn.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        helpBtn.setTitleColor(UIColor.ud.textCaption, for: .normal)
        helpBtn.tintColor = UIColor.ud.iconN2
        helpBtn.addTarget(self, action: #selector(openHelpGuide), for: .touchUpInside)
        let textWidth = text.getWidth(font: font)
        let btnWidth = 20 + textWidth
        let viewRect = view?.bounds ?? CGRect(origin: .zero, size: CGSize(width: Display.width, height: Display.height))
        helpBtn.frame = CGRect(x: viewRect.width - 16 - btnWidth, y: 56, width: btnWidth, height: 20)
        helpBtn.imageEdgeInsets = UIEdgeInsets(top: 2, left: 0, bottom: 2, right: textWidth + 4)
        helpBtn.titleEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 0)
        helpButton = helpBtn
        let helpItem = UIBarButtonItem(customView: helpBtn)
        helpItem.setTitleTextAttributes([.foregroundColor: UIColor.ud.iconN2], for: .normal)
        navigationItem.rightBarButtonItem = helpItem
        helpBtn.snp.makeConstraints { make in
            make.width.equalTo(btnWidth)
            make.height.equalTo(20)
        }
    }

    @objc
    func openHelpGuide() {
        guard let link = ProviderManager.default.commonSettingProvider?.stringValue(key: "open-imap")?.localLink,
              let url = URL(string: link) else { return }
        UIApplication.shared.open(url)
    }

    @objc
    func cancel() {
        editingField?.resignFirstResponder()
        dismiss(animated: true, completion: nil)
        logFreeBindCancel()
    }
    
    private func logFreeBindCancel() {
        guard isFreeBind else { return }
        var password = 0
        var address = 0
        var imapServer = 0
        var smtpServer = 0
        var imapPort = 0
        var smtpPort = 0
        if let account = imapAccount {
            password = account.password.isEmpty ? 0 : 1
            address = account.imapAddress.isEmpty ? 0 : 1
            imapServer = account.imapAddress.isEmpty ? 0: 1
            imapPort = (account.imapPort == -1) ? 0 : 1
            smtpServer = account.smtpAddress.isEmpty ? 0 : 1
            smtpPort = (account.smtpPort == -1) ? 0 : 1
        }
        MailTracker.log(event: "email_other_mail_advanced_setting_click", params: ["click": "close_page",
                                                                                   "page_type": type.pageType,
                                                                                   "password": password,
                                                                                   "address": address,
                                                                                   "imap_server": imapServer,
                                                                                   "imap_port": imapPort,
                                                                                   "smtp_server": smtpServer,
                                                                                   "smtp_port": smtpPort])

    }

    func setupViewModel() {
        if isFreeBind {
            MailLogger.info("[Free-Bind] get Imap account config accountID: \(accountID)")
            MailDataServiceFactory
                .commonDataService?
                .fetchSmtpImapConfig(mailAddress: scene == .reVerfiy ? nil : imapAccount?.mailAddress)
                .subscribe(onNext: { [weak self] (resp) in
                    guard let `self` = self else { return }
                    self.imapAccount?.imapAddress = resp.imapAddress
                    self.imapAccount?.smtpAddress = resp.smtpAddress
                    if resp.hasImapPort {
                        self.imapAccount?.imapPort = resp.imapPort
                    }
                    if resp.hasSmtpPort {
                        self.imapAccount?.smtpPort = resp.smtpPort
                    }
                    self.didLoadFlag = true
                    self.reloadLocalData()
                }, onError: { (error) in
                    self.reloadLocalData()
                    MailLogger.error("[Free-Bind] get Imap account config error: \(error)")
                }).disposed(by: disposeBag)
        } else if scene == .login || accountID.isEmpty {
            reloadLocalData()
        } else {
            MailLogger.info("[mail_client] getTripartiteAccountConfig accountID: \(accountID)")
            MailDataServiceFactory
                .commonDataService?
                .getTripartiteAccountConfig(accountID: accountID)
                .subscribe(onNext: { [weak self] (resp) in
                    guard let `self` = self else { return }
                    self.tripartiteAccount = resp.account
                    self.type = resp.account.provider
                    self.reloadLocalData()
                }, onError: { (error) in
                    MailLogger.error("[mail_client] getTripartiteAccountConfig fail error:\(error)")
                }).disposed(by: disposeBag)
        }
    }

    func reloadLocalData() {
        hideLoading()
        dataSource = makeDataSource()
        tableView.reloadData()
        tableView.tableFooterView?.isHidden = false
        updateLoginButtonStatus()
        didLoadFlag = true
        helpButton?.isHidden = tripartiteAccount?.receiver.protocol == .exchange
        guard isFreeBind,
              let address = imapAccount?.mailAddress,
              !address.isEmpty,
              !address.isLegalForEmail()
        else { return }
        showInputError(BundleI18n.MailSDK.Mail_ThirdClient_EnterValidAddress)
    }

    private func updateLoginButtonStatus() {
        guard scene == .login || isFreeBind else { return }
        if let account = self.tripartiteAccount {
            let canLogin = account.address.isLegalForEmail() && !Store.settingData.checkRepeatAddress(account.address)
            && !account.pass.authCode.isEmpty && !account.sender.domain.isEmpty && account.sender.port != -1
            && !account.receiver.domain.isEmpty && account.receiver.port != -1
            footerView.enableLogin(canLogin)
            tableView.tableFooterView = footerView
        } else if let account = self.imapAccount {
            let isAllValidate = domainValidateBlock(account.imapAddress ?? "") == nil && domainValidateBlock(account.smtpAddress ?? "") == nil && portValidateBlock("\(account.imapPort)") == nil && portValidateBlock("\(account.smtpPort)") == nil
            let canLogin = account.mailAddress.isLegalForEmail() && !Store.settingData.checkRepeatAddress(account.mailAddress)
            && !account.password.isEmpty && !account.imapAddress.isEmpty && account.imapPort != -1
            && !account.smtpAddress.isEmpty && account.smtpPort != -1 && isAllValidate
            footerView.enableLogin(canLogin)
            tableView.tableFooterView = footerView
        }
    }
    
    private func toggleFooterLoading(_ loading: Bool) {
        if loading {
            footerView.showLoading()
        } else {
            footerView.hideLoading()
        }
        tableView.tableFooterView = footerView
    }

    func didSelectProtocol() {
        // 暂时不支持修改
        return
        let source = UDActionSheetSource(sourceView: view, sourceRect: view.bounds, arrowDirection: .up)
        let pop = UDActionSheet(config: UDActionSheetUIConfig(isShowTitle: true, popSource: source))
        pop.setTitle(BundleI18n.MailSDK.Mail_ThirdClient_ServerType)
        let serverTypes: [MailClientProtocol] = [.IMAP, .POP3, .EXCHANGE, .SMTP]
        for proto in serverTypes {
            pop.addDefaultItem(text: proto.rawValue) { [weak self] in
                guard let `self` = self else { return }
                // 更新Setting操作
            }
        }
        pop.setCancelItem(text: BundleI18n.MailSDK.Mail_Alert_Cancel) {
            MailLogger.info("ProtoTypeClick Cancle")
        }
        navigator?.present(pop, from: self)
    }

    func didSelectEncryption(_ type: MailClientAdSettingSelectionCell.ClientSelectType,
                             cell: MailClientAdSettingCell) {
        editingField?.resignFirstResponder()
        if rootSizeClassIsSystemRegular {
            var popoverFrame: CGRect = .zero
            let sourceView: UIView? = cell
            if type == .sender {
                let row = IndexPath.init(row: 2, section: 3)
                let cellRect = tableView.rectForRow(at: row)
                popoverFrame = cellRect
            } else if type == .receiver {
                let row = IndexPath.init(row: 2, section: 2)
                let cellRect = tableView.rectForRow(at: row)
                popoverFrame = cellRect
            } else {
                popoverFrame = view?.frame ?? tableView.frame
            }
            showEncryptionPopover(type, addressFrame: popoverFrame, sourceView: sourceView)
        } else {
            showEncryptionActionSheet(type)
        }
    }

    private func showInputError(_ text: String) {
        guard tableView.numberOfSections > 0 else { return }
        let indexPath = IndexPath(row: 0, section: 0)
        UIView.animate(withDuration: 0.3) {
            self.tableView.scrollToRow(at: indexPath, at: .top, animated: false)
        } completion: { [weak self] _ in
            self?.mailAddressCell?.showDetectTips(text)
            self?.tableView.beginUpdates()
            self?.tableView.endUpdates()
        }
    }

    private func showEncryptionPopover(_ type: MailClientAdSettingSelectionCell.ClientSelectType, addressFrame: CGRect, sourceView: UIView?) {
        var items: [PopupMenuActionItem] = []
        let serverTypes = makeEncryptionTypes(type)

        for encryption in serverTypes {
            let encryptionItem = PopupMenuActionItem(title: encryption.rawValue, icon: UIImage()) { [weak self] (_, item) in
                guard let `self` = self else { return }
                self.updateEncryptionSetting(type: type, encryption: encryption)
            }
            items.append(encryptionItem)
        }
        let vc = PopupMenuPoverViewController(items: items)
        vc.hideIconImage = true
        vc.modalPresentationStyle = .popover
        vc.popoverPresentationController?.backgroundColor = UIColor.ud.bgBody
        vc.popoverPresentationController?.sourceView = sourceView
        if let bounds = sourceView?.bounds {
            vc.popoverPresentationController?.sourceRect = bounds
        }
        vc.popoverPresentationController?.permittedArrowDirections = type == .sender ? .down : .up
        vc.preferredContentSize = CGSize(width: 68, height: 160)
        navigator?.present(vc, from: self)
    }

    private func showEncryptionActionSheet(_ type: MailClientAdSettingSelectionCell.ClientSelectType) {
        let source = UDActionSheetSource(sourceView: view, sourceRect: view.bounds, arrowDirection: .up)
        let pop = UDActionSheet(config: UDActionSheetUIConfig(isShowTitle: true, popSource: source))
        pop.setTitle(BundleI18n.MailSDK.Mail_ThirdClient_SecureType)
        let serverTypes = makeEncryptionTypes(type)

        for encryption in serverTypes {
            pop.addDefaultItem(text: encryption.rawValue) { [weak self] in
                guard let `self` = self else { return }
                self.updateEncryptionSetting(type: type, encryption: encryption)
            }
        }
        pop.setCancelItem(text: BundleI18n.MailSDK.Mail_Alert_Cancel) {
            MailLogger.info("EncryptionTypeClick Cancle")
        }
        navigator?.present(pop, from: self)
    }

    private func makeEncryptionTypes(_ type: MailClientAdSettingSelectionCell.ClientSelectType) -> [MailClientEncryption] {
        var serverTypes = [MailClientEncryption]()
        if isFreeBind {
            serverTypes = [.SSL]
        } else {
            if type == .receiver {
                serverTypes = [.SSL, .None]
            } else {
                serverTypes = [.SSL, .STARTLS, .None]
            }
        }
        return serverTypes
    }

    func updateEncryptionSetting(type: MailClientAdSettingSelectionCell.ClientSelectType, encryption: MailClientEncryption) {
        // 更新Setting操作
        if type == .sender {
            self.tripartiteAccount?.sender.encryption = self.transEncryptionToPB(encry: encryption)
            if encryption == .SSL {
                self.tripartiteAccount?.sender.port = 465
            } else if encryption == .STARTLS {
                self.tripartiteAccount?.sender.port = 587
            } else if encryption == .None {
                self.tripartiteAccount?.sender.port = 25
            }
        } else if type == .receiver {
            self.tripartiteAccount?.receiver.encryption = self.transEncryptionToPB(encry: encryption)
            if encryption == .SSL {
                self.tripartiteAccount?.receiver.port = 993
            } else if encryption == .None {
                self.tripartiteAccount?.receiver.port = 143
            }
        }
        self.updateConfig()
    }


    func updateConfig(reload: Bool = true, sendReq: Bool = false) {
        dataSource = makeDataSource()
        updateLoginButtonStatus()
        guard !isFreeBind, sendReq else {
            if reload {
                self.reloadLocalData()
            }
            return
        }
        guard let account = tripartiteAccount else { return }
        footerView.showLoading()
        tableView.tableFooterView = footerView
        MailLogger.info("[mail_client] updateTripartiteAccountConfig accountID \(accountID)")
        let taskID = UUID().uuidString
        let event = MailAPMEvent.MailClientUpdateAccountConfig()
        event.markPostStart()
        apmHolder[MailAPMEvent.MailClientUpdateAccountConfig.self] = event
        MailDataServiceFactory
            .commonDataService?
            .updateTripartiteAccountConfig(accountID: accountID, taskID: taskID, receiver: account.receiver, sender: account.sender, pass: account.pass)
            .subscribe(onNext: { [weak self] (resp) in
                guard let `self` = self else { return }
//                self.account = resp.account
                MailLogger.info("[mail_client] updateTripartiteAccountConfig success")
                self.clientBaseApmInfoFill(account)
                event.endParams.append(MailAPMEventConstant.CommonParam.status_success)
                event.postEnd()
                if self.scene != .reVerfiy {
                    MailRoundedHUD.showSuccess(with: BundleI18n.MailSDK.Mail_ThirdClient_AccountNameUpdated, on: self.view)
                }
                if reload {
                    self.reloadLocalData()
                }
                if self.scene == .reVerfiy || self.scene == .config {
                    self.dismiss(animated: true)
                }
            }, onError: { [weak self] (error) in
                guard let `self` = self else { return }
                self.clientBaseApmInfoFill(account)
                event.endParams.appendError(error: error)
                event.endParams.append(MailAPMEventConstant.CommonParam.status_rust_fail)
                event.postEnd()
                let alert = LarkAlertController()
                alert.setTitle(text: BundleI18n.MailSDK.Mail_ThirdClient_UnableToLogIn)
                if self.tripartiteAccount?.receiver.protocol == .exchange {
                    alert.setContent(text: BundleI18n.MailSDK.Mail_ThirdClient_CheckAccountPasswordCorrect, alignment: .center)
                    alert.addPrimaryButton(text: BundleI18n.MailSDK.Mail_ThirdClient_OK, dismissCompletion: nil)
                } else {
                    alert.setContent(text: BundleI18n.MailSDK.Mail_ThirdClient_UnableToLogInDesc, alignment: .center)
                    alert.addSecondaryButton(text: BundleI18n.MailSDK.Mail_ThirdClient_ViewGuide, dismissCompletion: { [weak self] in
                        self?.openHelpGuide()
                    })
                    alert.addPrimaryButton(text: BundleI18n.MailSDK.Mail_ThirdClient_OK, dismissCompletion: nil)
                }
                self.navigator?.present(alert, from: self)
                MailLogger.error("[mail_client] updateTripartiteAccountConfig fail error:\(error)")
                self.footerView.hideLoading()
                self.tableView.tableFooterView = self.footerView
            }).disposed(by: disposeBag)
    }

    func clientBaseApmInfoFill(_ account: Email_Client_V1_TripartiteAccount) {
        let provider = MailAPMEvent.MailClientUpdateAccountConfig.EndParam.provider(account.provider.apmValue())
        apmHolder[MailAPMEvent.MailClientUpdateAccountConfig.self]?.endParams.append(provider)
        let loginPassType = MailAPMEvent.MailClientUpdateAccountConfig.EndParam.login_pass_type(account.pass.type.apmValue())
        apmHolder[MailAPMEvent.MailClientUpdateAccountConfig.self]?.endParams.append(loginPassType)
        let protocolType = MailAPMEvent.MailClientUpdateAccountConfig.EndParam.client_protocol(account.apmProtocolValue())
        apmHolder[MailAPMEvent.MailClientUpdateAccountConfig.self]?.endParams.append(protocolType)
        let receiverEncryptionType = MailAPMEvent.MailClientUpdateAccountConfig.EndParam.client_protocol(account.receiver.apmEncryptionValue())
        apmHolder[MailAPMEvent.MailClientUpdateAccountConfig.self]?.endParams.append(receiverEncryptionType)
        let senderEncryptionType = MailAPMEvent.MailClientUpdateAccountConfig.EndParam.client_protocol(account.sender.apmEncryptionValue())
        apmHolder[MailAPMEvent.MailClientUpdateAccountConfig.self]?.endParams.append(senderEncryptionType)
    }

    @objc
    func networkChanged() {
        guard let reachablility = reachability else {
            return
        }
        guard connection != reachablility.connection else {
            MailLogger.info("mail network changed repeat at mailClientAdSetting")
            return
        }
        MailLogger.info("mail network changed at mailClientAdSetting")
        connection = reachablility.connection
        if reachablility.connection == .none, !taskID.isEmpty {
            // 取消请求 弹toast
            MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_ThirdClient_NetworkErrorTryAgain, on: self.view)
            Store.fetcher?.cancelCreateTripartiteAccount(taskID: taskID)
                .subscribe(onNext: { [weak self] (_) in
                    MailLogger.info("[mail_client] cancel login success")
                    self?.taskID = ""
                }, onError: { [weak self] (error) in
                    guard let `self` = self else { return }
                    MailLogger.error("[mail_client] cancel login fail", error: error)
                    self.footerView.hideLoading()
                    self.tableView.tableFooterView = self.footerView
                }).disposed(by: self.disposeBag)
        }
    }
}

extension MailClientAdvanceSettingViewController: UDNoticeDelegate {
    func handleLeadingButtonEvent(_ button: UIButton) {}
    
    func handleTrailingButtonEvent(_ button: UIButton) { }
    
    func handleTextButtonEvent(URL: URL, characterRange: NSRange) {
        guard URL.safeURLString == ActionableTextView.kURLString else { return }
        opendSettingPage()
    }

    func opendSettingPage() {
        guard let localLink = self.serviceProvider?.provider.settingConfig?.linkConfig?.serverHelp.localLink else {
            MailLogger.info("no link config")
            return
        }
        guard let url = URL(string: localLink) else { return }
        UIApplication.shared.open(url)
        MailTracker.log(event: "email_other_mail_advanced_setting_click", params: ["click": "how_to_get_setting", "page_type": type.pageType])
    }
}

// Data Helper
extension MailClientAdvanceSettingViewController {
    private func makeDataSource() -> [MailSettingSectionModel] {
        if tripartiteAccount?.receiver.protocol == .exchange {
            return [makeLoginPassSection(),
                    makeProviderSection(),
                    makeReceviverConfigSection(containDomain: false)]
        } else if isFreeBind {
            return [makeLoginPassSection(),
                    makeReceviverConfigSection(),
                    makeSenderConfigSection()]
        } else {
            return [makeLoginPassSection(),
                    makeProviderSection(),
                    makeReceviverConfigSection(),
                    makeSenderConfigSection()]
        }
    }
    // 账号信息
    private func makeLoginPassSection() -> MailSettingSectionModel {
        let address = (isFreeBind ? imapAccount?.mailAddress : tripartiteAccount?.address) ?? ""
        let pass = (isFreeBind ? imapAccount?.password : tripartiteAccount?.pass.authCode) ?? ""
        let validateBlock: (String) -> String? = { address in
            if !(address.isLegalForEmail() || address.isEmpty) {
                return BundleI18n.MailSDK.Mail_ThirdClient_EnterValidAddress
            } else if Store.settingData.checkRepeatAddress(address) {
                return BundleI18n.MailSDK.Mail_ThirdClient_EmailAccountExisted
            } else {
                return nil
            }
        }
        let addressTitle = TitleType.normal(title: BundleI18n.MailSDK.Mail_ThirdClient_EmailAddress)
        let addressModel = MailSettingItemFactory
            .createClientInputModel(accountId: accountID, title: addressTitle,
                                    placeholder: BundleI18n.MailSDK.Mail_ThirdClient_EnterEmailAddress,
                                    content: address, validateBlock: validateBlock) { [weak self] content in
                if self?.isFreeBind == true {
                    self?.imapAccount?.mailAddress = content
                } else {
                    self?.tripartiteAccount?.address = content
                }
                self?.updateConfig(reload: false)
            }
        let passwordTitle = TitleType.normal(title: BundleI18n.MailSDK.Mail_ThirdClient_Password)
        let pwdModel = MailSettingItemFactory
            .createClientInputModel(accountId: accountID, title: passwordTitle,
                                    placeholder: BundleI18n.MailSDK.Mail_ThirdClient_EnterPassword,
                                    content: pass) { [weak self] content in
                if self?.isFreeBind == true {
                    self?.imapAccount?.password = content
                } else {
                    self?.tripartiteAccount?.pass.authCode = content
                }
                self?.updateConfig(reload: false)
            }
        return MailSettingSectionModel(items: [addressModel, pwdModel])
    }

    // 协议选择
    private func makeProviderSection() -> MailSettingSectionModel {
        var proto: MailClientProtocol = .IMAP
        if let receiverConfig = tripartiteAccount?.receiver {
            if receiverConfig.protocol == .exchange {
                proto = .EXCHANGE
            }
        }
        let providerModel = MailSettingItemFactory
            .createClientProtocolModel(accountId: accountID,
                                       title: BundleI18n.MailSDK.Mail_ThirdClient_ServerType, proto: proto)
        return MailSettingSectionModel(items: [providerModel])
    }

    // 收信服务器
    private func makeReceviverConfigSection(containDomain: Bool = true) -> MailSettingSectionModel {
        var domain = ""
        if let domainStr = (isFreeBind ? imapAccount?.imapAddress : tripartiteAccount?.receiver.domain) {
            domain = domainStr
        }
        if !didLoadFlag && type == .other && scene == .login {
            domain = ""
        }
        receiverTips = "imap.example.com" // 改需求写死提示了
        let domainValidateBlock = isFreeBind ? domainValidateBlock : nil
        let title: String = {
            if tripartiteAccount?.sender.protocol == .exchange {
                return BundleI18n.MailSDK.Mail_Shared_AddEAS_ServerDomain_FieldName
            } else {
                return BundleI18n.MailSDK.Mail_ThirdClient_ReceiveServer
            }
        }()
        // freeBind和三方title相同
        let serverTitle = titleType(freeBindTitle: title, thirdClientTitle: title) {[weak self] in
            self?.showAlert(title: title,
                            message: BundleI18n.MailSDK.Mail_LinkMail_IMAPPortFormat_Desc,
                            buttonTitle: BundleI18n.MailSDK.Mail_LinkMail_SMTP_ClickForGuide_Bttn, buttonClick: {[weak self] in
                self?.opendSettingPage()
            })
        }
        let domainModel = MailSettingItemFactory
            .createClientInputModel(accountId: accountID, title: serverTitle,
                                    placeholder: receiverTips,
                                    content: domain, validateBlock: domainValidateBlock) { [weak self] content in
                if self?.isFreeBind == true {
                    self?.imapAccount?.imapAddress = content
                } else {
                    self?.tripartiteAccount?.receiver.domain = content
                }
                
                self?.updateConfig(reload: false)
            }
        let portValidateBlock = isFreeBind ? portValidateBlock : nil
        var port = ""
        if let portInt = (isFreeBind ? imapAccount?.imapPort : tripartiteAccount?.receiver.port), portInt != -1 {
            port = "\(portInt)"
        }
        let imapTitle = titleType(freeBindTitle: BundleI18n.MailSDK.Mail_LinkMail_IMAPPort_Name,
                                  thirdClientTitle: BundleI18n.MailSDK.Mail_ThirdClient_ReceivePort,
                                  clickBlock: {[weak self] in
            self?.showAlert(title: BundleI18n.MailSDK.Mail_LinkMail_IMAPPort_Name,
                            message: BundleI18n.MailSDK.Mail_LinkMail_IMAPPort_Desc,
                            buttonTitle: BundleI18n.MailSDK.Mail_LinkMail_IMAPPort_LearnMore_Bttn, buttonClick: {[weak self] in
                self?.opendSettingPage()
            })
        })
        let portModel = MailSettingItemFactory
            .createClientInputModel(accountId: accountID, title: imapTitle,
                                    placeholder: BundleI18n.MailSDK.Mail_ThirdClient_993Example,
                                    content: port, validateBlock: portValidateBlock) { [weak self] content in
                if self?.isFreeBind == true {
                    self?.imapAccount?.imapPort = Int32(content) ?? -1
                } else {
                    self?.tripartiteAccount?.receiver.port = Int32(content) ?? -1
                }
                self?.updateConfig(reload: false)
            }
        let receiverEncry = transEncryptionType(encry: isFreeBind ? .ssl : tripartiteAccount?.receiver.encryption)
        let encryptionModel = MailSettingItemFactory
            .createClientEncryptionModel(accountId: accountID, title: BundleI18n.MailSDK.Mail_ThirdClient_SecureType, canSelect: true,
                                         encryption: receiverEncry) { [weak self] encryption in /* .SSL */
                guard let `self` = self else { return }
                self.tripartiteAccount?.receiver.encryption = self.transEncryptionToPB(encry: encryption)
                self.updateConfig()
            }
        if isFreeBind {
            return MailSettingSectionModel(items: containDomain ? [domainModel, portModel] : [domainModel])
        } else {
            return MailSettingSectionModel(items: containDomain ? [domainModel, portModel, encryptionModel] : [domainModel, encryptionModel])
        }
    }

    // 发信服务器
    private func makeSenderConfigSection() -> MailSettingSectionModel {
        var domain = ""
        if let domainStr = (isFreeBind ? imapAccount?.smtpAddress : tripartiteAccount?.sender.domain) {
            domain = domainStr
        }
        if !didLoadFlag && type == .other && scene == .login {
            domain = ""
        }
        senderTips = "smtp.example.com" // 改需求写死提示了
        let domainValidateBlock = isFreeBind ? domainValidateBlock : nil

        // freeBind和三方title相同
        let serverTitle = titleType(freeBindTitle: BundleI18n.MailSDK.Mail_ThirdClient_SendServer,
                                    thirdClientTitle: BundleI18n.MailSDK.Mail_ThirdClient_SendServer) { [weak self] in
            self?.showAlert(title: BundleI18n.MailSDK.Mail_ThirdClient_SendServer,
                            message: BundleI18n.MailSDK.Mail_LinkMail_SMTPPort_Desc,
                            buttonTitle: BundleI18n.MailSDK.Mail_LinkMail_SMTP_ClickForGuide_Bttn, buttonClick: {[weak self] in
                self?.opendSettingPage()
            })
        }
        let domainModel = MailSettingItemFactory
            .createClientInputModel(accountId: accountID, title: serverTitle,
                                    placeholder: senderTips,
                                    content: domain, validateBlock: domainValidateBlock) { [weak self] content in
                if self?.isFreeBind == true {
                    self?.imapAccount?.smtpAddress = content
                } else {
                    self?.tripartiteAccount?.sender.domain = content
                }
                self?.updateConfig(reload: false)

            }
        var port = ""
        if let portInt = (isFreeBind ? imapAccount?.smtpPort : tripartiteAccount?.sender.port), portInt != -1 {
            port = "\(portInt)"
        }
        let portValidateBlock = isFreeBind ? portValidateBlock : nil
        let smtpTitle = titleType(freeBindTitle: BundleI18n.MailSDK.Mail_LinkMail_SMTPPort_Name,
                                  thirdClientTitle: BundleI18n.MailSDK.Mail_ThirdClient_SendPort,
                                  clickBlock: {[weak self] in
            self?.showAlert(title: BundleI18n.MailSDK.Mail_LinkMail_SMTPPort_Name,
                            message: BundleI18n.MailSDK.Mail_LinkMail_CommonSMTPPortNumber_Desc,
                            buttonTitle: BundleI18n.MailSDK.Mail_LinkMail_IMAPPort_LearnMore_Bttn, buttonClick: { [weak self] in
                self?.opendSettingPage()
            })
        })
        let portModel = MailSettingItemFactory
            .createClientInputModel(accountId: accountID, title: smtpTitle,
                                    placeholder: BundleI18n.MailSDK.Mail_ThirdClient_465Example,
                                    content: port, validateBlock: portValidateBlock) { [weak self] content in
                if self?.isFreeBind == true {
                    self?.imapAccount?.smtpPort = Int32(content) ?? -1
                } else {
                    self?.tripartiteAccount?.sender.port = Int32(content) ?? -1
                }
                
                self?.updateConfig(reload: false)
            }
        let senderEncry = transEncryptionType(encry: isFreeBind ? .ssl : tripartiteAccount?.sender.encryption)
        let encryptionModel = MailSettingItemFactory
            .createClientEncryptionModel(accountId: accountID, title: BundleI18n.MailSDK.Mail_ThirdClient_SecureType, canSelect: true,
                                         encryption: senderEncry) { [weak self] encryption in /* .SSL */
                guard let `self` = self else { return }
                self.tripartiteAccount?.sender.encryption = self.transEncryptionToPB(encry: encryption)
                self.updateConfig()
            }

        if isFreeBind {
            return MailSettingSectionModel(items: [domainModel, portModel])
        } else {
            return MailSettingSectionModel(items: [domainModel, portModel, encryptionModel])
        }
    }

    private func titleType(freeBindTitle: String, thirdClientTitle: String, clickBlock: @escaping () -> Void) -> TitleType {
        if isFreeBind {
            return TitleType.infoButton(title: freeBindTitle, clickBlock: clickBlock)
        } else {
            return TitleType.normal(title: thirdClientTitle)
        }
    }

    private func transEncryptionType(encry: Email_Client_V1_ProtocolConfig.Encryption?) -> MailClientEncryption {
        guard let encry = encry else {
            return .None
        }
        let nativeEncryption: MailClientEncryption?
        switch encry {
        case .ssl:
            nativeEncryption = .SSL
        case .starttls:
            nativeEncryption = .STARTLS
        case .none:
            nativeEncryption = .None
        @unknown default:
            nativeEncryption = .None
        }
        return nativeEncryption ?? .None
    }

    private func transEncryptionToPB(encry: MailClientEncryption) -> Email_Client_V1_ProtocolConfig.Encryption {
        let pbEncryption: Email_Client_V1_ProtocolConfig.Encryption?
        switch encry {
        case .SSL:
            pbEncryption = .ssl
        case .STARTLS:
            pbEncryption = .starttls
        case .None:
            pbEncryption = .none
        @unknown default:
            pbEncryption = .none
        }
        return pbEncryption ?? .none
    }

    private func showAlert(title: String, message: String, buttonTitle: String, buttonClick: @escaping () -> Void) {
        var dialog = UDDialog()
        dialog.setTitle(text: title)
        dialog.setContent(text: message)
        dialog.addSecondaryButton(text: buttonTitle, dismissCompletion: buttonClick)
        dialog.addButton(text: BundleI18n.MailSDK.Mail_Common_OK_Button)
        self.present(dialog, animated: true)
    }
}
