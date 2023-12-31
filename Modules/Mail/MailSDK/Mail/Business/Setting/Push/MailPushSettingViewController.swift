//
//  MailPushSettingViewController.swift
//  MailSDK
//
//  Created by majx on 2020/9/15.
//

import UIKit
import LarkUIKit
import RxSwift
import EENavigator
import Homeric
import LarkAlertController
import RxCocoa
import RxDataSources
import RustPB
import UniverseDesignCheckBox
import FigmaKit
import UniverseDesignFont

protocol MailPushSettingDelegate: AnyObject {
    func updatePushSwitch(enable: Bool)
}

final class MailPushSettingViewController: MailBaseViewController, UITableViewDelegate, UITableViewDataSource {
    var viewModel: MailSettingViewModel?
    var accountId: String?

    private let disposeBag = DisposeBag()
    private var accountSetting: MailAccountSetting?
    private var dataSource: [MailSettingPushModel] = []
    private var typeDataSource: [MailSettingPushTypeModel] = []
    private var pushSwitchModel: MailSettingSwitchModel?
    private var scopeDataSource: [MailSettingPushScopeModel] = []
    private var hasScope: Bool = false
    private var allSwitch: Bool = false
    private var accountContext: MailAccountContext?
    weak var delegate: MailPushSettingDelegate?
    var viewWidth: CGFloat = 0

    init(viewModel: MailSettingViewModel?, accountContext: MailAccountContext?) {
        self.viewModel = viewModel
        self.accountContext = accountContext
        self.accountId = accountContext?.accountID ?? ""
        super.init(nibName: nil, bundle: nil)
    }

    override var serviceProvider: MailSharedServicesProvider? {
        accountContext
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        delegate?.updatePushSwitch(enable: allSwitch)
    }
    


    override func viewDidLoad() {
        super.viewDidLoad()
        viewWidth = view.bounds.width - 32 - 48 - 16
        setupViews()
        setupViewModel()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel?.viewController = self
    }

    override var navigationBarTintColor: UIColor {
        return UIColor.ud.bgFloatBase
    }

