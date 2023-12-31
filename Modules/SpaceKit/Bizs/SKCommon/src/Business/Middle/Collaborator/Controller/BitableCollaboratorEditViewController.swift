//
//  BitableBitableCollaboratorEditViewController.swift
//  Collaborator
//
//  Created by Da Lei on 2018/3/27.
//

import Foundation
import SKFoundation
import SKUIKit
import SKResource
import LarkUIKit
import EENavigator
import SwiftyJSON
import UniverseDesignIcon
import UniverseDesignColor
import UniverseDesignToast
import UniverseDesignDialog
import SKInfra

public protocol BitableCollaboratorEditViewControllerDelegate: AnyObject {
    func collaboratorsDidUpdated()
    func shouldShowFallbackToastAfterCollaboratorDidRemove(_ collaborator: Collaborator, from rule: BitablePermissionRule) -> Bool
    func requestToAddCollaborator(from: BitableCollaboratorEditViewController, rule: BitablePermissionRule)
}

public final class BitableCollaboratorEditViewController: BaseViewController {
    var addAvailability: BitableAdPermAddDisableReason = .none

    private var permStatistics: PermissionStatistics?
    private let permissionManager = DocsContainer.shared.resolve(PermissionManager.self)!
    private let token: String
    private var rule: BitablePermissionRule
    private weak var delegate: BitableCollaboratorEditViewControllerDelegate?
    private var data: [CollaboratorCellModel] = []
    private var updateRulesRequest: DocsRequest<JSON>?
    private var rulesRequest: DocsRequest<JSON>?
    private var collaborators: [Collaborator] = []
    private let bridgeData: BitableBridgeData

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.scrollDirection = .vertical
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = UDColor.bgBody
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(BitableCollaboratorCell.self, forCellWithReuseIdentifier: BitableCollaboratorCell.reuseIdentifier)
        collectionView.register(BitableEmptyCollaboratorsCell.self, forCellWithReuseIdentifier: BitableEmptyCollaboratorsCell.reuseIdentifier)
        return collectionView
    }()

    
    public init(token: String,
                bridgeData: BitableBridgeData,
                rule: BitablePermissionRule,
                delegate: BitableCollaboratorEditViewControllerDelegate,
                permStatistics: PermissionStatistics?,
                addAvailability: BitableAdPermAddDisableReason = .none
    ) {
        self.delegate = delegate
        self.token = token
        self.bridgeData = bridgeData
        self.rule = rule
        self.collaborators.append(contentsOf: rule.collaborators)
        self.permStatistics = permStatistics
        self.addAvailability = addAvailability
        super.init(nibName: nil, bundle: nil)
        self.initDataSource()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        addNotification()
        permStatistics?.reportBitablePremiumPermissionManageCollaboratorView()
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override public func viewDidTransition(from oldSize: CGSize, to size: CGSize) {
        super.viewDidTransition(from: oldSize, to: size)
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    override public func viewDidSplitModeChange() {
        super.viewDidSplitModeChange()
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    func loading(isBehindNavBar: Bool = false) {
        showLoading(isBehindNavBar: isBehindNavBar, backgroundAlpha: 0.05)
    }
    public override func backBarButtonItemAction() {
        permStatistics?.reportBitablePremiumPermissionManageCollaboratorClick(action: .back)
        super.backBarButtonItemAction()
    }
}

extension BitableCollaboratorEditViewController {
    private func setupView() {
        title = BundleI18n.SKResource.Bitable_AdvancedPermission_SetCollaborator
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { (make) in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalTo(navigationBar.snp.bottom)
        }
        addRightBarItemIfNeed()
    }

    private func addRightBarItemIfNeed() {
        let btnItem = SKBarButtonItem(image: UDIcon.memberAddOutlined,
                                      style: .plain,
                                      target: self,
                                      action: #selector(addCollaborator))
        if addAvailability.addable {
            btnItem.foregroundColorMapping = SKBarButton.defaultIconColorMapping
        } else {
            btnItem.foregroundColorMapping = [
                .normal: UDColor.iconDisabled,
                .highlighted: UDColor.iconDisabled
            ]
        }
        btnItem.id = .addMember
        self.navigationBar.trailingBarButtonItems = [btnItem]
    }

    private func initDataSource() {
        let data: [CollaboratorCellModel] = collaborators.compactMap {
            return CollaboratorCellModel(collaborator: $0, cellHeight: 72)
        }
        self.data = data
    }
    private func addNotification() {
        NotificationCenter.default.addObserver(self,
                                           selector: #selector(handleReceiveBitableRulesUpdateNotification),
                                           name: Notification.Name.Docs.bitableRulesUpdate,
                                           object: nil)
    }
    @objc
    func handleReceiveBitableRulesUpdateNotification() {
        loadPermissonRules()
    }

    func loadPermissonRules() {
        let handler: (BitablePermissionRules?, Error?) -> Void = { [weak self] (rules, error) in
            guard let self = self else { return }
            guard let rules = rules else {
                DocsLogger.error("fetch permisson rules error", error: error, component: LogComponents.permission)
                self.hideLoading()
                return
            }
            guard (error as? URLError)?.errorCode != NSURLErrorCancelled, error == nil else {
                self.hideLoading()
                self.showToast(text: BundleI18n.SKResource.Doc_Normal_PermissionRequest + BundleI18n.SKResource.Doc_AppUpdate_FailRetry, type: .failure)
                return
            }
            if let rule = rules.rule(ruleID: self.rule.ruleID) {
                self.rule = rule
                self.collaborators = rule.collaborators
            }
            self.initDataSource()
            self.collectionView.reloadData()
            DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_250) {
                self.hideLoading()
            }
        }
        self.rulesRequest = permissionManager.fetchBitablePermissionRules(token: token, bridgeData: bridgeData, complete: handler)
    }

    @objc
    private func addCollaborator() {
        switch addAvailability {
        case .adPermOff:
            self.showToast(text: BundleI18n.SKResource.Bitable_AdvancedPermission_EnableFirstTip, type: .failure)
        case .payment:
            self.showToast(text: BundleI18n.SKResource.Bitable_AdvancedPermission_PremiumFeatureIncludedInRoleTip, type: .failure)
        case .none:
            permStatistics?.reportBitablePremiumPermissionManageCollaboratorClick(action: .addCollaboratorIcon)
            requestCollaboratorSearchViewController()
        }
    }

    private func requestCollaboratorSearchViewController() {
        self.delegate?.requestToAddCollaborator(from: self, rule: rule)
    }

    private func showRemoveCollaboratorAlertController(collaborator: Collaborator) {
        permStatistics?.reportBitablePremiumPermissionRemoveConfirmView()
        let title = BundleI18n.SKResource.Bitable_AdvancedPermission_MoveCollaboratorTitle
        let message = BundleI18n.SKResource.Bitable_AdvancedPermission_MoveCollaboratorDesc
        let confirm = BundleI18n.SKResource.Bitable_AdvancedPermission_MoveCollaboratorSet

        let dialog = UDDialog()
        // 标题
        dialog.setTitle(text: title)
        // 内容
        dialog.setContent(text: message, style: .defaultContentStyle)
        // 取消按钮
        dialog.addSecondaryButton(text: BundleI18n.SKResource.Bitable_Common_ButtonCancel, dismissCompletion: {
            self.permStatistics?.reportBitablePremiumPermissionRemoveConfirmClick(action: .cancel)
        })

        // 移除按钮
        dialog.addDestructiveButton(text: confirm, dismissCompletion: { [weak self] in
            guard let self = self else { return }
            self.permStatistics?.reportBitablePremiumPermissionRemoveConfirmClick(action: .confirm)
            self.removeCollaborator(collaborator: collaborator)
        })
        present(dialog, animated: true, completion: nil)
    }

    private func removeCollaborator(collaborator: Collaborator) {
        guard DocsNetStateMonitor.shared.isReachable else {
            showToast(text: BundleI18n.SKResource.Doc_Facade_NetworkInterrutedRetry, type: .failure)
            return
        }
        var tempCollaborators: [Collaborator] = self.collaborators
        tempCollaborators.removeAll { $0.userID == collaborator.userID }

        self.loading()
        updateRulesRequest = permissionManager.updateBitablePermissionRules(token: token, roleID: rule.ruleID, collaborators: tempCollaborators, notify: false, complete: { [weak self] (json, error) in
            guard let self = self else { return }
            guard error == nil else {
                self.hideLoading()
                self.handleError(json: json, inputText: BundleI18n.SKResource.Doc_AppUpdate_FailRetry)
                return
            }
            if self.delegate?.shouldShowFallbackToastAfterCollaboratorDidRemove(collaborator, from: self.rule) == true {
                self.showToast(
                    text: BundleI18n.SKResource.Bitable_AdvancedPermissionsInherit_Delete_DeleteCollaboratorsFromRole_Desc,
                    type: .warn
                )
            }
            self.delegate?.collaboratorsDidUpdated()
            self.loadPermissonRules()
            if UserScopeNoChangeFG.WJS.bitableMobileSupportRemoteCompute {
                NotificationCenter.default.post(name: Notification.Name.Docs.bitableRulesUpdate, object: nil)
            }
        })
    }

    private func handleError(json: JSON?, inputText: String) {
        guard let json = json else {
            self.showToast(text: inputText, type: .failure)
            return
        }
        let code = json["code"].intValue
        if let errorCode = ExplorerErrorCode(rawValue: code) {
            let errorEntity = ErrorEntity(code: errorCode, folderName: "")
            self.showToast(text: errorEntity.wording, type: .failure)
        } else {
            self.showToast(text: inputText, type: .failure)
        }
    }

}

extension BitableCollaboratorEditViewController: BitableCollaboratorCellDelegate {
    func collaboratorCell(_ cell: BitableCollaboratorCell, didClickRightDeleteBtn collaborator: Collaborator?, at sender: UIGestureRecognizer?) {
        guard let collaborator = collaborator else { return }
        permStatistics?.reportBitablePremiumPermissionManageCollaboratorClick(action: .remove)

        if rule.ruleType.defaultRule {
            showToast(text: BundleI18n.SKResource.Bitable_AdvancedPermission_DefaultRoleCantRemoveCollaborator, type: .warn)
            return
        }
        showRemoveCollaboratorAlertController(collaborator: collaborator)
    }
    
    func collaboratorCell(_ cell: BitableCollaboratorCell, didClickAvatarView collaborator: Collaborator?) {
        if let user = collaborator, user.type == .user {
            HostAppBridge.shared.call(ShowUserProfileService(userId: user.userID, fileName: rule.name, fromVC: self))
        }
    }
}

extension BitableCollaboratorEditViewController: UICollectionViewDataSource & UICollectionViewDelegate & UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data.count > 0 ? data.count : 1
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard data.count > 0  else {
            return emptyPlaceholderCell(indexPath)
        }
        let reusableCell = collectionView.dequeueReusableCell(withReuseIdentifier: BitableCollaboratorCell.reuseIdentifier, for: indexPath)
        guard let cell = reusableCell as? BitableCollaboratorCell else {
            return reusableCell
        }
        cell.setModel(data[indexPath.row], canEdit: !rule.ruleType.defaultRule)
        cell.backgroundColor = UDColor.bgBody
        cell.delegate = self
        return reusableCell
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard data.count > 0 else {
            return CGSize(width: collectionView.bounds.width, height: collectionView.bounds.height)
        }
        let model = data[indexPath.row]
        return CGSize(width: collectionView.frame.width, height: model.cellHeight)
    }

    private func emptyPlaceholderCell(_ indexPath: IndexPath) -> UICollectionViewCell {
        let reusableCell = collectionView.dequeueReusableCell(withReuseIdentifier: BitableEmptyCollaboratorsCell.reuseIdentifier, for: indexPath)
        guard let cell = reusableCell as? BitableEmptyCollaboratorsCell else {
            return reusableCell
        }
        cell.addAvailability = addAvailability
        cell.tapEvent = { _ in
            self.permStatistics?.reportBitablePremiumPermissionManageCollaboratorClick(action: .addCollaboratorButton)
            self.requestCollaboratorSearchViewController()
        }
        return cell
    }
}
extension BitableCollaboratorEditViewController {
    func showToast(text: String, type: DocsExtension<UDToast>.MsgType) {
        guard let view = (self.view.window ?? self.view) else {
            return
        }
        UDToast.docs.showMessage(text, on: view, msgType: type)
    }
}
