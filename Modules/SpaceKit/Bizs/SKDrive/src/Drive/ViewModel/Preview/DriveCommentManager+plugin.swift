//
//  DriveCommentManager+plugin.swift
//  SKDrive
//
//  Created by huayufan on 2022/11/18.
//

import SKCommon
import SKFoundation
import SKResource
import UniverseDesignToast
import EENavigator
import SpaceInterface

extension DriveCommentManager {
    
    public func dismissNotHostVC(hostVC: UIViewController, completion: @escaping () -> Void) {
        if let presentedViewController = hostVC.presentedViewController {
            if presentedViewController.isBeingDismissed {
                presentedViewController.dismiss(animated: false) {
                    DocsLogger.driveInfo("hostVC presentedViewController dismisssing", component: LogComponents.comment)
                    completion()
                }
            } else {
                DocsLogger.error("hostVC presentedViewController:\(presentedViewController) exist", component: LogComponents.comment)
                presentedViewController.dismiss(animated: false) {
                    completion()
                }
            }
        } else {
            completion()
        }
    }
    
    func showComment(commentId: String?, hostVC: UIViewController, isFromFeed: Bool) {
        if commentModule?.isVisiable == false {
            dismissNotHostVC(hostVC: hostVC) { [weak self] in
                guard let self = self else { return }
                self.commentModule?.show(commentId: commentId, hostVC: hostVC, formSheetStyle: !isFromFeed)
            }
        } else if let commentId = commentId {
            commentModule?.switchComment(commentId: commentId)
        }
        commentModule?.setCaptureAllowed(canCopy)
    }
}

extension DriveCommentManager: CCMCopyPermissionDataSource {
    func getCopyPermissionService() -> UserPermissionService? {
        hostModule?.permissionService
    }

    public func ownerAllowCopy() -> Bool {
        return canCopy
    }
    
    func canPreview() -> Bool {
        return canPreviewProvider()
    }
}


extension DriveCommentManager: DocsCommentDependency {
    var businessConfig: CommentBusinessConfig {
        CommentBusinessConfig(canShowDarkName: false)
    }

    var commentDocsInfo: CommentDocsInfo {
        return docsInfo
    }

    var vcFollowDelegate: CommentVCFollowDelegateType? { .space(followAPIDelegate) }

    func driveCommentTopMaskHitTestView(_ point: CGPoint, _ event: UIEvent?) -> UIView? {
        guard let areaCommentProtocol = self.hostModule?.hostController?.children.last as? DriveSupportAreaCommentProtocol else { return nil }
        areaCommentProtocol.didTapBlank { [weak self] in
            self?.commentModule?.hide()
        }
        return areaCommentProtocol.areaDisplayView()
    }
    
    var externalCopyPermission: ExternalCopyPermission {
        if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
            guard let service = getCopyPermissionService() else {
                return .denied(BundleI18n.SKResource.Doc_Doc_CopyFailed)
            }
            let response = service.validate(operation: .copyContent)
            switch response.result {
            case .allow:
                return .permit
            case let .forbidden(denyType, _):
                switch denyType {
                case .blockByFileStrategy, .blockBySecurityAudit:
                    return .denied(BundleI18n.SKResource.CreationMobile_ECM_AdminDisableToast)
                default:
                    return .denied(BundleI18n.SKResource.Doc_Doc_CopyFailed)
                }
            }
        } else {
            let adminAllow = adminAllowCopyFG()
            let ownerAllow = ownerAllowCopyFG()
            let result = CCMSecurityPolicyService.syncValidate(entityOperate: .ccmCopy, fileBizDomain: .ccm, docType: .file, token: nil).allow
            switch (result, ownerAllow) {
            case (true, true):
                return .permit
            case (true, false):
                return .denied(BundleI18n.SKResource.Doc_Doc_CopyFailed)
            case (false, _):
                return .denied(BundleI18n.SKResource.CreationMobile_ECM_AdminDisableToast)
            }
        }
    }

    func showUserProfile(userId: String, from: UIViewController?) {

    }
    
    public func didCopyCommentContent() {
        PermissionStatistics.shared.reportDocsCopyClick(isSuccess: true)
    }
}

extension DriveCommentManager: CommentRNRequestType, CommentServiceType {

    func callFunction(for action: CommentEventListenerAction, params: [String: Any]?) {
        guard let `params` = params else { return }
        switch action {
        case .cancel:
            if let type = params["type"] as? String,
               type == "show_cards" {
                commentVCSwitchToComment.onNext("")
                commentAdapter.commentVCDismissed?()
            } else {
                DocsLogger.error("cancel params error", component: LogComponents.comment)
            }
           
        case .panelHeightUpdate:
            if let height = params["height"] as? CGFloat {
                hostModule?.hostController?.resizeContentViewIfNeed(height)
            } else {
                DocsLogger.error("panelHeightUpdate params error", component: LogComponents.comment)
            }
        case .switchCard:
            if let commentId = params["comment_id"] as? String,
               let page = params["page"] as? Int {
                commentAdapter.commentVCDidSwitchToPage?(page, commentId)
            } else {
                DocsLogger.error("switchCard params error", component: LogComponents.comment)
            }

        case .readMessage:
            if let messages = params["msgIds"] as? [String] {
                clearBadge(with: messages)
                commentAdapter.messageDidRead?(messages)
            } else {
                DocsLogger.error("readMessage params error", component: LogComponents.comment)
            }

        default:
            break
        }
    }
    
    
    /// 发送评论的能力
    var commentManager: RNCommentDataManager? {
        return commentAdapter.rnCommentDataManager
    }
    
    /// 发送reaction的能力
    var commonManager: RNCommonDataManager? {
        return commentAdapter.rnCommonDataManager
    }
    
}

extension DriveCommentManager: CommentRNAPIAdaperDependency {
    var docInfo: DocsInfo? {
        return docsInfo
    }
    
    func showError(msg: String) {
        let view = commentModule?.commentPluginView.window ?? UIView()
        UDToast.showFailure(with: msg, on: view)
    }
    
    func transformer(rnComment: RNCommentData) -> CommentData {
        let (commentData, _) = commentAdapter.constructComment(rnComment)
        commentAdapter.countChangeClosure?(commentData.comments.count)
        return commentData
    }
}
