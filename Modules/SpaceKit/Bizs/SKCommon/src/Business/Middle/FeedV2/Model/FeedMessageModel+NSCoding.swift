//
//  FeedMessageModel+NSCoding.swift
//  SKCommon
//
//  Created by huayufan on 2021/6/17.
//  


import Foundation
import SpaceInterface

extension FeedMessageModel: NSCoding {
    
    public func encode(with coder: NSCoder) {
        coder.encode(avatarUrl, forKey: "avatarUrl")
        coder.encode(commentCreateTime, forKey: "commentCreateTime")
        coder.encode(commentId, forKey: "commentId")
        coder.encode(messageId, forKey: "messageId")
        coder.encode(mentionId, forKey: "mentionId")
        coder.encode(commentMention, forKey: "commentMention")
        coder.encode(commentUpdateTime, forKey: "commentUpdateTime")
        coder.encode(createTime, forKey: "createTime")
        coder.encode(content, forKey: "content")
        coder.encode(quote, forKey: "quote")
        coder.encode(finish, forKey: "finish")
        coder.encode(isWhole, forKey: "isWhole")
        coder.encode(commentDelete, forKey: "commentDelete")
        coder.encode(name, forKey: "name")
        coder.encode(aliasInfo?.codingProxy, forKey: "displayName")
        coder.encode(replyId, forKey: "replyId")
        coder.encode(replyIndex, forKey: "replyIndex")
        coder.encode(solveStatus, forKey: "solveStatus")
        coder.encode(status.rawValue, forKey: "status")
        coder.encode(type?.rawValue ?? "", forKey: "type")
        coder.encode(userId, forKey: "userId")
        if translateContent != nil {
            coder.encode(translateContent, forKey: "translateContent")
        }
        coder.encode(translateStatus?.rawValue ?? "", forKey: "translateStatus")
        coder.encode(translateLang ?? "", forKey: "translateLang")
        coder.encode(localDeleted, forKey: "localDeleted")
        coder.encode(subType.rawValue, forKey: "subType")
        coder.encode(contentReactionKey, forKey: "contentReactionKey")
        coder.encode(contentReactionDelete, forKey: "contentReactionDelete")
    }
}
