//
//  NameCardListViewController.swift
//  LarkContact
//
//  Created by Aslan on 2021/4/18.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import LarkModel
import LarkUIKit
import EENavigator
import LarkSDKInterface
import LarkMessengerInterface
import LarkAlertController
import UniverseDesignEmpty
import LKCommonsLogging
import UniverseDesignTabs
import LarkContainer

final class NameCardListViewController: BaseUIViewController,
                                  UITableViewDelegate,
                                  UITableViewDataSource,
                                  UDTabsListContainerViewDelegate, UserResolverWrapper {

    static let logger = Logger.log(NameCardListViewController.self, category: "NameCardList")

    private var datasource: [NameCardListCellViewModel] = [] {
        didSet {
            DispatchQueue.main.async {
                if self.datasource.isEmpty {
                    self.tableView.isHidden = true
                    self.emptyView.isHidden = false
                } else {
                    self.tableView.isHidden = false
                    self.emptyView.isHidden = true
                }
            }
        }
    }
    private let disposeBag = DisposeBag()

    // MARK: Views
    fileprivate var tableView: UITableView = .init(frame: .zero)

    let viewModel: NameCardListViewModel
    var userResolver: LarkContainer.UserResolver

    let emptyView = UDEmptyView(config: UDEmptyConfig(description: UDEmptyConfig.Description(
        descriptionText: BundleI18n.LarkContact.Mail_Contacts_NoContactsAdd
    ), type: .noContact))
    let noPermissionView = UDEmptyView(config: UDEmptyConfig(description: UDEmptyConfig.Description(
        descriptionText: BundleI18n.LarkContact.Mail_ThirdClient_UnableLoadAccountExpired
    ), type: .noPreview))

    private lazy var sectionIndexView: UDSectionIndexView = {
        let indexView = UDSectionIndexView(frame: .zero)
        indexView.delegate = self
        indexView.dataSource = self
        indexView.itemPreviewMargin = 12
        return indexView
    }()

    private lazy var headerTips: MailGroupTaleHeaderTipsView = {
        return MailGroupTaleHeaderTipsView(frame: .zero)
    }()

    private var actualNavigationItem: UINavigationItem {
        // Name Card maybe nested inside other vc, in that case we should set parent's navigation item
        if let parent = parent, !(parent is UINavigationController) {
            return parent.navigationItem
        } else {
            return navigationItem
        }
    }

    private let impactFeedbackGenerator: UIImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)

    // MARK: LifeCircle
    init(viewModel: NameCardListViewModel, resolver: UserResolver) {
        self.viewModel = viewModel
        self.userResolver = resolver
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracer.trackExternalShow()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.ud.bgBody
        self.setupNavigationBar()
        self.initializeTableView()
        self.bindViewModel()
        NotificationCenter.default.addObserver(self, selector: #selector(refreshNameCardData), name: .LKNameCardEditNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleRemovedContact), name: .LKNameCardDeleteNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onAccountPermissionLost), name: .LKNameCardNoPermissionNotification, object: nil)
        viewModel.pageDidView()
    }

    fileprivate func extractedFunc() -> NameCardNavTitleView {
        return NameCardNavTitleView(title: BundleI18n.LarkContact.Mail_MailingList_EmailContacts,
                                    subTitle: viewModel.mailAddress)
    }

    private func setupNavigationBar() {
        isNavigationBarHidden = false
        if !viewModel.accountID.isEmpty {
            let titleView = extractedFunc()
            actualNavigationItem.titleView = titleView
        } else {
            self.title = BundleI18n.LarkContact.Lark_Contacts_ContactCards
        }

        let isContactList = viewModel is MailContactListViewModel
        let rightButton = LKBarButtonItem(title: BundleI18n.LarkContact.Lark_Legacy_Add)
        rightButton.button.tintColor = isContactList ? UIColor.ud.primaryContentDefault : UIColor.ud.textDisabled
        rightButton.setProperty(font: UIFont.systemFont(ofSize: 16), alignment: .center)
        rightButton.button.isUserInteractionEnabled = isContactList
        rightButton.addTarget(self, action: #selector(didClickAddButton), for: .touchUpInside)
        actualNavigationItem.rightBarButtonItem = rightButton
    }

    private func initializeTableView() {
        self.tableView = UITableView(frame: .zero, style: .plain)
        self.tableView.separatorColor = UIColor.ud.N50
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.rowHeight = 68
        self.tableView.estimatedRowHeight = 0
        self.tableView.estimatedSectionHeaderHeight = 0
        self.tableView.estimatedSectionFooterHeight = 0
        self.tableView.separatorStyle = .none
        self.tableView.keyboardDismissMode = .onDrag
        self.tableView.contentInsetAdjustmentBehavior = .never
        self.tableView.backgroundColor = UIColor.ud.bgBody
        let name = String(describing: ContactTableViewCell.self)
        self.tableView.register(ContactTableViewCell.self, forCellReuseIdentifier: name)
        self.view.addSubview(self.emptyView)
        self.emptyView.backgroundColor = UIColor.ud.bgBody
        self.view.addSubview(self.noPermissionView)
        self.noPermissionView.backgroundColor = UIColor.ud.bgBody
        self.noPermissionView.isHidden = true
        self.view.addSubview(self.tableView)
        self.tableView.addBottomLoadMoreView { [weak self] in
            guard let `self` = self else {
                return
            }

            self.viewModel.fetchNameCardList(isRefresh: false)
        }
        if let header = viewModel.headerTitle {
            headerTips.labelTitle.text = header
            let size = self.headerTips.sizeThatFits(CGSize(width: self.view.bounds.width, height: 0))
            if viewModel.accountID.isEmpty {
                self.headerTips.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
                self.tableView.tableHeaderView = headerTips
            } else {
                self.headerTips.backgroundColor = UIColor.ud.bgBody
                self.view.addSubview(headerTips)
                self.headerTips.snp.makeConstraints { make in
                    make.left.right.equalToSuperview()
                    make.top.equalToSuperview()
                    make.height.equalTo(size.height)
                }
            }
        }
        self.tableView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            if viewModel.headerTitle != nil && !viewModel.accountID.isEmpty {
                make.top.equalTo(headerTips.snp.bottom)
            } else {
                make.top.equalToSuperview()
            }
        }
        self.emptyView.useCenterConstraints = true
        self.emptyView.snp.remakeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalToSuperview()
        }

        self.noPermissionView.useCenterConstraints = true
        self.noPermissionView.snp.remakeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalToSuperview()
        }

        // 指示条
        self.view.addSubview(self.sectionIndexView)
        self.sectionIndexView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(12)
            make.width.equalTo(10)
            make.height.equalTo(0)
        }
    }

    @objc
    private func didClickAddButton() {
        let nameCardEditBody = NameCardEditBody(source: "contact", accountID: viewModel.accountID)
        navigator.push(body: nameCardEditBody, from: self)
        NameCardTrack.trackClickAddInList()
        MailContactStatistics.addContact(accountType: viewModel.mailAccountType)
    }

    private func bindViewModel() {
        // 默认开始loading
        self.loadingPlaceholderView.isHidden = false
        // load逻辑在viewModel中
        self.viewModel.datasourceDriver.drive { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .empty:
                self.updateList([])
            case .success(datasource: let nameCardList):
                self.updateList(nameCardList)
            case .failure(error: let error):
                if (error.underlyingError as? APIError)?.errorCode == 250_504 {
                    self.tableView.isHidden = true
                    self.noPermissionView.isHidden = false
                    self.loadingPlaceholderView.isHidden = true
                } else {
                    self.retryLoadingView.isHidden = false
                    self.loadingPlaceholderView.isHidden = true
                    self.tableView.reloadData()
                    self.tableView.endBottomLoadMore(hasMore: true)
                    self.tableView.enableBottomLoadMore(true)
                }
            }
        }.disposed(by: self.disposeBag)

        self.viewModel.itemRemoveDriver?.drive(onNext: { [weak self] index in
            guard let self = self, self.datasource[safe: index] != nil else { return }
            let indexPath = IndexPath(item: index, section: 0)
            self.datasource.remove(at: index)
            self.tableView.deleteRows(at: [indexPath], with: .automatic)

        }).disposed(by: self.disposeBag)

        self.retryLoadingView.retryAction = { [weak self] in
            self?.loadingPlaceholderView.isHidden = false
            self?.viewModel.fetchNameCardList(isRefresh: true)
        }

        self.viewModel.fetchNameCardList(isRefresh: true)
    }

    private func updateList(_ nameCardList: [NameCardListCellViewModel]) {
        datasource = nameCardList
        retryLoadingView.isHidden = true
        loadingPlaceholderView.isHidden = true
        tableView.reloadData()
        tableView.endBottomLoadMore()
        tableView.enableBottomLoadMore(viewModel.hasMore)
        if let text = viewModel.headerTitle {
            headerTips.labelTitle.text = text
            let size = headerTips.sizeThatFits(CGSize(width: view.bounds.width, height: 0))
            headerTips.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        }
        headerTips.isHidden = nameCardList.isEmpty
        (actualNavigationItem.titleView as? NameCardNavTitleView)?.subTitleLabel.text = self.viewModel.mailAddress
    }

    /// 接收到编辑页面发出的数据更新信号后，列表需要随着更新
    @objc
    func refreshNameCardData(notification: Notification) {
        if let info = notification.userInfo,
           let accountID = info["accountID"] as? String,
           accountID != viewModel.accountID {
            // 更新的不是当前账号，不处理
            return
        } else {
            self.viewModel.fetchNameCardList(isRefresh: true)
            DispatchQueue.main.async {
                self.tableView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
            }
        }
    }

    @objc
    private func handleRemovedContact(notification: Notification) {
        (viewModel as? MailContactListViewModel)?.handleContactRemovePush(notification: notification)
    }

    /// 邮箱账号权限失效，退出当前名片列表或显示无列表人提示
    @objc
    private func onAccountPermissionLost(notification: Notification) {
        if (viewModel as? MailContactListViewModel)?.asChildList == false {
            popSelf()
        } else {
            datasource = []
            headerTips.isHidden = true
        }
    }

    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Ensure that the data source of this tableView won't be accessed by an indexPath out of range
        guard tableView.cellForRow(at: indexPath) != nil, indexPath.row < self.datasource.count else {
            return
        }
        tableView.deselectRow(at: indexPath, animated: true)

        let selectItem = self.datasource[indexPath.row]
        selectItem.didSelect(fromVC: self, accountID: viewModel.accountID, resolver: userResolver)
        NameCardListViewController
            .logger
            .info("NameCardList select at index:\(indexPath.row), item:\(selectItem.self)")
    }

    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        if !viewModel.canLeftDelete {
            return nil
        }
        return BundleI18n.LarkContact.Lark_Legacy_DeleteIt
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        self.deleteRow(indexPath: indexPath)
        tableView.setEditing(false, animated: false)
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return viewModel.canLeftDelete ? .delete : .none
    }

    @available(iOS 11.0, *)
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if !viewModel.canLeftDelete {
            return nil
        }
        let delete = UIContextualAction(style: .destructive, title: BundleI18n.LarkContact.Lark_Legacy_DeleteIt) { [weak self] (_, _, completionHandler) in
            self?.deleteRow(indexPath: indexPath)
            self?.tableView.setEditing(false, animated: false)
            completionHandler(false)
        }
        delete.backgroundColor = .ud.functionDangerFillDefault
        let configuration = UISwipeActionsConfiguration(actions: [delete])
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }

    func deleteRow(indexPath: IndexPath) {
        NameCardListViewController
            .logger
            .info("NameCardList prepare delete at index:\(indexPath.row)")
        let alertController = LarkAlertController()
        alertController.setTitle(text: BundleI18n.LarkContact.Lark_Contacts_DeleteContactCardConfirmation)
        alertController.addCancelButton()
        alertController.addPrimaryButton(text: BundleI18n.LarkContact.Lark_Contacts_Delete, dismissCompletion: { [weak self] in
            guard let `self` = self, indexPath.row < self.datasource.count else {
                return
            }
            let deleteItem = self.datasource[indexPath.row]
            self.viewModel.removeData(deleteNameCardInfo: deleteItem, atIndex: indexPath.row)
            NameCardListViewController
                .logger
                .info("NameCardList delete at index:\(indexPath.row), namecardId:\(deleteItem.entityId)")
        })
        navigator.present(alertController, from: self)
    }

    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datasource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let name = String(describing: ContactTableViewCell.self)
        if let cell = tableView.dequeueReusableCell(withIdentifier: name) as? ContactTableViewCell,
           let vm = self.datasource[safe: indexPath.row] {
            let item = ContactTableViewCellProps(nameCardCellViewModel: vm)
            cell.setProps(item)
            return cell
        } else {
            return UITableViewCell(style: .default, reuseIdentifier: "emptyCell")
        }
    }

    // MARK: UDTabsListContainerViewDelegate
    func listView() -> UIView {
        return view
    }
}

