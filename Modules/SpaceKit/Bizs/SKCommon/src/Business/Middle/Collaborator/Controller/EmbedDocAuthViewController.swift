//
//  EmbedDocAuthViewController.swift
//  SKCommon
//
//  Created by guoqp on 2022/2/28.
//
// swiftlint:disable file_length

import SKResource
import SKUIKit
import SKFoundation
import SwiftyJSON
import EENavigator
import UniverseDesignToast
import LarkTraitCollection
import RxSwift
import UniverseDesignActionPanel
import UniverseDesignColor
import UniverseDesignInput
import UniverseDesignEmpty
import SwiftUI
import LarkUIKit
import UniverseDesignDialog
import SpaceInterface


private let cellReuseIdentifier: String = "EmbedDocAuthCell"

public final class EmbedDocAuthViewController: BaseViewController {

    let disposeBag: DisposeBag = DisposeBag()

    let vm: EmbedDocAuthViewModel
    let body: EmbedDocAuthControllerBody
    private let permStatistics: PermissionStatistics
    /// 是否群聊（埋点用）
    var isGroupChat: Bool { body.chatType == 2 }

    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 0.1))
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 0.1))
        tableView.allowsSelection = true
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UDColor.bgBody
        tableView.rowHeight = 66
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorStyle = .none
        tableView.register(EmbedDocAuthCell.self, forCellReuseIdentifier: cellReuseIdentifier)
        return tableView
    }()

    private lazy var emptyView: UDEmpty = {
        let emptyView = UDEmpty(config: .init(title: .init(titleText: ""),
                                                  description: .init(descriptionText: BundleI18n.SKResource.CreationMobile_Common_Placeholder_FailedToLoad),
                                                  imageSize: 100,
                                                  type: .loadingFailure,
                                                  labelHandler: nil,
                                                  primaryButtonConfig: nil,
                                              secondaryButtonConfig: nil))
        return emptyView
    }()

    private lazy var failView: UIView = {
        let view = UIView()
        view.isHidden = true
        return view
    }()

    public init(body: EmbedDocAuthControllerBody) {
        self.body = body
        vm = EmbedDocAuthViewModel(body: body)
        let ccmCommonParameters = CcmCommonParameters(fileId: DocsTracker.encrypt(id: body.objToken),
                                                      fileType: DocsType(rawValue: body.docsType).name,
                                                      module: DocsType(rawValue: body.docsType).name,
                                                      userPermRole: 0,
                                                      userPermissionRawValue: 0,
                                                      publicPermission: nil)
        self.permStatistics = PermissionStatistics(ccmCommonParameters: ccmCommonParameters)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func retryButtonClick(_ button: UIButton) {
        requestEmbedDocAuthList()
    }
}

extension EmbedDocAuthViewController {
    public override func viewDidLoad() {
        super.viewDidLoad()

        self.title = BundleI18n.SKResource.CreationMobile_Docs_EmbeddedFiles_AccessDetails_Title

        view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.top.equalTo(self.navigationBar.snp.bottom).offset(1)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }

        view.addSubview(failView)
        failView.addSubview(emptyView)

        view.bringSubviewToFront(self.navigationBar)

        requestEmbedDocAuthList()
        setupNetworkMonitor()

