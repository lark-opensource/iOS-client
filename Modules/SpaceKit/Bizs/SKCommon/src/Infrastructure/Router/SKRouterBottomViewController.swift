//
//  ISVViewController.swift
//  SKECM
//
//  Created by guoqp on 2020/7/29.
//

import Foundation
import LarkUIKit
import EENavigator
import SKUIKit
import SnapKit
import SKFoundation
import SKResource
import UniverseDesignEmpty
import SpaceInterface
import SKInfra

public enum NotSupportType {
    case defaultView // 默认兜底页
}

public enum ContentPromptype {
    case permissionPrompt(token: String, type: DocsType, ownerName: String, canApply: Bool, specialPermission: SpecialPermission)  //权限提示
    case failurePrompt  //失败提示
    case unavailable(NotSupportType)
    case deleteResotre(token: String, completion: ((UIViewController) -> Void))
    case empty(config: UDEmptyConfig)
    case shareControlByCAC(token: String, type: DocsType) /// cac分享管控
    case previewControlByCAC(token: String, type: DocsType) /// cac预览管控

}

public final class SKRouterBottomViewController: BaseViewController {
    private var type: ContentPromptype
    private var navTitle: String = ""

    var applyPermissionView: SKApplyPermissionView?

    lazy var listEmptyView: EmptyListPlaceholderView = {
        let v = EmptyListPlaceholderView()
        return v
    }()

    private lazy var defaultEmptyView: UDEmptyView = {
        let description = UDEmptyConfig.Description(descriptionText: BundleI18n.SKResource.CreationMobile_ECM_SiteUnavailableDesc)
        let config = UDEmptyConfig(title: nil, description: description, type: .ccm400_403)
        let view = UDEmptyView(config: config)
        return view
    }()
    
    private lazy var notSupportVersionView: UDEmptyView = {
        let description = UDEmptyConfig.Description(descriptionText: BundleI18n.SKResource.LarkCCM_Docs_EmptyStates_VersionUpdate_mob)
        let config = UDEmptyConfig(title: nil, description: description, type: .upgraded)
        let view = UDEmptyView(config: config)
        return view
    }()

    public init(_ type: ContentPromptype, title: String) {
        self.type = type
        self.navTitle = title
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        DocsLogger.info("SKRouterBottomViewController deinit")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        switch type {
        case .permissionPrompt(let tuple):
            let meta = SpaceMeta(objToken: tuple.0, objType: tuple.1)
            showApplyPermissionView(spaceMeta: meta, ownerName: tuple.2, ownerID: "", canApply: tuple.3, specialPermission: tuple.4)
        case .failurePrompt:
            showFailView()
        case .unavailable(.defaultView):
            showDefaultNativeView()
        case let .deleteResotre(token, completion):
            showDeleteRestoreEmptyView(token: token, completion: completion)
        case let .empty(config: config):
            showCustomEmptyView(config: config)
        case let .shareControlByCAC(token, type):
            showShareControlByCACPermissionView(token: token, type: type)
        case let .previewControlByCAC(token, type):
            showPreviewControlByCACPermissionView(token: token, type: type)
        }
        self.title = navTitle
    }

