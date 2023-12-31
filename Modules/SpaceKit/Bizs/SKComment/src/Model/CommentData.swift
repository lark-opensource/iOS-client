//
//  NewCommentViewData.swift
//  SpaceKit
//
//  Created by bytedance on 2018/10/25.
//

import UIKit
import SpaceInterface
import SwiftyJSON
import SKResource
import SKFoundation
import SKCommon

extension CommentData {

    public var docsInfo: DocsInfo? {
        return commentDocsInfo as? DocsInfo
    }

    public func changeStyle(_ style: SpaceComment.Style) {
        self.style = style
    }

    public func changeComments(_ comments: [Comment]) {
        self.comments = comments
    }
    
    public var hasHighlighted: Bool {
        guard let currentCommentID = currentCommentID,
              currentCommentID.isEmpty == false else {
                return false
        }
        return true
    }
    
    var hasNewInput: Bool {
        let newInputComment = comments.first { (comment) -> Bool in
            return comment.isNewInput
        }
        guard newInputComment != nil else {
            return  false
        }
        return true
    }
    
    public func addFooter() {
        for comment in comments {
            comment.addFooter()
        }
    }
    
    public static func empty() -> CommentData {
        return CommentData(comments: [], currentPage: nil, style: .normalV2, docsInfo: nil, commentType: .card, commentPermission: [])
    }
}

extension CommentData {
    static func == (lhs: CommentData, rhs: CommentData) -> Bool {
        return lhs.comments == rhs.comments
    }
    
    func setActiveComment(_ commentId: String) {
        guard !commentId.isEmpty else { return }
        self.currentCommentID = commentId
        self.currentPage = nil
        var findCommentId = false
        for (idx, comment) in self.comments.enumerated() {
            if comment.commentID == commentId {
                DocsLogger.info("[comment sdk] set activeComment:\(commentId) quote:\(comment.quote ?? "")",
                                 component: LogComponents.comment)
                comment.isActive = true
                self.currentPage = idx
                findCommentId = true
            } else {
                comment.isActive = false
            }
        }
        DocsLogger.info("[comment sdk] set activeComment findCommentId:\(findCommentId)",
                         component: LogComponents.comment)
    }
}
