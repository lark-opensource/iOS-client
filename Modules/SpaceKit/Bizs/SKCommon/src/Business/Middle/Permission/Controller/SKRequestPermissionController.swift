//
//  SKRequestPermissionController.swift
//  SKCommon
//
//  Created by Weston Wu on 2021/12/30.
//

import UIKit
import SwiftyJSON
import EENavigator
import SKUIKit
import SKResource
import SKFoundation
import RxSwift
import RxRelay
import UniverseDesignEmpty
import SpaceInterface
import SKInfra

open class SKRequestPermissionController: UIViewController {
    private var applyPermissionView: SKApplyPermissionView?
    private var docsInfo: DocsInfo
    private var canRequestPermission: Bool // 是否展示请求权限
    public let defaultBlockType: SKApplyPermissionBlockType
    private var permStatistics: PermissionStatistics
    private let disposeBag = DisposeBag()
    public var unlockByPasswordHandler: (() -> Void)?

    // defaultBlockType 仅在 canRequestPermission 为 false 时生效
    public init(_ docsInfo: DocsInfo, canRequestPermission: Bool, defaultBlockType: SKApplyPermissionBlockType = .userPermissonBlock) {
        self.docsInfo = docsInfo
        self.canRequestPermission = canRequestPermission
        self.defaultBlockType = defaultBlockType
        let publicPermissionMeta = DocsContainer.shared.resolve(PermissionManager.self)?.getPublicPermissionMeta(token: docsInfo.objToken)
        let userPermissions = DocsContainer.shared.resolve(PermissionManager.self)?.getUserPermissions(for: docsInfo.objToken)
        let ccmCommonParameters = CcmCommonParameters(fileId: docsInfo.encryptedObjToken,
                                                      fileType: docsInfo.type.name,
                                                      appForm: (docsInfo.isInVideoConference == true) ? "vc" : "none",
                                                      subFileType: docsInfo.fileType,
                                                      module: docsInfo.type.name,
                                                      userPermRole: userPermissions?.permRoleValue,
                                                      userPermissionRawValue: userPermissions?.rawValue,
                                                      publicPermission: publicPermissionMeta?.rawValue)
        self.permStatistics = PermissionStatistics(ccmCommonParameters: ccmCommonParameters)
        super.init(nibName: nil, bundle: nil)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        DocsLogger.info("SKRequestPermissionController -- deinit")
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    open override func willMove(toParent parent: UIViewController?) {
        if parent == nil {
            // 权限界面隐藏时，移除弹出的 alert
            // 使用 presentee 会导致 Crash: https://t.wtturl.cn/M14wcbd/
            // self.presentee?.dismiss(animated: false)
            self.presentedViewController?.dismiss(animated: false)
        }
        super.willMove(toParent: parent)
    }

    public func setupView() {
        if canRequestPermission {
            fetchPermissionStatus()
        } else {
            DocsLogger.warning("NoPermissionController without request permission")
            showApplyPermissionView(canApply: false, blockType: defaultBlockType)
        }
    }

    private func fetchPermissionStatus() {

        let moreActions: [UserPermissionEnum] = [.view, .perceive]
        let paramsActions = moreActions.map { $0.rawValue }
        let params: [String: Any] = ["token": docsInfo.objToken,
                                     "type": docsInfo.type.rawValue,
                                     "actions": paramsActions]
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.suitePermissonDocumentActionsState, params: params)
            .set(method: .POST)
            .set(timeout: 20)
            .set(encodeType: .jsonEncodeDefault)
        request.rxResponse().subscribe(onSuccess: { [self] json, error in
            guard let result = json else {
                DispatchQueue.main.async {
                    self.showApplyPermissionView(canApply: false, blockType: .userPermissonBlock)
                }
                return
            }

            if let permissionStatusCode = result["data"]["permission_status_code"].int {
                if permissionStatusCode == DocsNetworkError.Code.passwordRequired.rawValue,
                   let handler = unlockByPasswordHandler {
                    DispatchQueue.main.async {
                        self.showPasswordView(handler: handler)
                    }
                    return
                }

                let isAuditError = permissionStatusCode == DocsNetworkError.Code.reportError.rawValue
                || permissionStatusCode == DocsNetworkError.Code.auditError.rawValue
                if isAuditError,
                   let isOwner = result["data"]["is_owner"].bool,
                   !isOwner {
                    // 文档被审核，且非 owner，展示无权限不可申请页面
                    DocsLogger.error("non-owner access audit content")
                    DispatchQueue.main.async {
                        self.showApplyPermissionView(canApply: false, blockType: .userPermissonBlock, isAppealingView: true)
                    }
                    return
                }
            }
            
            /// admin、cac管控
            let userPermisson = UserPermission(json: result)
            if userPermisson.shareControlByCAC() {
                DocsLogger.error("be share control by CAC")
                DispatchQueue.main.async {
                    self.showApplyPermissionView(canApply: false, blockType: .shareControlByCAC)
                }
                return
            }
            if userPermisson.previewControlByCAC() {
                DocsLogger.error("be preview control by CAC")
                DispatchQueue.main.async {
                    self.showApplyPermissionView(canApply: false, blockType: .previewControlByCAC)
                }
                return
            }
            if userPermisson.adminBlocked() {
                DocsLogger.error("be admin blocked")
                DispatchQueue.main.async {
                    self.showApplyPermissionView(canApply: false, blockType: .adminBlock)
                }
                return
            }

            if let ownerInfo = result["meta"]["owner"].dictionary,
               let enName = ownerInfo["en_name"]?.string,
               let cnName = ownerInfo["cn_name"]?.string,
               let canApply = ownerInfo["can_apply_perm"]?.bool,
               let ownerID = ownerInfo["id"]?.string,
               canApply == true {
                let aliasInfo = UserAliasInfo(json: result["meta"]["owner"]["display_name"])
                DispatchQueue.main.async {
                    let name: String
                    if let displayName = aliasInfo.currentLanguageDisplayName {
                        name = displayName
                    } else {
                        name = DocsSDK.currentLanguage == .zh_CN ? cnName : enName
                    }
                    self.showApplyPermissionView(canApply: true, name: name, ownerID: ownerID, blockType: .userPermissonBlock)
                }
            } else {
                DocsLogger.error("fetch permission state failed", error: error)
                DispatchQueue.main.async {
                    self.showApplyPermissionView(canApply: false, blockType: .userPermissonBlock)
                }
            }
        })
        .disposed(by: disposeBag)
    }

