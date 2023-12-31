//
//  FeedListViewModelType.swift
//  LarkOpenFeed
//
//  Created by liuxianyu on 2022/5/23.
//

import Foundation
import RustPB

public enum FeedListViewModelType {
    case message
    case done
    case general
    case at
    case mute

    public static let feedListVMTypes: [Feed_V1_FeedFilter.TypeEnum: FeedListViewModelType] = [
        .inbox: FeedListViewModelType.message, // 全部
        .message: FeedListViewModelType.message, // 消息
        .mute: FeedListViewModelType.mute, // 免打扰
        .atMe: FeedListViewModelType.at, // @我
        .unread: FeedListViewModelType.general, // 未读
        .doc: FeedListViewModelType.general, // 云文档
        .p2PChat: FeedListViewModelType.general, // 单聊
        .groupChat: FeedListViewModelType.general, // 群聊
        .bot: FeedListViewModelType.general, // 机器人
        .helpDesk: FeedListViewModelType.general, // 服务台
        .topicGroup: FeedListViewModelType.general, // 话题圈
        .done: FeedListViewModelType.done, // 已完成
        .cryptoChat: FeedListViewModelType.general, // 密聊
        .thread: FeedListViewModelType.general, // 话题
        .unreadOverDays: FeedListViewModelType.general, // 超一周未读分组
        .instantMeetingGroup: FeedListViewModelType.general, // 临时会议群分组
        .calendarGroup: FeedListViewModelType.general // 日程会议群分组
    ]
}
