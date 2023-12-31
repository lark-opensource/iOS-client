//
//  MountCommentModel.swift
//  SpaceInterface
//
//  Created by huayufan on 2023/3/28.
//  


import UIKit

// Drive评论在使用的，从原来WebCommentProcessor中迁移过来

public typealias MountNodePoint = (type: DocsType, token: String)

public struct MountCommentInfo {

    public var type: AtInputTextType? // 评论类型
    public var focusType: AtInputFocusType? // 新建 or 编辑

    public let mountNodePoint: MountNodePoint // file type + file token

    public var commentID: String?
    public var replyID: String?

    public var isRetry: Bool

    public var isGlobal: Bool {
        return type == .global
    }

    public init(type: AtInputTextType?, focusType: AtInputFocusType?, mountNodePoint: MountNodePoint, commentID: String?, replyID: String?, isRetry: Bool = false) {
        self.type = type
        self.focusType = focusType
        self.mountNodePoint = mountNodePoint
        self.commentID = commentID
        self.replyID = replyID
        self.isRetry = isRetry
    }
    
    mutating func update(isRetry: Bool, commentId: String, replyId: String) {
        self.isRetry = isRetry
        self.replyID = replyId
        self.commentID = commentId
    }
}

public struct MountComment {
    public let content: CommentContent // 评论原始数据
    public var info: MountCommentInfo // 辅助信息
    public init(content: CommentContent, info: MountCommentInfo) {
        self.content = content
        self.info = info
    }
}