        permStatistics.reportPermissionCitedDocAuthorizeView(isGroupChat: isGroupChat)
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        embededDocUpdateCard()
        removeToast()
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        addHeaderView()
    }

    public override func backBarButtonItemAction() {
        self.permStatistics.reportPermissionCitedDocAuthorizeClick(clickType: .back, isGroupChat: isGroupChat)
        super.backBarButtonItemAction()
    }

    private func updateEmptyType(type: UDEmptyType) {
        switch type {
        case .loadingFailure:
            self.emptyView.update(config: .init(title: .init(titleText: ""),
                                                description: .init(descriptionText: BundleI18n.SKResource.CreationMobile_Common_Placeholder_FailedToLoad),
                                                imageSize: 100,
                                                type: .loadingFailure,
                                                labelHandler: nil,
                                                primaryButtonConfig: (BundleI18n.SKResource.CreationMobile_Common_ButtonRetry, { [weak self] button in
          guard let self = self else { return }
          self.retryButtonClick(button)
     }), secondaryButtonConfig: nil))
        case .noWifi:
            self.emptyView.update(config: .init(title: .init(titleText: ""),
                                                description: .init(descriptionText: BundleI18n.SKResource.CreationMobile_Common_NoInternet),
                                                imageSize: 100,
                                                type: .noWifi,
                                                labelHandler: nil,
                                                primaryButtonConfig: nil,
                                                secondaryButtonConfig: nil))
        default: break
        }
    }

    private func addHeaderView() {
        let headerView = EmbedDocAuthHeaderView(width: view.frame.width)
        headerView.update(chatName: body.chatName, detail: body.detail,
                          roleType: CollaboratorType(rawValue: body.chatType) ?? .user,
                          imageKey: body.chatAvatar, chatID: body.chatID)
        headerView.click = { [weak self] userID, name in
            guard let self = self else { return }
            HostAppBridge.shared.call(ShowUserProfileService(userId: userID, fileName: name, fromVC: self))
        }
        let height = headerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
        headerView.frame = CGRect(x: 0, y: 0, width: 0, height: height)
        tableView.tableHeaderView = headerView

        ///为了位置居中显示
        failView.snp.remakeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(view.safeAreaLayoutGuide.layoutFrame.height - height)
        }
        emptyView.snp.remakeConstraints { make in
            make.centerY.centerX.equalToSuperview()
        }
    }

    private func setupNetworkMonitor() {
        DocsNetStateMonitor.shared.addObserver(self) { (networkType, isReachable) in
            DocsLogger.info("Current networkType info, networkType: \(networkType), isReachable: \(isReachable)")
            DispatchQueue.main.async { [weak self] in  // 监听网络变化的对象比较多，避免在同一个runloop执行操作卡顿
                guard let self = self else { return }
                if isReachable, self.vm.embedDocs.count == 0 {
                    self.requestEmbedDocAuthList()
                }
            }
        }
    }

    private func openDoc(doc: EmbedDoc) {
        let file = SpaceEntryFactory.createEntry(type: DocsType(rawValue: doc.type), nodeToken: "", objToken: doc.token)
        let body = SKEntryBody(file)
        let context: [String: Any] = [SKEntryBody.fileEntryListKey: [file],
                                      SKEntryBody.fromKey: FileListStatistics.Module.unknown]
        Navigator.shared.docs.showDetailOrPush(body: body, context: context, wrap: LkNavigationController.self, from: self)
    }
}

extension EmbedDocAuthViewController {
    func requestEmbedDocAuthList() {
        guard DocsNetStateMonitor.shared.isReachable else {
            updateEmptyType(type: .noWifi)
            self.failView.isHidden = (self.vm.embedDocs.count > 0)
            return
        }
        showLoading(duration: 0)
        vm.embededDocAuthList { [weak self] result in
            guard let self = self else { return }
            self.hideLoading()
            self.updateEmptyType(type: .loadingFailure)
            self.failView.isHidden = (self.vm.embedDocs.count > 0)
            switch result {
            case .Success:
                self.tableView.reloadData()
            default: break
            }
        }
    }
    
