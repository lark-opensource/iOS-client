//
//  MailSettingViewController.swift
//  Action
//
//  Created by TangHaojin on 2019/7/29.
//

import UIKit
import LarkUIKit
import RxSwift
import EENavigator
import Homeric
import LarkAlertController
import FigmaKit
import UniverseDesignFont
import UniverseDesignNotice
import UniverseDesignToast
import LarkTab

protocol MailClientSettingDelegate: AnyObject {
    func needRefreshHomeNav()
    func scrollToTopOfThreadList(accountId: String)
}

protocol MailSettingDelegate: AnyObject {
    func popToMailHome(accountId: String)
}

final class MailSettingViewController: MailBaseViewController, UITableViewDelegate, UITableViewDataSource {
    var viewModel: MailSettingViewModel?
    var accountId: String?
    var isPrimarySetting: Bool = false
    weak var clientDelegate: MailClientSettingDelegate?
    weak var settingDelegate: MailSettingDelegate?

    private let notifyBag = DisposeBag()
    let disposeBag = DisposeBag()
    private var accountSetting: MailAccountSetting?
    private var dataSource: [MailSettingSectionModel] {
        return accountSetting?.settingSections ?? []
    }

    private var tipsView: UDNotice = {
        let text = NSAttributedString(string: BundleI18n.MailSDK.Mail_Mailbox_PublicMailboxSettingSync,
                                      attributes: [.foregroundColor: UIColor.ud.textTitle])
        var config = UDNoticeUIConfig(type: .info, attributedText: text)
        let view = UDNotice(config: config)
        view.clipsToBounds = true
        return view
    }()
    private lazy var bindOnboardView: MailSettingFreeBindOnboardView = {
        let naviHeight = self.navigationController?.navigationBar.frame.height ?? 0
        let topMargin = UIApplication.shared.statusBarFrame.height + naviHeight
        let view = MailSettingFreeBindOnboardView(topMargin: topMargin)
        view.gotoBind = { [weak self] in
            MailTracker.log(event: "email_lark_setting_click", params: ["click": "mail_bind"])
            self?.jumpAddMailClientPage()
        }
        return view
    }()

    private let userContext: MailUserContext

    init(userContext: MailUserContext) {
        self.userContext = userContext
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var serviceProvider: MailSharedServicesProvider? {
        userContext
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        userContext.editorLoader.preloadEditor()
        setupViews()
        setupViewModel()
        // 适配iOS 15 bartintcolor颜色不生效问题
        updateNavAppearanceIfNeeded()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateNavAppearanceIfNeeded()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutCells()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel?.viewController = self
        clientDelegate?.needRefreshHomeNav()
    }

    override var navigationBarTintColor: UIColor {
        return UIColor.ud.bgFloatBase
    }

    func setupViews() {
        /// 添加表格视图
        view.backgroundColor = UIColor.ud.bgFloatBase
        view.addSubview(tableView)
        view.addSubview(tipsView)
        tableView.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(0)
            make.bottom.equalToSuperview()
        }
        tipsView.isHidden = true
        tipsView.snp.makeConstraints { (make) in
            make.top.leading.trailing.equalToSuperview()
        }
        
    }
    