    func setupViews() {
        view.backgroundColor = UIColor.ud.bgFloatBase
        /// 添加表格视图
        title = BundleI18n.MailSDK.Mail_Setting_NewEmailNotification
        view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalTo(0)
        }
    }

    func setupViewModel() {
        if viewModel == nil, let accountContext = accountContext {
            viewModel = MailSettingViewModel(accountContext: accountContext)
        } else {
            reloadData()
        }
        self.viewModel?.refreshDriver.drive(onNext: { [weak self] () in
            guard let `self` = self else { return }
            self.reloadData()
        }).disposed(by: disposeBag)
    }
    
    func reloadData() {
        if let accountSetting = viewModel?.getPrimaryAccountSetting() {
            self.accountSetting = accountSetting
            accountId = accountSetting.account.mailAccountID
            dataSource = createPushSettingSection(by: accountSetting.account)
            if Store.settingData.clientStatus != .mailClient {
                typeDataSource = createPushTypeSettingSection(by: accountSetting.account)
            }
            scopeDataSource = createPushScopeSettingSection(by: accountSetting.account)
            hasScope = (accountSetting.setting.notificationScope != .default)
            pushSwitchModel = createMailPushSwitchModel(by: accountSetting.account)
            allSwitch = pushSwitchModel?.status ?? false
        }
        tableView.reloadData()
    }

    private func logClickAction(clickInfo: String, status: Bool) {
        MailTracker.log(event: "email_lark_setting_click",
                        params: ["click": clickInfo, "target": "none", "status": status ? "check" : "uncheck"])
    }

    private func createPushSettingSection(by account: MailAccount) -> [MailSettingPushModel] {
        let accountId = account.mailAccountID
        var mailPushSettings: [MailSettingPushModel] = [MailSettingItemFactory.createAccountMailPushModel(status: account.mailSetting.newMailNotification,
                                                                                                          accountId: account.mailAccountID,
                                                                                                          address: account.accountAddress) { [weak self](status) in
            guard let `self` = self else { return }
            self.viewModel?.getAccountSetting(of: accountId)?.updateSettings(.newMailNotification(enable: status))
            self.changeStatus(accountId, status: status)
            self.tableView.reloadData()
        }]

        let accountStatus = account.mailSetting.emailClientConfigs.first?.configStatus
        let userType = account.mailSetting.userType
        let accountType = MailSettingItemFactory.getAccountStatusType(userType: userType, status: accountStatus)
        if Store.settingData.clientStatus == .mailClient || Store.settingData.isInIMAPFlow(account) || accountType == .noAccountAttach {
            // 跟共存那块一起优化
            mailPushSettings.removeAll()
        }
        let sharedAccounts = account.sharedAccounts
        if !sharedAccounts.isEmpty {
            mailPushSettings.append(contentsOf: sharedAccounts
                .sorted{ $0.mailSetting.userType.priorityValue() > $1.mailSetting.userType.priorityValue() }
                .map {
                    let accountId = $0.mailAccountID
                    return MailSettingItemFactory.createAccountMailPushModel(status: $0.mailSetting.newMailNotification,
                                                                             accountId: $0.mailAccountID,
                                                                             address: $0.accountAddress) { [weak self] (status) in
                        guard let `self` = self else { return }
                        self.changeStatus(accountId, status: status)
                        self.tableView.reloadData()
                        self.viewModel?.getAccountSetting(of: accountId)?.updateSettings(.newMailNotification(enable: status))
                    }
                })
        }
        return mailPushSettings
    }

    func changeStatus(_ accountId: String, status: Bool) {
        var targetIndex = -1
        for (index, viewModel) in dataSource.enumerated() where accountId == viewModel.accountId {
            targetIndex = index
        }
        if targetIndex != -1 {
            dataSource[targetIndex].status = status
        }
    }

    func createPushScopeSettingSection(by account: MailAccount) -> [MailSettingPushScopeModel] {
        let accountId = account.mailAccountID
        let allScope = MailSettingPushScopeModel(cellIdentifier: MailSettingPushCell.lu.reuseIdentifier,
                                                 accountId: account.mailAccountID,
                                                 title: BundleI18n.MailSDK.Mail_Settings_NewMailNotification_NotificationScope_AllNewEmails,
                                                 scope: .all,
                                                 status: account.mailSetting.notificationScope == .all,
                                                 clickHandler: { [weak self] in
            guard let `self` = self,
                  self.scopeDataSource[0].status == false else { return } // 过滤掉选项已经选择的情况
            self.viewModel?.getAccountSetting(of: accountId)?.updateSettings(.newMailNotificationScope(.all))
            self.updateScopeLocalValue(.all)
            self.tableView.reloadData()
        })
        let inboxScope = MailSettingPushScopeModel(cellIdentifier: MailSettingPushCell.lu.reuseIdentifier,
                                                   accountId: account.mailAccountID,
                                                   title: BundleI18n.MailSDK.Mail_Settings_NewMailNotification_NotificationScope_InboxOnly,
                                                   scope: .inboxOnly,
                                                   status: account.mailSetting.notificationScope == .inboxOnly,
                                                   clickHandler: { [weak self] in
            guard let `self` = self,
                  self.scopeDataSource[1].status == false else { return } // 过滤掉选项已经选择的情况
            self.viewModel?.getAccountSetting(of: accountId)?.updateSettings(.newMailNotificationScope(.inboxOnly))
            self.updateScopeLocalValue(.inboxOnly)
            self.tableView.reloadData()
        })
        return [allScope, inboxScope]
    }

    func updateScopeLocalValue(_ scope: MailNotificationScope) {
        // 乐观更新本地数据
        let tempDataSource = scopeDataSource
        for index in tempDataSource.indices {
            scopeDataSource[index].status = (scopeDataSource[index].scope == scope)
        }
    }

    func createPushTypeSettingSection(by account: MailAccount) -> [MailSettingPushTypeModel] {
        let accountId = account.mailAccountID

        let pushType = MailSettingPushTypeModel(
            cellIdentifier: MailSettingPushCell.lu.reuseIdentifier,
            accountId: account.mailAccountID,
            title: BundleI18n.MailSDK.Mail_Settings_BannerNotification,
            status: account.mailSetting.newMailNotificationChannel >> 0 & 1 != 0,
            channel: account.mailSetting.newMailNotificationChannel,
            switchHandler: { [weak self] status in
                self?.viewModel?.getAccountSetting(of: accountId)?.updateSettings(.newMailNotificationChannel(.push, enable: status))
                let newChannel = Store.settingData.changeChannel(
                    oldChannel: self?.typeDataSource[0].channel ?? account.mailSetting.newMailNotificationChannel,
                    channel: .push, enable: status)
                self?.updateChannelLocalValue(newChannel)
                self?.typeDataSource[0].status = status
                self?.tableView.reloadData()
                self?.logClickAction(clickInfo: "banner_hint", status: status)
            }, type: .push)

        let botType = MailSettingPushTypeModel(
            cellIdentifier: MailSettingPushCell.lu.reuseIdentifier,
            accountId: account.mailAccountID,
            title: BundleI18n.MailSDK.Mail_Settings_MessageNotification,
            status: account.mailSetting.newMailNotificationChannel >> 1 & 1 != 0,
            channel: account.mailSetting.newMailNotificationChannel,
            switchHandler: { [weak self] status in
                self?.viewModel?.getAccountSetting(of: accountId)?.updateSettings(.newMailNotificationChannel(.bot, enable: status))
                let newChannel = Store.settingData.changeChannel(
                    oldChannel: self?.typeDataSource[1].channel ?? account.mailSetting.newMailNotificationChannel,
                    channel: .bot, enable: status)
                // 数据流转需要梳理，目前是乐观更新UI数据的
                self?.updateChannelLocalValue(newChannel)
                self?.typeDataSource[1].status = status
                self?.tableView.reloadData()
                self?.logClickAction(clickInfo: "im_hint", status: status)
            }, type: .bot)

        return [pushType, botType]
    }

    func updateChannelLocalValue(_ channel: Int32) {
        let tempDataSource = typeDataSource
        for index in tempDataSource.indices {
            typeDataSource[index].channel = channel
        }
    }

    func createMailPushSwitchModel(by account: MailAccount) -> MailSettingSwitchModel {
        print("[mail_newbot] SettingViewModel -- createMailPushSwitchModel status: \(account.mailSetting.allNewMailNotificationSwitch)")
        return MailSettingSwitchModel(cellIdentifier: MailSettingSwitchCell.lu.reuseIdentifier,
                                      accountId: account.mailAccountID,
                                      title: BundleI18n.MailSDK.Mail_Setting_NewEmailNotification,
                                      status: account.mailSetting.allNewMailNotificationSwitch,
                                      switchHandler: { [weak self] status in
                                        print("[mail_newbot] SettingViewModel -- MailSettingSwitchModel closure: \(status)")
                                        self?.viewModel?.getAccountSetting(of: account.mailAccountID)?.updateSettings(.allNewMailNotificationSwitch(enable: status))
                                        if let priAcc = Store.settingData.getCachedPrimaryAccount() {
                                            self?.viewModel?.getAccountSetting(of: priAcc.mailAccountID)?.updateSettings(.allNewMailNotificationSwitch(enable: status))
                                        }
                                        self?.pushSwitchModel?.status = status// 这块的数据流转很乱 待梳理 -_-||
                                        self?.logClickAction(clickInfo: "new_mail_hint", status: status)
                                      })
    }

    /// 创建表格视图
    lazy var tableView: InsetTableView = {
        let tableView = InsetTableView(frame: .zero)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 48, bottom: 0, right: 0)
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.backgroundColor = UIColor.ud.bgFloatBase
        tableView.separatorColor = UIColor.ud.lineDividerDefault
        tableView.contentInsetAdjustmentBehavior = .never

        /// registerCell
        tableView.lu.register(cellSelf: MailSettingSwitchCell.self)
        tableView.lu.register(cellSelf: MailSettingPushCell.self)
        return tableView
    }()

    // MARK: - UITableViewDelegate, UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        var section = 1 // 新邮件通知总开关
        if allSwitch {
            if multiAccount() {
                section += 1 // 多账号开关
                if !allAccountClosePush() {
                    if hasScope {
                        section += 1 // 通知范围
                    }
                    section += 1 // 通知形式
                }
            } else {
                if hasScope {
                    section += 1 // 通知范围
                }
                section += 1 // 通知形式
            }
        }
        return section
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if multiAccount() {
            if section == 0 {
                return 1
            } else if section == 1 {
                return dataSource.count
            } else if hasScope && section == 2 {
                return scopeDataSource.count
            } else {
                return typeDataSource.count
            }
        } else {
            if section == 0 {
                return 1
            } else if hasScope && section == 1 {
                return scopeDataSource.count
            } else {
                return typeDataSource.count
            }
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var pushTypeSection: Int = 0
        if multiAccount() {
            pushTypeSection = hasScope ? 3 : 2
        } else {
            pushTypeSection = hasScope ? 2 : 1
        }
        return indexPath.section == pushTypeSection ? notificationTypeHeight(indexPath) : 48
    }

    func notificationTypeHeight(_ indexPath: IndexPath) -> CGFloat {
        if Store.settingData.hasMailClient() && indexPath.row == 1 {
            return 172 + BundleI18n.MailSDK.Mail_ThirdClient_SettingsWontApplyToConnectedAccounts.getTextHeight(font: UIFont.systemFont(ofSize: 14.0, weight: .regular), width: viewWidth) + 2
        } else {
            return 172
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        /// config different setting item
        if indexPath.section == 0 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: MailSettingSwitchCell.lu.reuseIdentifier) as? MailSettingSwitchCell else {
                return UITableViewCell()
            }
            if let item = self.pushSwitchModel {
                cell.item = item
                cell.settingSwitchDelegate = self
            } else {
                let accountId = dataSource.first?.accountId ?? ""
                let item = MailSettingSwitchModel(cellIdentifier: MailSettingSwitchCell.lu.reuseIdentifier,
                                                  accountId: accountId, title: BundleI18n.MailSDK.Mail_Settings_EnableNotification,
                                                  status: viewModel?.getPrimaryAccountSetting()?.setting.allNewMailNotificationSwitch ?? false) { status in
                    self.viewModel?.getAccountSetting(of: accountId)?.updateSettings(.allNewMailNotificationSwitch(enable: status))
                }
                cell.item = item
            }
            return cell

        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: MailSettingPushCell.lu.reuseIdentifier) as? MailSettingPushCell else {
                return UITableViewCell()
            }
            var config = UDCheckBoxUIConfig()
            config.style = .circle
            cell.superViewWidth = viewWidth
            if (multiAccount() && indexPath.section == 1) {
                let settingItem = dataSource[indexPath.row]
                cell.updateUIConfig(boxType: .multiple, config: config)
                cell.updateStatus(isSelected: settingItem.status, isEnabled: true)
                cell.item = settingItem
            } else if ((!multiAccount() && hasScope && indexPath.section == 1) || (multiAccount() && hasScope && indexPath.section == 2)) {
                cell.updateUIConfig(boxType: .single, config: config)
                let settingItem = scopeDataSource[indexPath.row]
                cell.updateStatus(isSelected: settingItem.status, isEnabled: true)
                cell.item = settingItem
            } else {
                let pushTypeItem = typeDataSource[indexPath.row]
                cell.updateUIConfig(boxType: .multiple, config: config)
                cell.updateStatus(isSelected: pushTypeItem.status, isEnabled: true)
                cell.item = pushTypeItem
            }
            return cell
        }
    }

    private enum Section {
        case account // 账号列表
        case scope // 通知范围
        case type // 通知形式
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            return UIView()
        } else {
            let formStr = Store.settingData.clientStatus == .mailClient ? "" : BundleI18n.MailSDK.Mail_Settings_NotificationForm
            let view: UITableViewHeaderFooterView = UITableViewHeaderFooterView()
            let detailLabel = UILabel()
            var sectionType: Section = .account
            if multiAccount() {
                if section == 1 {
                    sectionType = .account
                } else if hasScope && section == 2 {
                    sectionType = .scope
                } else {
                    sectionType = .type
                }
            } else {
                if hasScope && section == 1 {
                    sectionType = .scope
                } else {
                    sectionType = .type
                }
            }
            switch sectionType {
            case .account:
                detailLabel.text = BundleI18n.MailSDK.Mail_Settings_EnableNotificationForAccounts
            case .scope:
                detailLabel.text = BundleI18n.MailSDK.Mail_Settings_NewMailNotification_Scope_Title
            case .type:
                detailLabel.text = formStr
            }
            detailLabel.font = UIFont.systemFont(ofSize: 14)
            detailLabel.textColor = UIColor.ud.textCaption
            detailLabel.textAlignment = .left
            detailLabel.numberOfLines = 0
            view.addSubview(detailLabel)
            detailLabel.snp.makeConstraints { (make) in
                make.top.equalTo(17)
                make.left.equalTo(24)
                make.width.equalToSuperview().offset(-36)
                make.bottom.equalTo(-6)
                if title.isEmpty {
                    make.height.equalTo(0.01)
                }
            }
            return view
        }
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }

    func multiAccount() -> Bool {
        return dataSource.count > 1 || Store.settingData.clientStatus == .mailClient
    }

    func allAccountClosePush() -> Bool {
        return !dataSource.map({ $0.status }).contains(true)
    }
}

extension MailPushSettingViewController: MailSettingSwitchDelegate, MailAccountSettingDelegate {

    func resetData() {
        viewModel?.reloadLocalDataPublish.onNext(())
    }

    func getHUDView() -> UIView? {
        return view
    }

    func didChangeSettingSwitch(_ status: Bool) {
        allSwitch = status
        tableView.reloadData() // 本地乐观更新UI
    }
}