    func cancelAuthFor(doc: EmbedDoc) {
        let role = doc.permType == .container ? EmbedAuthRole.None : EmbedAuthRole.SinglePageNone
        let model = EmbedAuthModel(token: doc.objectToken, type: doc.objectType, collaboratorId: vm.body.chatID, collaboratorType: vm.body.chatType, collaboratorRole: role)
        vm.embededDocCancelAuth(embedAuthModels: [model]) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .Success(let docs):
                self.embedDocRecord(docs: docs)
                self.tableView.reloadData()
                self.showToast(text: BundleI18n.SKResource.CreationMobile_Docs_EmbeddedFiles_AccessDetails_Toast_Revoked, type: .success)
            case .NoPermisson:
                self.tableView.reloadData()
                self.showToast(text: BundleI18n.SKResource.CreationMobile_Docs_EmbeddedFiles_AccessDetails_Toast_NoPermRevoke, type: .failure)
            default:
                self.showToast(text: BundleI18n.SKResource.CreationMobile_Docs_EmbeddedFiles_AccessDetails_Toast_FailedtoRevoke, type: .failure)
            }
        }
        self.permStatistics.reportPermissionCitedDocAuthorizeClick(clickType: .cancelAuthorize(objctId: doc.token), isGroupChat: isGroupChat)
    }

    func cancelAllEmbededDoc() {
        let docs = vm.embedDocs.filter { return $0.chatHasPermission && $0.senderHasSharePermission }
        let models: [EmbedAuthModel] = docs.compactMap { doc in
            return EmbedAuthModel(token: doc.objectToken, type: doc.objectType,
                                  collaboratorId: vm.body.chatID, collaboratorType: vm.body.chatType,
                                  collaboratorRole: (doc.permType == .container) ? EmbedAuthRole.None : EmbedAuthRole.SinglePageNone)
        }
        showToast(text: BundleI18n.SKResource.LarkCCM_EmbeddedFiles_PermissionRevoking_Toast_Mobile, type: .loading)
        vm.revokeAllAccess(embedAuthModels: models) { [weak self] result in
            guard let self = self else { return }
            self.removeToast()
            self.tableView.reloadData()
            switch result {
            case .Success(let docs):
                self.embedDocRecord(docs: docs)
                self.showToast(text: BundleI18n.SKResource.CreationMobile_Docs_EmbeddedFiles_AccessDetails_Toast_AllRevoked, type: .success)
            case .AllFail:
                self.showToast(text: BundleI18n.SKResource.CreationMobile_Docs_EmbeddedFiles_AccessDetails_Toast_FailedtoRevoke, type: .failure)
            case .PartFail(let docs):
                self.embedDocRecord(docs: docs)
                self.showToast(text: BundleI18n.SKResource.CreationMobile_Docs_EmbeddedFiles_AccessDetails_Toast_FailedtoRevokeSome, type: .failure)
            default:
                self.showToast(text: BundleI18n.SKResource.CreationMobile_Docs_EmbeddedFiles_AccessDetails_Toast_FailedtoRevoke, type: .failure)
            }
        }
    }
    
    func authFor(doc: EmbedDoc) {
        let role = doc.permType == .container ? EmbedAuthRole.CanView : EmbedAuthRole.SinglePageCanView
        let model = EmbedAuthModel(token: doc.objectToken, type: doc.objectType, collaboratorId: vm.body.chatID, collaboratorType: vm.body.chatType, collaboratorRole: role)
        vm.embededDocAuth(embedAuthModels: [model]) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .Success(let docs):
                self.embedDocRecord(docs: docs)
                self.tableView.reloadData()
                self.showToast(text: BundleI18n.SKResource.CreationMobile_Docs_EmbeddedFiles_AccessDetails_Toast_Granted, type: .success)
            case .CollaboratorLimit:
                self.showTipsDialog(content: BundleI18n.SKResource.CreationMobile_Docs_EmbeddedFiles_AccessDetails_Toast_MaxCollaborator)
            case .cacBlocked:
                self.showCacBlockedDialog()
            case .NoPermisson:
                self.tableView.reloadData()
                self.showToast(text: BundleI18n.SKResource.LarkCCM_EmbeddedFiles_NoPermissionToGrantAccess_Toast, type: .failure)
            default:
                self.showToast(text: BundleI18n.SKResource.CreationMobile_Docs_EmbeddedFiles_AccessDetails_Toast_FailedtoGrant, type: .failure)
            }
            self.permStatistics.reportPermissionCitedDocAuthorizeClick(clickType: .authorize(isAskOwner: false, objctId: doc.token), isGroupChat: self.isGroupChat)
        }
    }
    
    func authAllEmbededDoc() {
        let docs = vm.embedDocs.filter { return !$0.chatHasPermission && $0.senderHasSharePermission }
        let models: [EmbedAuthModel] = docs.compactMap { doc in
            return EmbedAuthModel(token: doc.objectToken, type: doc.objectType,
                                  collaboratorId: vm.body.chatID, collaboratorType: vm.body.chatType,
                                  collaboratorRole: doc.permType == .container ? EmbedAuthRole.CanView : EmbedAuthRole.SinglePageCanView)
        }
        showToast(text: BundleI18n.SKResource.LarkCCM_EmbeddedFiles_PermissionGranting_Toast_Mobile, type: .loading)
        vm.grantAllAccess(embedAuthModels: models) { [weak self] result in
            guard let self = self else { return }
            self.removeToast()
            self.tableView.reloadData()
            switch result {
            case .Success(let docs):
                self.embedDocRecord(docs: docs)
                self.showToast(text: BundleI18n.SKResource.LarkCCM_EmbeddedFiles_GrantedAllPermission_Toast_Mobile, type: .success)
            case .AllFail:
                self.showToast(text: BundleI18n.SKResource.LarkCCM_EmbeddedFiles_GrantedAllPermission_AllFailed_Toast_Mobile, type: .failure)
            case .PartFail(let docs):
                self.embedDocRecord(docs: docs)
                self.showToast(text: BundleI18n.SKResource.LarkCCM_EmbeddedFiles_GrantedAllPermission_PartlyFailed_Toast_Mobile, type: .failure)
            default:
                self.showToast(text: BundleI18n.SKResource.CreationMobile_Docs_EmbeddedFiles_AccessDetails_Toast_FailedtoGrant, type: .failure)
            }
        }
    }

    func embedDocRecord(docs: [EmbedDoc]) {
        let status: [EmbedAuthRecodeStatus] = docs.compactMap { doc in
            let perm = doc.chatHasPermission ? 1 : 0
            return EmbedAuthRecodeStatus(token: doc.objectToken, type: doc.objectType, permission: perm, permType: doc.permType)
        }
        vm.embedDocRecord(status: status) { ret in
            DocsLogger.info("embedDocRecord \(ret)")
        }
    }

    func embededDocUpdateCard() {
        vm.embededDocUpdateCard { ret in
            DocsLogger.info("embededDocUpdateCard \(ret)")
        }
    }

    /// 全部取消授权提示弹窗
    private func showCancelAllEmbededDocDialog() {
        self.permStatistics.reportPermissionCitedDocAuthorizeClick(clickType: .allCancel, isGroupChat: isGroupChat)
        
        let dialog = UDDialog()
        let type = CollaboratorType(rawValue: body.chatType) ?? .user
        let content: String
        switch type {
        case .group, .temporaryMeetingGroup, .permanentMeetingGroup:
            content = BundleI18n.SKResource.CreationMobile_Docs_EmbeddedFiles_AccessDetails_RevokeAll_Subtitle_Group
        default:
            content = BundleI18n.SKResource.CreationMobile_Docs_EmbeddedFiles_AccessDetails_RevokeAll_Subtitle_Private
        }
        dialog.setTitle(text: BundleI18n.SKResource.CreationMobile_Docs_EmbeddedFiles_AccessDetails_RevokeAll_Title)
        dialog.setContent(text: content)
        dialog.addSecondaryButton(text: BundleI18n.SKResource.Doc_Facade_Cancel, dismissCompletion: { [weak self] in
            guard let self = self else { return }
            self.permStatistics.reportPermissionCitedDocAllAuthorizeClick(isConfirm: false, popUpType: .allCancel, citedDocNum: self.vm.revokeDocCount, isGroupChat: self.isGroupChat)
        })
        dialog.addPrimaryButton(text: BundleI18n.SKResource.Doc_Facade_Confirm, dismissCompletion: { [weak self] in
            guard let self = self else { return }
            self.permStatistics.reportPermissionCitedDocAllAuthorizeClick(isConfirm: true, popUpType: .allCancel, citedDocNum: self.vm.revokeDocCount, isGroupChat: self.isGroupChat)
            self.cancelAllEmbededDoc()
        })
        present(dialog, animated: true, completion: { [weak self] in
            guard let self = self else { return }
            self.permStatistics.reportPermissionCitedDocAllAuthorizeView(popUpType: .allCancel, citedDocNum: self.vm.revokeDocCount, isGroupChat: self.isGroupChat)
        })
    }
    
    /// 全部授权提示弹窗
    private func showAuthAllEmbededDocDialog() {
        self.permStatistics.reportPermissionCitedDocAuthorizeClick(clickType: .allAuthorize, isGroupChat: isGroupChat)
        
        let dialog = UDDialog()
        let type = CollaboratorType(rawValue: body.chatType) ?? .user
        let content: String
        switch type {
        case .group, .temporaryMeetingGroup, .permanentMeetingGroup:
            content = BundleI18n.SKResource.LarkCCM_EmbeddedFiles_GrantAllPermissionConfirm_ToGroup_Subtitle_Mobile
        default:
            content = BundleI18n.SKResource.LarkCCM_EmbeddedFiles_GrantAllPermissionConfirm_ToUser_Subtitle_Mobile
        }
        dialog.setTitle(text: BundleI18n.SKResource.LarkCCM_EmbeddedFiles_GrantAllPermissionConfirm_Title_Mobile)
        dialog.setContent(text: content)
        dialog.addSecondaryButton(text: BundleI18n.SKResource.Doc_Facade_Cancel, dismissCompletion: { [weak self] in
            guard let self = self else { return }
            self.permStatistics.reportPermissionCitedDocAllAuthorizeClick(isConfirm: false, popUpType: .allAuthorize, citedDocNum: self.vm.grantDocCount, isGroupChat: self.isGroupChat)
        })
        dialog.addPrimaryButton(text: BundleI18n.SKResource.Doc_Facade_Confirm, dismissCompletion: { [weak self] in
            guard let self = self else { return }
            self.permStatistics.reportPermissionCitedDocAllAuthorizeClick(isConfirm: true, popUpType: .allAuthorize, citedDocNum: self.vm.grantDocCount, isGroupChat: self.isGroupChat)
            self.authAllEmbededDoc()
        })
        present(dialog, animated: true, completion: { [weak self] in
            guard let self = self else { return }
            self.permStatistics.reportPermissionCitedDocAllAuthorizeView(popUpType: .allAuthorize, citedDocNum: self.vm.grantDocCount, isGroupChat: self.isGroupChat)
        })
    }
    
    // 提示弹窗
    private func showTipsDialog(content: String) {
        let dialog = UDDialog()
        dialog.setTitle(text: BundleI18n.SKResource.LarkCCM_EmbeddedFiles_NoPermissionToGrantAccess_Title)
        dialog.setContent(text: content)
        dialog.addPrimaryButton(text: BundleI18n.SKResource.Doc_Facade_Confirm, dismissCompletion: nil)
        present(dialog, animated: true, completion: nil)
    }
}