    func showFreeBindOnboardView(_ show: Bool) {
        tableView.isHidden = show
        guard show else {
            bindOnboardView.removeFromSuperview()
            return
        }
        guard bindOnboardView.superview == nil, viewModel?.showFreeBind == true else {
            return
        }
        view.addSubview(bindOnboardView)
        bindOnboardView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    func layoutCells() {
        for cell in tableView.visibleCells where (cell as? MailSettingConversationCell) == nil {
            if let baseCell = cell as? MailSettingBaseCell {
                baseCell.adjustLabelLayout()
            }
        }
    }
    
    func setupViewModel() {
        if viewModel == nil {
            viewModel = MailSettingViewModel(accountContext: userContext.getCurrentAccountContext())
        } else {
            reloadData()
        }
        self.viewModel?.viewController = self
        self.viewModel?.refreshDriver.drive(onNext: { [weak self] () in
            guard let `self` = self else { return }
            self.reloadData()
        }).disposed(by: disposeBag)
    }

    func updateTitle() {
        title = BundleI18n.MailSDK.Mail_Setting_Title
    }

    func updateStrangerModelSwitch(_ isOn: Bool) {
        guard let indexPaths = tableView.indexPathsForVisibleRows else { return }
        for indexPath in indexPaths where
        (dataSource[indexPath.section].items[indexPath.row] as? MailSettingStrangerModel) != nil {
            if let strangerModelCell = tableView.cellForRow(at: indexPath) as? MailSettingSwitchCell {
                strangerModelCell.setSwitchButton(isOn)
            }
        }
    }
    
    func updateAttamentModelCapacity() {
        guard let indexPaths = tableView.indexPathsForVisibleRows else { return }
        for indexPath in indexPaths where
        (dataSource[indexPath.section].items[indexPath.row] as? MailSettingAttachmentsModel) != nil {
            if let model = dataSource[indexPath.section].items[indexPath.row] as? MailSettingAttachmentsModel {
                viewModel?.updateAttachmentsCapacity(model: model, forceUpdate: true)
            }
        }
    }

    func updateCacheModelStatus() {
        guard let indexPaths = tableView.indexPathsForVisibleRows else { return }
        for indexPath in indexPaths where
        (dataSource[indexPath.section].items[indexPath.row] as? MailSettingCacheModel) != nil {
            if let model = dataSource[indexPath.section].items[indexPath.row] as? MailSettingCacheModel {
                viewModel?.updateCacheRangeStatus(model: model, forceUpdate: true)
            }
        }
    }

    func reloadData() {
        if isPrimarySetting {
            accountSetting = viewModel?.getPrimaryAccountSetting()
        } else {
            accountSetting = viewModel?.getAccountSetting(of: accountId)
        }

        // account is not vaild, dismiss the account detail setting page
        if let setting = accountSetting?.account.mailSetting,
            setting.userType != .larkServer,
            setting.userType != .gmailApiClient,
            setting.userType != .exchangeApiClient,
            setting.userType != .exchangeClient,
            (setting.userType != .tripartiteClient && setting.emailClientConfigs.first?.configStatus == nil),
            accountSetting?.isAccountDetailSetting ?? false {
            self.navigationController?.popViewController(animated: true)
            return
        }

        tipsView.isHidden = !(accountSetting?.account.isShared ?? false)
        if let userType = accountSetting?.account.mailSetting.userType, userType == .tripartiteClient {
            let text = NSAttributedString(string: BundleI18n.MailSDK.Mail_ThirdClient_ConnectedDesc(),
                                          attributes: [.foregroundColor: UIColor.ud.textTitle])
            var config = UDNoticeUIConfig(type: .info, attributedText: text)
            tipsView.updateConfigAndRefreshUI(config)
        }
        let height = tipsView.sizeThatFits(CGSize(width: view.bounds.width, height: CGFloat.greatestFiniteMagnitude)).height
        tableView.snp.updateConstraints({ (make) in
            let topMargin = height == 0 ? 39 : height
            make.top.equalTo(tipsView.isHidden ? 0 : topMargin)
        })
        accountId = accountSetting?.account.mailAccountID
        showFreeBindOnboardView(viewModel?.showFreeBind == true)
        tableView.reloadData()
        updateTitle()
        layoutCells()
    }

    /// 创建表格视图
    lazy var tableView: UITableView = {
        let tableView = InsetTableView(frame: .zero)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 100
        tableView.estimatedSectionFooterHeight = 100
        tableView.estimatedSectionHeaderHeight = 0.01
//        tableView.tableFooterView = UIView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 0.1, height: 16)))
//        tableView.tableHeaderView = UIView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 0.1, height: CGFloat.leastNormalMagnitude)))
        tableView.rowHeight = UITableView.automaticDimension
        tableView.sectionFooterHeight = UITableView.automaticDimension
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 76, bottom: 16 + Display.bottomSafeAreaHeight, right: 0)
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.backgroundColor = UIColor.ud.bgFloatBase
        tableView.separatorColor = UIColor.ud.lineDividerDefault

        /// registerCell
        tableView.lu.register(cellSelf: MailSettingSwitchCell.self)
        tableView.lu.register(cellSelf: MailSettingAccountCell.self)
        tableView.lu.register(cellSelf: MailSettingSignatureCell.self)
        tableView.lu.register(cellSelf: MailSettingOOOCell.self)
        tableView.lu.register(cellSelf: MailSettingAttachmentsCell.self)
        tableView.lu.register(cellSelf: MailSettingCacheCell.self)
        tableView.lu.register(cellSelf: MailSettingAccountInfoCell.self)
        tableView.lu.register(cellSelf: MailSettingUnlinkCell.self)
        tableView.lu.register(cellSelf: MailSettingRelinkCell.self)
        tableView.lu.register(cellSelf: MailSettingStatusCell.self)
        tableView.lu.register(cellSelf: MailSettingDraftLandCell.self)
        tableView.lu.register(cellSelf: MailSettingAddOperationCell.self)
        tableView.lu.register(cellSelf: MailSettingConversationCell.self)
        tableView.lu.register(cellSelf: MailSettingSyncRangeCell.self)
        return tableView
    }()

