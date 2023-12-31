//
//  FeedMuteService.swift
//  LarkOpenFeed
//
//  Created by xiaruzhen on 2023/4/3.
//

import Foundation

public protocol FeedMuteConfigService {
    // 依据筛选状态，更新 showMute 字段
    func updateShowMute(_ showMute: Bool)

    // 是否展示免打扰分组相关功能
    func getShowMute() -> Bool

    // 免打扰分组的fg
    func addMuteGroupEnable() -> Bool
}
