//
//  ChatNavigationItem.swift
//  LarkOpenChat
//
//  Created by zc09v on 2021/10/12.
//

import UIKit
import Foundation
/// 枚举的优先级不是最后的排序 需要业务上指定(必须指定 否则将不知道该按钮怎么排序)
/// 比如: ChatNavigationBarModule的左侧&右侧按钮
/// 分别在ChatNavigationBarLeftModule & ChatNavigationBarRightModule
/// 业务线如果新加按钮 需要到对应left or right SubModule的itemsOrder指定顺序
public enum ChatNavigationExtendItemType: Int, CaseIterable {
    /// right
    case oncallMiniProgram  // 服务台小程序入口
    case searchItem         // 搜索
    case groupMeetingItem   // 群会议
    case phoneItem          // 语音视频
    case videoItem          // 视频
    case addNewMember       // 群添加人员
    case p2pCreateGroup     // 单聊拉人创建群
    case shareItem          // 分享
    case moreItem           // 会话更多信息
    case groupMember        // 查看群成员
    case cancel             // 取消按钮
    case myAIChatMode       // myMy分会话
    case foldItem           // 展开更多

    /// left
    case back               // 返回按钮
    case close              // 关闭按钮
    case fullScreen         // 全屏按钮
    case unread             // 未读
    case closeScene         // 关闭当前Scene ipad
    case scene              // Scene ipad
    case closeDetail        // pad搜索结果页-消息分栏使用，点击后关闭detail页回到搜索全屏
}

public struct ChatNavigationExtendItem {

    public let type: ChatNavigationExtendItemType
    public let view: UIView

    public init(type: ChatNavigationExtendItemType, view: UIView) {
        self.type = type
        self.view = view
    }
}
