//
//  CollaboratorEditLynxViewController.swift
//  SKCommon
//
//  Created by peilongfei on 2022/11/28.
//  


import SKFoundation
import SKResource
import SKUIKit
import BDXServiceCenter
import LarkUIKit
import UniverseDesignColor
import UniverseDesignDialog
import LarkLocalizations
import BDXBridgeKit
import SwiftyJSON
import EENavigator
import SpaceInterface

public protocol CollaboratorEditDelegate: AnyObject {
    func updateManagerEntryPanelCollaborators()
    func updateFileOwnerId(newOwnerId: String)
    func dissmissSharePanelFromCollaboratorEdit(animated: Bool, completion: (() -> Void)?)
}

final class CollaboratorEditLynxViewController: LynxBaseViewController {
    
    var supportOrientations: UIInterfaceOrientationMask = .portrait
    
    private let shareEntity: SKShareEntity
    private let fileModel: CollaboratorFileModel
    private let collaborators: [Collaborator]
    private let containerCollaborators: [Collaborator]
    private let singlePageCollaborators: [Collaborator]
    private let statistics: CollaboratorStatistics
    private let permStatistics: PermissionStatistics?
    private let userPermission: UserPermissionAbility?
    private let publicPermission: PublicPermissionMeta?
    private weak var delegate: CollaboratorEditDelegate?
    private weak var organizationNotifyDelegate: OrganizationInviteNotifyDelegate?
    private let isInVideoConference: Bool
    private weak var followAPIDelegate: BrowserVCFollowDelegate?

    private(set) var currentChooseSource: CollaboratorSource /// 当前展示的列表类型
    
    init(shareEntity: SKShareEntity,
                fileModel: CollaboratorFileModel,
                collaborators: [Collaborator],
                containerCollaborators: [Collaborator],
                singlePageCollaborators: [Collaborator],
                statistics: CollaboratorStatistics,
                permStatistics: PermissionStatistics?,
                userPermission: UserPermissionAbility?,
                publicPermission: PublicPermissionMeta?,
                delegate: CollaboratorEditDelegate,
                organizationNotifyDelegate: OrganizationInviteNotifyDelegate,
                isInVideoConference: Bool,
                followAPIDelegate: BrowserVCFollowDelegate?) {
        self.shareEntity = shareEntity
        self.fileModel = fileModel
        self.collaborators = collaborators
        self.containerCollaborators = containerCollaborators
        self.singlePageCollaborators = singlePageCollaborators
        self.statistics = statistics
        self.permStatistics = permStatistics
        self.userPermission = userPermission
        self.publicPermission = publicPermission
        self.delegate = delegate
        self.organizationNotifyDelegate = organizationNotifyDelegate
        self.isInVideoConference = isInVideoConference
        self.followAPIDelegate = followAPIDelegate
        if fileModel.wikiV2SingleContainer {
            self.currentChooseSource = .container
        } else {
            self.currentChooseSource = .defaultType
        }
        super.init(nibName: nil, bundle: nil)
        shareContextID = UUID().uuidString
        let userInfo = User.current.info
        let account: [String:String] = [
            "uid": userInfo?.userID ?? "",
            "avatarUrl": userInfo?.avatarURL ?? "",
            "tenantId": userInfo?.tenantID ?? "",
            "tenantName": userInfo?.tenantName ?? "",
            "cnName": userInfo?.nameCn ?? "",
            "enName": userInfo?.nameEn ?? "",
            "userName": userInfo?.name ?? "",
            "displayName": userInfo?.aliasInfo?.displayName ?? ""
        ]
        initialProperties = [
            "url": shareEntity.shareUrl,
            "token": shareEntity.objToken,
            "type": shareEntity.type.fixedRawValueForBitableSubType,
            "bitableSubType": shareEntity.type.fixedBitableSubType,
            "title": shareEntity.title,
            "isOwner": shareEntity.isOwner,
            "isDocV2": shareEntity.spaceSingleContainer,
            "isWiki": shareEntity.isFromWiki,
            "shareToken": shareEntity.formShareFormMeta?.shareToken ?? shareEntity.bitableShareEntity?.meta?.shareToken,
            "ownerType": shareEntity.folderType?.ownerType,
            "shareVersion": shareEntity.shareVersion,
            "isShareFolder": shareEntity.isShareFolder,
            "spaceId": shareEntity.spaceID,
            "account": account,
            "isRoot": shareEntity.isShareFolderRoot,
            "appDisplayName": LanguageManager.bundleDisplayName,
            "canShowExternalTag": EnvConfig.CanShowExternalTag.value,
            "statisticParams": permStatistics?.commonParameters,
            "transferOwnerEnable": shareEntity.enableTransferOwner
        ]
        templateRelativePath = "pages/collaborator-manager/template.js"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UDColor.bgBase
        NotificationCenter.default.addObserver(self, selector: #selector(notifyLynxMemberChange), name: Notification.Name.Docs.refreshCollaborators, object: nil)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        lynxView?.triggerLayout()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if SKDisplay.pad {
            return [.all]
        }
        return supportOrientations
    }

