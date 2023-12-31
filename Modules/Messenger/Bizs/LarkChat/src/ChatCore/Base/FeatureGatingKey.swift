//
//  FeatureGatingKey.swift
//  LarkChat
//
//  Created by 李勇 on 2020/4/14.
//

import Foundation
import LarkFeatureGating
import LarkSetting

extension FeatureGatingKey {
    /// 是否展示群 tab
    static let enableChatTab = "im.chat.titlebar.tabs.202203"
    /// 支持用户添加单篇文档tab
    static let chatTitlebarTabAddDoc = "im.chat.titlebar.add.doc.202105"
    /// 群 tab 是否展示引导
    static let enableChatTabOnboarding = "im.chat.tab.onboarding"
}
