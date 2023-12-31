//
//  MockDocsFeedAPI.swift
//  SpaceDemoTests
//
//  Created by chensi(陈思) on 2022/3/14.
//  Copyright © 2022 Bytedance. All rights reserved.


import Foundation
@testable import SKCommon

class MockDocsFeedAPI: DocsFeedAPI {
    
    var clickMessageAction: (() -> Void)?
    
    var clearMessageIds: (([String]) -> Void)?

    var clickProfileAction: (() -> Void)?
    
    /// 通知前端高度 drive没有
    func setPanelHeight(height: CGFloat) {}
    
    /// 消除红点
    func didClearBadge(messageIds: [String]) {
        self.clearMessageIds?(messageIds)
    }
    
    func panelDismiss() {}
    
    /// 展示个人信息
    func showProfile(userId: String) {
        clickProfileAction?()
    }
    
    /// 打开文档
    func openUrl(url: URL) {}
    
    /// 翻译评论。drive没有
    func translate(commentId: String, replyId: String) {}
    
    func clickMessage(message: FeedMessageModel) {
        clickMessageAction?()
    }
    
    func didChangeMuteState(isMute: Bool) {}
}
