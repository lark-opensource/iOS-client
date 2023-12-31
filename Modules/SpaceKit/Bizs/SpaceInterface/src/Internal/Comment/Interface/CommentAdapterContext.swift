//
//  CommentAdapterContext.swift
//  SKCommon
//
//  Created by chenhuaguan on 2020/11/19.
//

import Foundation

public enum CommentFrom: String {
    case web // 正文
    case photo // 图片查看器
    case feedV2 // 消息改版2.0
    case gadget
}

public protocol CommentAdaptContext {
    var currentCommentID: String { get }
    var currentComment: Comment? { get }
    var currentCommentType: CommentData.CommentType { get }
    var currentEditingCommentItem: CommentItem? { get }
    var atInputTextType: AtInputTextType { get }
    var atInputFocusType: AtInputFocusType { get }
    var commentViewHeight: CGFloat? { get }
    var from: CommentFrom { get }
    func showSuccess(_ text: String)
    func showFailed(_ text: String)
}
