//
//  LarkInterface+Spotlight.swift
//  LarkTourInterface
//
//  Created by Meng on 2019/12/12.
//

import Foundation

public enum SpotlightType: String, CaseIterable {
    case invite_entry           // 邀请成员入口
    case product_feed           // 单品引导 - feed
    case product_calendar       // 单品引导 - calendar
    case product_drive          // 单品引导 - 云空间
    case product_workspace      // 单品引导 - 工作台
    case product_video          // 单品引导 - 视频会议
}

public struct SpotlightItem: Equatable {
    public var title: String
    public var detail: String
    public var targetRect: CGRect
    public init(title: String, detail: String, targetRect: CGRect) {
        self.title = title
        self.detail = detail
        self.targetRect = targetRect
    }
}