    // MARK: - UITableViewDelegate, UITableViewDataSource
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
        if settingItem is MailSettingAccountInfoModel {
            if let cell = tableView.dequeueReusableCell(withIdentifier: settingItem.cellIdentifier) as? MailSettingAccountInfoCell {
                cell.dependency = self
                cell.item = settingItem
                cell.accessibilityIdentifier = MailAccessibilityIdentifierKey.SettingAccountInfoCellKey
                return cell
            }
        } else if settingItem is MailSettingAccountModel {
            let cell = MailSettingAccountCell.init(style: .default, reuseIdentifier: settingItem.cellIdentifier)
            cell.dependency = self
            cell.item = settingItem
            cell.accessibilityIdentifier = MailAccessibilityIdentifierKey.SettingAccountCellKey
            var leftMargin: CGFloat = 0
            if indexPath.row == dataSource[indexPath.section].items.count - 2 {
                leftMargin = 13
            } else {
                leftMargin = 73
            }
            cell.separatorInset = UIEdgeInsets(top: 0, left: leftMargin, bottom: 0, right: 0)
            return cell
        } else if settingItem is MailSettingAddOperationModel {
            if let cell = tableView.dequeueReusableCell(withIdentifier: settingItem.cellIdentifier) as? MailSettingAddOperationCell {
                cell.dependency = self
                cell.item = settingItem
                return cell
            }
        } else if settingItem is MailSettingServerConfigModel {
            if let cell = tableView.dequeueReusableCell(withIdentifier: settingItem.cellIdentifier) as? MailSettingStatusCell {
                cell.dependency = self
                cell.item = settingItem
                return cell
            }
        } else if settingItem is MailSettingSenderAliasModel {
            if let cell = tableView.dequeueReusableCell(withIdentifier: settingItem.cellIdentifier) as? MailSettingStatusCell {
                cell.dependency = self
                cell.item = settingItem
                return cell
            }
        } else if settingItem is MailSettingUndoModel {
            if let cell = tableView.dequeueReusableCell(withIdentifier: settingItem.cellIdentifier) as? MailSettingStatusCell {
                cell.dependency = self
                cell.item = settingItem
                cell.accessibilityIdentifier = MailAccessibilityIdentifierKey.SettingUndoCellKey
                return cell
            }
        } else if settingItem is MailSettingSwipeActionsModel {
            if let cell = tableView.dequeueReusableCell(withIdentifier: settingItem.cellIdentifier) as? MailSettingStatusCell {
                cell.dependency = self
                cell.item = settingItem
                cell.accessibilityIdentifier = MailAccessibilityIdentifierKey.SettingSwipeActionsCellKey
                return cell
            }
        } else if settingItem is MailSettingSignatureModel {
            if let cell = tableView.dequeueReusableCell(withIdentifier: settingItem.cellIdentifier) as? MailSettingSignatureCell {
                cell.dependency = self
                cell.item = settingItem
                cell.accessibilityIdentifier = MailAccessibilityIdentifierKey.SettingSignatureCellKey
                return cell
            }
        } else if settingItem is MailSettingOOOModel {
            if let cell = tableView.dequeueReusableCell(withIdentifier: settingItem.cellIdentifier) as? MailSettingOOOCell {
                cell.dependency = self
                cell.item = settingItem
                cell.accessibilityIdentifier = MailAccessibilityIdentifierKey.SettingOooCellKey
                return cell
            }
        } else if settingItem is MailSettingAttachmentsModel {
            if let cell = tableView.dequeueReusableCell(withIdentifier: settingItem.cellIdentifier) as? MailSettingAttachmentsCell {
                cell.dependency = self
                cell.item = settingItem
                if let attachmentSettingItem = settingItem as? MailSettingAttachmentsModel {
                    attachmentSettingItem.capacityChange
                        .observeOn(MainScheduler.instance)
                        .subscribe(onNext:{(state) in
                            switch state {
                            case .refresh:
                                cell.refreshCapacity()
                            }
                        }).disposed(by: disposeBag)
                }
                cell.accessibilityIdentifier = MailAccessibilityIdentifierKey.SettingAttachmentsCellKey
                return cell
            }
        } else if settingItem is MailSettingCacheModel {
            if let cell = tableView.dequeueReusableCell(withIdentifier: settingItem.cellIdentifier) as? MailSettingCacheCell {
                cell.dependency = self
                cell.item = settingItem
                if let cacheSettingItem = settingItem as? MailSettingCacheModel {
                    cacheSettingItem.cacheStatusChange
                        .observeOn(MainScheduler.instance)
                        .subscribe(onNext:{ [weak cell] _ in
                            cell?.refreshStatus()
                        }).disposed(by: disposeBag)
                }
                cell.accessibilityIdentifier = MailAccessibilityIdentifierKey.SettingCacheCellKey
                return cell
            }
        } else if settingItem is MailSettingSyncRangeModel {
            if let cell = tableView.dequeueReusableCell(withIdentifier: settingItem.cellIdentifier) as? MailSettingSyncRangeCell {
                cell.dependency = self
                cell.item = settingItem
                cell.accessibilityIdentifier = MailAccessibilityIdentifierKey.SettingSyncRangeCellKey
                return cell
            }
        } else if settingItem is MailSettingUnlinkModel {
            if let cell = tableView.dequeueReusableCell(withIdentifier: settingItem.cellIdentifier) as? MailSettingUnlinkCell {
                cell.item = settingItem
                cell.accessibilityIdentifier = MailAccessibilityIdentifierKey.SettingUnlinkCellKey
                return cell
            }
        } else if settingItem is MailSettingRelinkModel {
           if let cell = tableView.dequeueReusableCell(withIdentifier: settingItem.cellIdentifier) as? MailSettingRelinkCell {
               cell.item = settingItem
               cell.dependency = self
               cell.accessibilityIdentifier = MailAccessibilityIdentifierKey.SettingRelinkCellKey
               return cell
           }
        } else if settingItem is MailDraftLangModel {
            if let cell = tableView.dequeueReusableCell(withIdentifier: settingItem.cellIdentifier) as? MailSettingDraftLandCell {
                cell.item = settingItem
                cell.dependency = self
                cell.userContext = userContext
                return cell
            }
        } else if settingItem is MailSettingAutoCCModel {
            if let cell = tableView.dequeueReusableCell(withIdentifier: settingItem.cellIdentifier) as? MailSettingStatusCell {
                cell.item = settingItem
                cell.dependency = self
                return cell
            }
        } else if settingItem is MailSettingPushModel {
            if let cell = tableView.dequeueReusableCell(withIdentifier: settingItem.cellIdentifier) as? MailSettingStatusCell {
                cell.dependency = self
                cell.item = settingItem
                return cell
            } else if let cell = tableView.dequeueReusableCell(withIdentifier: settingItem.cellIdentifier) as? MailSettingSwitchCell {
                cell.item = settingItem
                return cell
            }
        } else if settingItem is MailSettingAttachmentModel {
            if let cell = tableView.dequeueReusableCell(withIdentifier: settingItem.cellIdentifier) as? MailSettingStatusCell {
                cell.dependency = self
                cell.item = settingItem
                return cell
            } else if let cell = tableView.dequeueReusableCell(withIdentifier: settingItem.cellIdentifier) as? MailSettingSwitchCell {
                cell.item = settingItem
                return cell
            }
        } else if settingItem is MailSettingConversationModel {
            if userContext.featureManager.open(.conversationSetting),
               let cell = tableView.dequeueReusableCell(withIdentifier: settingItem.cellIdentifier) as? MailSettingConversationCell {
                cell.dependency = self
                cell.item = settingItem
                if userContext.featureManager.open(FeatureKey(fgKey: .threadCustomSwipeActions, openInMailClient: true)) {
                    cell.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
                }
                return cell
            } else if let cell = tableView.dequeueReusableCell(withIdentifier: settingItem.cellIdentifier) as? MailSettingSwitchCell {
                cell.item = settingItem
                return cell
            }
        } else if settingItem is MailSettingWebImageModel {
            if let cell = tableView.dequeueReusableCell(withIdentifier: settingItem.cellIdentifier) as? MailSettingStatusCell {
                cell.item = settingItem
                cell.dependency = self
                return cell
            }
        } else if settingItem is MailAliasSettingModel {
            if let cell = tableView.dequeueReusableCell(withIdentifier: settingItem.cellIdentifier) as? MailSettingStatusCell {
                cell.item = settingItem
                cell.dependency = self
                return cell
            }
        } else {
            if let cell = tableView.dequeueReusableCell(withIdentifier: settingItem.cellIdentifier) as? MailSettingSwitchCell {
                cell.item = settingItem
                return cell
            }
        }

        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        guard let view = view as? UITableViewHeaderFooterView else { return }
        view.textLabel?.textColor = UIColor.ud.textCaption
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let view = view as? UITableViewHeaderFooterView else { return }
        view.textLabel?.textColor = UIColor.ud.textCaption
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section < dataSource.count else { return nil }
        if section == 0 && !tipsView.isHidden {
            return createHeaderView(title: "", noSpace: true)
        }
        let sectionModel = dataSource[section]
        return createHeaderView(title: sectionModel.headerText)
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard section < dataSource.count else { return nil }
        let section = dataSource[section]
        return createFooterView(title: section.footerText)
    }

    private func createHeaderView(title: String, noSpace: Bool = false) -> UITableViewHeaderFooterView {
        let view = UITableViewHeaderFooterView()
        if noSpace {
            view.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 0.01)
            return view
        }
        let detailLabel: UILabel = UILabel()
        detailLabel.text = title
        detailLabel.font = UIFont.systemFont(ofSize: 14)
        detailLabel.textColor = UIColor.ud.textCaption
        detailLabel.textAlignment = .justified
        detailLabel.numberOfLines = 0
        view.contentView.addSubview(detailLabel)
        detailLabel.snp.makeConstraints { (make) in
//            make.top.equalTo(16)
//            make.bottom.equalTo(-4)
            make.top.equalTo(8)
            make.bottom.equalTo(-2)
            make.right.equalToSuperview()
            make.left.equalTo(4)
            if title.isEmpty {
                make.height.equalTo(0.01)
            }
//            else {
//                make.height.equalTo(16)
//            }
        }
        return view
    }

    private func createFooterView(title: String) -> UITableViewHeaderFooterView {
        let view = UITableViewHeaderFooterView()
        let detailLabel: UILabel = UILabel()
        detailLabel.text = title
        detailLabel.font = UIFont.systemFont(ofSize: 14.0)
        detailLabel.textColor = UIColor.ud.textPlaceholder
        detailLabel.numberOfLines = 0
        view.contentView.addSubview(detailLabel)
        detailLabel.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.right.equalTo(-14)
            if title.isEmpty {
                make.top.equalTo(2)
                make.bottom.equalTo(-2)
                make.height.equalTo(0.01)
            } else {
//                make.top.equalTo(4)
                make.top.equalTo(3)
                make.bottom.equalTo(-6)//(-12)
//                make.height.equalTo(getTitleHeight(title))
            }
        }
        return view
    }
}

