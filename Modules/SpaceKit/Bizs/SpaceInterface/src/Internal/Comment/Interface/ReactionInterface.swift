//
//  ReactionInterface.swift
//  SpaceInterface
//
//  Created by huayufan on 2023/3/31.
//  


import Foundation

public protocol CommentReactionInfoType {
    var referType: String { get }
    var referKey: String? { get }
    var replyId: String? { get }
    /// 评论卡片id,仅用于正文reaction
    var commentId: String? { get }
}
