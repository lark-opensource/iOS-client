//
//  DriveCommentAdapter+DocsFeedAPI.swift
//  SKDrive
//
//  Created by huayufan on 2021/6/16.
//  


import SKCommon
import SKFoundation
import EENavigator

extension DriveCommentAdapter: DocsFeedAPI {

    /// 通知前端高度 drive没有
    func setPanelHeight(height: CGFloat) {}
    
    /// 消除红点
    func didClearBadge(messageIds: [String]) {
        messageDidRead?(messageIds)
    }
    
    func panelDismiss() {
        messageWillDismiss?()
    }
    
    /// 展示个人信息
    func showProfile(userId: String) {
        guard let fromVC = self.hostController else {
            spaceAssertionFailure("fromVC cannot be nil")
            return
        }
        HostAppBridge.shared.call(ShowUserProfileService(userId: userId, fileName: self.docsInfo.title, fromVC: fromVC))
    }
    
    /// 打开文档
    func openUrl(url: URL) {
        guard let fromVC = self.hostController else {
            spaceAssertionFailure("fromVC cannot be nil")
            return
        }
        if self.commentLinkInterceptor?(url) ?? false {
            // URL 被拦截，不做处理
            return
        }
        Navigator.shared.push(url, from: fromVC)
    }
    
    /// 翻译评论。drive没有
    func translate(commentId: String, replyId: String) {}
    
    func clickMessage(message: FeedMessageModel) {
        var sectionId = ""
        if message.type == .mention {
            sectionId = message.messageId
        } else if message.type == .comment {
            sectionId = message.isWhole ? "isWhole" : message.commentId
        }
        messageDidClickComment?(sectionId, message)
    }

    func didChangeMuteState(isMute: Bool) {}
}
