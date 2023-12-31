//
//  BitableCollaboratorInviteViewController.swift
//  SKCommon
//
//  Created by liweiye on 2020/8/24.
//

import UIKit
import SwiftyJSON
import LarkLocalizations
import SKFoundation
import SKUIKit
import SKResource
import UniverseDesignToast
import RxSwift
import RxCocoa
import LarkUIKit
import EENavigator
import LarkFeatureGating
import UniverseDesignColor
import LarkAlertController
import UniverseDesignDialog
import SKInfra

protocol BitableCollaboratorInviteViewControllerDelegate: AnyObject {
    func collaboardInvite(_ collaboardInvite: BitableCollaboratorInviteViewController, didUpdateWithItems items: [Collaborator])
}

class BitableCollaboratorInviteViewController: BaseViewController {

    weak var delegate: BitableCollaboratorInviteViewControllerDelegate?

    let disposeBag: DisposeBag = DisposeBag()
    private var updateRulesRequest: DocsRequest<JSON>?

    var datas: [CollaboratorSearchResultCellItem] = []
    var items: [Collaborator] {
        didSet {
            self.datas = self.items.map {
                return CollaboratorSearchResultCellItem(selectType: .none,
                                                        imageURL: $0.avatarURL,
                                                        imageKey: $0.imageKey,
                                                        title: $0.name,
                                                        detail: $0.detail,
                                                        isExternal: $0.isExternal,
                                                        blockExternal: $0.blockExternal,
                                                        isCrossTenanet: $0.isCrossTenant,
                                                        roleType: $0.type,
                                                        organizationTagValue: $0.organizationTagValue)
            }
            self.delegate?.collaboardInvite(self, didUpdateWithItems: self.items)
            if oldValue.count > 0 && self.items.isEmpty {
                self.backBarButtonItemAction()
            }
        }
    }
    private let cellReuseIdentifier: String = "CollaboratorSearchResultCell"
    private lazy var collaboratorInvitationTableView: UITableView = {
        let tableView = UITableView()
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 0.1))
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 0.1))
        tableView.allowsSelection = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UDColor.bgBody
        tableView.rowHeight = 66
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorStyle = .none
        tableView.register(CollaboratorSearchResultCell.self, forCellReuseIdentifier: cellReuseIdentifier)
        return tableView
    }()
    lazy var collaboratorBottomView: CollaboratorBottomView = {
        let view = CollaboratorBottomView()
        return view
    }()
    // 用于挡住 optionBar 在iPhone X下方空白去的投影
    private lazy var buttonEmptyView: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.bgBody
        return view
    }()

    let permissionManager = DocsContainer.shared.resolve(PermissionManager.self)!


    private(set) var inviteVM: CollaboratorInviteVCDependency

    init(vm: CollaboratorInviteVCDependency) {
        self.inviteVM = vm
        self.items = vm.items
        super.init(nibName: nil, bundle: nil)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let items = self.items
        self.items = items
        self.collaboratorInvitationTableView.reloadData()
        self.inviteVM.statistics?.reportShowCollaborateSettingPage()
    }

    func loading(isBehindNavBar: Bool = false) {
        showLoading(isBehindNavBar: isBehindNavBar, backgroundAlpha: 0.05)
    }
}

extension BitableCollaboratorInviteViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        title = BundleI18n.SKResource.Bitable_AdvancedPermission_AddCollaborator
        view.addSubview(collaboratorInvitationTableView)
        view.addSubview(collaboratorBottomView)
        view.addSubview(buttonEmptyView)


        collaboratorInvitationTableView.snp.makeConstraints { (make) in
            make.top.equalTo(self.navigationBar.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(collaboratorBottomView.snp.top)
        }
        configCollaboratorBottomView()

        view.bringSubviewToFront(self.navigationBar)

        collaboratorBottomView.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }
        collaboratorBottomView.confirmButtonTappedBlock = { [weak self] _ in
            guard let self = self else { return }
            self.inviteCollaborators()
        }
        buttonEmptyView.snp.makeConstraints { (make) in
            make.top.equalTo(collaboratorBottomView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
        inviteVM.permStatistics?.reportBitablePremiumPermissionInviteCollaboratorView()
    }


    private func configCollaboratorBottomView() {
        var config = CollaboratorBottomViewLayoutConfig()
        config.showNotification = false
        config.showHintLabel = false
        config.showTextView = false
        config.inviteButtonText = BundleI18n.SKResource.Doc_Share_CollaboratorInvite
        self.collaboratorBottomView.setupUI(config)
    }

    override func backBarButtonItemAction() {
        // 非栈顶，不能返回
        if let navigationController = self.navigationController,
           let index = index(of: self, in: navigationController),
           index != navigationController.viewControllers.count - 1 {
            DocsLogger.info("not at stack top")
            return
        }
        inviteVM.permStatistics?.reportBitablePremiumPermissionInviteCollaboratorClick(action: .back)
        super.backBarButtonItemAction()
    }
    private func index(of target: UIViewController, in navigation: UINavigationController) -> Int? {
        var target = target
        while !navigation.viewControllers.contains(target) {
            guard let parent = target.parent else {
                return nil
            }
            target = parent
        }
        return navigation.viewControllers.firstIndex(of: target)
    }
    private func backWhileRequestCompleted() {
        dismiss(animated: true, completion: nil)
    }
}