extension NameCardListViewController: UDSectionIndexViewDataSource, UDSectionIndexViewDelegate {
    func numberOfItemViews(in sectionIndexView: UDSectionIndexView) -> Int {
        return 2
    }

    func sectionIndexView(_ sectionIndexView: UDSectionIndexView, itemViewAt section: Int) -> UDSectionIndexViewItem {
        let itemView = UDSectionIndexViewItem()
//        guard section < self.datasource.count else { return itemView }

        itemView.titleFont = UIFont.systemFont(ofSize: 14)
        itemView.selectedColor = UIColor.clear
        itemView.titleSelectedColor = UIColor.ud.textLinkNormal
        itemView.titleColor = UIColor.ud.textPlaceholder
        itemView.title = "self.datasource[section].groupTitle"
        return itemView
    }

    func sectionIndexView(_ sectionIndexView: UDSectionIndexView, itemPreviewFor section: Int) -> UDSectionIndexViewItemPreview {
        let preview = UDSectionIndexViewItemPreview(title: "self.datasource[section].groupTitle", type: .drip)
        preview.color = UIColor.ud.colorfulBlue
        return preview
    }

    func sectionIndexView(_ sectionIndexView: UDSectionIndexView, didSelect section: Int) {
        self.impactFeedbackGenerator.prepare()
        self.impactFeedbackGenerator.impactOccurred()
        sectionIndexView.selectItem(at: section)
        sectionIndexView.showItemPreview(at: section, hideAfter: 0.2)
        // 过滤空section的情况
        if tableView(self.tableView, numberOfRowsInSection: section) > 0 {
            self.tableView.scrollToRow(at: IndexPath(row: 0, section: section), at: .top, animated: false)
        }
        Tracer.trackExternalLetterClick()
    }