extension MailSettingViewController: MailSettingAccountCellDependency, MailSettingDelegate {
    func jumpSettingOfAccount(_ accountId: String) {
        let settingVC = MailSettingViewController(userContext: userContext)
        settingVC.accountId = accountId
        settingVC.viewModel = viewModel
        settingVC.clientDelegate = clientDelegate
        settingVC.settingDelegate = self
        navigator?.push(settingVC, from: self)
    }

    func popToMailHome(accountId: String) {
        let viewControllers = self.navigator?.navigation?.viewControllers ?? []
        MailLogger.info("[mail_cache_preload] self.clientDelegate：\(self.clientDelegate)")
        self.clientDelegate?.scrollToTopOfThreadList(accountId: accountId)
        if viewControllers.count >= 3 {
            /// 需要把视图栈里面的setting vc都退出去，如果包含非Mail VC的情况下
            MailLogger.info("[mail_cache_preload] need pop out lark open setting vc 1")
            self.navigator?.navigation?.setViewControllers([viewControllers.first, viewControllers.last].compactMap { $0 }, animated: false)
            self.backToMailHome(completion: nil)
        }  else if viewControllers.count >= 2 {
            MailLogger.info("[mail_cache_preload] need pop out lark open setting vc 2")
            self.navigator?.navigation?.setViewControllers([viewControllers.first].compactMap { $0 }, animated: false)
        } else {
            self.backToMailHome(completion: nil)
        }
    }

