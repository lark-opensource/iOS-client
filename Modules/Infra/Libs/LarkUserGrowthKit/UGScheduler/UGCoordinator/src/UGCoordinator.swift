//
//  UGCoordinator.swift
//  UGCoodinator
//
//  Created by zhenning on 2021/1/21.
//

import Foundation
import RxRelay
import RxCocoa
import LKCommonsLogging
import ThreadSafeDataStructure
import RustPB
import Homeric
import LarkSetting
import LarkContainer

/// 依赖UGGraph的调度核心逻辑实现
final class UGCoordinator {
    private static let log = Logger.log(UGCoordinator.self, category: "UGScheduler")
    private var resultRelay = BehaviorRelay<CoordinatorResult>(value:
                                                                CoordinatorResult(rpState: .hide, rpEntitys: []))
    var resultDriver: Driver<CoordinatorResult> {
        return resultRelay.skip(1).asDriver(onErrorJustReturn: CoordinatorResult(rpState: .hide, rpEntitys: []))
    }
    private var tracer: Tracer {
        return self.graph.tracer
    }

    // 有向图
    private lazy var graph: UGDAGraph = {
        let graph = UGDAGraph()
        return graph
    }()

    // 业务节点列表
    private var bizNodes: SafeArray<UGBizNode> = [] + .readWriteLock
    // 数据
    private var entityInfos: [UGReachPointEntityInfo] {
        return bizNodes.getImmutableCopy().map { $0.entityInfo }
    }
    // 每次调度的结果
    private var resultMap: SafeDictionary<String, ReachPointState> = [:] + .readWriteLock
    // 正在屏幕上展示的节点列表
    /// 1. 定义一个正在显示的showing节点数组，每次图计算完成需要和showingNodes进行对比，解决冲突
    /// 2. 当dismiss事件触发时，需要从showingNodes里移除，如果非避让，则对应节点的ttl做处理
    /// 3. 当display事件触发时，需要添加到showingNodes，如果是消费，则从图中移除
    private var showingNodes: SafeArray<UGBizNode> = [] + .readWriteLock
    // 在并发case下保证原子性，加锁
    private let lock: NSRecursiveLock = NSRecursiveLock()

    let userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    // 获取结果，并清空
    func getDisplayResult() {
        lock.lock()
        defer { lock.unlock() }
        let dagRootNodeIDs = self.graph.rootNodeIds
        // check if conflict
        let needShowNodes = self.entityInfos
            .filter { dagRootNodeIDs.contains($0.entity.reachPointID) }
            .map { UGBizNode(entityInfo: $0) }
        let conflictNodes = needShowNodes.filter { $0.isConflict }
        // 解决完冲突的node
        var conflictSolvedNodes: [UGBizNode] = []

        // 排序优先级，高到低, sort by prioty sorted rootnodes, with isConfict
        let sortedConflictNodes = conflictNodes
            .sorted(by: { $0.priority > $1.priority })
        if sortedConflictNodes.count > 1 {
            // resolve preShow nodes conflict
            sortedConflictNodes.enumerated().forEach { idx, node in
                for index in (idx + 1) ..< sortedConflictNodes.count {
                    let nextNode = sortedConflictNodes[index]
                    // 冲突域
                    guard isNodeConflict(node1: node, node2: nextNode) else {
                        return
                    }
                    // 对即将出图冲突的节点，建立依赖关系
                    self.addDependency(parentNode: node, childNode: nextNode, graph: graph)
                }
            }
            // 获取更新后preshow nodes
            let preshowSolvedRootNodes = self.graph.rootNodeIds
            conflictSolvedNodes = entityInfos
                .filter { preshowSolvedRootNodes.contains($0.entity.reachPointID) }
                .map { UGBizNode(entityInfo: $0) }
            Self.log.debug("[UGCoordinator]: getDisplayResult sortedConflictNodes",
                           additionalData: ["preshowSolvedRootNodes": "\(preshowSolvedRootNodes)"])
        } else {
            conflictSolvedNodes = conflictNodes
        }
        // 即将显示的节点
        var preshowNodes: [UGBizNode] = needShowNodes.filter { !$0.isConflict }
        preshowNodes.lf_appendContentsIfNotContains(conflictSolvedNodes)
        // 和正在显示的节点解决冲突 showing node
        let _showingNodes = self.showingNodes.getImmutableCopy()
        if _showingNodes.isEmpty {
            preshowNodes.forEach { showingNode in
                resultMap[showingNode.nodeID] = .show
            }
        } else {
            // 和在展示的节点冲突的出图节点
            let conflictPreshowNodes = preshowNodes.filter { preshowNode in
                var hasConfilct = false
                showingNodes.forEach { showingNode in
                    if isNodeConflict(node1: preshowNode, node2: showingNode) {
                        hasConfilct = true
                        return
                    }
                }
                return hasConfilct
            }

            // 不冲突的出图节点
            let noConflictPreshowNodes = preshowNodes.filter { !conflictSolvedNodes.contains($0) }
            noConflictPreshowNodes.forEach {
                resultMap[$0.nodeID] = .show
            }
            conflictPreshowNodes.forEach { conflictPreshowNode in
                for index in 0 ..< _showingNodes.count {
                    let showingNode = _showingNodes[index]
                    // 解决对即将出图的节点和正在显示的节点
                    guard isNodeConflict(node1: conflictPreshowNode, node2: showingNode) else { return }
                    // 解决和正在展示的节点冲突
                    resolvePreAndShowingNodesConflict(preShow: conflictPreshowNode, showingNode: showingNode, directedGraph: graph)
                }
            }
            Self.log.debug("[UGCoordinator]: getDisplayResult conflict",
                           additionalData: [
                            "noConflictPreshowNodes": "\(noConflictPreshowNodes.map { $0.reachPointID })",
                            "conflictPreshowNodes": "\(conflictPreshowNodes.map { $0.reachPointID })"
                           ])
        }
        // 获取更新后preshow nodes
        sendCoordinatorResult()
        Self.log.debug("[UGCoordinator]: getDisplayResult",
                       additionalData: [
                        "resultMap": "\(resultMap)"
                       ])
    }
}

