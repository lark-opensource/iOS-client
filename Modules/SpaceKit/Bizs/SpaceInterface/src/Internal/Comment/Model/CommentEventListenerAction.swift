//
//  CommentEventListenerAction.swift
//  SKCommon
//
//  Created by huayufan on 2022/1/12.
//  


import Foundation

public enum CommentEventListenerAction: String {
    
    case switchStyle
    /**
       commentId: String
       replyId: String
       index: -1 时为关闭图片
     */
    case activateImageChange

    /**
     type: String
     */
    case cancel
    case panelHeightUpdate
    case switchCard
    case onMention
    
    // 原addEventListener RN使用
    case change
    case publish
    case delete
    case reopen
    case resolve
    case edit
//    case translate
    
    
    // 原评论RN接口转到WebView
    
    /**
       commentId?: String // 新增回复必填
       content: String
       imgId: String // 图片查看器内评论需要
       imageList: Array<{ uuid: string; src: string; }>;
     */
    case addComment
    case addReply
    
    /**
       commentId: String
       replyId: String
       content: String
       imageList: Array<{ uuid: string; src: string; token: string;}>;
     */
    case updateReply // 编辑评论
    
    /**
       commentId: String
       replyId: String
     */
    case deleteReply // 删除评论
    
    /**
       commentId: String
     */
    case resolveComment
    
    /**
       commentId: String
       replyId: String
     */
    case retryOperation
    
    /**
       commentId: String
       replyId: String
     */
    case translate
    
    /**
       reactionKey: String
       replyId: String
     */
    case addReaction
    case removeReaction
    
    /**
       replyId: String
     */
    case getReactionDetail
    
    /**
      msgIds: [String]
     */
    case readMessage // 评论消息已读
    
    /**
      commentId: String
     */
    case readMessageByCommentId // 正文表情回应卡片已读
    
    /**
     cur_comment_id: String;
     replyId: String;
     replyPercentage: Double;
     */
    case scrollComment // 滚动通知
    
    case activeCommentInvisible // 激活评论滚动到屏幕外
    
    /**
     commentId: String 评论卡片id
     reactionKey: String 表情标识
     */
    case addContentReaction
    case removeContentReaction
    
    /**
     commentId: String 评论卡片id
     */
    case getContentReactionDetail
    
    /// 点击图片评论入口按钮
    case clickImageComment
    
    /**
     commentId: String 评论卡片id
     */
    case anchorLinkSwitch
    
    case onMenuClicked
}
