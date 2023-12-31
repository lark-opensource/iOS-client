//
//  CommentReaction.swift
//  SpaceKit
//
//  Created by xurunkang on 2019/6/5.
//  

import Foundation
import SwiftyJSON
import SpaceInterface
import LarkReactionView
import LarkReactionDetailController


public struct ReactionRequestInfo: CommentReactionInfoType {
    public var referType: String
    public var referKey: String?
    public var replyId: String?
    public var commentId: String? { nil }
    
    public init(referType: String, referKey: String? = nil, replyId: String? = nil) {
        self.referType = referType
        self.referKey = referKey
        self.replyId = replyId
    }
}

extension CommentReaction: Equatable {
    public static func == (lhs: CommentReaction, rhs: CommentReaction) -> Bool {
        return ( lhs.reactionKey == rhs.reactionKey && lhs.totalCount == rhs.totalCount )
    }
}

extension ReactionInfo {
    var toLarkDetailReaction: LarkReactionDetailController.Reaction {
        return LarkReactionDetailController.Reaction(
            type: self.reactionKey,
            chatterIds: self.users.map({ $0.id })
        )
    }
}
