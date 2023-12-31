//
//  UGDAGraph.swift
//  UGCoodinator
//
//  Created by zhenning on 2021/1/21.
//

import UIKit
import Foundation
import LKCommonsLogging
import LarkExtensions
import Homeric

// 有向图接口
public final class UGDAGraph {

    private static let log = Logger.log(UGDAGraph.self, category: "UGScheduler")
    let tracer = Tracer()

    // 节点列表
    var nodes: [UGDAGNode] = []
    // 根节点列表
    var rootNodes: [UGDAGNode] {
        // 入度为0
        let rootNodes = self.nodes.filter {
            $0.indegree == 0
        }
        Self.log.debug("[UGDAGraph]: rootNodes = \(rootNodes.map { $0.nodeID })")
        return rootNodes
    }
    var rootNodeIds: [String] {
        return rootNodes.map { $0.nodeID }
    }
    // 节点列表
    private var nodesIndegreeMap: [String: Int] {
        let nodesIndegreeMap: [String: Int] = self.nodes.reduce(into: [String: Int]()) {
            $0[$1.nodeID] = $1.indegree
        }
        Self.log.debug("[UGDAGraph]: nodesIndegreeMap = \(nodesIndegreeMap)")
        return nodesIndegreeMap
    }

    public init() {}

    public func initGraph(dagNodes: [UGDAGNode]) {
        self.nodes = dagNodes
        self.updateIndegreeOfNodes(nodes: dagNodes)
        // 判断图是否存在循环
        guard !isGraphHasCircle() else {
            let identifier = String(CACurrentMediaTime())
            self.tracer
                .traceLog(msg: "there is circle dependency in graph!, error = \(UGCoordinatorErrorCode.relation_circle_error)")
                .traceMetric(
                    eventKey: Homeric.UG_REACH_COORDINATOR_ERROR,
                    identifier: identifier,
                    category: ["isSuccess": "false",
                               "errorCode": "\(UGCoordinatorErrorCode.relation_circle_error)",
                               "reachpointId": dagNodes.first?.nodeID ?? ""],
                    extra: ["errMsg": "there is circle dependency in graph!"],
                    isEndPoint: true
                )
            Self.log.error("[UGDAGraph]: 图中有循环！")
            return
        }
    }

    // 更新节点的入度
    private func updateIndegreeOfNodes(nodes: [UGDAGNode]) {
        nodes.forEach {
            // 更新每个节点的边和子节点入度
            traverseChildNode(parentNode: $0) { (childID) in
                changeNodeIndegree(nodeID: childID, isIncrease: true)
                Self.log.debug("[UGDAGraph]: updateIndegreeOfNodes 遍历子节点 childID = \(childID)")
            }
        }
    }
}

// MARK: - Node
extension UGDAGraph {

    // 节点添加，同时更新对应的边和关系
    func addBizNode(ugNode: UGBizNode) {
        let dagNode = UGDAGNode(nodeID: ugNode.nodeID, childIDs: ugNode.childIDs)
        addDAGNode(dagNode: dagNode)
    }

    // 节点添加，同时更新对应的边和关系，自动去重
    public func addDAGNode(dagNode: UGDAGNode) {
        guard !nodes.contains(dagNode) else {
            Self.log.error("[UGDAGraph]: addnode already exist: nodeID = \(dagNode.nodeID)")
            return
        }
        nodes.lf_appendIfNotContains(dagNode)
        dagNode.childIDs.forEach {
            addRelationGraphArc(parentID: dagNode.nodeID, childID: $0)
        }
    }

    // 节点添加，同时更新对应的边和关系，自动去重
    func addNodes(dagNodes: [UGDAGNode]) {
        nodes.lf_appendContentsIfNotContains(dagNodes)
        dagNodes.forEach { dagNode in
            dagNode.childIDs.forEach {
                addRelationGraphArc(parentID: dagNode.nodeID, childID: $0)
            }
        }
    }

    // 删除节点，同时更新子节点关系
    public func removeNode(nodeID: String) {
        // 移除和子节点关系，更新子节点入度
        if let node = getNodeInGraphByNodeID(nodeID: nodeID) {
            node.childIDs.forEach {
                removeRelationGraphArc(parentID: nodeID, childID: $0)
            }
        }
        // 移除node
        if let idx = nodes.firstIndex(where: { $0.nodeID == nodeID }) {
            nodes.remove(at: idx)
        } else {
            Self.log.error("[UGDAGraph]: removeNode node not exist: nodeID = \(nodeID)")
        }
    }

    // 删除节点,同时更新子节点关系
    func removeNode(reachPointEntity: UGReachPointEntity) {
        removeNode(nodeID: reachPointEntity.reachPointID)
    }

    // 删除节点,同时更新子节点关系
    func removeNodes(entitys: [UGReachPointEntity]) {
        entitys.forEach {
            removeNode(reachPointEntity: $0)
        }
    }

    // 增加/减少节点入度
    // 如果节点在根节点数组中，需要将其移除
    func changeNodeIndegree(nodeID: String, isIncrease: Bool) {
        guard let node = getNodeInGraphByNodeID(nodeID: nodeID) else {
            Self.log.error("[UGDAGraph]: changeNodeIndegree 图中不存在该节点！nodeId = \(nodeID)")
            return
        }
        let delta = isIncrease ? 1 : -1
        node.indegree += delta
        Self.log.debug("[UGDAGraph]: changeNodeIndegree nodeId = \(nodeID), isIncrease = \(isIncrease), node.indegree = \(node.indegree)")
    }
}