// MARK: - Node
extension UGCoordinator {

    // 从DAG图中移除节点，更新其子节点信息、依赖关系、调度结果
    private func removeNodeAndUpdateInfo(nodeID: String, graph: UGDAGraph) {
        lock.lock()
        defer { lock.unlock() }

        // 删除节点前先通知ReachPoint隐藏
        if userResolver.fg.staticFeatureGatingValue(with: "ug.banner.support_auto_offline") {
            self.resultMap[nodeID] = .hide
            self.sendCoordinatorResult()
        }

        guard let node = getResultNodeById(nodeID: nodeID) else { return }

        graph.traverseChildNode(parentNode: UGDAGNode(ugNode: node)) { (childID) in
            graph.removeRelationGraphArc(parentID: nodeID, childID: childID)
        }
        graph.removeNode(nodeID: nodeID)
        // remove parent relation
        if let parentID = node.parentID {
            graph.removeRelationGraphArc(parentID: parentID, childID: nodeID)
        }
        // 移除显示中的node
        var oldShowingNodes = self.showingNodes.getImmutableCopy()
        oldShowingNodes.lf_remove(object: node)
        self.showingNodes.replaceInnerData(by: oldShowingNodes)
        Self.log.debug("[UGCoordinator]: removeNodeAndUpdateInfo nodeID: \(nodeID)")
    }
}

// MARK: - Graph
extension UGCoordinator {

    /// 初始化子图
    private func initSubGraph(entityInfos: [UGReachPointEntityInfo]) -> UGDAGraph? {
        guard !entityInfos.isEmpty else {
            Self.log.error("[UGCoordinator]: initSubGraph, entitys is empty!")
            return nil
        }
        let nodes = entityInfos.map { UGDAGNode(ugNode: UGBizNode(entityInfo: $0)) }
        let subGraph = UGDAGraph()
        subGraph.initGraph(dagNodes: nodes)
        return subGraph
    }

    // 添加子节点
    private func addEntityInfos(entityInfos: [UGReachPointEntityInfo]) {
        lock.lock()
        defer { lock.unlock() }
        // 去掉bizNodes中重复的节点
        let validBizNodes = entityInfos
            .map { UGBizNode(entityInfo: $0) }
            .filter { !self.bizNodes.contains($0) }
        let dagNodes = validBizNodes.map { UGDAGNode(ugNode: $0) }
        if self.graph.isEmpty() {
            self.graph.initGraph(dagNodes: dagNodes)
        } else {
            self.graph.addNodes(dagNodes: dagNodes)
        }
        // 添加数据
        self.bizNodes.append(contentsOf: validBizNodes)
        Self.log.debug("[UGCoordinator]: addEntityInfos, newShowEntitys = \(entityInfos)")
    }

