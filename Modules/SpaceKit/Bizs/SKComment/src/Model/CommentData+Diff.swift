//
//  CommentData+Diff.swift
//  SKCommon
//
//  Created by huayufan on 2021/12/19.
//  


import Foundation
import SKFoundation
import Differentiator
import SpaceInterface

// MARK: Differentiable
extension CommentItem: IdentifiableType, Hashable, Equatable {
  

    public func hash(into hasher: inout Hasher) {
        hasher.combine(replyID)
    }

    public static func == (lhs: CommentItem, rhs: CommentItem) -> Bool {
        var isEqual = lhs.createTimeStamp == rhs.createTimeStamp &&
        lhs.updateTimeStamp == rhs.updateTimeStamp &&
        lhs.creatTime == rhs.creatTime &&
        lhs.updateTime == rhs.updateTime &&
        lhs.content == rhs.content &&
        lhs.reactions == rhs.reactions &&
        lhs.status == rhs.status &&
        lhs.quote == rhs.quote &&
        lhs.isSending == rhs.isSending &&
        lhs.translateContent == rhs.translateContent &&
        lhs.translateStatus == rhs.translateStatus &&
        lhs.errorCode == rhs.errorCode &&
        lhs.replyUUID == rhs.replyUUID &&
        lhs.retryType == rhs.retryType
        let sameImage = lhs.imageList == rhs.imageList
        isEqual = isEqual && lhs.isActive == rhs.isActive &&
           lhs.isNewInput == rhs.isNewInput &&
           lhs.permission == rhs.permission &&
           sameImage
        if !isEqual, sameImage {
            if lhs.imageList == rhs.imageList {
                _syncImagesState(lhs: lhs, rhs: rhs)
            }
        }
        return isEqual
    }
    
    static func != (lhs: CommentItem, rhs: CommentItem) -> Bool {
        if lhs == rhs {
            return false
        } else {
            return true
        }
    }
    
    public var identity: String {
        return self.replyID
    }
    
    private static func _syncImagesState(lhs: CommentItem, rhs: CommentItem) {
        guard lhs.imageList.count == rhs.imageList.count else {
            return
        }
        for (item1, item2) in zip(lhs.imageList, rhs.imageList) {
            if item1.status != .none {
                item2.update(status: item1.status)
            } else if item2.status != .none {
                item1.update(status: item2.status)
            }
        }
    }
}

extension Comment: IdentifiableType, Hashable {
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(commentID)
        hasher.combine(quote ?? "")
    }
    
    public var identity: String {
        return self.commentID
    }

    public static func == (lhs: Comment, rhs: Comment) -> Bool {
        return lhs.commentID == rhs.commentID &&
               lhs.quote == rhs.quote &&
               lhs.isActive == rhs.isActive
    }
}

public struct AnimatableCommentModel {
    public var model: Comment
    public var items: [CommentItem]

    public init(model: Comment, items: [CommentItem]) {
        self.model = model
        self.items = items
    }
    
}

extension AnimatableCommentModel: AnimatableSectionModelType {

    public var identity: String {
        return model.identity
    }

    public init(original: AnimatableCommentModel, items: [CommentItem]) {
        self.model = original.model
        self.items = items
        self.model.commentList = items
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.model.identity)
    }
}


extension AnimatableCommentModel: Equatable {
    
    public static func == (lhs: AnimatableCommentModel, rhs: AnimatableCommentModel) -> Bool {
        return lhs.model == rhs.model
            && lhs.items == rhs.items
    }
}
