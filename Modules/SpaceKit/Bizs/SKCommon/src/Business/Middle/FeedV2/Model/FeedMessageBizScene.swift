//
//  FeedMessageBizScene.swift
//  SKCommon
//
//  Created by chensi(陈思) on 2022/5/19.
//  


import Foundation

/// feed消息的业务场景，对应不同的UI样式
public enum FeedMessageBizScene {
    
    /// 当前文档被分享给我
    case thisDocSharedToMe
    
    /// 正文中mention
    case mentionedInText
    
    /// 正文中mention原文被删除
    case mentionedTextDeleted
    
    /// 评论原文被删除
    case commentQuoteDeleted
    
    /// 添加划词评论
    case newPartialCommentAdded
    
    /// 在已有评论下增加评论
    case morePartialCommentAdded
    
    /// 回复划词评论(at了某人)
    case partialReplyAdded
    
    /// 全文评论 & 回复全文评论
    case newFullCommentAdded
    
    /// 划词评论被解决
    case partialCommentResolved
    
    /// 全文评论被解决
    case fullCommentResolved
    
    /// 评论被删除
    case commentBeDeleted
    
    /// 添加了正文表情回应
    case contentReactionAdded
    
    /// 正文表情回应被解决
    case contentReactionResolved
    
    /// 正文表情回应已取消
    case contentReactionCancelled
    
    /// 正文表情回应原文被删除
    case contentReactionQuoteDeleted
}

extension FeedMessageModel {
    
    /// 业务场景，注意要穷尽已定义的所有case不要遗漏，检测顺序需要明确后再修改
    public var bizScene: FeedMessageBizScene {
        
        if type == .docsReaction {
            if contentReactionDelete == true {
                return .contentReactionCancelled
            }
            if finish == true {
                return .contentReactionResolved
            }
            if localDeleted == true {
                return .contentReactionQuoteDeleted
            }
            if contentReactionKey.isEmpty == false {
                return .contentReactionAdded
            }
        }
        
        if type == .share {
            return .thisDocSharedToMe
        }
        
        if type == .mention && localDeleted {
            return .mentionedTextDeleted
        }
        
        if type == .mention {
            return .mentionedInText
        }
        
        if commentDelete { // 优先级: "已删除" > "已解决", 因为先删除某条回复再解决整个评论卡片,该条回复预期显示"已删除"
            return .commentBeDeleted
        }
        
        if finish {
            return isWhole ? .fullCommentResolved : .partialCommentResolved
        }
        
        if type == .comment && localDeleted {
            return .commentQuoteDeleted
        }
        
        if type == .comment && isWhole {
            return .newFullCommentAdded
        }
        
        if commentMention && (replyIndex > 0) {
            return .partialReplyAdded
        }
        
        return (replyIndex > 0) ? .morePartialCommentAdded : .newPartialCommentAdded
    }
}
