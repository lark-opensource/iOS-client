//
//  ContactApplicationViewController.swift
//  LarkContact
//
//  Created by 姚启灏 on 2018/8/5.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import LarkModel
import LarkUIKit
import UniverseDesignToast
import LarkSDKInterface
import LarkAccountInterface
import LKCommonsLogging
import LarkMessengerInterface
import AppReciableSDK
import UniverseDesignEmpty
import LarkContainer
import LarkContactComponent

protocol ContactApplicationViewControllerRouter {
    func pushPersonalCardVC(_ vc: ContactApplicationViewController, chatterId: String)
    func pushAddFriendFromContact(_ vc: ContactApplicationViewController,
                                  _ inviteInfo: InviteAggregationInfo,
                                  _ source: ExternalInviteSourceEntrance)
    func pushExternalInviteFromContactApplicationPage(_ vc: ContactApplicationViewController)
}

final class ContactApplicationViewController: BaseUIViewController, UITableViewDelegate, UITableViewDataSource {

    public var router: ContactApplicationViewControllerRouter?
    static let logger = Logger.log(ContactApplicationViewController.self, category: "LarkContact.ContactApplicationViewController")

    private let disposeBag = DisposeBag()
    private var chatApplications: [ChatApplication] = [] {
        didSet {
            if chatApplications.isEmpty {
                self.tableView.isHidden = true
                self.emptyView.isHidden = false
            }
        }
    }
    private let userResolve: UserResolver
    private let passportUserService: PassportUserService
    private let tenantNameService: LarkTenantNameService

    private var hasMore: Bool = false
    private let pageSize = 20

