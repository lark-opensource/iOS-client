//
//  UGCoordinatorMockDependency.swift
//  UGCoodinator
//
//  Created by zhenning on 2021/1/21.
//

import Foundation
import RustPB
import UGCoordinator

// mock 测试

// swiftlint:disable all
class UGCoordinatorMockDependency: UGCoordinatorDependency {

    func getExampleReachPointEntitys() -> [UGReachPointEntity] {
//        let entitys = getBubblesEntitys()
        let entitys = getComplexEntitys()
        return entitys
    }

    func getTestCaseReachPointEntitys() -> [UGReachPointEntity] {
        let entitys = getInterfaceTestCaseEntitys()
        return entitys
    }
}

// MARK: - Basic
extension UGCoordinatorMockDependency {
    func createEntity(reachPointID: String,
                      scenarioID: String,
                      childIDs: [String]? = nil,
                      priority: Int,
                      ttl: Int? = 0,
                      isConflict: Bool,
                      defenseStrategy: UGDefenseStrategy? = nil,
                      needGrab: Bool? = false) -> UGReachPointEntity {
        var relation = UGReachPointRelation()
        if let childIDs = childIDs {
            relation.childIds = childIDs
        }
        relation.isConflict = isConflict
        relation.ttl = Int32(ttl ?? 0)
        relation.priority = Int32(priority)
        relation.needGrab = needGrab ?? false
        relation.defenseStrategy = defenseStrategy ?? .unknown

        var config = Ugreach_V1_ReachPointConfig()
        config.relation = relation

        var entity = UGReachPointEntity()
        entity.reachPointID = reachPointID
        entity.scenarioID = scenarioID
        entity.config = config
        return entity
    }
}

// MARK: - 接口单侧
extension UGCoordinatorMockDependency {
    // 初始化
    func getInterfaceTestCaseEntitys() -> [UGReachPointEntity] {
        let entity1 = createEntity(reachPointID: "guide1", scenarioID: "sce1", childIDs: ["guide2"], priority: 0, isConflict: false)
        let entity2 = createEntity(reachPointID: "guide2", scenarioID: "sce1", childIDs: ["guide3"], priority: 0, isConflict: false)
        let entity3 = createEntity(reachPointID: "guide3", scenarioID: "sce1", priority: 0, isConflict: false)
        return [entity1, entity2, entity3]
    }
}

// MARK: - 逻辑集测

extension UGCoordinatorMockDependency {
    func getScenario1Entitys() -> [UGReachPointEntity] {
        let banner = createEntity(reachPointID: "1",
                                  scenarioID: "1",
                                  childIDs: ["2"],
                                  priority: 100,
                                  ttl: -1,
                                  isConflict: false)
        let modal = createEntity(reachPointID: "2",
                                 scenarioID: "1",
                                 priority: 100000,
                                 isConflict: true)
        let scene1 = [banner, modal]
        return scene1
    }

    func getScenario2Entitys() -> [UGReachPointEntity] {
        let bubbleEntity21 = createEntity(reachPointID: "3",
                                          scenarioID: "2",
                                          childIDs: ["4"],
                                          priority: 100,
                                          isConflict: true)
        let bubbleEntity22 = createEntity(reachPointID: "4",
                                          scenarioID: "2",
                                          childIDs: ["5"],
                                          priority: 100,
                                          isConflict: true)
        let bubbleEntity23 = createEntity(reachPointID: "5",
                                          scenarioID: "2",
                                          priority: 100,
                                          isConflict: true)
        let scene2 = [bubbleEntity21, bubbleEntity22, bubbleEntity23]
        return scene2
    }

    func getScenario3Entitys() -> [UGReachPointEntity] {
        let bubbleEntity31 = createEntity(reachPointID: "6",
                                          scenarioID: "3",
                                          childIDs: ["7"],
                                          priority: 10,
                                          isConflict: true)
        let bubbleEntity32 = createEntity(reachPointID: "7",
                                          scenarioID: "3",
                                          priority: 1000,
                                          isConflict: true)
        let scene3 = [bubbleEntity31, bubbleEntity32]
        return scene3
    }

    func getScenario4Entitys() -> [UGReachPointEntity] {
        let bubbleEntity41 = createEntity(reachPointID: "8",
                                          scenarioID: "4",
                                          priority: 10,
                                          isConflict: true)
        let scene4 = [bubbleEntity41]
        return scene4
    }

    func getComplexEntitys() -> [UGReachPointEntity] {
        let scene1 = getScenario1Entitys()
        let scene2 = getScenario2Entitys()
        let scene3 = getScenario3Entitys()
        let scene4 = getScenario4Entitys()
        return scene1 + scene2 + scene3 + scene4
    }
    // case1: 检测气泡依赖关系, 1 -> 2 -> 3
    func getBubblesEntitys() -> [UGReachPointEntity] {
        let bubbleEntity1 = createEntity(reachPointID: "1",
                                         scenarioID: "1",
                                         childIDs: ["2"],
                                         priority: 1,
                                         isConflict: false)
        let bubbleEntity2 = createEntity(reachPointID: "2",
                                         scenarioID: "1",
                                         childIDs: ["3"],
                                         priority: 2,
                                         isConflict: false)
        let bubbleEntity3 = createEntity(reachPointID: "3",
                                         scenarioID: "1",
                                         priority: 3,
                                         isConflict: false,
                                         needGrab: false)
        return [bubbleEntity1, bubbleEntity2, bubbleEntity3]
    }

}
