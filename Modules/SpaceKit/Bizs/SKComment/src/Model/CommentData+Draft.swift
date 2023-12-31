//
//  CommentData+Draft.swift
//  SKCommon
//
//  Created by huayufan on 2022/8/23.
//  


import Foundation
import SKFoundation
import SpaceInterface

extension CommentItem: CommentDraftKeyProvider {
    
    // 自身的draftKey
    public var commentDraftKey: CommentDraftKey {
        let isWhole = false
        guard let token = docsInfo?.token, !token.isEmpty else {
            DocsLogger.error("get commentDraftKey error, token is nil", component: LogComponents.comment)
            return CommentDraftKey(entityId: nil, sceneType: .newComment(isWhole: isWhole))
        }
        if isNewInput {
            return CommentDraftKey(entityId: token, sceneType: .newComment(isWhole: isWhole))
        }
        switch self.viewStatus {
        case .normal:
            // 一般不会走这里
            return CommentDraftKey(entityId: token, sceneType: .newComment(isWhole: false))
        case .edit:
            return CommentDraftKey(entityId: token,
                                   sceneType: .editExisting(commentId: commentId ?? "", replyId: replyID))
        case .reply:
            return CommentDraftKey(entityId: token,
                                   sceneType: .newReply(commentId: commentId ?? ""))
        }
    }
    
    public var newReplyKey: CommentDraftKey {
        guard let token = docsInfo?.token, !token.isEmpty else {
            return CommentDraftKey(entityId: nil, sceneType: .newComment(isWhole: false))
        }
        return CommentDraftKey(entityId: token,
                               sceneType: .newReply(commentId: commentId ?? ""))
    }
    
    public var editDraftKey: CommentDraftKey {
        guard let token = docsInfo?.token, !token.isEmpty else {
            DocsLogger.error("get commentDraftKey error, token is nil", component: LogComponents.comment)
            return CommentDraftKey(entityId: nil, sceneType: .newComment(isWhole: false))
        }
        return CommentDraftKey(entityId: token,
                               sceneType: .editExisting(commentId: commentId ?? "", replyId: replyID))
    }
}