    func jumpAdSetting(_ accountId: String, provider: MailTripartiteProvider) {
        if provider.isTokenLogin() {
            Store.settingData.tokenRelink(provider: provider, navigator: userContext.navigator, from: self, accountID: accountId)
        } else {
            if userContext.featureManager.realTimeOpen(.newFreeBindMail, openInMailClient: false) {
                let loginVC = MailClientLoginViewController(type: .other, accountContext: userContext.getAccountContextOrCurrent(accountID: accountId), scene: .freeBindInvaild)
                let loginNav = LkNavigationController(rootViewController: loginVC)
                var imapAccount = MailImapAccount(mailAddress: "", password: "", bindType: .reBind)
                if let config = accountSetting?.account.mailSetting.emailClientConfigs.first {
                    imapAccount.mailAddress = config.emailAddress
                }
                loginVC.imapAccount = imapAccount
                loginNav.modalPresentationStyle = Display.pad ? .formSheet : .fullScreen
                self.navigator?.present(loginNav, from: self)
            } else {
                let adSettingVC = MailClientAdvanceSettingViewController(scene: .reVerfiy,
                                                                         accountID: accountId,
                                                                         accountContext: userContext.getAccountContext(accountID: accountId),
                                                                         isFreeBind: false,
                                                                         type: provider)
                let adSettingNav = LkNavigationController(rootViewController: adSettingVC)
                adSettingNav.modalPresentationStyle = Display.pad ? .formSheet : .fullScreen
                navigator?.present(adSettingNav, from: self)
            }
        }
    }
}

