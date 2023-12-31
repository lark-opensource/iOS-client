//
//  FeatureGatingKey.swift
//  LarkThread
//
//  用于管理仅在LarkThread业务中使用的FeatureGatingKey。
//
//  Created by lizhiqiang on 2020/3/11.
//

import Foundation

struct FeatureGatingKey {
    /// 观察者模式下显示订阅checkbox
    static let joinGroupWithSubscribeEnable = "group.participant.default.subscribe"

    /// 小组、话题详情页、动态列表 请求数目动态调整
    static let dynamicRequestCountEnable = "group.dynamic.request.count"
}
