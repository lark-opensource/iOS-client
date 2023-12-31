//
//  UGCoordinatorMock.swift
//  UGCoodinator
//
//  Created by zhenning on 2021/1/21.
//

import Foundation
import RxSwift
import UGCoordinator

// Test Case

// swiftlint:disable all
public class UGCoordinatorMock {

    public static var shared = UGCoordinatorMock()
    let manager = UGCoordinatorManager()
    let dependency = UGCoordinatorMockDependency()
    let disposeBag = DisposeBag()

    public init() {
        manager.registerCoordinatorResult()
            .subscribe(onNext: { result in
                print("manager result = \(result)")
            }).disposed(by: disposeBag)
    }

    public func testOnReachPointEvent(reachPointEvent: CoordinatorReachPointEvent) {
        manager.onReachPointEvent(reachPointEvent: reachPointEvent)
    }

    public func testConsumeBubble(reachPointIDs: [String]) {
        let event = CoordinatorReachPointEvent(action: .consume, reachPointIDs: reachPointIDs)
        testOnReachPointEvent(reachPointEvent: event)
    }
}

// MARK: - Test Case
extension UGCoordinatorMock {
    // 接口单测
    // https://bytedance.feishu.cn/wiki/wikcnmfsEgfzZA3y4xFB75dAbCe?from=from_parent_docs#CNCWdW
    public func testAPICase() {
        let entitys = dependency.getInterfaceTestCaseEntitys()
        let scenarioContext = createUGScenarioContext(scenarioID: "sce1",
                                                      priority: 1000,
                                                      entities: entitys)
        manager.onScenarioTrigger(scenarioContext: scenarioContext)
        manager.onScenarioLeave(scenarioContext: scenarioContext)
    }
}

// MARK: - Example

extension UGCoordinatorMock {

    // ref: https://bytedance.feishu.cn/wiki/wikcntEHAElsx7QThIq7pDmkmGf
    public func testExample() {
        testonScenarioTrigger() // 1, 3, 6
        testConsumeBubble(reachPointIDs: ["1"]) // 1, 2
        testConsumeBubble(reachPointIDs: ["2"]) // 1, 3, 6
        testConsumeBubble(reachPointIDs: ["6"]) // 1, 3, 7
    }

    public func testShowScenario1() {
        let entitys = dependency.getScenario1Entitys()
        let scenarioContext = createUGScenarioContext(scenarioID: "1",
                                                      priority: 1000,
                                                      entities: entitys)
        manager.onScenarioTrigger(scenarioContext: scenarioContext)
    }

    public func testShowScenario2() {
        let entitys = dependency.getScenario2Entitys()
        let scenarioContext = createUGScenarioContext(scenarioID: "2",
                                                      priority: 1000,
                                                      shareScenarioIDs: ["3"],
                                                      entities: entitys)
        manager.onScenarioTrigger(scenarioContext: scenarioContext)
    }

    public func testShowScenario3() {
        let entitys = dependency.getScenario3Entitys()
        let scenarioContext = createUGScenarioContext(scenarioID: "3",
                                                      priority: 1000,
                                                      shareScenarioIDs: ["2"],
                                                      entities: entitys)
        manager.onScenarioTrigger(scenarioContext: scenarioContext)
    }

    public func testShowScenario4() {
        let entitys = dependency.getScenario4Entitys()
        let scenarioContext = createUGScenarioContext(scenarioID: "4",
                                                      priority: 10,
                                                      entities: entitys)
        manager.onScenarioTrigger(scenarioContext: scenarioContext)
    }

    public func testonScenarioTrigger() {
        testShowScenario1()
        testShowScenario2()
        testShowScenario3()
        testShowScenario4()
    }

    public func testShowBubble1() {
        let event = CoordinatorReachPointEvent(action: .show, reachPointIDs: ["1"])
        testOnReachPointEvent(reachPointEvent: event)
    }
}

// MARK: - Tool

extension UGCoordinatorMock {
    private func createUGScenarioContext(scenarioID: String,
                                         priority: Int,
                                         shareScenarioIDs: [String]? = nil,
                                         entities: [UGReachPointEntity]) -> UGScenarioContext {
        var scenarioContext = UGScenarioContext()
        scenarioContext.scenarioID = scenarioID
        scenarioContext.priority = Int32(priority)
        scenarioContext.shareScenarioIds = shareScenarioIDs ?? []
        scenarioContext.entities = entities
        return scenarioContext
    }
}

// MARK: - DAGraph

extension UGCoordinatorMock {

    public func testDAGraph() {
        let dagNodes = [
            UGDAGNode(nodeID: "0", childIDs: []),
            UGDAGNode(nodeID: "1", childIDs: ["2"]),
            UGDAGNode(nodeID: "2", childIDs: ["3"]),
            // UGDAGNode(nodeID: "3", childIDs: ["4"]),
            // UGDAGNode(nodeID: "4", childIDs: ["5"]),
            // UGDAGNode(nodeID: "5", childIDs: ["0"])
            UGDAGNode(nodeID: "3", childIDs: [])
        ]
        let node4 = UGDAGNode(nodeID: "4", childIDs: ["3"])

        let graph = UGDAGraph()
        graph.initGraph(dagNodes: dagNodes)
        graph.removeNode(nodeID: "1")
        graph.addDAGNode(dagNode: node4)
    }
}
