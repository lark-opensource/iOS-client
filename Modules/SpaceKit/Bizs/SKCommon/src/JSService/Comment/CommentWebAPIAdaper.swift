//
//  CommentWebAPIAdaper.swift
//  SKBrowser
//
//  Created by huayufan on 2022/9/30.
//  


import UIKit
import SKFoundation
import SpaceInterface

public final class CommentWebAPIAdaper: CommentAPIAdaper {
    
    weak var commentService: CommentServiceType?
    
    public var apiType: CommentAPIAdaperType { .webview }
    
    public init(commentService: CommentServiceType) {
        self.commentService = commentService
    }
    
    /// 保留新增评论cache，用于重试
    var addCommentCache: [String: [String: Any]] = [:]

    func callFunction(_ action: CommentEventListenerAction, _ params: [String: Any]?) {
        guard let commentService = commentService else {
            DocsLogger.error("commentService is nil request action:\(action) fail", component: LogComponents.comment)
            return
        }
        var sendParams = params ?? [:]
        if let add = willSendToWeb?(action), !add.isEmpty {
            sendParams.merge(add) { (_, new) in new }
        }
        commentService.callFunction(for: action, params: sendParams)
    }
    
    /// 将要发送通用数据给前端/后台之前，业务方可以添加业务相关的字段，如图片评论的imgId，或者展示loading
    public var willSendToWeb: ((CommentEventListenerAction) -> [String: Any])?
}

// MARK: - CURD

extension CommentWebAPIAdaper {
    
    public func addComment(_ content: CommentAPIContent) {
        let res = content.parsing([.commentId, .content, .imageList, .isWhole])
        if let commentId: String = content[.commentId] {
            addCommentCache[commentId] = res
        }
        callFunction(.addComment, res)
    }
    
    public func retryAddNewComment(_ content: CommentAPIContent) {
        if let commentId: String = content[.commentId],
        let cache = addCommentCache[commentId] {
            callFunction(.retryOperation, cache)
        } else {
            DocsLogger.error("retry add new comment fail, cachenot found", component: LogComponents.comment)
        }
    }

    public func addReply(_ content: CommentAPIContent) {
        let res = content.parsing([.commentId, .content, .imageList, .isWhole, .replyUUID])
        DocsLogger.debug("addReply: \(res)", component: LogComponents.comment)
        callFunction(.addReply, res)
    }

    public func updateReply(_ content: CommentAPIContent) {
        let res = content.parsing([.commentId, .replyId, .content, .imageList, .replyUUID])
        callFunction(.updateReply, res)
    }
    
    public func deleteReply(_ content: CommentAPIContent) {
        let res = content.parsing([.commentId, .replyId])
        callFunction(.deleteReply, res)
    }
    
    public func resolveComment(_ content: CommentAPIContent) {
        let res = content.parsing([.commentId])
        callFunction(.resolveComment, res)
    }
    
    public func retry(_ content: CommentAPIContent) {
        let res = content.parsing([.commentId, .replyId])
        callFunction(.retryOperation, res)
    }
}

// MARK: - Magic Share

extension CommentWebAPIAdaper {
    
    public func scrollComment(_ content: CommentAPIContent) {
        let res = content.parsing([.curCommentId, .replyId, .replyPercentage])
        callFunction(.scrollComment, res)
    }
    
    public func activeCommentInvisible(_ content: CommentAPIContent) {
        let res = content.parsing([.curCommentId])
        callFunction(.activeCommentInvisible, res)
    }
}


// MARK: - Reaction

extension CommentWebAPIAdaper {
    public func addReaction(_ content: CommentAPIContent) {
        let res = content.parsing([.reactionKey, .replyId])
        callFunction(.addReaction, res)
    }
    
    public func removeReaction(_ content: CommentAPIContent) {
        let res = content.parsing([.reactionKey, .replyId])
        callFunction(.removeReaction, res)
    }
    
    public func addContentReaction(_ content: CommentAPIContent) {
        let res = content.parsing([.commentId, .reactionKey])
        callFunction(.addContentReaction, res)
    }
    
    public func removeContentReaction(_ content: CommentAPIContent) {
        let res = content.parsing([.commentId, .reactionKey])
        callFunction(.removeContentReaction, res)
    }
    
    public func getReactionDetail(_ content: CommentAPIContent) {
        let res = content.parsing([.replyId])
        callFunction(.getReactionDetail, res)
    }
    
    public func getContentReactionDetail(_ content: CommentAPIContent) {
        let res = content.parsing([.commentId])
        callFunction(.getContentReactionDetail, res)
    }
    
    public func setDetailPanel(_ content: CommentAPIContent) {
        // Web 不需要
    }
    
    public func anchorLinkSwitch(_ content: CommentAPIContent) {
        let res = content.parsing([.commentId])
        callFunction(.anchorLinkSwitch, res)
    }
    
    public func clickQuoteMenu(_ content: CommentAPIContent) {
        let res = content.parsing([.menuId, .commentId])
        callFunction(.onMenuClicked, res)
    }
}


// MARK: - Badge

extension CommentWebAPIAdaper {
    
    public func readMessage(_ content: CommentAPIContent) {
        let res = content.parsing([.msgIds])
        callFunction(.readMessage, res)
    }
    
    public func readMessageByCommentId(_ content: CommentAPIContent) {
        let res = content.parsing([.commentId])
        callFunction(.readMessageByCommentId, res)
    }
    
}

// MARK: - Sync status

extension CommentWebAPIAdaper {
    
    public func switchCard(_ content: CommentAPIContent) {
        let res = content.parsing([.comment_id, .from, .height])
        callFunction(.switchCard, res)
    }
    
    public func panelHeightUpdate(_ content: CommentAPIContent) {
        let res = content.parsing([.height])
        callFunction(.panelHeightUpdate, res)
    }
    
    public func close(_ content: CommentAPIContent) {
        let res = content.parsing([.type])
        callFunction(.cancel, res)
    }
    
    public func cancelActive(_ content: CommentAPIContent) {
        let res = content.parsing([.type])
        callFunction(.cancel, res)
    }
    
    public func onMention(_ content: CommentAPIContent) {
        let res = content.parsing([.id, .avatarUrl, .name, .cnName, .enName, .unionId, .department])
        callFunction(.onMention, res)
    }
    
    public func translate(_ content: CommentAPIContent) {
        let res = content.parsing([.commentId, .replyId, .targetLanguage])
        callFunction(.translate, res)
    }
    
    public func activateImageChange(_ content: CommentAPIContent) {
        let res = content.parsing([.commentId, .replyId, .index])
        callFunction(.activateImageChange, res)
    }
}
