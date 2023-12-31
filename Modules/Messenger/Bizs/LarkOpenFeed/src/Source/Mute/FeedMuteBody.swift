//
//  FeedMuteBody.swift
//  LarkOpenFeed
//
//  Created by xiaruzhen on 2023/4/3.
//

import Foundation
import EENavigator

/// 免打扰会话的消息提醒设置
public struct FeedBadgeStyleSettingBody: PlainBody {
    public static var pattern: String = "//client/feed/badgeStyleSetting"

    public init() {}
}