    private func showDefaultNativeView() {
        view.addSubview(defaultEmptyView)
        defaultEmptyView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func showCustomEmptyView(config: UDEmptyConfig) {
        defaultEmptyView.update(config: config)
        view.addSubview(defaultEmptyView)
        defaultEmptyView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func showDeleteRestoreEmptyView(token: String, completion: @escaping ((UIViewController) -> Void)) {
        let emptyView = DocsRestoreEmptyView(type: .space(objToken: token, objType: .folder))
        view.addSubview(emptyView)
        emptyView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        emptyView.restoreCompeletion = { [weak self] in
            guard let self = self else { return }
            completion(self)
        }
    }

    private func dismissApplyPermissionView() {
        if applyPermissionView != nil {
            applyPermissionView?.removeFromSuperview()
            applyPermissionView = nil
        }
    }

    private func showApplyPermissionView(spaceMeta: SpaceMeta, ownerName: String, ownerID: String, canApply: Bool, specialPermission: SpecialPermission) {
        dismissApplyPermissionView()
        let token = spaceMeta.objToken
        let type = spaceMeta.objType
        let publicPermissionMeta = DocsContainer.shared.resolve(PermissionManager.self)?.getPublicPermissionMeta(token: token)
        let userPermissions = DocsContainer.shared.resolve(PermissionManager.self)?.getUserPermissions(for: token)
        let ccmCommonParameters = CcmCommonParameters(fileId: DocsTracker.encrypt(id: token),
                                                      fileType: type.name,
                                                      module: type.name,
                                                      userPermRole: userPermissions?.permRoleValue,
                                                      userPermissionRawValue: userPermissions?.rawValue,
                                                      publicPermission: publicPermissionMeta?.rawValue)
        let permStatistics = PermissionStatistics(ccmCommonParameters: ccmCommonParameters)
        let applyPermissionView = SKApplyPermissionView(token: token,
                                                        type: type,
                                                        canApplyPermission: canApply,
                                                        ownerName: ownerName,
                                                        ownerID: ownerID,
                                                        specialPermission: specialPermission,
                                                        permStatistics: permStatistics,
                                                        applyType: .userPermissonBlock)
        self.view.addSubview(applyPermissionView)
        applyPermissionView.delegate = self
        applyPermissionView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        self.applyPermissionView = applyPermissionView
    }
    
    /// cac分享管控
    private func showShareControlByCACPermissionView(token: String, type: DocsType) {
        showApplyPermissionView(spaceMeta: SpaceMeta(objToken: token, objType: type),
                                ownerName: "",
                                ownerID: "",
                                canApply: false,
                                specialPermission: .normal)
        self.applyPermissionView?.tipTitle = type == .folder ? BundleI18n.SKResource.LarkCCM_Workspace_ConAccess_NoAccess_EmptyHeader : BundleI18n.SKResource.LarkCCM_Workspace_ConAccess_NoPerm_Title
        self.applyPermissionView?.iconImage = UDEmptyType.noAccess.defaultImage()
        self.applyPermissionView?.tipDetail = type == .folder ?
        BundleI18n.SKResource.LarkCCM_Workspace_ConAccess_NoAccess_EmptyDescrip :
        BundleI18n.SKResource.LarkCCM_Workspace_ConAccess_NoPerm_Description
    }
    /// cac预览管控
    private func showPreviewControlByCACPermissionView(token: String, type: DocsType) {
        showApplyPermissionView(spaceMeta: SpaceMeta(objToken: token, objType: type),
                                ownerName: "",
                                ownerID: "",
                                canApply: false,
                                specialPermission: .normal)
        self.applyPermissionView?.iconImage = UDEmptyType.noPreview.defaultImage()
        applyPermissionView?.tipTitle = ""
        self.applyPermissionView?.tipDetail = BundleI18n.SKResource.CreationMobile_Docs_UnableToAccess_SecurityReason
    }

    private func showFailView() {
        view.addSubview(self.listEmptyView)
        if !DocsNetStateMonitor.shared.isReachable {
            self.listEmptyView.config(error: ErrorInfoStruct(type: .noNet, title: BundleI18n.SKResource.Doc_Space_EmptyPageNoNetDefaultTip, domainAndCode: nil))
        } else {
            self.listEmptyView.config(error: ErrorInfoStruct(type: .openFileFail, title: BundleI18n.SKResource.Doc_Doc_GetWikiInfoOtherErr, domainAndCode: nil))
        }
        self.listEmptyView.snp.remakeConstraints { (make) in
            make.top.bottom.left.right.equalTo(0)
        }
    }
}

extension SKRouterBottomViewController: SKApplyPermissionViewDelegate {
    public func getHostVC() -> UIViewController? {
        return self
    }
    public func presentVC(_ vc: UIViewController, animated: Bool) {
        Navigator.shared.present(vc, from: self)
    }
    public func showOwnerProfile(ownerID: String, ownerName: String) {
        guard ownerID.isEmpty == false else {
            DocsLogger.warning("ownerid is empty")
            return
        }
        HostAppBridge.shared.call(ShowUserProfileService(userId: ownerID, fromVC: self))
    }
}

//兜底页支持MagicShare
extension SKRouterBottomViewController: FollowableViewController {

    public var isEditingStatus: Bool {
        return false
    }

    public var followTitle: String {
        ""
    }
    
    public var followScrollView: UIScrollView? {
        return nil
    }
    
    public func onSetup(followAPIDelegate: SpaceFollowAPIDelegate) {
        
    }
    
    public func refreshFollow() {
        
    }
    
    public func executeJS(operation: String, params: [String: Any]?) {
        
    }
}
