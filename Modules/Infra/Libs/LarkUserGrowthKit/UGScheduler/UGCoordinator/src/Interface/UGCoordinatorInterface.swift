//
//  UGCoordinatorInterface.swift
//  UGCoodinator
//
//  Created by zhenning on 2021/1/21.
//

import Foundation
import RustPB

// 场景触达信息
public typealias UGScenarioContext = Ugreach_V1_ScenarioContext
public typealias UGReachPointEntity = Ugreach_V1_ReachPointEntity
public typealias UGReachPointRelation = Ugreach_V1_ReachPointRelation
public typealias UGDefenseStrategy = UGReachPointRelation.DefenseStrategy

public struct CoordinatorReachPointEvent {
    var action: ActionEvent // 显示、关闭、消费、移除
    var reachPointIDs: [String]
    public init(action: ActionEvent,
                reachPointIDs: [String]) {
        self.action = action
        self.reachPointIDs = reachPointIDs
    }
}

/// 事件
public enum ReachPointState {
    // 展示
    case show
    // 消失
    case hide
}

public struct CoordinatorResult {
    public var rpState: ReachPointState // 展示状态
    public var rpEntitys: [UGReachPointEntity] // 触达点位信息数组

    public init(rpState: ReachPointState,
                rpEntitys: [UGReachPointEntity]) {
        self.rpState = rpState
        self.rpEntitys = rpEntitys
    }
}

/// 事件
public enum ActionEvent {
    // 展示
    case show
    // 消失
    case hide
    // 消费（消失并从图中去掉）
    case consume
    // 直接从图中摘掉，并移除关系
    case remove
}

// MARK: - Model

// 触达点位实体
public struct UGReachPointEntityInfo {
    public let entity: UGReachPointEntity
    public var sceShareIDs: [String]?
    public var scePriority: Int
    public init(entity: UGReachPointEntity,
                sceShareIDs: [String]? = nil,
                scePriority: Int) {
        self.entity = entity
        self.sceShareIDs = sceShareIDs
        self.scePriority = scePriority
    }
}

protocol UGNodeType: Equatable {
    var nodeID: String { get }
    var childIDs: [String] { get set }
    // 入度
    var indegree: Int { get set }
}

/// 图节点
public final class UGDAGNode: UGNodeType {
    var nodeID: String
    var childIDs: [String]
    // 入度
    var indegree: Int = 0

    public init(nodeID: String,
         childIDs: [String]) {
        self.nodeID = nodeID
        self.childIDs = childIDs
    }

    init(ugNode: UGBizNode) {
        self.nodeID = ugNode.nodeID
        self.childIDs = ugNode.childIDs
    }

    /// 节点信息
    public func info() -> String {
        let infoString = nodeID + "\(childIDs), indegree = \(indegree)"
        return infoString
    }

    public static func == (lhs: UGDAGNode, rhs: UGDAGNode) -> Bool {
        return lhs.nodeID == rhs.nodeID
    }
}

/// 调度数据结构节点
final class UGBizNode: UGNodeType {
    // 基本属性
    var nodeID: String {
        return reachPointID
    }
    var scenarioID: String
    let reachPointID: String
    var childIDs: [String]
    // server下发的配置依赖id
    var rawChildIDs: [String]?
    // server下发的父节点id
    var parentID: String?
    // 数据源
    let entityInfo: UGReachPointEntityInfo
    // 数据源
    var entity: UGReachPointEntity {
        return entityInfo.entity
    }
    // 入度
    var indegree: Int = 0
    // 节点总优先级：entity优先级+ scePriority
    var priority: Int = 0
    /// 冲突
    // 是否与其他 node 互斥
    var isConflict: Bool = false
    // 共享的reachpoint域
    var sceShareIDs: [String]?
    // 消费次数
    var ttl: Int = 0
    // 被抢占时的应对策略
    var defenseStrategy: UGDefenseStrategy
    // 是否需要重建
    var needRebuild: Bool? = false
    // 是否需要强占，当优先级较高的时候
    var needGrab: Bool = false
    init(entityInfo: UGReachPointEntityInfo) {
        self.entityInfo = entityInfo
        let entity = entityInfo.entity
        self.reachPointID = entity.reachPointID
        self.scenarioID = entity.scenarioID
        let relation = entity.config.relation
        self.childIDs = relation.childIds
        // 总优先级
        self.priority = Int(relation.priority) + Int(entityInfo.scePriority)
        self.parentID = relation.parentID
        self.isConflict = relation.isConflict
        self.needGrab = relation.needGrab
        self.defenseStrategy = relation.defenseStrategy
        self.rawChildIDs = relation.childIds
        self.sceShareIDs = entityInfo.sceShareIDs ?? []
        self.ttl = Int(relation.ttl)
    }

    static func == (lhs: UGBizNode, rhs: UGBizNode) -> Bool {
        return lhs.nodeID == rhs.nodeID
    }

    func resetChildIDs() {
        self.childIDs = self.rawChildIDs ?? []
    }

    func reset() {
        self.childIDs = self.rawChildIDs ?? []
        self.indegree = 0
    }

}
