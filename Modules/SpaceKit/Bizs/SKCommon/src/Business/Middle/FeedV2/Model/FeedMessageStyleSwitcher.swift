//
//  FeedMessageStyleSwitcher.swift
//  SKCommon
//
//  Created by chensi(陈思) on 2022/5/21.
//  


import Foundation
import SKResource
import SpaceInterface

struct FeedMessageStyle {
    
    private let base: FeedMessageModel
    
    init(_ base: FeedMessageModel) {
        self.base = base
    }
}

extension FeedMessageModel {
    
    var autoStyled: FeedMessageStyle {
        FeedMessageStyle(self)
    }
}

extension FeedMessageStyle {
    
    var titleTextFormatter: (String) -> String {
        return base.bizScene.titleTextFormatter2
    }
    
    var shouldDisplayQuoteText: Bool {
        if base.associatedDocsType == .file { // drive中的feed消息都不显示引文
            return false
        }
        return base.bizScene.shouldDisplayQuoteText
    }
    
    var toastTextWhenTapped: String? {
        return base.bizScene.toastTextWhenTapped2
    }
    
    var feedCellReuseId: String {
        
        guard base.userId != User.current.basicInfo?.userID else { // 自己的消息不显示
            return FeedCommentEmptyCell.reuseIdentifier
        }
        
        let onlyShowTitle = base.bizScene.onlyShowTitleInFeedCell // 只显示标题，不显示引文&评论内容
        
        if onlyShowTitle {
            return FeedCommentCell.simpleStyleIdentifier
        } else {
            return FeedCommentCell.reuseIdentifier
        }
    }
}

private extension FeedMessageBizScene {
    
    /// 标题格式化block， 入参是name
    var titleTextFormatter1: (String) -> String {
        switch self {
        case .thisDocSharedToMe:
            return { (name: String) -> String in
                BundleI18n.SKResource.CreationMobile_Feed_SharedDocWithYou("\(name) ")
            }
        case .mentionedInText, .mentionedTextDeleted:
            return { (name: String) -> String in
                AtInfo.mentionString(userName: name)?.string ?? ""
            }
        case .partialReplyAdded, .commentQuoteDeleted:
            return { (name: String) -> String in
                BundleI18n.SKResource.Doc_Feed_At(name)
            }
        case .newPartialCommentAdded, .newFullCommentAdded, .commentQuoteDeleted:
            return { (name: String) -> String in
                BundleI18n.SKResource.Doc_Feed_New_Comment(name)
            }
        case .morePartialCommentAdded, .commentQuoteDeleted:
            return { (name: String) -> String in
                BundleI18n.SKResource.Doc_Feed_New_Reply(name)
            }
        case .partialCommentResolved, .fullCommentResolved:
            return { _ -> String in
                BundleI18n.SKResource.Doc_Feed_Comment_Resolve
            }
        case .commentBeDeleted:
            return { _ -> String in
                BundleI18n.SKResource.Doc_Feed_Comment_Delete
            }
        case .contentReactionAdded, .contentReactionQuoteDeleted:
            return { (name: String) -> String in
                BundleI18n.SKResource.LarkCCM_Docx_emojiReaction_Notice_UserReacted(name)
            }
        case .contentReactionResolved:
            return { (name: String) -> String in
                BundleI18n.SKResource.LarkCCM_Docx_emojiReaction_Notice_ReactionResolved(name)
            }
        case .contentReactionCancelled:
            return { (name: String) -> String in
                BundleI18n.SKResource.LarkCCM_Docx_emojiReaction_Notice_userRecalled(name)
            }
        }
    }
    
    /// 标题格式化block， 入参是name
    var titleTextFormatter2: (String) -> String {
        switch self {
        case .thisDocSharedToMe:
            return { (name: String) -> String in
                BundleI18n.SKResource.CreationMobile_Feed_SharedDocWithYou("\(name) ")
            }
        case .mentionedInText:
            return { (name: String) -> String in
                BundleI18n.SKResource.CreationMobile_Docs_Notification_CommentMentioned(name)
            }
        case .mentionedTextDeleted:
            return { (name: String) -> String in
                BundleI18n.SKResource.CreationMobile_Docs_Notification_CommentMentioned(name)
            }
        case .commentQuoteDeleted:
            return { (name: String) -> String in
                BundleI18n.SKResource.CreationMobile_Common_Notifications_OriginalTextDeleted(name)
            }
        case .newPartialCommentAdded:
            return { (name: String) -> String in
                BundleI18n.SKResource.CreationMobile_Docs_Notification_Comment(name)
            }
        case .partialReplyAdded, .morePartialCommentAdded:
            return { (name: String) -> String in
                BundleI18n.SKResource.CreationMobile_Docs_Notification_ReplyComment(name)
            }
        case .newFullCommentAdded:
            return { (name: String) -> String in
                BundleI18n.SKResource.CreationMobile_Common_Notifications_DocCommentAdded_Desc(name)
            }
        case .partialCommentResolved:
            return { (name: String) -> String in
                BundleI18n.SKResource.CreationMobile_Docs_Notification_ResolveComment(name)
            }
        case .fullCommentResolved:
            return { (name: String) -> String in
                BundleI18n.SKResource.CreationMobile_Common_Notifications_DocCommentResolved(name)
            }
        case .commentBeDeleted:
            return { (name: String) -> String in
                BundleI18n.SKResource.CreationMobile_Docs_Notification_CommentDeleted(name)
            }
        case .contentReactionAdded, .contentReactionQuoteDeleted:
            return { (name: String) -> String in
                BundleI18n.SKResource.LarkCCM_Docx_emojiReaction_Notice_UserReacted(name)
            }
        case .contentReactionResolved:
            return { (name: String) -> String in
                BundleI18n.SKResource.LarkCCM_Docx_emojiReaction_Notice_ReactionResolved(name)
            }
        case .contentReactionCancelled:
            return { (name: String) -> String in
                BundleI18n.SKResource.LarkCCM_Docx_emojiReaction_Notice_userRecalled(name)
            }
        }
    }
    
