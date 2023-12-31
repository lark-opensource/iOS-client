//
//  CommentViewFactory.swift
//  SpaceKit
//
//  Created by xurunkang on 2019/3/15.
//  

import Foundation

public typealias ReactionCallback = (ReactionCacllBackData) -> Void

public typealias WebCommentSendCallBack = (Int?, String?) -> Void

public protocol CommentHeaderOutlet {
    /// 点击返回按钮，目前仅是从 Feed 进入的页面有用
    func didClickBackButton(_ commentContext: CommentAdaptContext)
    /// 退出编辑
    func didExitEditing(_ commentContext: CommentAdaptContext)
}

public protocol CommentBodyOutlet {
    // INPUT
    /// 获取复制权限
    func canCopyComment(_ commentContext: CommentAdaptContext) -> Bool
    func canCommentNow(_ commentContext: CommentAdaptContext) -> Bool

    // OUTPUT
    /// 点击评论头像
    func comment(_ commentContext: CommentAdaptContext, didClickAvaterImage userID: String?)
    /// 点击表情详情中的头像
    func didClickAvatarInReactionDetail(_ commentContext: CommentAdaptContext, userID: String?, nav: UINavigationController)
    /// 点击链接
    func comment(_ commentContext: CommentAdaptContext, didClickLink link: URL)
    /// 点击@内容
    func comment(_ commentContext: CommentAdaptContext, didClickAtInfo atInfo: AtInfo)
    /// 点击复制内容
    func comment(_ commentContext: CommentAdaptContext, didCopyContent content: String)
    /// 取消评论高亮
    func comment(_ commentContext: CommentAdaptContext, cancelHightLight cancel: Bool)
    /// 切换到新的页面
    func comment(_ commentContext: CommentAdaptContext, didSwitchPage page: Int, position: CGFloat?, completion: (() -> Void)?)
    /// 增加或者减少 Reaction
    func comment(_ commentContext: CommentAdaptContext,
                 didClickReaction commentItem: CommentItem,
                 key: String,
                 response: ReactionCallback?)
    /// 获取 Reaction 详情
    func comment(_ commentContext: CommentAdaptContext,
                 fetchMoreReaction commentItem: CommentItem,
                 commentReaction: CommentReaction)
    /// 通知前端Reaction详情面板打开状态
    func comment(_ commentContext: CommentAdaptContext,
                 setDetailPanel reaction: CommentReaction,
                 status: Int)
    /// 通知外部点击翻译评论
    func comment(translate commentId: String, replyId: String)
}

public extension CommentBodyOutlet {
    func didClickAvatarInReactionDetail(_ commentContext: CommentAdaptContext, userID: String?, nav: UINavigationController) {}
}

public protocol CommentFooterOutlet {

    func cancelNewInput()

    /// 点击发送按钮
    func comment(_ commentContext: CommentAdaptContext,
                 didClickSendButton content: CommentContent,
                 inputType: AtInputTextType,
                 docType: DocsType,
                 sendCallBack: WebCommentSendCallBack?)
}


public final class ReactionCacllBackData {
    
    public var code: Int?
    public var msg: String?
    public var referType: String?
    public var referKey: String?
    public private(set) var data: [Any]?
    public private(set) var replyId: String?

    public var reactions: [CommentReaction] = []
    
    /// 自定义字段
    public var isNewReaction: Bool = true
    
    public var rawData: [String: Any] = [:]
    
    required public init() {}
}