extension MailSettingViewController: MailSettingSignatureCellDependency {
    func jumpSignatureSettingPage(accountId: String) {
        // 点击签名上报
        let event = NewCoreEvent(event: .email_lark_setting_click)
        event.params = ["target": "none",
                        "click": "mail_signature"]
        event.post()
        let sigFG = userContext.featureManager.realTimeOpen(.enterpriseSignature, openInMailClient: true)
        if isMailClient(accountId) || (!isMailClient(accountId) && sigFG) {
            let signatureVC = MailSettingSignatureViewController(accountContext: userContext.getCurrentAccountContext())
            let value = self.viewModel?.getEmailAndName(accountId)
            signatureVC.accountId = accountId
            signatureVC.email = value?.0 ?? ""
            signatureVC.name = value?.1 ?? ""
            navigator?.push(signatureVC, from: self)
        } else {
            viewModel?.getEmailPrimaryAccount()
            let signatureVC = MailSignatureSettingViewController(viewModel: viewModel, accountContext: userContext.getAccountContextOrCurrent(accountID: accountId))
            navigator?.push(signatureVC, from: self)
        }
    }

    private func isMailClient(_ accountId: String) -> Bool {
        if let account = Store.settingData.getCachedAccountList()?.first(where: { $0.mailAccountID == accountId }) {
            return account.mailSetting.userType == .tripartiteClient
        }
        return false
    }
}

extension MailSettingViewController: MailSettingOOOCellDependency {
    func jumpOOOSettingPage() {
        viewModel?.getEmailPrimaryAccount()
        let oooSettingVC = MailOOOSettingViewController(
            accountContext: userContext.getCurrentAccountContext()
            , viewModel: viewModel,
            source: .setting,
            accountId: accountId ?? ""
        )
        navigator?.push(oooSettingVC, from: self)
    }
}

extension MailSettingViewController: MailSettingAttachmentsCellDependency {
    func jumpAttachmentsSettingPage() {
        // 点击跳转超大附件上报
        let event = NewCoreEvent(event: .email_lark_setting_click)
        event.params = ["target": "none",
                        "click": "large_attachment_manage",
                        "mail_account_type": Store.settingData.getMailAccountType()]
        event.post()
        
        let vc = MailAttachmentsManagerViewController(accountContext: userContext.getAccountContextOrCurrent(accountID: accountId), accountID:accountId ?? "", transferFolderKey: "")
        vc.capacityChange
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext:{ [weak self] (state) in
                        guard let self = self else { return }
                        switch state {
                        case .delete:
                            self.updateAttamentModelCapacity()
                        }
                    }).disposed(by: disposeBag)
        userContext.navigator.push(vc, from:self)
    }
}
extension MailSettingViewController: MailSettingCacheCellDependency, MailCacheSettingDelegate {
    func jumpCacheSettingPage() {
        let event = NewCoreEvent(event: .email_lark_setting_click)
        event.params = ["target": "none",
                        "click": "offline_cache_setting"]
        event.post()
        viewModel?.getEmailPrimaryAccount()
        let cacheSettingVC = MailCacheSettingViewController(viewModel: viewModel,
                                                            accountContext: userContext.getAccountContextOrCurrent(accountID: accountId))
        cacheSettingVC.delegate = self
        if rootSizeClassIsRegular {
            userContext.navigator.push(cacheSettingVC, from: self)
        } else {
            let cacheSettingNav = LkNavigationController(rootViewController: cacheSettingVC)
            cacheSettingNav.modalPresentationStyle = Display.pad ? .formSheet : .fullScreen
            userContext.navigator.present(cacheSettingNav, from: self)
        }
    }