    func sectionIndexView(_ sectionIndexView: UDSectionIndexView, toucheMoved section: Int) {
        self.impactFeedbackGenerator.prepare()
        self.impactFeedbackGenerator.impactOccurred()
        sectionIndexView.selectItem(at: section)
        sectionIndexView.showItemPreview(at: section)
        // 过滤空section的情况
        if tableView(self.tableView, numberOfRowsInSection: section) > 0 {
            self.tableView.scrollToRow(at: IndexPath(row: 0, section: section), at: .top, animated: false)
        }
    }

    func sectionIndexView(_ sectionIndexView: UDSectionIndexView, toucheCancelled section: Int) {}
}

final class MailGroupTaleHeaderTipsView: UIView {
    var labelTitle: UILabel = {
        var label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 2
        label.textColor = UIColor.ud.textCaption
        return label
    }()

    var line: UIView = {
        var view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }()

    override func layoutSubviews() {
        super.layoutSubviews()

        labelTitle.frame = CGRect(x: 16, y: 12, width: self.bounds.width - 32, height: self.bounds.height - 24)
        line.frame = CGRect(x: 0, y: self.bounds.height - 0.5, width: self.bounds.width, height: 0.5)
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        labelTitle.frame = CGRect(x: 0, y: 0, width: size.width - 32, height: 0)
        labelTitle.sizeToFit()
        return CGSize(width: labelTitle.frame.width + 32, height: labelTitle.frame.height + 24)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.addSubview(labelTitle)
        self.addSubview(line)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
