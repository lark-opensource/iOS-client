//
//  File.swift
//  SpaceKit
//
//  Created by xurunkang on 2019/3/25.
//  

import Foundation
import EENavigator
import SKCommon
import SKFoundation
import SKUIKit
import SKResource
import UniverseDesignToast
import SpaceInterface

extension DriveCommentAdapter: CommentBodyOutlet {
    func comment(translate commentId: String, replyId: String) {

    }

    func comment(_ commentContext: CommentAdaptContext,
                 fetchMoreReaction commentItem: CommentItem,
                 commentReaction: CommentReaction) {
        rnCommonDataManager.getReactionDetail(commentReaction)
    }

    func comment(_ commentContext: CommentAdaptContext, setDetailPanel reaction: CommentReaction, status: Int) {
        let r = RNCommonDataManager.Reaction(referType: reaction.referType,
                                              referKey: reaction.referKey ?? "",
                                              reactionKey: reaction.reactionKey,
                                              status: status)
        rnCommonDataManager.setReactionDetailPanelStatus(r)
    }

    func comment(_ commentContext: CommentAdaptContext, didClickReaction commentItem: CommentItem, key: String, response: ReactionCallback?) {
        guard let curUserID = User.current.info?.userID else {
            return DocsLogger.driveInfo("no valid user id")
        }

        var isCurUserInUsers = false
        if let commentReaction = commentItem.reactions?.first(where: { $0.reactionKey == key }) {
            isCurUserInUsers = commentReaction.userList.contains { $0.userId == curUserID }
        }

        let r = RNCommonDataManager.Reaction(
            referType: commentItem.reactionType ?? "",
            referKey: commentItem.replyID,
            reactionKey: key,
            status: isCurUserInUsers ? 0 : 1,
            replyId: commentItem.replyID)
        if isCurUserInUsers {
            rnCommonDataManager.removeReaction(r, response: response)
        } else {
            rnCommonDataManager.addReaction(r, response: response)
        }
    }

    func canCopyComment(_ commentContext: CommentAdaptContext) -> Bool {
        // drive没有复制权限限制，故直接返回true
        return true
    }

    func canCommentNow(_ commentContext: CommentAdaptContext) -> Bool {
        return permission.contains(.canComment)
    }

    func comment(_ commentContext: CommentAdaptContext, didClickAvaterImage userID: String?) {
        guard let fromVC = self.hostController else {
            spaceAssertionFailure("fromVC cannot be nil")
            return
        }
        if let userID = userID {
            HostAppBridge.shared.call(ShowUserProfileService(userId: userID, fileName: docsInfo.title, fromVC: fromVC))
        }
    }

    func comment(_ commentContext: CommentAdaptContext, didClickLink link: URL) {
        if DocsUrlUtil.url(type: .file, token: fileToken).absoluteString == link.absoluteString {
            commentContext.showFailed(BundleI18n.SKResource.Drive_Drive_LinkToCurrentFile)
        } else {
            if let handledByInterceptor = commentLinkInterceptor?(link),
                handledByInterceptor {
                // URL 被拦截，不做处理
                return
            }
            guard let hostController = hostController else {
                DocsLogger.error("failed to push when click comment link")
                assertionFailure()
                return
            }
            Navigator.shared.push(link, from: hostController)
        }
    }

    func comment(_ commentContext: CommentAdaptContext, didClickAtInfo atInfo: AtInfo) {
        if atInfo.type == .user { // 用户跳转到 Lark Profile
            guard let fromVC = self.hostController else {
                spaceAssertionFailure("fromVC cannot be nil")
                return
            }
            HostAppBridge.shared.call(ShowUserProfileService(userId: atInfo.token, fileName: docsInfo.title, fromVC: fromVC))
            return
        }

        if shouldHandleSamePage(atInfo) { return }

        // 处理文档的跳转
        guard let url = atInfo.hrefURL() else {
            DocsLogger.error("Click unknown atInfo in comment", extraInfo: ["type": atInfo.type])
            return
        }
        if let handledByInterceptor = commentLinkInterceptor?(url),
            handledByInterceptor {
            return
        }
        guard let hostController = hostController else {
            DocsLogger.error("failed to push when click space link")
            assertionFailure()
            return
        }
        Navigator.shared.push(url, from: hostController)
    }

    func comment(_ commentContext: CommentAdaptContext, didCopyContent content: String) {}

    func comment(_ commentContext: CommentAdaptContext, cancelHightLight cancel: Bool) {}

    func comment(_ commentContext: CommentAdaptContext, didSwitchPage page: Int, position: CGFloat?, completion: (() -> Void)?) {
        let commentID = commentContext.currentCommentID
        commentVCDidSwitchToPage?(page, commentID)
    }

    // 处理文件评论链接点击本文件的情况
    func shouldHandleSamePage(_ atInfo: AtInfo) -> Bool {
        if atInfo.type == .file && fileToken == atInfo.token {
            if let hostWindow = hostController?.view.window {
                UDToast.showFailure(with: BundleI18n.SKResource.Drive_Drive_LinkToCurrentFile, on: hostWindow)
            }
            return true
        }
        return false
    }
}
