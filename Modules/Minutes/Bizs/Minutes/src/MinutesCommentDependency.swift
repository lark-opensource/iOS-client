//
//  MinutesCommentDependency.swift
//  MinutesMod
//
//  Created by yangyao on 2022/11/15.
//

import Foundation

public struct MinutesCommentPermissionType {
    public let canComment: Bool
    public let canResolve: Bool
    public let canShowMore: Bool
    public let canShowVoice: Bool
    public let canReaction: Bool
    public let canCopy: Bool
    public let canDelete: Bool
    public let canTranslate: Bool
    public let canDownload: Bool
}

public enum MinutesCommentModuleAction: Int {
    /// 手动拉取评论时返回
    case fetch
    /// 主动推送
    case change
    /// 新增评论数据
    case publish
    ///  删除评论
    case delete
    /// 解决评论
    case resolve
    /// 编辑评论
    case edit
}

public enum MinutesCloseCommentType: Int {
    case cancelNewInput
    case closeNewInput
    case closeFloatCard
}

public struct MinutesCCMComment {
    public let commentID: String
    public let commentUUID: String
    public let replyCount: Int
    public let commentList: [String]
    
    public init(commentID: String, commentUUID: String, replyCount: Int, commentList: [String]) {
        self.commentID = commentID
        self.commentUUID = commentUUID
        self.replyCount = replyCount
        self.commentList = commentList
    }
}

public protocol CCMCommentDelegate: AnyObject {
    func didDeleteComment(with commentId: String)
    
    func didResolveComment(with commentId: String)

    func didSwitchCard(commentId: String, height: CGFloat)
    
    /// 关掉评论UI时会回调给业务接入方
    func cancelComment(type: MinutesCloseCommentType)

    /// 键盘事件通知
    func keyboardChange(options: Int, textViewHeight: CGFloat)
}

public protocol MinutesCommentDependency {
    func initCCMCommentModule(token: String, type: Int, permission: MinutesCommentPermissionType, translateLanguage: String?, delegate: CCMCommentDelegate?)
    func fetchComment()
    
    func updateTranslateLang(lan: String)
        
    func showCommentCards(commentId: String, replyId: String?)
    func showCommentInput(quote: String, tmpCommentId: String)
        
    func setCommentMetadata(commentIds: [String])
        
    func dismiss()
    
    var isVisiable: Bool { get }
    
    func updatePermission(permission: MinutesCommentPermissionType)
}