    override func registerBizHandlers(for lynxView: BDXLynxViewProtocol) {
        super.registerBizHandlers(for: lynxView)
        
        lynxView.registerHandler({ _, _, _, callback in
            NotificationCenter.default.post(name: Notification.Name.Docs.refreshCollaborators, object: nil)
            callback(BDXBridgeStatusCode.succeeded.rawValue, nil)
        }, forMethod: "ccm.notifyMemberChange")
        
        lynxView.registerHandler({ _, _, _, callback in
            NotificationCenter.default.post(name: Notification.Name.Docs.refreshCollaborators, object: nil)
            callback(BDXBridgeStatusCode.succeeded.rawValue, nil)
        }, forMethod: "ccm.notifyLockChange")
        
        lynxView.registerHandler({ _, _, _, callback in
            callback(BDXBridgeStatusCode.succeeded.rawValue, nil)
        }, forMethod: "ccm.registerMemberChange")
        
        lynxView.registerHandler({ [weak self] _, _, _, callback in
            self?.dissmissSharePanel(animated: true, completion: nil)
            callback(BDXBridgeStatusCode.succeeded.rawValue, nil)
        }, forMethod: "ccm.exitWhenNoPermission")
        
        let dialogBridgeHandler = CheckBoxDialogBridgeHandler(hostController: self)
        lynxView.registerHandler(dialogBridgeHandler.handler, forMethod: dialogBridgeHandler.methodName)
        
        lynxView.registerHandler({ [weak self] _, _, params, callback in
            guard let self = self else { return }
            if let jsonStr = params?["userInfoList"] as? String {
                let json = JSON(parseJSON: jsonStr)
                let jsonDicts = json.arrayValue.compactMap({ $0.dictionaryObject })
                let collaborators = Collaborator.collaborators(jsonDicts, isOldShareFolder: self.shareEntity.isOldShareFolder)
                self.requestCollaboratorSearchViewController(existedCollaborators: collaborators)
            }
            callback(BDXBridgeStatusCode.succeeded.rawValue, nil)
        }, forMethod: "ccm.jumpToInviteCollaborator")
        
        PageOpenBridgeHandler.register(key: "jump_user_profile") { (url, params, vc) -> Bool in
            guard let components = URLComponents(string: url.absoluteString) else { return false }
            guard components.scheme == "lark", components.host == "ccm.bytedance.net", components.path == "/ccm/profile_main",
                let userID = params["id"] as? String else {
                return false
            }
            LKDeviceOrientation.forceInterfaceOrientationIfNeed(to: .portrait) { [weak self] in
                guard self != nil else { return }
                HostAppBridge.shared.call(ShowUserProfileService(userId: userID, fromVC: vc))
            }
            return true
        }
    }
    
    @objc private func notifyLynxMemberChange() {
        let event = GlobalEventEmiter.Event(
            name: "ccm.notifyMemberChangeNative",
            params: [:]
        )
        self.globalEventEmiter.send(event: event, needCache: true)
    }
    
    
    private func requestCollaboratorSearchViewController(existedCollaborators: [Collaborator]) {
        let viewModel = CollaboratorSearchViewModel(existedCollaborators: existedCollaborators,
                                                    selectedItems: [],
                                                    fileModel: fileModel,
                                                    lastPageLabel: nil,
                                                    statistics: statistics,
                                                    userPermission: userPermission,
                                                    publicPermisson: publicPermission,
                                                    isInVideoConference: isInVideoConference)
        let dependency = CollaboratorSearchVCDependency(statistics: statistics,
                                                        permStatistics: permStatistics,
                                                        needShowOptionBar: false)
        let needActivateKeyboard = SKDisplay.pad || UIApplication.shared.statusBarOrientation.isPortrait
        let uiConfig = CollaboratorSearchVCUIConfig(needActivateKeyboard: needActivateKeyboard,
                                                    source: .collaboratorEdit)
        let vc = CollaboratorSearchViewController(viewModel: viewModel,
                                                  dependency: dependency,
                                                  uiConfig: uiConfig)
        vc.collaboratorSearchVCDelegate = self
        vc.organizationNotifyDelegate = self
        vc.followAPIDelegate = followAPIDelegate
        vc.supportOrientations = self.supportedInterfaceOrientations
        let navVC = LkNavigationController(rootViewController: vc)
        navVC.modalPresentationStyle = .formSheet
        self.present(navVC, animated: true, completion: nil)
    }
}

extension CollaboratorEditLynxViewController: CollaboratorSearchViewControllerDelegate {

    func dissmissSharePanel(animated: Bool, completion: (() -> Void)?) {
        delegate?.dissmissSharePanelFromCollaboratorEdit(animated: animated, completion: {
            self.navigationController?.popViewController(animated: false)
            completion?()
        })
    }
}

extension CollaboratorEditLynxViewController: OrganizationInviteNotifyDelegate {
    
    func dismissSharePanelAndNotify(completion: (() -> Void)?) {
        organizationNotifyDelegate?.dismissSharePanelAndNotify(completion: completion)
    }
    func dismissInviteCompletion(completion: (() -> Void)?) {
        let title = BundleI18n.SKResource.LarkCCM_Workspace_InviteOrg_MuteNotice_Content_Header
        let content = BundleI18n.SKResource.LarkCCM_Workspace_InviteOrg_MuteNotice_Content_Popup
        let buttonTitle = BundleI18n.SKResource.LarkCCM_Workspace_InviteOrg_MuteNotice_GotIt_Button
        let dialog = UDDialog()
        dialog.setTitle(text: title)
        dialog.setContent(text: content)
        dialog.addPrimaryButton(text: buttonTitle, dismissCompletion: {
            dialog.dismiss(animated: false) { [weak self] in
                self?.organizationNotifyDelegate?.dismissSharePanelAndNotify(completion: nil)
                completion?()
            }
        })
        permStatistics?.reportBlockNotifyAlertView()
        Navigator.shared.present(dialog, from: self)
    }
}
