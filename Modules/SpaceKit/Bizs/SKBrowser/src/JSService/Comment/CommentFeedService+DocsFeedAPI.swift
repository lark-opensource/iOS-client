//
//  CommentFeedService+action.swift
//  SKBrowser
//
//  Created by huayufan on 2021/6/16.
//  


import SKCommon
import SKFoundation
import SpaceInterface
import SKInfra

// MARK: - DocsFeedAPI

extension CommentFeedService: DocsFeedAPI {
    
    public func setPanelHeight(height: CGFloat) {
        model?.jsEngine.callFunction(.setPanelHeight,
                                     params: ["height": height],
                                     completion: nil)
    }
    
    /// 仅同步给前端，消除仍由端上处理
    public func didClearBadge(messageIds: [String]) {
        callFunction(for: .readMessage, params: ["msgIds": messageIds])
    }
    
    public func panelDismiss() {
        feedPanel = nil
        model?.jsEngine.callFunction(.hideMessages,
                                     params: ["commentPanelOpen": false],
                                     completion: nil)
    }
    
    public func showProfile(userId: String) {
        navigator?.showUserProfile(token: userId)
    }
    
    public func openUrl(url: URL) {
        navigator?.requiresOpen(url: url)
    }
    
    public func translate(commentId: String, replyId: String) {
        
        if let jsService = model?.jsEngine.fetchServiceInstance(CommentShowCardsService.self) {
            let api = CommentWebAPIAdaper(commentService: jsService)
            var sendContent = CommentAPIContent([.commentId: commentId,
                                                 .replyId: replyId])
            api.translate(sendContent)
        } else {
            DocsLogger.feedError("translate jsService not found")
        }
    }
    
    public func clickMessage(message: FeedMessageModel) {
        guard let type = message.type else {
            DocsLogger.feedError("message type not supported")
            return
        }
        // 删除或者解决就不要告诉前端了
        if message.commentDelete || message.finish || message.localDeleted || message.subType == .commentSolve { return }
        if message.canCallFrontToScrollToCard {
            if message.isWhole {
                DocsLogger.feedInfo("Click Feed Message: isWhole-True, commentId:\(message.commentId), replyId:\(message.replyId)")
                model?.jsEngine.callFunction(.scrollToMessage,
                                             params: ["isGlobalComment": true,
                                                      "commentId": message.commentId,
                                                      "replyId": message.replyId],
                                             completion: nil)
            } else {
                DocsLogger.feedInfo("Click Feed Message: isWhole-False, commentId:\(message.commentId), replyId:\(message.replyId)")
                var replyId = message.replyId
                if message.type == .docsReaction { // 正文表情回应特殊处理，replyId应当依照commentId
                    replyId = message.commentId
                }
                let loadEnable = SettingConfig.commentPerformanceConfig?.loadEnable == true
                if loadEnable {
                    let simulateCallback = DocsJSService.simulateCommentEntrance.rawValue
                    model?.jsEngine.simulateJSMessage(simulateCallback, params: ["clickFrom" : "feed", "clickTime": Date().timeIntervalSince1970 * 1000, "viewOnly": true])
                }
                model?.jsEngine.callFunction(.activeComment,
                                             params: ["commentId": message.commentId,
                                                      "replyId": replyId,
                                                      "from": "feed"],
                                             completion: nil)
            }
        } else if type == .mention {
            DocsLogger.feedInfo("Click Feed Message: Mention, mentionId:\(message.mentionId)")
            model?.jsEngine.callFunction(.scrollToMessage,
                                         params: ["mentionId": message.mentionId],
                                         completion: nil)
        }
    }

    public func didChangeMuteState(isMute: Bool) {
        callFunction(for: .toggleMute, params: ["isRemind": !isMute])
    }
}

extension FeedMessageModel {
    
    fileprivate var canCallFrontToScrollToCard: Bool {
        let value1 = self.type == .comment || self.subType == .reaction || self.subType == .commentReopen // 评论
        let reactionScenes: [FeedMessageBizScene] = [.contentReactionAdded, .contentReactionResolved, .contentReactionCancelled, .contentReactionQuoteDeleted]
        let value2 = reactionScenes.contains(bizScene) // 表情回应相关的，都调前端，前端用于埋点
        return value1 || value2
    }
}
