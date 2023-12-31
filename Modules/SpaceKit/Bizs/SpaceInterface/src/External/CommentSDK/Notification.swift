//
//  Notification.swift
//  SpaceInterface
//
//  Created by huayufan on 2023/3/28.
//  


import Foundation

// comment
extension Notification.Name {
    public static let CommentReloadData: Notification.Name = Notification.Name("CommentViewControllerReloadData")

    public static let CommentFeedV2Back: Notification.Name = Notification.Name("Comment.feedV2.back")

    public static let CommentFeedClose: Notification.Name = Notification.Name("Comment.feed.close") //从Feed进入到评论后拖拽或者点击空白关闭评论
    public static let CommentVCDismiss: Notification.Name = Notification.Name("Comment.vc.dismiss")
    
    public static let DismissPanelBeforeShowComment: Notification.Name = Notification.Name("Comment.vc.DismissPanelBeforeShowComment")
}

// comment input
extension Notification.Name {

    public static var commentForcePotraint: Notification.Name {
        Notification.Name("docs.bytedance.notification.name.NOTIFICATION_FORCE_PORTRAIT")
    }
    
    public static var commentCancelForcePotraint: Notification.Name {
        Notification.Name("docs.bytedance.notification.name.NOTIFICATION_CANCEL_FORCE_PORTRAIT")
    }

}
