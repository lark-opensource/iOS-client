//
//  FeedActionService.swift
//  LarkOpenFeed
//
//  Created by liuxianyu on 2023/7/7.
//

import Foundation
import LarkModel
import RustPB

/// action 触发的事件类型
public enum FeedActionEvent {
    case leftSwipe  // 左滑aciton
    case rightSwipe // 右滑aciton
    case longPress  // 长按菜单
}

public protocol FeedActionService {
    /// 说明: FeedActionService 为使用方提供 types 集合以及转换实例的方法
    /// AllTypes = SupplementTypes + BizTypes
    /// SupplementTypes 和 BizTypes 集合是互斥关系, 前者由使用方决策, 后者由业务方决策

    // 依据手势事件获取使用方补充的 SupplementTypes（业务方不感知）
    func getSupplementTypes(model: FeedActionModel, event: FeedActionEvent) -> [FeedActionType]

    // 依据手势事件获取Biz决策的 BizTypes (使用方可以不感知)
    // useSetting: 业务控制是否响应feed action setting
    func getBizTypes(model: FeedActionModel, event: FeedActionEvent, useSetting: Bool) -> [FeedActionType]

    // 依据 Types 集合转成对应的 Action 实例
    func transformToActionItems(model: FeedActionModel, types: [FeedActionType], event: FeedActionEvent) -> [FeedActionBaseItem]
}