    // 移除子节点
    private func removeEntityInfos(entitys: [UGReachPointEntity]) {
        lock.lock()
        defer { lock.unlock() }

        guard !self.graph.isEmpty() else { return }

        let needRemoveNodeIDs = entitys.map { $0.reachPointID }
        // 更新图
        self.graph.removeNodes(entitys: entitys)
        // 更新数据
        // 剩下的数据
        let leftNodes = self.bizNodes.getImmutableCopy().filter { !needRemoveNodeIDs.contains($0.reachPointID) }
        self.bizNodes.replaceInnerData(by: leftNodes)
        Self.log.debug("[UGCoordinator]: removeEntityInfos, needRemoveNodeIDs = \(needRemoveNodeIDs), leftNodes = \(leftNodes)")
    }

}

// MARK: - Relation

extension UGCoordinator {

    // 对两个node之间添加关系
    private func addDependency(parentNode: UGBizNode, childNode: UGBizNode, graph: UGDAGraph) {
        graph.addRelationGraphArc(parentID: parentNode.nodeID, childID: childNode.nodeID)
    }

    // 删除依赖关系
    private func removeDependency(parentID: String, childID: String, graph: UGDAGraph) {
        graph.removeRelationGraphArc(parentID: parentID, childID: childID)
    }

    // 删除指定节点的子节点关系
    private func removeDependencyOfNode(parentNode: UGBizNode) {
        parentNode.childIDs.forEach({
            removeDependency(parentID: parentNode.nodeID, childID: $0, graph: graph)
        })
    }
}

// MARK: - Event

extension UGCoordinator {

    // 触发某个场景
    func onScenarioTrigger(scenarioContext: UGScenarioContext) {
        // entities非空
        guard !scenarioContext.entities.isEmpty else {
            return
        }

        self.addEntityInfos(entityInfos: scenarioContext.entities.map {
            UGReachPointEntityInfo(entity: $0,
                                   sceShareIDs: scenarioContext.shareScenarioIds,
                                   scePriority: Int(scenarioContext.priority))
        })
    }

    // 移除某个场景
    func onScenarioLeave(scenarioContext: UGScenarioContext) {
        self.removeEntityInfos(entitys: scenarioContext.entities)
    }

    // 某个引导触达点位变化事件（展示、隐藏、消费）
    func onReachPointEvent(reachPointEvent: CoordinatorReachPointEvent) {
        lock.lock()
        defer { lock.unlock() }

        let reachPointIDs = reachPointEvent.reachPointIDs
        reachPointIDs.forEach { reachPointID in
            switch reachPointEvent.action {
            // 节点已展示在屏幕
            case .show:
                self.onReachPointShow(reachPointID: reachPointID)
            // 暂时隐藏、还在图内
            case .hide:
                self.onReachPointHide(reachPointID: reachPointID)
            // 节点已消费，更新ttl
            case .consume:
                self.onConsumeNode(nodeID: reachPointID)
            // 移除，从图中去掉
            case .remove:
                self.removeNodeAndUpdateInfo(nodeID: reachPointID, graph: graph)
            }
            Self.log.debug("[UGCoordinator]: onReachPointEvent action = \(reachPointEvent.action)")
        }
    }

    /// 节点展示
    func onReachPointShow(reachPointID: String) {
        lock.lock()
        defer { lock.unlock() }

        guard let node = self.getResultNodeById(nodeID: reachPointID) else { return }
        // 边界条件，不应出现上次的发送的结果里，如果是，则将rp对应的关系移除
        guard !showingNodes.map({ $0.reachPointID }).contains(node.nodeID) else {
            Self.log.error("[UGCoordinator]: onReachPointShow has already showing reachPointID = \(reachPointID)")
            return
        }

        var oldShowingNodes = self.showingNodes.getImmutableCopy()
        oldShowingNodes.lf_appendIfNotContains(node)
        self.showingNodes.replaceInnerData(by: oldShowingNodes)
    }

