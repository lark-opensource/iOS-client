//
//  CommentBusinessPlugin.swift
//  SKCommon
//
//  Created by huayufan on 2022/9/27.
//  


import UIKit
import SKFoundation
import SpaceInterface
import SKCommon
import SKInfra

/// 负责处理回调给业务接入方之前的一些逻辑处理
class CommentBusinessPlugin: CommentPluginType {

    weak var context: CommentServiceContext?

    static let identifier: String = "BusinessPlugin"

    func apply(context: CommentServiceContext) {
        self.context = context
    }
    
    func mutate(action: CommentAction) {
        switch action {
        case let .interaction(ui):
            handleUIAction(action: ui)
        case let .ipc(ipcAction, _):
            handleIPCAction(action: ipcAction)
        default:
            break
        }
    }
    
    func handleUIAction(action: CommentAction.UI) {
        switch action {

        case let .clickURL(url):
            handleOpenDocs(url: url)
            
        case let .clickAtInfoAndCheckPermission(atInfo, item, rect, view):
            clickAtInfoAndCheckPermission(atInfo, item, rect, view)

        case let .clickAvatar(item):
            handleClickAvatar(item)
            
        case let .clickAtInfoDirectly(atInfo):
            handleClickAtInfo(atInfo)
            
        case let .scanQR(code):
            handleScanQR(code)

        case let .keepPotraint(force):
            dependency?.forcePortraint(force: force)
        default:
            break
        }
    }
    
    func handleIPCAction(action: CommentAction.IPC) {
        switch action {
        case let .clickReactionName(userId, nav):
            handleShowUserProfile(userId: userId, from: nav)
        default:
            break
        }
    }
    
    var dependency: DocsCommentDependency? {
        let businessDependency = context?.businessDependency
        spaceAssert(businessDependency != nil)
        return businessDependency
    }
}

extension CommentBusinessPlugin {
    
    func clickAtInfoAndCheckPermission(_ atInfo: AtInfo, _ item: CommentItem, _ rect: CGRect, _ view: UIView) {
        let isLarkDocsApp = DocsSDK.isInLarkDocsApp
        if atInfo.type == .user {
            let isGuest = User.current.basicInfo?.isGuest ?? false
            guard !isGuest, !item.anonymous, !isLarkDocsApp else {
                // 自己是匿名用户、或者匿名用户发的评论都屏蔽
                DocsLogger.info("didClickAtInfo, isGuest=\(isGuest), item.anonymous=\(item.anonymous)", component: LogComponents.comment)
                return
            }
            guard let docsInfo = context?.docsInfo else {
                DocsLogger.error("context docsInfo is nil", component: LogComponents.comment)
                return
            }
            let docsKey = AtUserDocsKey(token: docsInfo.objToken, type: docsInfo.type)
            let hasInvitePermission = AtPermissionManager.shared.canInvite(for: docsKey.token)
            let canShowDarkName = dependency?.businessConfig.canShowDarkName ?? true
            if canShowDarkName, canSupportInviteUser(docsInfo), hasInvitePermission,
               let hasPermission = AtPermissionManager.shared.hasPermission(atInfo.token, docsKey: docsKey), hasPermission == false {
                let permStatistics = PermissionStatistics.getReporterWith(docsInfo: docsInfo)
                permStatistics?.reportPermissionShareAtPeopleView()
                context?.scheduler?.dispatch(action: .interaction(.showContentInvite(at: atInfo, rect: rect, rectInView: view)))
                return //如果弹了tips则return
            }
        }
        DocsLogger.info("didClickAtInfo, will self=\(self)", component: LogComponents.comment)
        
        // 有权限，则直接打开
        handleClickAtInfo(atInfo)
    }
    
    func handleClickAtInfo(_ atInfo: AtInfo) {
        if atInfo.type != .user, atInfo.type != .unknown {
            SecLinkStatistics.recordClickLinkStatistics(scene: .ccm, location: .docsSdkComment)
        }
        if atInfo.type == .user { // 用户跳转到 Lark Profile
            handleShowUserProfile(userId: atInfo.token, from: nil)
        } else if let url = atInfo.hrefURL() { // 处理文档的跳转
            handleOpenDocs(url: url)
        } else {
            DocsLogger.error("clickAtInfo type error:\(atInfo.type)", component: LogComponents.comment)
        }
    }
    
    func handleClickAvatar(_ item: CommentItem) {
        let isLarkDocsApp = DocsSDK.isInLarkDocsApp
        let isGuest = User.current.basicInfo?.isGuest ?? false
        var userId: String = item.userID 
        var needBlock = false
        if item.isNewInput {
            userId = User.current.basicInfo?.userID ?? ""
            needBlock = isGuest || isLarkDocsApp
        } else {
            needBlock = isGuest || isLarkDocsApp || item.anonymous
        }
        guard !needBlock else {
            // 自己是匿名用户、或者匿名用户发的评论都屏蔽
            DocsLogger.info("didClickAvatarImage, isGuest=\(isGuest), anonymous=\(item.anonymous))", component: LogComponents.comment)
            return
        }
        handleShowUserProfile(userId: userId, from: nil)
    }
    
    func handleScanQR(_ code: String) {
        guard let pattern = context?.pattern else { return }
        // 能在内部处理 就在内部处理，不能在内部处理再抛出去
        switch pattern {
        case .aside:
            // CCM需要在外部处理
            dependency?.scanQR(code: code)
        case .float:
            if context?.docsInfo?.isInCCMDocs == true {
                dependency?.scanQR(code: code)
            } else {
                context?.scheduler?.reduce(state: .scanQR(code: code))
            }
        case .drive:
            context?.scheduler?.reduce(state: .scanQR(code: code))
        }
    }
    
    func handleOpenDocs(url: URL) {
        // 先判断是否评论锚点链接
        guard handleComemntAnchorLink(url) == false else {
            return
        }
        
        // 能在内部处理 就在内部处理，不能在内部处理再抛出去
        guard let dependency = dependency else {
            DocsLogger.error("dependency is nil", component: LogComponents.comment)
            return
        }
        if dependency.businessConfig.canOpenUR {
            context?.scheduler?.reduce(state: .openDocs(url: url))
        } else {
            dependency.openDocs(url: url)
        }
    }
    
    private func handleComemntAnchorLink(_ url: URL) -> Bool {
        guard DocsUrlUtil.getFileToken(from: url) == context?.docsInfo?.token else {
            DocsLogger.info("click difference url", component: LogComponents.comment)
            return false
        }
        let commentAnchorLink = url.docs.isCommentAnchorLink
        guard commentAnchorLink.isCommentAnchor,
              !commentAnchorLink.commentId.isEmpty else {
            return false
        }
        context?.scheduler?.dispatch(action: .api(.anchorLinkSwitch(commentId: commentAnchorLink.commentId), nil))
        return true
    }

    func handleShowUserProfile(userId: String, from: UIViewController?) {
        guard let dependency = dependency else {
            DocsLogger.error("dependency is nil", component: LogComponents.comment)
            return
        }
        if dependency.businessConfig.canOpenProfile {
            context?.scheduler?.reduce(state: .showUserProfile(userId: userId, from: from))
        } else {
            dependency.showUserProfile(userId: userId, from: from)
        }
    }
}