    private func showApplyPermissionView(canApply: Bool, name: String = "", ownerID: String = "", blockType: SKApplyPermissionBlockType, isAppealingView: Bool = false) {
        let applyPermissionView = SKApplyPermissionView(token: docsInfo.objToken,
                                                        type: docsInfo.type,
                                                        canApplyPermission: canApply,
                                                        ownerName: name,
                                                        ownerID: ownerID,
                                                        permStatistics: permStatistics,
                                                        applyType: blockType)
        applyPermissionView.delegate = self
        view.addSubview(applyPermissionView)
        view.bringSubviewToFront(applyPermissionView)
        applyPermissionView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        //Lark举报兜底页
        if isAppealingView {
            applyPermissionView.tipTitle = BundleI18n.SKResource.LarkCCM_Security_ShareSuspend_Risk_Empty
            applyPermissionView.iconImage = UDEmptyType.loadingFailure.defaultImage()
            applyPermissionView.tipDetail = nil
        }

        switch blockType {
        case .adminBlock, .previewControlByCAC:  ///预览管控
            applyPermissionView.iconImage = UDEmptyType.noPreview.defaultImage()
            applyPermissionView.tipTitle = ""
            applyPermissionView.tipDetail = BundleI18n.SKResource.CreationMobile_Docs_UnableToAccess_SecurityReason
        case .shareControlByCAC:  /// cac管控
            applyPermissionView.iconImage = UDEmptyType.noAccess.defaultImage()
            applyPermissionView.tipTitle = BundleI18n.SKResource.LarkCCM_Workspace_ConAccess_NoPerm_Title
            applyPermissionView.tipDetail = BundleI18n.SKResource.LarkCCM_Workspace_ConAccess_NoPerm_Description
        default: break
        }
        
        self.applyPermissionView = applyPermissionView
    }

    private func showPasswordView(handler: @escaping () -> Void) {
        let passwordInputVC = PasswordInputViewController(token: docsInfo.objToken,
                                                          type: docsInfo.type,
                                                          isFolderV2: false)
        addChild(passwordInputVC)
        view.addSubview(passwordInputVC.view)
        passwordInputVC.didMove(toParent: self)
        passwordInputVC.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        passwordInputVC.unlockStateRelay.asSignal()
            .filter { $0 }
            .map { _ in () }
            .emit(onNext: handler)
            .disposed(by: disposeBag)
    }
}

extension SKRequestPermissionController: SKApplyPermissionViewDelegate {
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