    /// 是否应该显示引文
    var shouldDisplayQuoteText: Bool {
        switch self {
        case .thisDocSharedToMe:
            return false
        case .mentionedInText:
            return false
        case .mentionedTextDeleted:
            return false
        case .commentQuoteDeleted:
            return false
        case .newPartialCommentAdded:
            return true
        case .partialReplyAdded, .morePartialCommentAdded:
            return true
        case .newFullCommentAdded:
            return true
        case .partialCommentResolved:
            return true
        case .fullCommentResolved:
            return true
        case .commentBeDeleted:
            return false
        case .contentReactionAdded:
            return true
        case .contentReactionResolved:
            return true
        case .contentReactionCancelled:
            return false
        case .contentReactionQuoteDeleted:
            return false
        }
    }
    
    /// 点击后的toast
    var toastTextWhenTapped1: String? {
        switch self {
        case .thisDocSharedToMe:
            return nil
        case .mentionedInText:
            return nil
        case .mentionedTextDeleted:
            return BundleI18n.SKResource.Doc_Feed_At_OriginText_Deleted
        case .commentQuoteDeleted:
            return BundleI18n.SKResource.Doc_Feed_Comment_OriginText_Deleted
        case .newPartialCommentAdded:
            return nil
        case .partialReplyAdded, .morePartialCommentAdded:
            return nil
        case .newFullCommentAdded:
            return nil
        case .partialCommentResolved:
            return BundleI18n.SKResource.Doc_Feed_Comment_Resolve
        case .fullCommentResolved:
            return BundleI18n.SKResource.Doc_Feed_Comment_Resolve
        case .commentBeDeleted:
            return BundleI18n.SKResource.Doc_Feed_Comment_Delete
        case .contentReactionAdded:
            return nil
        case .contentReactionResolved:
            return BundleI18n.SKResource.LarkCCM_Docx_emojiReaction_Resolved_Toast
        case .contentReactionCancelled:
            return BundleI18n.SKResource.LarkCCM_Docx_emojiReaction_recalled_toast
        case .contentReactionQuoteDeleted:
            return BundleI18n.SKResource.LarkCCM_Docx_emojiReaction_TextDeleted_Toast
        }
    }
    
    /// 点击后的toast
    var toastTextWhenTapped2: String? {
        switch self {
        case .thisDocSharedToMe:
            return nil
        case .mentionedInText:
            return nil
        case .mentionedTextDeleted:
            return BundleI18n.SKResource.Doc_Feed_At_OriginText_Deleted
        case .commentQuoteDeleted:
            return nil
        case .newPartialCommentAdded:
            return nil
        case .partialReplyAdded, .morePartialCommentAdded:
            return nil
        case .newFullCommentAdded:
            return nil
        case .partialCommentResolved:
            return BundleI18n.SKResource.Doc_Feed_Comment_Resolve
        case .fullCommentResolved:
            return BundleI18n.SKResource.Doc_Feed_Comment_Resolve
        case .commentBeDeleted:
            return BundleI18n.SKResource.Doc_Feed_Comment_Delete
        case .contentReactionAdded:
            return nil
        case .contentReactionResolved:
            return BundleI18n.SKResource.LarkCCM_Docx_emojiReaction_Resolved_Toast
        case .contentReactionCancelled:
            return BundleI18n.SKResource.LarkCCM_Docx_emojiReaction_recalled_toast
        case .contentReactionQuoteDeleted:
            return BundleI18n.SKResource.LarkCCM_Docx_emojiReaction_TextDeleted_Toast
        }
    }
    
    var onlyShowTitleInFeedCell: Bool {
        switch self {
        case .thisDocSharedToMe:
            return true
        case .mentionedInText:
            return true
        case .mentionedTextDeleted:
            return true
        case .commentQuoteDeleted:
            return false
        case .newPartialCommentAdded:
            return false
        case .partialReplyAdded, .morePartialCommentAdded:
            return false
        case .newFullCommentAdded:
            return false
        case .partialCommentResolved, .fullCommentResolved:
            return false
        case .commentBeDeleted:
            return true
        case .contentReactionAdded:
            return false
        case .contentReactionResolved:
            return false
        case .contentReactionCancelled:
            return true
        case .contentReactionQuoteDeleted:
            return false
        }
    }
}
