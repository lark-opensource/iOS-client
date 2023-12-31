//
//  GroupedExternalContactsViewController.swift
//  LarkContact
//
//  Created by zhenning on 2021/03/20.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import LarkModel
import LarkActionSheet
import LarkUIKit
import EENavigator
import LarkSDKInterface
import LarkAddressBookSelector
import UniverseDesignActionPanel
import UniverseDesignEmpty
import UniverseDesignTabs
import LarkFeatureGating
import LarkContainer
import LKCommonsLogging
import LarkContactComponent

protocol GroupedExternalContactsViewControllerRouter {
    func pushPersonalCardVC(_ vc: GroupedExternalContactsViewController, chatterId: String)
    func pushExternalInvitePage(_ vc: GroupedExternalContactsViewController)
}

final class GroupedExternalContactsViewController: BaseUIViewController, UITableViewDelegate, UITableViewDataSource {

    public var router: GroupedExternalContactsViewControllerRouter?
    static let logger = Logger.log(GroupedExternalContactsViewController.self, category: "LarkContact.GroupedExternalContactsViewController")
    private var datasource: [ContactsGroupInfo] = [] {
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
    // 别名 FG
    @FeatureGating("lark.chatter.name_with_another_name_p2") private var isSupportAnotherNameFG: Bool

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.separatorColor = UIColor.ud.lineDividerDefault
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 68
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .onDrag
        tableView.contentInsetAdjustmentBehavior = .never
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 6))
        headerView.backgroundColor = UIColor.ud.bgBody
        tableView.tableHeaderView = headerView
        #if swift(>=5.5)
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        #endif
        let name = String(describing: ContactTableViewCell.self)
        tableView.register(ContactTableViewCell.self, forCellReuseIdentifier: name)
        return tableView
    }()

    private lazy var sectionIndexView: UDSectionIndexView = {
        let indexView = UDSectionIndexView(frame: .zero)
        indexView.delegate = self
        indexView.dataSource = self
        indexView.itemPreviewMargin = Layout.sectionIndexitemPreviewMargin
        return indexView
    }()
    private let impactFeedbackGenerator: UIImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)

    private let viewModel: GroupedExternalContactsViewModel
    private let emptyView = UDEmptyView(
        config: UDEmptyConfig(description: UDEmptyConfig.Description(descriptionText: BundleI18n.LarkContact.Lark_Legacy_ContactEmpty),
        type: .noContact)
    )
    private lazy var inviteEntryView: ExternalContactInviteEntryView = {
        let title = !viewModel.isCurrentAccountInfoSimple ?
            BundleI18n.LarkContact.Lark_NewContacts_AddExternalContactsB :
            BundleI18n.LarkContact.Lark_NewContacts_AddContactsb
        let view = ExternalContactInviteEntryView(title: title)
        view.lu.addTapGestureRecognizer(action: #selector(pushExternalInvitePage), target: self)
        return view
    }()
    private let userResolver: UserResolver
    private let tenantNameService: LarkTenantNameService

    init(viewModel: GroupedExternalContactsViewModel, router: GroupedExternalContactsViewControllerRouter? = nil, resolver: UserResolver) throws {
        self.router = router
        self.viewModel = viewModel
        self.userResolver = resolver
        self.tenantNameService = try resolver.resolve(assert: LarkTenantNameService.self)
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
        self.setupNavigationBar()
        self.addInviteEntryIfNeeded()
        self.initializeTableView()
        self.bindViewModel()
        ExternalContactsAppReciableTrack.externalContactsPageFirstRenderCostTrack()
        ContactTracker.External.View(resolver: userResolver)
    }

    private func setupNavigationBar() {
        isNavigationBarHidden = false
        let naviBarTitle = viewModel.isCurrentAccountInfoSimple
            ? BundleI18n.LarkContact.Lark_Legacy_Contact
            : BundleI18n.LarkContact.Lark_Legacy_StructureExternal
        self.title = naviBarTitle
    }

    private func addInviteEntryIfNeeded() {
        if viewModel.hasInviteEntry {
            view.addSubview(inviteEntryView)
            inviteEntryView.snp.makeConstraints { (make) in
                make.top.equalToSuperview().offset(8)
                make.left.right.equalToSuperview()
                make.height.equalTo(66)
            }
        }
    }

    private func initializeTableView() {
        self.view.addSubview(self.emptyView)
        self.view.addSubview(self.tableView)

        self.view.backgroundColor = UIColor.ud.bgBase
        self.tableView.backgroundColor = UIColor.ud.bgBody
        self.tableView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            if viewModel.hasInviteEntry {
                make.top.equalTo(inviteEntryView.snp.bottom).offset(8)
            } else {
                make.top.equalToSuperview()
            }
        }
        self.emptyView.useCenterConstraints = true
        self.emptyView.snp.remakeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
           if viewModel.hasInviteEntry {
               make.top.equalTo(inviteEntryView.snp.bottom).offset(8)
           } else {
               make.top.equalToSuperview()
           }
        }
        // 指示条
        self.view.addSubview(self.sectionIndexView)
        self.sectionIndexView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(Layout.sectionIndexViewRight)
            make.width.equalTo(Layout.sectionIndexViewWidth)
            make.height.equalTo(0)
        }
    }

    private func bindViewModel() {
        // 默认开始loading
        self.loadingPlaceholderView.isHidden = false
        // load逻辑在viewModel中
        self.viewModel.datasourceObservable.subscribe(onNext: { [weak self] (groupedContacts) in
            self?.datasource = groupedContacts
            self?.loadingPlaceholderView.isHidden = true
            self?.tableView.reloadData()
            self?.refreshSectionIndexView()
        }, onError: { [weak self] _ in
            self?.loadingPlaceholderView.isHidden = true
            // 显示空页面
            self?.datasource = []
            self?.tableView.reloadData()
        }).disposed(by: self.disposeBag)

        // 全部加载
        self.viewModel.loadData()
        self.viewModel.observePushData()
    }

    @objc
    func pushExternalInvitePage() {
        Tracer.trackExternalInvite("external_contacts")
        self.router?.pushExternalInvitePage(self)
        ContactTracker.External.Click.AddExternal()
    }

    private func refreshSectionIndexView() {
        self.sectionIndexView.snp.updateConstraints({ (make) in
            make.height.equalTo(Layout.sectionIndexItemHeight * CGFloat(self.datasource.count))
        })
        self.sectionIndexView.superview?.layoutIfNeeded()
        self.sectionIndexView.reloadData()
        self.sectionIndexView.selectItem(at: 0)
    }

    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Ensure that the data source of this tableView won't be accessed by an indexPath out of range
        guard tableView.cellForRow(at: indexPath) != nil else { return }

        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section < datasource.count {
            let contact = datasource[indexPath.section].contacts[indexPath.row]
            self.router?.pushPersonalCardVC(self, chatterId: contact.userID)
            ContactTracker.External.Click.MemberAvatar()
        }
    }

    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return BundleI18n.LarkContact.Lark_Legacy_DeleteIt
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        self.deleteRow(indexPath: indexPath)
        tableView.setEditing(false, animated: false)
    }

    @available(iOS 11.0, *)
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(style: .destructive, title: BundleI18n.LarkContact.Lark_Legacy_DeleteIt) { [weak self] (_, _, completionHandler) in
            self?.deleteRow(indexPath: indexPath)
            tableView.setEditing(false, animated: false)
            completionHandler(false)
        }

        let configuration = UISwipeActionsConfiguration(actions: [delete])
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }

    func deleteRow(indexPath: IndexPath) {
        let actionSheet = UDActionSheet(config: UDActionSheetUIConfig(style: .autoAlert, isShowTitle: true))
        actionSheet.setTitle(BundleI18n.LarkContact.Lark_Legacy_DialogDeleteExternalContactTitle)
        actionSheet.addDestructiveItem(text: BundleI18n.LarkContact.Lark_Legacy_DeleteIt) { [weak self] in
            guard let `self` = self, indexPath.section < self.datasource.count else { return }

            let contactGroup = self.datasource[indexPath.section]

            guard indexPath.row < contactGroup.contacts.count else { return }

            let deleteItem = contactGroup.contacts[indexPath.row]

            self.datasource[indexPath.section].contacts.remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
            self.viewModel.removeData(deleteContactInfo: deleteItem)
        }
        actionSheet.setCancelItem(text: BundleI18n.LarkContact.Lark_Legacy_Cancel)
        userResolver.navigator.present(actionSheet, from: self)
    }

    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section < datasource.count  else { return 0 }

        let contactGroup = datasource[section]
        return contactGroup.contacts.count
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return datasource.count
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section < datasource.count, !viewModel.diableGroup else { return nil }

        let titleLable = UILabel()
        let insert: CGFloat = 14
        titleLable.frame = CGRect(x: insert, y: 6, width: self.tableView.bounds.width - insert * 2, height: 18)
        titleLable.font = UIFont.systemFont(ofSize: 14)
        titleLable.textColor = UIColor.ud.textCaption
        titleLable.text = self.tableView(tableView, titleForHeaderInSection: section)
        let headerView = UIView()
        headerView.backgroundColor = UIColor.ud.bgBody
        headerView.addSubview(titleLable)
        return headerView
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = UIColor.ud.bgBase
        return headerView
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard section < datasource.count, !viewModel.diableGroup else { return nil }
        let contactGroup = datasource[section]
        return contactGroup.groupTitle
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return viewModel.diableGroup ? CGFloat.leastNonzeroMagnitude : 28
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let name = String(describing: ContactTableViewCell.self)
        if let cell = tableView.dequeueReusableCell(withIdentifier: name) as? ContactTableViewCell,
           indexPath.section < datasource.count {
            let contactGroup: ContactsGroupInfo = self.datasource[indexPath.section]
            let contactInfo: ContactInfo = contactGroup.contacts[indexPath.row]
            let item = ContactTableViewCellProps(contactInfo: contactInfo, isSupportAnotherName: isSupportAnotherNameFG)
            let tenantNameStatus = contactInfo.tenantNameStatus
            let tenantNameIsEmpty = contactInfo.tenantName.isEmpty
            let certificateStatus = contactInfo.certificationInfo.certificateStatus
            Self.logger.info("index section: \(indexPath.section) row: \(indexPath.row) tenantNameStatus: \(tenantNameStatus) tenantNameIsEmpty: \(tenantNameIsEmpty) certificateStatus: \(certificateStatus)")
            cell.setProps(item, tenantNameService: tenantNameService)
            return cell
        } else {
            return UITableViewCell(style: .default, reuseIdentifier: "emptyCell")
        }
    }

    // MARK: - UIScrollViewDelegate
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if let section = self.tableView.indexPathsForVisibleRows?.first?.section,
            self.sectionIndexView.currentItem != self.sectionIndexView.item(at: section) {
            self.sectionIndexView.selectItem(at: section)
        }
    }
}