extension BitableCollaboratorInviteViewController {

    func inviteCollaborators() {
        var params: [String: Any] = [:]
        params["collaborator_count"] = self.items.count
        params["group_count"] = CollaboratorUtils.containsGroupCollaboratorsCount(self.items)
        params["department_count"] = CollaboratorUtils.containsOrganizationCollaboratorsCount(self.items)
        inviteVM.permStatistics?.reportBitablePremiumPermissionInviteCollaboratorClick(action: .invite, params: params)

        guard let rule = inviteVM.bitablePermissonRule else { return }
        guard DocsNetStateMonitor.shared.isReachable else {
            showToast(text: BundleI18n.SKResource.Doc_Facade_NetworkInterrutedRetry, type: .failure)
            return
        }

        var keyValue: [String: Collaborator] = [:]
        rule.collaborators.forEach {
            keyValue[$0.userID] = $0
        }
        self.items.forEach {
            keyValue[$0.userID] = $0
        }

        let tempCollaborators: [Collaborator] = keyValue.compactMap { (_, collaborator) in
            return collaborator
        }

        self.loading()
        updateRulesRequest = permissionManager
            .updateBitablePermissionRules(token: inviteVM.fileModel.objToken,
                                          roleID: rule.ruleID, collaborators: tempCollaborators, notify: false, complete: { [weak self] (json, error) in
            guard let self = self else { return }
            self.hideLoading()
            guard let json = json else {
                self.showToast(text: BundleI18n.SKResource.Doc_Share_CollaboratorInvite + BundleI18n.SKResource.Doc_AppUpdate_FailRetry, type: .failure)
                DocsLogger.info(error?.localizedDescription ?? "")
                return
            }
            let code = json["code"].intValue

            guard code == 0 else {
                self.handleInviteCollaboratorsError(json: json)
                return
            }
            NotificationCenter.default.post(name: Notification.Name.Docs.bitableRulesUpdate, object: nil)
            self.showSuccessTips(text: BundleI18n.SKResource.Bitable_AdvancedPermission_CollaboratorAdded)
        })

    }

    //邀请协作者失败toast
    func handleInviteCollaboratorsError(json: JSON) {
        let code = json["code"].intValue
        if let errorCode = ExplorerErrorCode(rawValue: code) {
            let errorEntity = ErrorEntity(code: errorCode, folderName: "")
            self.showToast(text: errorEntity.wording, type: .failure)
        } else {
            self.showToast(text: BundleI18n.SKResource.Bitable_AdvancedPermission_FailedToAddCollaborator, type: .failure)
        }
    }
}

extension BitableCollaboratorInviteViewController {
    @objc
    private func menuButtonAction(sender: CollaboratorInviteMenuButton) {
        guard let cell = sender.superview as? UITableViewCell,
              let indexPath = self.collaboratorInvitationTableView.indexPath(for: cell) else {
            return
        }
        self.items.remove(at: indexPath.row)
        self.collaboratorInvitationTableView.deleteRows(at: [indexPath], with: .automatic)
        inviteVM.permStatistics?.reportBitablePremiumPermissionInviteCollaboratorClick(action: .remove)
    }
}

extension BitableCollaboratorInviteViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.datas.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: CollaboratorSearchResultCell
        if let tempCell = (tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier) as? CollaboratorSearchResultCell) {
            cell = tempCell
        } else {
            cell = CollaboratorSearchResultCell(style: .subtitle, reuseIdentifier: cellReuseIdentifier)
        }
        guard indexPath.row >= 0, indexPath.row < datas.count else { return UITableViewCell() }
        cell.update(item: datas[indexPath.row])
        cell.backgroundColor = UDColor.bgBody
        return cell
    }
}

extension BitableCollaboratorInviteViewController: UITableViewDelegate {
    private func addDeleteButton(willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let button = CollaboratorInviteMenuButton()
        button.setImage(BundleResources.SKResource.Common.Collaborator.collaborators_form_remove.ud.withTintColor(UDColor.N800), for: .normal)
        button.addTarget(self, action: #selector(menuButtonAction(sender:)), for: .touchUpInside)
        button.sizeToFit()
        button.docs.addStandardHighlight()
        cell.accessoryView = button
    }
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard indexPath.row >= 0 && indexPath.row < self.items.count else {
            return
        }
        addDeleteButton(willDisplay: cell, forRowAt: indexPath)
    }
}


extension BitableCollaboratorInviteViewController {
    func showSuccessTips(text: String) {
        self.showToast(text: text, type: .success)
        self.backWhileRequestCompleted()
    }
}

extension BitableCollaboratorInviteViewController {
    func showToast(text: String, type: DocsExtension<UDToast>.MsgType) {
        guard let view = (self.view.window ?? Navigator.shared.mainSceneWindow) else {
            return
        }
        UDToast.docs.showMessage(text, on: view, msgType: type)
    }
}
