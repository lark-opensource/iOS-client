//
//  Event.swift
//  UGContainer
//
//  Created by mochangxing on 2021/1/26.
//

import Foundation

/// 事件定义
public struct ReachPointEvent {
    /// 事件名称
    public let eventName: String
    /// 触达点位类型
    public let reachPointType: String
    /// 触达点位 id
    public let reachPointId: String
    /// 物料key
    public let materialKey: String?
    /// 物料id
    public let materialId: Int64?

    public let consumeTypeValue: Int
    /// 额外上下文
    public let extra: [String: String]

    public init(eventName: String,
                reachPointType: String,
                reachPointId: String,
                materialKey: String? = nil,
                materialId: Int64? = nil,
                consumeTypeValue: Int = 0,
                extra: [String: String]) {
        self.eventName = eventName
        self.reachPointType = reachPointType
        self.reachPointId = reachPointId
        self.materialKey = materialKey
        self.materialId = materialId
        self.consumeTypeValue = consumeTypeValue
        self.extra = extra
    }
}

public extension ReachPointEvent {
    
    init(eventName: ReachPointEvent.Key,
         reachPointType: String,
         reachPointId: String,
         materialKey: String? = nil,
         materialId: Int64? = nil,
         consumeTypeValue: Int = 0,
         extra: [String: String]) {
        self.eventName = eventName.rawValue
        self.reachPointType = reachPointType
        self.reachPointId = reachPointId
        self.materialKey = materialKey
        self.materialId = materialId
        self.consumeTypeValue = consumeTypeValue
        self.extra = extra
    }

    enum Key: String {
        /// ReachPoint显示
        case didShow
        /// ReachPoint隐藏
        case didHide
        /// ReachPoint消费
        case consume
        /// ReachPoint创建
        case onCreate
        /// ReachPoint初始化完成
        case onReady
        /// ReachPoint销毁
        case onDestroy
        /// ReachPoint移除
        case onRemove
        /// 点击事件
        case onClick
    }
}