    func updateCacheRangeSuccess(accountId: String, expandPreload: Bool, offline: Bool, allowMobileTraffic: Bool) {
        MailCacheSettingViewController.changeCacheRangeSuccess(accountId: accountId, showProgrssBtn: true, expandPreload: expandPreload, offline: offline, allowMobileTraffic: allowMobileTraffic, view: self.view) { [weak self] in
            self?.confirmPreloadProgress(accountId: accountId)
        }
        self.updateCacheModelStatus()
    }

    func confirmPreloadProgress(accountId: String) {
        if self.navigator?.navigation?.viewControllers.last?.animatedTabBarController?.currentTab == .mail {
            MailLogger.info("[mail_cache_preload] confirmPreloadProgress, back to mail home")
            if let mailtabvc = navigator?.navigation?.viewControllers.first?.animatedTabBarController?.viewControllers?.first as? MailTabBarController, let homevc = mailtabvc.content as? MailHomeController {
                self.clientDelegate = homevc
            }
            clientDelegate?.scrollToTopOfThreadList(accountId: accountId)
            userContext.navigator.pop(from: self) { [weak self] in
                MailLogger.info("[mail_cache_preload] confirmPreloadProgress, after pop \(self?.settingDelegate) \(self?.clientDelegate)")
                if let settingDelegate = self?.settingDelegate {
                    MailLogger.info("[mail_cache_preload] settingDelegate popToMailHome")
                    settingDelegate.popToMailHome(accountId: accountId)
                } else {
                    MailLogger.info("[mail_cache_preload] popToMailHome")
                    self?.popToMailHome(accountId: accountId)
                }
            }
        } else {
            userContext.navigator.switchTab(Tab.mail.url, from: self, animated: true) {  [weak self] _ in
                MailLogger.info("[mail_cache_preload] confirmPreloadProgress, switch to mail home")
                if let mailtabvc = self?.navigator?.navigation?.viewControllers.first?.animatedTabBarController?.viewControllers?.first as? MailTabBarController, let homevc = mailtabvc.content as? MailHomeController {
                    self?.clientDelegate = homevc
                }
                self?.clientDelegate?.scrollToTopOfThreadList(accountId: accountId)
            }
        }
    }
}

extension MailSettingViewController: MailSettingSyncRangeCellDependency, MailSyncRangeSettingDelegate {
    func jumpSyncRangeSettingPage() {
        viewModel?.getEmailPrimaryAccount()
        let syncRangeSettingVC = MailSyncRangeSettingViewController(viewModel: viewModel, accountContext: userContext.getAccountContext(accountID: accountId) ?? userContext.getCurrentAccountContext())
        syncRangeSettingVC.delegate = self
        let nav = LkNavigationController(rootViewController: syncRangeSettingVC)
        nav.modalPresentationStyle = .overFullScreen
        navigator?.present(nav, from: self)
    }

    func updateSyncRangeSuccess(accountId: String) {
        MailRoundedHUD.showSuccess(with: BundleI18n.MailSDK.Mail_Shared_AddEAS_EmailSyncCompleted_Toast, on: self.view)
        viewModel?.updateMailClientSyncRangeStatus(accountId: accountId)
    }
}

extension MailSettingViewController: MailSettingStatusCellDependency, MailPushSettingDelegate, MailSettingConverstionCellDependency, MailSenderAliasDelegate {
    func jumpToAliasSettingPage(_ accID: String) {
        viewModel?.getEmailPrimaryAccount()
        let mailAccountContext = userContext.getAccountContextOrCurrent(accountID: accID)
        let aliasSettingVC = MailSettingAliasViewController(accountContext: mailAccountContext, viewModel: viewModel, accountId: accID)
        navigator?.push(aliasSettingVC,from: self)
    }
    
    func jumpConversationPage() {
        viewModel?.getEmailPrimaryAccount()
        let conversationVC = MailConversationSettingViewController(viewModel: viewModel, accountContext: userContext.getAccountContextOrCurrent(accountID: accountId))
        navigator?.push(conversationVC, from: self)
    }
    func jumpToPushSettingPage() {
        viewModel?.getEmailPrimaryAccount()
        let pushSettingVC = MailPushSettingViewController(viewModel: viewModel, accountContext: userContext.getAccountContext(accountID: accountId))
        pushSettingVC.delegate = self
        navigator?.push(pushSettingVC, from: self)
    }

    func jumpToAttachmentSettingPage() {
        viewModel?.getEmailPrimaryAccount()
        let vc = MailAttachmentSettingViewController(viewModel: viewModel)
        userContext.navigator.push(vc, from: self)
    }
    
