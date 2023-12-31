//
//  LKTabbarController+Spotlight.swift
//  LarkNavigation
//
//  Created by Meng on 2019/12/13.
//

import Foundation
import LarkUIKit
import AnimatedTabBar
import LarkTab

// swiftlint:disable identifier_name
enum SpotlightAccessoryIdentifier: String {
    case navibar_first_button
    case tab_feed
    case tab_calendar
    case tab_drive
    case tab_workspace
    case tab_video
    case tab_mail
}

public enum SpotlightType: String, CaseIterable {
    case invite_entry           // 邀请成员入口
    case product_feed           // 单品引导 - feed
    case product_calendar       // 单品引导 - calendar
    case product_drive          // 单品引导 - 云空间
    case product_workspace      // 单品引导 - 工作台
    case product_video          // 单品引导 - 视频会议
}
