//
//  CommentScrollInfo.swift
//  SKCommon
//
//  Created by huayufan on 2022/3/9.
//  


import UIKit

public struct CommentScrollInfo {

    var commentId: String
    
    var replyId: String
    
    var replyPercentage: Double
    
    init(commentId: String, replyId: String, replyPercentage: Double) {
        self.commentId = commentId
        self.replyId = replyId
        self.replyPercentage = replyPercentage
    }
    
}