    /// 节点消失
    func onReachPointHide(reachPointID: String) {
        lock.lock()
        defer { lock.unlock() }

        guard let node = self.getResultNodeById(nodeID: reachPointID) else { return }
        var oldShowingNodes = self.showingNodes.getImmutableCopy()
        oldShowingNodes.lf_remove(object: node)
        self.showingNodes.replaceInnerData(by: oldShowingNodes)
        resultMap.removeValue(forKey: reachPointID)
    }

    // 消费 UG 图中的节点
    // 有几种类型：
    // 1 不需要重建，消费节点
    // 2 需要重建
    // 3 消费，根据 ttl 看是否需要在下次消费时标记为重建
    private func onConsumeNode(nodeID: String) {
        guard let node = getResultNodeById(nodeID: nodeID),
              graph.getNodeInGraphByNodeID(nodeID: node.nodeID) != nil else {
            return
        }

        // 节点是否重建
        let needRebuild = node.needRebuild ?? false

        if needRebuild {
            traversDependencyTree(nodeID: node.nodeID) { childID in
                if graph.getRootNodeInGraphByNodeID(nodeID: childID) != nil {
                    removeNodeAndUpdateInfo(nodeID: childID, graph: graph)
                }
            }
            // 重建节点
            rebuildNode(nodeID: nodeID, graph: graph)
            node.needRebuild = false
        }

        // 消费逻辑
        // 处理ttl
        if node.ttl == 0 { // 只展示一次
            removeNodeAndUpdateInfo(nodeID: node.nodeID, graph: graph)
        } else if node.ttl > 0 { // 展示多次
            removeNodeAndUpdateInfo(nodeID: node.nodeID, graph: graph)
            graph.addBizNode(ugNode: node)
            node.ttl -= 1
            node.needRebuild = true
        } else if node.ttl < 0 { // 无限次展示的
            removeDependencyOfNode(parentNode: node)
            node.needRebuild = true
        }
        Self.log.debug("[UGCoordinator]: onConsumeNode nodeID = \(nodeID)")
    }
}

// MARK: - Util

extension UGCoordinator {

    /// 发送结果信号
    private func sendCoordinatorResult() {
        // 处理不同状态节点结果
        func handleNodesWithRPState(nodeIDs: [String], rpState: ReachPointState) {
            guard !nodeIDs.isEmpty else { return }

            let rpEntitys = self.entityInfos
                .filter { nodeIDs.contains($0.entity.reachPointID) }
                .map { $0.entity }
            sendCoordinatorResultByState(rpState: rpState, rpEntitys: rpEntitys)
        }
        // show
        let showNodeIDs = resultMap.keys.filter { resultMap[$0] == .show }.getImmutableCopy()
        handleNodesWithRPState(nodeIDs: showNodeIDs, rpState: .show)
        // hide
        let hideNodeIDs = resultMap.keys.filter { resultMap[$0] == .hide }.getImmutableCopy()
        handleNodesWithRPState(nodeIDs: hideNodeIDs, rpState: .hide)
        resetResult()
    }

    // reset resultMap
    func resetResult() {
        resultMap.removeAll()
    }

    /// 发送结果信号
    private func sendCoordinatorResultByState(rpState: ReachPointState, rpEntitys: [UGReachPointEntity]) {
        guard !rpEntitys.isEmpty else {
            Self.log.error("[UGCoordinator]: sendCoordinatorResult rpEntitys is empty!")
            return
        }

        let result = CoordinatorResult(rpState: rpState, rpEntitys: rpEntitys)
        Self.log.debug("[UGCoordinator]: sendCoordinatorResult CoordinatorResult: \(result)")
        self.resultRelay.accept(result)
    }

    private func getResultNodeById(nodeID: String) -> UGBizNode? {
        guard let bizNode = self.bizNodes.first(where: { $0.reachPointID == nodeID }) else {
            Self.log.error("[UGCoordinator]: getResultNodeById bizNode nodeID: \(nodeID) is empty!")
            return nil
        }
        guard self.graph.nodes.first(where: { $0.nodeID == nodeID }) != nil else {
            Self.log.error("[UGCoordinator]: getResultNodeById dagNode nodeID: \(nodeID) is empty!")
            return nil
        }
        return bizNode
    }