// MARK: - Relation Arc
extension UGDAGraph {

    /// 添加边关系，并且更新节点入度
    func addRelationGraphArc(parentID: String, childID: String) {
        guard let parentNode = getNodeInGraphByNodeID(nodeID: parentID),
              !parentNode.childIDs.contains(childID) else {
            Self.log.error("[UGDAGraph]: addRelationGraphArc invalid! parentID = \(parentID)")
            return
        }
        // 添加子节点关系
        parentNode.childIDs.lf_appendIfNotContains(childID)
        // 更新子节点的入度
        changeNodeIndegree(nodeID: childID, isIncrease: true)
        Self.log.debug("[UGDAGraph]: addRelationGraphArc parentID = \(parentID), childID = \(childID)")
    }

    /// 删除边, 删除节点的关系，并更新子节点的入度
    func removeRelationGraphArc(parentID: String, childID: String) {
        guard let parentNode = getNodeInGraphByNodeID(nodeID: parentID),
              !parentNode.childIDs.isEmpty,
              parentNode.childIDs.contains(childID) else {
            Self.log.error("[UGDAGraph]: removeRelationGraphArc invalid! parentID = \(parentID)")
            return
        }
        // 删除子节点关系
        if let index = parentNode.childIDs.firstIndex(of: childID) {
            parentNode.childIDs.remove(at: index)
            Self.log.debug("[UGDAGraph]: removeRelationGraphArc index = \(index)")
        }
        // 更新子节点的入度
        changeNodeIndegree(nodeID: childID, isIncrease: false)
        Self.log.debug("[UGDAGraph]: removeRelationGraphArc parentID = \(parentID)")
    }
}

// MARK: - Tree
extension UGDAGraph {

    // 遍历节点一级子节点，访问深度为1， callback: 回调
    func traverseChildNode(parentNode: UGDAGNode, callback: ((_ childID: String) -> Void)) {
        guard !parentNode.childIDs.isEmpty else {
            Self.log.debug("[UGDAGraph]: parent childIDs is empty, parent = \(parentNode.nodeID)")
            return
        }
        parentNode.childIDs.forEach { callback($0) }
        Self.log.debug("[UGDAGraph]: traverseChildNode parent = \(parentNode.nodeID)")
    }

    // 遍历节点的生成树, callback: 回调注入
    // 访问节点时会执行 handleChildCallback，前者先序执行，后者后序执行
    // checkIsCycle: 是否检查子节点的入度
    func traverseTree(node: UGDAGNode, checkNextIsRoot: Bool? = false, handleChildCallback: ((_ childID: String) -> Void)) {
        guard !node.childIDs.isEmpty else {
            Self.log.debug("[UGDAGraph]: node childIDs is empty, node = \(node)")
            return
        }

        node.childIDs.forEach {
            if let node = getNodeInGraphByNodeID(nodeID: $0) {
                traverseTree(node: node, handleChildCallback: handleChildCallback)
                handleChildCallback($0)
            } else {
                Self.log.error("[UGDAGraph]: traverseTree nodeis not in graph nodeID = \($0)")
            }
        }
        Self.log.debug("[UGDAGraph]: traverseTree nodeID = \(node.nodeID), indegree = \(node.indegree)")
    }
}

// MARK: - Util
extension UGDAGraph {
    // 是否是空图
    func isEmpty() -> Bool {
        return nodes.isEmpty
    }

    // 获取图中的节点
    func getNodeInGraphByNodeID(nodeID: String) -> UGDAGNode? {
        return nodes.first(where: { $0.nodeID == nodeID })
    }

    // 获取图中的Root根节点
    func getRootNodeInGraphByNodeID(nodeID: String) -> UGDAGNode? {
        let directedNode = rootNodes.first(where: { $0.nodeID == nodeID })
        return directedNode
    }

    // 用于检测图中是否有环的方法
    // 拓扑排序，删除图中所有入度为 0 的点/从入度为 0 的点开始遍历图，如果有节点不被访问到，则代表存在回路
    func isGraphHasCircle() -> Bool {
        var visitedNodes: Int = 0
        traverseGraph(roots: self.rootNodes, map: self.nodesIndegreeMap) { _ in
            visitedNodes += 1
        }
        let hasCircle = visitedNodes != self.nodes.count
        return hasCircle
    }

    // 遍历图，删除图中所有入度为 0 的点/从入度为 0 的点开始遍历图
    func traverseGraph(roots: [UGDAGNode], map: [String: Int], callback: (_ childNode: UGDAGNode) -> Void) {
        var copyedRoots = roots
        var copyedMap = map
        roots.forEach {
            if let idx = copyedRoots.firstIndex(of: $0) {
                copyedRoots.remove(at: idx)
            }
            callback($0)
            $0.childIDs.forEach({ childID in
                guard copyedMap.keys.contains(childID) else { return }
                // 子节点入度减去移除的父节点入度
                copyedMap[childID]? -= 1
                if let childIndegree = copyedMap[childID],
                   childIndegree == 0,
                   let childNode = getNodeInGraphByNodeID(nodeID: childID) {
                    copyedRoots.append(childNode)
                }
            })
        }
        // 直到入度为0的节点都不在
        if !copyedRoots.isEmpty {
            traverseGraph(roots: copyedRoots, map: copyedMap, callback: callback)
        }
    }
}
