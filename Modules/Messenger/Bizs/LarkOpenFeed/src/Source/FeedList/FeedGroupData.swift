//
//  EntityData.swift
//  LarkOpenFeed
//
//  Created by xiaruzhen on 2023/9/1.
//

import Foundation
import RustPB

public enum FeedGroupData {
    // TODO: open feed tea埋点以及日志打印
    public static func name(groupType: Feed_V1_FeedFilter.TypeEnum) -> String {
        switch groupType {
        case .inbox:        return "inbox" // 全部
        case .atMe:         return "at_me" // @我
        case .unread:       return "unread" // 未读
        case .doc:          return "docs" // 云文档
        case .p2PChat:      return "p2p_chat" // 单聊
        case .groupChat:    return "group_chat" // 群聊
        case .bot:          return "bot" // 机器人
        case .helpDesk:     return "helpdesk" // 服务台
        case .topicGroup:   return "channel" // 话题群
        case .done:         return "done" // 已完成
        case .cryptoChat:   return "secret_chat" // 密聊
        case .message:      return "message" // 消息
        case .mute:         return "mute" // 免打扰
        case .team:         return "team" // 团队
        case .tag:          return "label" // 标签
        case .thread:       return "thread" // 话题帖子
        case .flag:         return "mark" // 标记
        case .unreadOverDays: return "unread_over_days" // 超7天未读分组
        case .instantMeetingGroup: return "instant_meeting_group" // 临时会议群分组
        case .calendarGroup: return "calendar_meeting" // 日程会议群分组
        @unknown default:            return "unknown"
        }
    }
}