    func jumpToSwipeActionsSettingPage() {
        viewModel?.getEmailPrimaryAccount()
        let swipeActionsSettingVC = MailSwipeActionsSettingViewController(userContext: userContext, viewModel: viewModel, accountId: accountId ?? "")
        navigator?.push(swipeActionsSettingVC, from: self)
    }

    func jumpUndoSettingPage() {
        viewModel?.getEmailPrimaryAccount()
        let undoSettingVC = MailUndoSettingViewController(viewModel: viewModel, accountContext: userContext.getAccountContextOrCurrent(accountID: accountId))
        navigator?.push(undoSettingVC, from: self)
    }

    func jumpToClientAdSettingPage(_ accID: String?) {
        let adSettingVC = MailClientAdvanceSettingViewController(scene: .config, accountID: accID ?? "", accountContext: userContext.getAccountContext(accountID: accID), isFreeBind: userContext.featureManager.realTimeOpen(.newFreeBindMail, openInMailClient: false))
        let adSettingNav = LkNavigationController(rootViewController: adSettingVC)
        adSettingNav.modalPresentationStyle = Display.pad ? .formSheet : .fullScreen
        navigator?.present(adSettingNav, from: self)
    }

    func jumpToClientAliasSettingPage(_ accID: String?) {
        guard let accID = accID else { return }
        let titleText = BundleI18n.MailSDK.Mail_ThirdClient_AccountNameMobile
        let aliasSettingVC = MailSenderAliasController(viewModel: viewModel,
                                                       accountId: accID,
                                                       accountContext: userContext.getAccountContextOrCurrent(accountID: accID),
                                                       titleText: titleText,
                                                       currentAddress: nil)
        aliasSettingVC.delegate = self
        let aliasNav = LkNavigationController(rootViewController: aliasSettingVC)
        aliasNav.modalPresentationStyle = .fullScreen
        navigator?.present(aliasNav, from: self)
    }

    func shouldShowAliasLimit() -> Bool {
        if userContext.featureManager.open(FeatureKey(fgKey: .sendMailNameSetting, openInMailClient: true)) {
            return true
        }
        return false
    }

    func didUpdateAliasAndDismiss(address: MailAddress) {
        MailRoundedHUD.showSuccess(with: BundleI18n.MailSDK.Mail_ThirdClient_AccountNameUpdated, on: self.view)
    }

    func updateUndoSwitch(enable: Bool) {
        viewModel?.updateUndoSwitch(enable)
    }

    func updatePushSwitch(enable: Bool) {
        viewModel?.updatePushSwitch(enable)
    }
    
    func updateWebImageSwitch(enable: Bool) {
        viewModel?.updateWebImageSwitch(enable: enable)
    }
    
    func jumpToWebImageDisplaySettingPage(_ accID: String?) {
        viewModel?.getEmailPrimaryAccount()
        let vc = MailWebImageSettingViewController(viewModel: viewModel, accountContext: userContext.getAccountContext(accountID: accID))
        navigator?.push(vc, from: self)
    }

    func updateAutoCCSwitch(enable: Bool) {
        viewModel?.updateAutoCCSwitch(enable: enable)
    }

    func jumpToAutoCCSettingPage() {
        viewModel?.getEmailPrimaryAccount()
        if let accountId = accountId {
            let vc = MailAutoCCSettingViewController(viewModel: viewModel, accountId: accountId)
            navigator?.push(vc, from: self)
        }
    }
}

extension MailSettingViewController: MailSettingDraftLangCellDependency {
    func jumpDraftLangSettingPage() {
        viewModel?.getEmailPrimaryAccount()
        let vc = MailDraftLangViewController(viewModel: viewModel, accountContext: userContext.getAccountContextOrCurrent(accountID: accountId))
        navigator?.push(vc, from: self)
    }
}

extension MailSettingViewController: MailSettingAddOperationCellDependency {
    func handleAddOperation() {
        guard let count = viewModel?.accountListSettings?.filter({ $0.account.mailSetting.userType == .tripartiteClient }).count,
              count < 5 else {
                  MailRoundedHUD.showTips(with: BundleI18n.MailSDK.Mail_ThirdClient_AddEmailAccountsDesc, on: self.view)
                  return
              }
        let vc = MailClientViewController(scene: userContext.featureManager.realTimeOpen(.newFreeBindMail, openInMailClient: false) ? .newFreeBindSetting : .setting, userContext: userContext)
        vc.displaying = true
        let nav = LkNavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        navigator?.present(nav, from: self)
    }

    func jumpAddMailClientPage() {
        self.handleAddOperation()
    }
}