    // 判断两个节点是否冲突
    // isStrict: 共享域都不互相包含才不为冲突，只有一个包含也视为冲突, 默认是不严格的
    private func isNodeConflict(node1: UGBizNode, node2: UGBizNode, isStrict: Bool? = false) -> Bool {
        // 定义处理逻辑
        func _confictFunc(node1: UGBizNode, node2: UGBizNode, isStrict: Bool? = false) -> Bool {
            // 判断node是否在nodeInCache的共享域
            if let sceShareIDs2 = node2.sceShareIDs,
               sceShareIDs2.contains(node1.scenarioID) {
                if let isStrict = isStrict, isStrict {
                    // 判断nodeInCache是否在node的共享域
                    if let sceShareIDs1 = node1.sceShareIDs,
                       sceShareIDs1.contains(node2.scenarioID) {
                        return false
                    }
                    return true
                } else {
                    return false
                }
            }
            return true
        }
        // 处理逻辑
        if node1.isConflict {
            return _confictFunc(node1: node1, node2: node2, isStrict: isStrict)
        } else if node2.isConflict {
            return _confictFunc(node1: node2, node2: node1, isStrict: isStrict)
        } else {
            return false
        }
    }

    // 解决和冲突两个节点在图中的冲突（即将展示和在展示的节点）
    private func resolvePreAndShowingNodesConflict(preShow: UGBizNode,
                                 showingNode: UGBizNode,
                                 directedGraph: UGDAGraph) {
        // 判断是否在sid下共享域
        let preShowNodeID = preShow.nodeID
        let showingNodeID = showingNode.nodeID

        guard isNodeConflict(node1: preShow, node2: showingNode) else {
            Self.log.error("[UGCoordinator]: resolveConflict not Conflict! nodeID = \(preShowNodeID) nodeInCache = \(showingNodeID)")
            return
        }
        let newP = preShow.priority
        let oldP = showingNode.priority
        if newP <= oldP {
            addDependency(parentNode: showingNode, childNode: preShow, graph: directedGraph)
        } else {
            // newP > oldP
            if preShow.needGrab {
                let defenseStrategy = showingNode.defenseStrategy
                switch defenseStrategy {
                case .giveUp:
                    removeNodeAndUpdateInfo(nodeID: showingNodeID, graph: graph)
                    onConsumeNode(nodeID: showingNodeID)
                    resultMap[showingNodeID] = .hide
                case .roundabout, .unknown:
                    /// 迂回(回到 pop 队列中)
                    resultMap[showingNodeID] = .hide
                    resultMap[preShow.nodeID] = .show
                    addDependency(parentNode: preShow, childNode: showingNode, graph: graph)
                @unknown default:
                    break
                }
            } else {
                addDependency(parentNode: showingNode, childNode: preShow, graph: directedGraph)
            }
        }
        Self.log.debug("[UGCoordinator]: resolveConflict preShowNodeID = \(preShowNodeID) showingNodeID = \(showingNodeID)")
    }

    private func rebuildNode(nodeID: String, graph: UGDAGraph) {
        guard let node = getResultNodeById(nodeID: nodeID),
              graph.getNodeInGraphByNodeID(nodeID: nodeID) != nil else {
            Self.log.error("rebuildNode node is not valid nodeID = \(nodeID)")
            return
        }

        // 重建 DAG 节点信息
        node.resetChildIDs()
        // 重建与子节点的关系
        graph.traverseChildNode(parentNode: UGDAGNode(ugNode: node)) { childID in
            guard let childNode = getResultNodeById(nodeID: childID) else { return }

            // 如果图中已经存在该子节点
            if graph.getNodeInGraphByNodeID(nodeID: childID) != nil {
                graph.addRelationGraphArc(parentID: nodeID, childID: childID)
            } else {
                childNode.reset()
                graph.addBizNode(ugNode: childNode)
                graph.addRelationGraphArc(parentID: nodeID, childID: childID)
                childNode.needRebuild = true
            }
        }
        Self.log.debug("[UGCoordinator]: rebuildNode nodeID = \(nodeID)")
    }

    private func traversDependencyTree(nodeID: String, callBack: ((String) -> Void)) {
        guard let node = self.getResultNodeById(nodeID: nodeID) else { return }

        node.childIDs.forEach({
            if let childNode = getResultNodeById(nodeID: $0) {
                traversDependencyTree(nodeID: childNode.nodeID) { (childID) in
                    callBack(childID)
                }
            }
        })
        Self.log.debug("[UGCoordinator]: traversDependencyTree nodeID = \(nodeID)")
    }
}
