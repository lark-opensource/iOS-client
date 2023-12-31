//
//  CommentDraftKeyScene.swift
//  SpaceInterface
//
//  Created by huayufan on 2023/3/28.
//  


import Foundation

public enum CommentDraftKeyScene {
    case newComment(isWhole: Bool)                          // 新增评论(isWhole是否是全文评论)
    case newReply(commentId: String)                        // 新增回复
    case editExisting(commentId: String, replyId: String)   // 编辑现有的
}
