//
//  NewExternalContactsViewController.swift
//  LarkContact
//
//  Created by zhenning on 2020/07/20.
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
import UniverseDesignActionPanel
import UniverseDesignEmpty
import LarkFeatureGating
import LarkContainer

protocol NewExternalContactsViewControllerRouter {
    func pushPersonalCardVC(_ vc: NewExternalContactsViewController, chatterId: String)
    func pushExternalInvitePage(_ vc: NewExternalContactsViewController)
}

final class NewExternalContactsViewController: BaseUIViewController, UITableViewDelegate, UITableViewDataSource, UserResolverWrapper {
    // 别名 FG
    @FeatureGating("lark.chatter.name_with_another_name_p2") private var isSupportAnotherNameFG: Bool
    public var router: NewExternalContactsViewControllerRouter?

    private var datasource: [ContactInfo] = [] {
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
    var userResolver: LarkContainer.UserResolver
    private let disposeBag = DisposeBag()

    fileprivate var tableView: UITableView = .init(frame: .zero)
    fileprivate let viewModel: NewExternalContactsViewModel
    fileprivate let emptyView = UDEmptyView(
        config: UDEmptyConfig(description: UDEmptyConfig.Description(descriptionText: BundleI18n.LarkContact.Lark_Legacy_ContactEmpty),
        type: .noContact)
    )
    private lazy var inviteEntryView: ExternalContactInviteEntryView = {
        let title = !viewModel.isCurrentAccountInfoSimple ?
            BundleI18n.LarkContact.Lark_NewContacts_AddExternalContactsB :
            BundleI18n.LarkContact.Lark_NewContacts_AddContactsb
        let view = ExternalContactInviteEntryView(title: title)
        view.addTarget(self, action: #selector(pushExternalInvitePage), for: .touchUpInside)
        return view
    }()

    init(viewModel: NewExternalContactsViewModel, router: NewExternalContactsViewControllerRouter? = nil, resolver: UserResolver) {
        self.router = router
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
        self.setupNavigationBar()
        self.addInviteEntryIfNeeded()
        self.initializeTableView()
        self.bindViewModel()
        ExternalContactsAppReciableTrack.externalContactsPageFirstRenderCostTrack()
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
                make.height.equalTo(54)
            }
        }
    }

    private func initializeTableView() {
        self.tableView = UITableView(frame: .zero, style: .plain)
        self.tableView.separatorColor = UIColor.ud.N50
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.rowHeight = 68
        self.tableView.separatorStyle = .none
        self.tableView.keyboardDismissMode = .onDrag
        self.tableView.contentInsetAdjustmentBehavior = .never
        let name = String(describing: ContactTableViewCell.self)
        self.tableView.register(ContactTableViewCell.self, forCellReuseIdentifier: name)
        self.view.addSubview(self.emptyView)
        self.view.addSubview(self.tableView)
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
    }

    private func bindViewModel() {
        // 默认开始loading
        self.loadingPlaceholderView.isHidden = false
        // load逻辑在viewModel中
        self.viewModel.datasourceObservable.subscribe(onNext: { [weak self] (contacts) in
            self?.datasource = contacts
            self?.loadingPlaceholderView.isHidden = true
            self?.tableView.reloadData()
        }, onError: { [weak self] _ in
            self?.loadingPlaceholderView.isHidden = true
            // 显示空页面
            self?.datasource = []
            self?.tableView.reloadData()
        }).disposed(by: self.disposeBag)

        // 全部加载
        self.viewModel.loadData(loadAll: true)
        self.viewModel.observePushData()
    }

    @objc
    func pushExternalInvitePage() {
        Tracer.trackExternalInvite("external_contacts")
        self.router?.pushExternalInvitePage(self)
    }

    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Ensure that the data source of this tableView won't be accessed by an indexPath out of range
        guard tableView.cellForRow(at: indexPath) != nil else { return }

        tableView.deselectRow(at: indexPath, animated: true)
        self.router?.pushPersonalCardVC(self, chatterId: datasource[indexPath.row].userID)
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
            guard let `self` = self, indexPath.row < self.datasource.count else {
                return
            }
            let deleteItem = self.datasource[indexPath.row]
            self.datasource.remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
            self.viewModel.removeData(deleteContactInfo: deleteItem)
            if self.datasource.count <= self.viewModel.pageSize, self.viewModel.hasMore {
                self.tableView.removeBottomLoadMore()
                self.viewModel.loadData()
            }
        }
        actionSheet.setCancelItem(text: BundleI18n.LarkContact.Lark_Legacy_Cancel)
        navigator.present(actionSheet, from: self)
    }

    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datasource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let name = String(describing: ContactTableViewCell.self)
        if let cell = tableView.dequeueReusableCell(withIdentifier: name) as? ContactTableViewCell {
            let contactInfo: ContactInfo = self.datasource[indexPath.row]
            let item = ContactTableViewCellProps(contactInfo: contactInfo, isSupportAnotherName: isSupportAnotherNameFG)
            cell.setProps(item)
            return cell
        } else {
            return UITableViewCell(style: .default, reuseIdentifier: "emptyCell")
        }
    }
}
