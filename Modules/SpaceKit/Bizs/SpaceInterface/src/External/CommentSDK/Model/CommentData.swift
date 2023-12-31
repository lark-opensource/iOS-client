//
//  CommentData.swift
//  SpaceInterface
//
//  Created by huayufan on 2023/3/30.
//  


import Foundation

public struct SpaceComment {
    public enum Style: String {
        case normal // 普通模式
        case fullScreen // 全屏模式
        case photo // 图片浏览器中的评论卡片样式，不带评论数
        case edit // 编辑状态 -> 隐藏三个点
        case backV2 //有返回，又有评论数

        //下面是新版评论样式
        case normalV2 // V2版本普通模式
        case editV2  // V2版本普通模式编辑态
    }
}

public final class CommentData: NSObject {
    
    public enum CommentType: String {
        case card // 卡片评论
        case full // 全文评论

        public var transform2AtInputTextType: AtInputTextType {
            switch self {
            case .card:
                return .cards
            case .full:
                return .global
            }
        }
    }

    public var chatID: String? //如果是群公告，群的id
    
    /// 有值时表示需要高亮展示该条评论
    public var currentReplyID: String?
    
    /// 有值时表示需要高亮某条评论，nil表示仅仅需要更新
    public var currentCommentID: String?
    /// 当前高亮评论位置,目前iPad评论会用来对齐
    public var currentCommentPos: CGFloat?
    /// 目前iPad评论会用来取消高亮
    public var cancelHightLight: Bool = false
    public var commentPermission: CommentPermission
    /// 数据是否已经加载完，ipad评论会有个loading
    public var isLoaded: Bool = false
    
    public var comments: [Comment] // 评论列表展示数据
    public var currentPage: Int? // 当前评论
    public var style: SpaceComment.Style // Comment View 的样式
    public private(set) var commentDocsInfo: CommentDocsInfo? // 文档信息详情
    private(set) var nPercentScreenHeight: CGFloat? // 屏幕展示高度百分比
    private(set) var commentType: CommentData.CommentType // 评论类型
    public var fromFeed: Bool = false // 来做feed点击
    public var isInPicture: Bool = false // 是否是图片评论
    
    /// 目前用于识别drive的局部评论
    public var localCommentIds: [String] = []
    
    public var paylod: [String: Any] = [:]
    
    /// 埋点使用
    public var statsExtra: CommentStatsExtra?
    
    public init(comments: [Comment],
         currentPage: Int?,
         style: SpaceComment.Style,
         docsInfo: CommentDocsInfo?,
         nPercentScreenHeight: CGFloat? = nil,
         commentType: CommentData.CommentType,
         commentPermission: CommentPermission) {
        self.comments = comments
        self.currentPage = currentPage
        self.style = style
        self.commentDocsInfo = docsInfo
        self.nPercentScreenHeight = nPercentScreenHeight
        self.commentType = commentType
        self.commentPermission = commentPermission
        super.init()
        self.set(commentPermission, docsInfo)
    }
    
    private func set(_ commentPermission: CommentPermission, _ docsInfo: CommentDocsInfo?) {
        self.commentPermission = commentPermission
        for comment in comments {
            comment.commentDocsInfo = docsInfo
            comment.permission = commentPermission
            comment.commentList.forEach {
                $0.permission = commentPermission
                $0.commentDocsInfo = docsInfo
                $0.commentId = comment.commentID
            }
        }
    }
    
    public var commentDesc: String {
        var pos = "nil"
        if let currentCommentPos = currentCommentPos {
            pos = "\(currentCommentPos)"
        }
        var qt = ""
#if BETA || ALPHA || DEBUG
        for comment in comments where comment.commentID == currentCommentID {
            qt = comment.quote ?? ""
            break
        }
#endif
        return "cur_id:\(currentCommentID ?? "nil") pos:\(pos) isCancel:\(cancelHightLight) isLoaded:\(isLoaded) reply_id:\(currentReplyID ?? "") page:\(currentPage) qt:\(qt) inPic:\(isInPicture)"
    }
}