// MARK: - SectionIndexViewDataSource

extension GroupedExternalContactsViewController: UDSectionIndexViewDataSource, UDSectionIndexViewDelegate {

    func numberOfItemViews(in sectionIndexView: UDSectionIndexView) -> Int {
        return self.datasource.count
    }

    func sectionIndexView(_ sectionIndexView: UDSectionIndexView, itemViewAt section: Int) -> UDSectionIndexViewItem {
        let itemView = UDSectionIndexViewItem()
        guard section < self.datasource.count else { return itemView }

        itemView.titleFont = UIFont.systemFont(ofSize: 14)
        itemView.selectedColor = UIColor.clear
        itemView.titleSelectedColor = UIColor.ud.textLinkNormal
        itemView.titleColor = UIColor.ud.textPlaceholder
        itemView.title = self.datasource[section].groupTitle
        return itemView
    }

    func sectionIndexView(_ sectionIndexView: UDSectionIndexView,
                          itemPreviewFor section: Int) -> UDSectionIndexViewItemPreview {
        let preview = UDSectionIndexViewItemPreview(title: self.datasource[section].groupTitle, type: .drip)
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

extension GroupedExternalContactsViewController {
    enum Layout {
        static let sectionIndexViewWidth: CGFloat = 20
        static let sectionIndexViewRight: CGFloat = -6
        static let sectionIndexItemHeight: CGFloat = 16
        static let sectionIndexitemPreviewMargin: CGFloat = 20
    }
}