extension EmbedDocAuthViewController: UITableViewDataSource {

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return vm.embedDocs.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: EmbedDocAuthCell
        if let tempCell = (tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier) as? EmbedDocAuthCell) {
            cell = tempCell
        } else {
            cell = EmbedDocAuthCell(style: .subtitle, reuseIdentifier: cellReuseIdentifier)
        }
        guard indexPath.row >= 0, indexPath.row < vm.embedDocs.count else { return UITableViewCell() }

        let doc = vm.embedDocs[indexPath.row]
        let cellItem = EmbedDocAuthCellItem(title: doc.displayTitle,
                                            ownerName: doc.ownerName,
                                            image: doc.defaultIcon,
                                            isAuth: doc.chatHasPermission)

        cell.update(item: cellItem)
        return cell
    }
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard vm.embedDocs.count > 0 else { return nil }
        let view = EmbedDocAuthCellSectionHeaderView()
        view.click = { [weak self] enabledAction in
            if enabledAction == .grant {
                self?.showAuthAllEmbededDocDialog()
            } else {
                self?.showCancelAllEmbededDocDialog()
            }
        }
        view.update(hasPermissionCount: vm.hasPermissionCount, noPermissonCount: vm.noPermissonCount, enabledAction: vm.enabledAction)
        return view
    }
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 68
    }
}

