//
//  CommentAPIAdaper.swift
//  SKCommon
//
//  Created by huayufan on 2022/9/27.
//  


import UIKit

public struct CommentAPIContent {
    public var params: [String: Any] = [:]
    
    public typealias CommentResponseType = ((Any) -> Void)
    
    public var resonse: CommentResponseType?
    
    // 有新字段在这里补充
    public enum APIKey: String {

        // 通用字段
        case commentId
        case comment_id // switchCard时或者发给RN时传递
        case activeCommentId
        case replyId
        case content
        case reactionKey
        case imageList
        case replyPercentage // double
        case curCommentId = "cur_comment_id" // MS滚动时传递
        case height
        case from
        case msgIds
        case others
        case isWhole
        case index // Int
        case type
        case localCommentId = "local_comment_id" // 新增评论时传给前端or RN的fakeId
        case menuId
        case replyUUID = "reply_uuid" // 回复/编辑评论时传给前端or RN的fakeId
        
        // mention用

        case id
        case avatarUrl = "avatar_url"
        case name
        case cnName = "cn_name"
        case enName = "en_name"
        case unionId = "union_id"
        case department

        //translate用
        case targetLanguage
        
        // RN接口专用

        case quote
        case extra
        case bizParams
        case position
        case rnReplyId = "reply_id"
        case rnIsWhole = "is_whole"
        case rnParentType = "parent_type"
        case rnParentToken = "parent_token"
        case finish
        case page // Int, drive使用
        case referType
        case referKey
        case status
    }
    
    public static var logFunc: ((String) -> Void)?
    
    public func parsing(_ keys: [APIKey]) -> [String: Any] {
        var res: [String: Any] = [:]
        for key in keys {
            if let value = params[key.rawValue] {
                if let str = value as? String, str.isEmpty {
                    Self.logFunc?("comment api key:\(key) string value is empty")
                }
                res[key.rawValue] = value
            } else {
                Self.logFunc?("comment api key:\(key) is nil")
            }
        }
        return res
    }
    
    public init(_ params: [APIKey: Any]) {
        self.params = Dictionary(uniqueKeysWithValues: params.map { ($0.rawValue, $1) })
    }
    
    public subscript<T>(key: APIKey) -> T? {
        return self.params[key.rawValue] as? T
    }
}

public enum CancelType: String {
    case close          = "show_cards" // 关闭评论卡片
    case newInput       = "doc_comment" // 取消新增评论（局部评论）
    case globalComment  = "whole_comment" // 取消新增评论（全文评论）
}

public enum CommentAPIAdaperType {
    case rn
    case webview
}

/// 接口要考虑CCM、小程序、以及后面的妙计
/// 为使接口易于扩展，参数名固定，`不能依赖业务字段`，按需提取。
public protocol CommentAPIAdaper {
    
    var apiType: CommentAPIAdaperType { get }
    
    func addComment(_ content: CommentAPIContent)
    func addReply(_ content: CommentAPIContent)
    func updateReply(_ content: CommentAPIContent)
    func deleteReply(_ content: CommentAPIContent)
    func resolveComment(_ content: CommentAPIContent)
    func retry(_ content: CommentAPIContent)
    func translate(_ content: CommentAPIContent)
    func addReaction(_ content: CommentAPIContent)
    func removeReaction(_ content: CommentAPIContent)
    /// 只有RN在使用
    func setDetailPanel(_ content: CommentAPIContent)
    func getReactionDetail(_ content: CommentAPIContent)
    /// 评论已读
    func readMessage(_ content: CommentAPIContent)
    /// 正文block表情回应卡片已读
    func readMessageByCommentId(_ content: CommentAPIContent)
    /// 滚动通知
    func scrollComment(_ content: CommentAPIContent)
    /// 激活评论滚动到屏幕外
    func activeCommentInvisible(_ content: CommentAPIContent)
    func addContentReaction(_ content: CommentAPIContent)
    func removeContentReaction(_ content: CommentAPIContent)
    func getContentReactionDetail(_ content: CommentAPIContent)
    
    func close(_ content: CommentAPIContent)
    func cancelActive(_ content: CommentAPIContent)
    func switchCard(_ content: CommentAPIContent)
    func panelHeightUpdate(_ content: CommentAPIContent)
    func onMention(_ content: CommentAPIContent)
    func activateImageChange(_ content: CommentAPIContent)

    /// 新增评论失败，点击toast重试时
    func retryAddNewComment(_ content: CommentAPIContent)
    func anchorLinkSwitch(_ content: CommentAPIContent)
    
    func clickQuoteMenu(_ content: CommentAPIContent)
}