    fileprivate var tableView: UITableView = .init(frame: .zero)
    fileprivate var viewModel: ContactApplicationViewModel
    fileprivate let emptyView = UDEmptyView(config: UDEmptyConfig(description: UDEmptyConfig.Description(descriptionText: BundleI18n.LarkContact.Lark_Legacy_ApplicationEmpty), type: .noContact))
    private lazy var inviteEntryView: ExternalContactInviteEntryView = {
        let title = !viewModel.isCurrentAccountInfoSimple ?
            BundleI18n.LarkContact.Lark_NewContacts_AddExternalContactsB :
            BundleI18n.LarkContact.Lark_NewContacts_AddContactsb
        let view = ExternalContactInviteEntryView(title: title)
        view.lu.addTapGestureRecognizer(action: #selector(pushExternalInvitePage), target: self)
        return view
    }()
    private lazy var addContactEntry: InviteEntryView = {
        let view = InviteEntryView(
            icon: Resources.add_friend_from_contact,
            title: BundleI18n.LarkContact.Lark_NewContacts_AddExternalContacts_ImportFromContacts
        )
        view.addTarget(self, action: #selector(pushAddFriendFromContact), for: .touchUpInside)
        return view
    }()
    private lazy var entryContainer: UIView = {
        let view = UIView()
        return view

    }()

    init(viewModel: ContactApplicationViewModel,
         router: ContactApplicationViewControllerRouter? = nil,
         resolver: UserResolver) throws {
        self.viewModel = viewModel
        self.router = router
        self.userResolve = resolver
        self.passportUserService = try resolver.resolve(assert: PassportUserService.self)
        self.tenantNameService = try resolver.resolve(assert: LarkTenantNameService.self)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NewContactsAppReciableTrack.newContactPageLoadEnd()
        Tracer.trackContactNewContactShow()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = BundleI18n.LarkContact.Lark_Legacy_ContactsNew
        self.addInviteAndImportEntryIfNeeded()
        self.initializeTableView()
        self.bindViewModel()
        isToolBarHidden = true
    }

    private func addInviteAndImportEntryIfNeeded() {
        if viewModel.hasInviteEntry {
            view.addSubview(entryContainer)
            entryContainer.addSubview(inviteEntryView)
            entryContainer.snp.makeConstraints { (make) in
                make.top.equalToSuperview().offset(8)
                make.left.right.equalToSuperview()
                make.height.equalTo(66)
            }
            inviteEntryView.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
        }
    }

    private func initializeTableView() {
        self.view.backgroundColor = UIColor.ud.bgBase
        self.tableView = UITableView(frame: .zero, style: .grouped)
        self.tableView.delegate = self
        self.tableView.dataSource = self
        tableView.estimatedRowHeight = 64
        tableView.rowHeight = UITableView.automaticDimension
        self.tableView.separatorStyle = .none
        self.tableView.backgroundColor = UIColor.ud.bgBody
        self.tableView.keyboardDismissMode = .onDrag
        self.tableView.contentInsetAdjustmentBehavior = .never
        let name = String(describing: ContactApplicationTableViewCell.self)
        self.tableView.register(ContactApplicationTableViewCell.self, forCellReuseIdentifier: name)
        let identifier = String(describing: DataItemViewCell.self)
        self.tableView.register(DataItemViewCell.self, forCellReuseIdentifier: identifier)
        self.tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: CGFloat.leastNormalMagnitude))
        self.view.addSubview(self.emptyView)
        self.view.addSubview(self.tableView)
        self.tableView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            if viewModel.hasInviteEntry {
                make.top.equalTo(entryContainer.snp.bottom).offset(8)
            } else {
                make.top.equalToSuperview()
            }
        }
        self.emptyView.useCenterConstraints = true
        self.emptyView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
           if viewModel.hasInviteEntry {
               make.top.equalTo(entryContainer.snp.bottom).offset(8)
           } else {
               make.top.equalToSuperview()
           }
        }
    }

    @objc
    func pushExternalInvitePage() {
        self.router?.pushExternalInviteFromContactApplicationPage(self)
        ContactTracker.New.Click.AddExternal()
    }

    private func bindViewModel() {
        self.loadingPlaceholderView.isHidden = false

        self.viewModel.datasourceDriver.drive(onNext: { [weak self] (applications) in
            self?.chatApplications = applications
            self?.loadingPlaceholderView.isHidden = true
            self?.tableView.reloadData()
        }).disposed(by: self.disposeBag)

        self.viewModel.hasMoreDriver.drive(onNext: { [weak self] (hasMore) in
            guard let `self` = self else { return }
            self.tableView.endBottomLoadMore()
            self.hasMore = hasMore
            if hasMore {
                self.tableView.addBottomLoadMoreView { [weak self] in
                    self?.viewModel.loadMore()
                }
            } else {
                self.tableView.removeBottomLoadMore()
            }
        }).disposed(by: self.disposeBag)

        self.viewModel.preloadData()
    }

    private func pushPersonalCardVC(indexPath: IndexPath) {
        let application = self.chatApplications[indexPath.row]
        self.router?.pushPersonalCardVC(self, chatterId: application.contactSummary.userId)
    }

    @objc
    func pushAddFriendFromContact() {
        let hud = UDToast.showLoading(on: self.view, disableUserInteraction: true)

        viewModel.fetchInviteLinkInfo()
            .timeout(.seconds(5), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] (inviteInfo) in
                hud.remove()
                guard let `self` = self else { return }
                self.router?.pushAddFriendFromContact(self, inviteInfo, .contactNew)
            }, onError: { error in
                hud.remove()
                ContactApplicationViewController.logger.error("fetchInviteLink failed", error: error)
            }).disposed(by: disposeBag)
    }

    private func agreeAppliction(indexPath: IndexPath) {
        let key = AppReciableSDK.shared.start(biz: .Messenger,
                                              scene: .Contact,
                                              event: .contactOptApproveApplication,
                                              page: nil)
        self.viewModel.agreeApplication(index: indexPath.row)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                Tracer.trackContactApproveFriendSuccess()
                AppReciableSDK.shared.end(key: key)
                guard let window = self?.view.window else { return }
                UDToast.showTips(with: BundleI18n.LarkContact.Lark_NewContacts_AcceptedContactRequestToast(), on: window)
            }, onError: { [weak self] (error) in
                guard let window = self?.view.window else {
                    return
                }
                var alertMessage = BundleI18n.LarkContact.Lark_Legacy_ErrorMessageTip
                if let error = error.underlyingError as? APIError {
                    switch error.type {
                    case .targetExternalCoordinateCtl, .externalCoordinateCtl:
                        alertMessage = BundleI18n
                            .LarkContact
                            .Lark_Contacts_CantCompleteOperationNoExternalCommunicationPermission
                    default:
                        break
                    }
                    Tracer.trackContactApproveFriendFail(errorCode: error.code, errorMsg: "\(error)")
                    AppReciableSDK.shared.error(params: ErrorParams(biz: .Messenger,
                                                                    scene: .Contact,
                                                                    event: .contactOptApproveApplication,
                                                                    errorType: .Network,
                                                                    errorLevel: .Exception,
                                                                    errorCode: Int(error.code),
                                                                    userAction: nil,
                                                                    page: nil,
                                                                    errorMessage: error.serverMessage))

                }
                UDToast.showFailure(with: alertMessage, on: window, error: error)
            }).disposed(by: disposeBag)
        let userID = passportUserService.user.userID
        Tracer.trackContactNewContactAgreeClick(userID: userID)
    }

    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Ensure that the data source of this tableView won't be accessed by an indexPath out of range
        guard tableView.cellForRow(at: indexPath) != nil else { return }

        tableView.deselectRow(at: indexPath, animated: true)
        pushPersonalCardVC(indexPath: indexPath)
        ContactTracker.New.Click.MemberAvatar()
    }

    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return BundleI18n.LarkContact.Lark_Legacy_DeleteIt
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            deleteApplication(indexPath, tableView)
        }
    }

    private func deleteApplication(_ indexPath: IndexPath, _ tableView: UITableView) {
        chatApplications.remove(at: indexPath.row)
        if chatApplications.isEmpty {
            tableView.deleteSections([indexPath.section], animationStyle: .none)
        } else {
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
        delete(indexPath: indexPath)
        tableView.setEditing(false, animated: false)
    }

    @available(iOS 11.0, *)
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(style: .destructive, title: BundleI18n.LarkContact.Lark_Legacy_DeleteIt) { [weak self] (_, _, completionHandler) in
            guard let self = self else {
                return
            }
            self.deleteApplication(indexPath, self.tableView)
            completionHandler(false)
        }

        let configuration = UISwipeActionsConfiguration(actions: [delete])
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }

    func delete(indexPath: IndexPath) {
        self.viewModel.removeData(index: indexPath.row)
        if self.chatApplications.count < self.pageSize, self.hasMore {
            self.tableView.removeBottomLoadMore()
            self.viewModel.loadMore()
        }
    }
    // MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        if chatApplications.isEmpty {
            return 0
        }
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatApplications.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let name = String(describing: ContactApplicationTableViewCell.self)
        if let cell = tableView.dequeueReusableCell(withIdentifier: name) as? ContactApplicationTableViewCell {
            let model: ChatApplication = chatApplications[indexPath.row]
            cell.setContent(model,
                            delegate: self,
                            tenantNameService: tenantNameService)
            let tenantNameStatus = model.contactSummary.tenantNameStatus
            let tenantNameIsEmpty = model.contactSummary.tenantName.isEmpty
            let certificateStatus = model.contactSummary.certificationInfo.certificateStatus
            Self.logger.info("index row: \(indexPath.row) tenantNameStatus: \(tenantNameStatus) tenantNameIsEmpty: \(tenantNameIsEmpty) status: \(model.status) certificateStatus: \(certificateStatus)")
            return cell
        } else {
            return UITableViewCell(style: .default, reuseIdentifier: "emptyCell")
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? 5 : CGFloat.leastNonzeroMagnitude
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section > 0 else { return nil }
        let view = UIView(frame: CGRect(x: 0, y: 0, width: self.tableView.bounds.width, height: 5))
        view.backgroundColor = UIColor.ud.bgBody
        return view
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNonzeroMagnitude
    }

}

extension ContactApplicationViewController: ContactApplicationTableViewCellDelegate {
    func viewAction(_ cell: ContactApplicationTableViewCell) {
        guard let index = self.tableView.indexPath(for: cell) else {
            return
        }
        agreeAppliction(indexPath: index)
    }
}