extension EmbedDocAuthViewController: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        guard indexPath.row >= 0, indexPath.row < vm.embedDocs.count else { return }
        let doc = vm.embedDocs[indexPath.row]
        openDoc(doc: doc)
    }
    public func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard indexPath.row >= 0, indexPath.row < vm.embedDocs.count else { return nil }
        let doc = vm.embedDocs[indexPath.row]
        // auth
        let authAction = UIContextualAction(style: .normal,
                                            title: BundleI18n.SKResource.CreationMobile_Docs_EmbeddedFiles_AccessDetails_GrantAccess) { [weak self] _, _, completionHandler in
            self?.authFor(doc: doc)
            completionHandler(true)
        }
        authAction.backgroundColor = UDColor.colorfulBlue

        // cancel auth
        let cancelAuthAction = UIContextualAction(style: .normal,
                                                  title: BundleI18n.SKResource.CreationMobile_Docs_EmbeddedFiles_AccessDetails_RevokeAccess) { [weak self] _, _, completionHandler in
            self?.cancelAuthFor(doc: doc)
            completionHandler(true)
        }
        cancelAuthAction.backgroundColor = UDColor.N500

        // no sender permission
        let noPermissionTitle = doc.chatHasPermission ?
        BundleI18n.SKResource.CreationMobile_Docs_EmbeddedFiles_AccessDetails_RevokeAccess :
        BundleI18n.SKResource.CreationMobile_Docs_EmbeddedFiles_AccessDetails_GrantAccess
        let noPermissionAction = UIContextualAction(style: .normal,
                                                  title: noPermissionTitle) { [weak self] _, _, completionHandler in
            if doc.chatHasPermission {
                self?.showToast(text: BundleI18n.SKResource.CreationMobile_Docs_EmbeddedFiles_AccessDetails_Toast_NoPermRevoke, type: .failure)
            } else {
                self?.showTipsDialog(content: BundleI18n.SKResource.CreationMobile_Docs_EmbeddedFiles_NoPermToGrant_Tooltip)
            }
            completionHandler(true)
        }
        noPermissionAction.backgroundColor = UDColor.N350

        // swipe actions
        let swipe: UISwipeActionsConfiguration
        if !doc.senderHasSharePermission {
            swipe = UISwipeActionsConfiguration(actions: [noPermissionAction])
        } else if doc.chatHasPermission {
            swipe = UISwipeActionsConfiguration(actions: [cancelAuthAction])
        } else {
            swipe = UISwipeActionsConfiguration(actions: [authAction])
        }
        swipe.performsFirstActionWithFullSwipe = false
        return swipe
    }
}

extension EmbedDocAuthViewController {
    func showToast(text: String, type: DocsExtension<UDToast>.MsgType) {
        guard let view = self.view.window ?? self.view else {
            return
        }
        UDToast.docs.showMessage(text, on: view, msgType: type)
    }
    
    func removeToast() {
        guard let view = self.view.window ?? self.view else {
            return
        }
        UDToast.removeToast(on: view)
    }
    /// 展示被cac管控的弹框
    private func showCacBlockedDialog() {
        let content = BundleI18n.SKResource.LarkCCM_Workspace_ConAccess_ShareMentionFail_Toast
        let config = UDDialogUIConfig()
        config.contentMargin = .zero
        let dialog = UDDialog(config: config)
        dialog.setTitle(text: BundleI18n.SKResource.LarkCCM_Workspace_ConAccess_ShareFail_Title)
        dialog.setContent(text: content)
        dialog.addPrimaryButton(text: BundleI18n.SKResource.LarkCCM_Workspace_ConAccess_GotIt_Button)
        present(dialog, animated: true, completion: nil)
    }
}
