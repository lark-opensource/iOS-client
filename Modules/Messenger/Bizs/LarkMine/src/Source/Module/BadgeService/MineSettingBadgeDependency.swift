//
//  MineSettingBadgeDependency.swift
//  LarkMine
//
//  Created by liuxianyu on 2021/12/2.
//

import UIKit
import Foundation
import RxSwift
import ServerPB
import UGBadge
import UGReachSDK
import LKCommonsLogging
import ThreadSafeDataStructure
import LarkMessengerInterface
import LarkVersion

protocol MineSettingBadgeDependency {
    /// 主动触发UG消费badge, 仅叶子节点允许触发消费操作
    func consumeBadges(badgeIds: [String])
    /// 判断对应 badge 在路径树规则下应该展示的样式
    func getBadgeStyle(badgeId: String) -> MineBadgeNodeStyle
}

extension MineSettingBadgeDependency {
    func consumeBadges(badgeIds: [String]) {}

    func getBadgeStyle(badgeId: String) -> MineBadgeNodeStyle {
        return .none
    }
}

final class MineSettingBadgeDependencyImp: MineSettingBadgeDependency, BadgeReachPointDelegate {
    static let log = Logger.log(MineSettingBadgeDependency.self, category: "LarkMine")
    private let scenarioId: String
    private let reachServiceImp: UGReachSDKService
    private let updateServiceImp: VersionUpdateService
    private let disposeBag = DisposeBag()

    /// cloud setting 平台拿到的路径树规则 [叶子节点:父节点集合]
    private var cloudSettingBadgesMap = [String: [String]]()
    /// cloud setting 里需要维护的 UGReachPoints，用于触发代理回调
    private var ugReachPoints = [BadgeReachPoint]()
    /// UGSDK 在该场景下激活的所有 Reach Points
    private var activeReachPoints: SafeDictionary<String, BadgeReachPoint> = [:] + .readWriteLock
    /// 维护路径树中所有的节点数据
    private var allBadgeNodes: SafeDictionary<String, MineBadgeNode> = [:] + .readWriteLock

    init(scenarioId: String = MineUGBadgeScene.setting.rawValue,
         reachServiceImp: UGReachSDKService,
         updateServiceImp: VersionUpdateService) {
        self.scenarioId = scenarioId
        self.reachServiceImp = reachServiceImp
        self.updateServiceImp = updateServiceImp

        fetchCloudSettingBadgesMap()
    }

    deinit {
        for rp in ugReachPoints {
            reachServiceImp.recycleReachPoint(reachPointId: rp.reachPointId, reachPointType: BadgeReachPoint.reachPointType)
        }
    }

    // MARK: - Pubilc
    /// 仅叶子节点允许触发消费操作
    func consumeBadges(badgeIds: [String]) {
        badgeIds.forEach { badgeId in
            guard let badgeNode = obtainBadgeNode(badgeId: badgeId), badgeNode.isLeaf else {
                return
            }
            Self.log.info("[MineBadge] onConsumeRP - id: \(badgeId)")
            // RP数据清理，UG触发消费
            if let badgeReachPoint = activeReachPoints[badgeId],
               !customBadgeIds().contains(badgeId) {
                badgeReachPoint.reportClosed()
                reachServiceImp.recycleReachPoint(reachPointId: badgeId, reachPointType: BadgeReachPoint.reachPointType)
            }
            updateActiveReachPoints(badgeId, nil)
        }

        NotificationCenter.default.post(name: MineNotification.DidShowSettingUpdateGuide, object: nil, userInfo: nil)
    }

    func getBadgeStyle(badgeId: String) -> MineBadgeNodeStyle {
        guard let badgeNode = allBadgeNodes[badgeId] as? MineBadgeNode else { return .none }
        if badgeNode.isLeaf {
            guard let reachPoint = activeReachPoints[badgeId] else { return .none }
            return getLeafBadgeStyle(reachPoint: reachPoint)
        } else {
            return getParentBadgeStyle(leafIds: badgeNode.leafIds)
        }
    }

    // MARK: - Custom
    private func fetchCloudSettingBadgesMap() {
        //TODO: 改为 cloudSetting 脚本下发 by xianyu
        var cloudSettingBadgesMap = [String: [String]]()
        cloudSettingBadgesMap[MineUGBadgeID.privacy.rawValue] = [MineUGBadgeID.about.rawValue, MineUGBadgeID.setting.rawValue]
        cloudSettingBadgesMap[MineUGBadgeID.agreement.rawValue] = [MineUGBadgeID.about.rawValue, MineUGBadgeID.setting.rawValue]
        cloudSettingBadgesMap[MineUGBadgeID.upgrade.rawValue] = [MineUGBadgeID.about.rawValue, MineUGBadgeID.setting.rawValue]
        self.cloudSettingBadgesMap = cloudSettingBadgesMap

        setupUGReachPointsByMap(cloudSettingBadgesMap)
        setupCustomReachPoint()
    }

    private func customBadgeIds() -> [String] {
        return [MineUGBadgeID.upgrade.rawValue]
    }

    // MARK: - BadgeReachPoint
    private func setupUGReachPointsByMap(_ map: [String: [String]]) {
        let ugReachPointIds = cloudSettingBadgesMap.keys.filter({ !customBadgeIds().contains($0) })
        ugReachPoints = setupUGReachPoints(ugReachPointIds)

        // 获取该场景下UG的RP物料
        reachServiceImp.tryExpose(by: scenarioId, specifiedReachPointIds: ugReachPointIds)
    }

    private func setupUGReachPoints(_ reachPointIds: [String]) -> [BadgeReachPoint] {
        var reachPoints = [BadgeReachPoint]()
        for reachPointId in reachPointIds {
            let reachPoint = createReachPoint(reachPointId)
            if let rp = reachPoint {
                reachPoints.append(rp)
            }
        }
        return reachPoints
    }

    private func setupCustomReachPoint() {
        // 处理自定义的升级RP
        if let upgradeRP = createReachPoint(MineUGBadgeID.upgrade.rawValue) {
            updateActiveReachPoints(MineUGBadgeID.upgrade.rawValue, upgradeRP)
        }

        updateServiceImp.isShouldUpdate.subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            let upgradeRP = self.createReachPoint(MineUGBadgeID.upgrade.rawValue)
            self.updateActiveReachPoints(MineUGBadgeID.upgrade.rawValue, upgradeRP)
        }).disposed(by: self.disposeBag)
    }

    private func updateActiveReachPoints(_ reachPointId: String, _ reachPoint: BadgeReachPoint?) {
        activeReachPoints[reachPointId] = reachPoint
        buildActiveBadgesMap()
    }

    private func createReachPoint(_ reachPointId: String) -> BadgeReachPoint? {
        if reachPointId == MineUGBadgeID.upgrade.rawValue {
            guard updateServiceImp.shouldUpdate else {
                return nil
            }
            let customRP = BadgeReachPoint()
            customRP.reachPointId = reachPointId
            return customRP
        }

        guard !customBadgeIds().contains(reachPointId) else {
            return nil
        }
        let bizContextProvider = UGSyncBizContextProvider(scenarioId: scenarioId) { [:] }
        guard let reachPoint = obtainBadgeDataFromUGSDK(reachPointId) else {
            return nil
        }
        reachPoint.delegate = self
        return reachPoint
    }

    private func obtainBadgeDataFromUGSDK(_ reachPointId: String) -> BadgeReachPoint? {
        let bizContextProvider = UGSyncBizContextProvider(scenarioId: scenarioId) { [:] }
        return reachServiceImp.obtainReachPoint(reachPointId: reachPointId, bizContextProvider: bizContextProvider)
    }

    // MARK: - BadgeNode
    private func obtainBadgeNode(badgeId: String) -> MineBadgeNode? {
        guard let badgeNode = allBadgeNodes[badgeId] as? MineBadgeNode else { return nil }
        return badgeNode
    }

    /// 构建路径树相关数据结构
    private func buildActiveBadgesMap() {
        let activeRPs = activeReachPoints.values
        var nodes: SafeDictionary<String, MineBadgeNode> = [:] + .readWriteLock

        activeRPs.forEach {
            let leafId = $0.reachPointId
            if let parentBadgeIds = cloudSettingBadgesMap[leafId],
               !parentBadgeIds.isEmpty {
                //构建路径树
                updateBadgeNodes(leafId: leafId, parentIds: parentBadgeIds, nodes: nodes, reachPoint: $0)
            }
        }
        self.allBadgeNodes = nodes
    }

    private func getLeafBadgeStyle(reachPoint: BadgeReachPoint) -> MineBadgeNodeStyle {
        if reachPoint.reachPointId == MineUGBadgeID.upgrade.rawValue {
            return .upgrade
        }

        if let badgeData = reachPoint.badgeData {
            switch badgeData.type {
            case .redPoint: return .dot()
            case .text:     return .label(badgeData.viewText.content)
            case .number:   return .dot()
            @unknown default:   return .dot()
            }
        }
        return .none
    }

    private func getParentBadgeStyle(leafIds: [String]) -> MineBadgeNodeStyle {
        if leafIds.contains(MineUGBadgeID.upgrade.rawValue) {
            return .upgrade
        }
        return .dot()
    }

    /// 从叶子节点出发
    private func updateBadgeNodes(leafId: String, parentIds: [String], nodes: SafeDictionary<String, MineBadgeNode>, reachPoint: BadgeReachPoint) {
        updateLeafNode(leafId, parentIds, nodes, reachPoint)
        for parentId in parentIds {
            updateParentNode(leafId, parentId, nodes, reachPoint)
        }
    }

    private func updateParentNode(_ leafId: String, _ parentId: String, _ nodes: SafeDictionary<String, MineBadgeNode>, _ reachPoint: BadgeReachPoint) {
        if var parentNode = nodes[parentId] as? MineBadgeNode {
            var leafIds = parentNode.leafIds
            leafIds.append(leafId)
            parentNode.leafIds = leafIds.filterDuplicates({ $0 })
            nodes[parentId] = parentNode
        } else {
            let newParentNode = MineBadgeNode(isLeaf: false, leafIds: [leafId], badgeId: parentId)
            nodes[parentId] = newParentNode
        }
    }

    private func updateLeafNode(_ leafId: String, _ parentIds: [String], _ nodes: SafeDictionary<String, MineBadgeNode>, _ reachPoint: BadgeReachPoint) {
        if var leafNode = nodes[leafId] as? MineBadgeNode {
            var ids = leafNode.parentIds
            ids += parentIds
            leafNode.parentIds = ids.filterDuplicates({ $0 })
            nodes[leafId] = leafNode
        } else {
            let newLeafNode = MineBadgeNode(isLeaf: true, parentIds: parentIds, badgeId: leafId)
            nodes[leafId] = newLeafNode
        }
    }

    // MARK: - BadgeReachPointDelegate
    func onShow(badgeView: UIView, badgeReachPoint: BadgeReachPoint) {
        Self.log.info("[MineBadge] onShowRP - id: \(badgeReachPoint.reachPointId), type: \(badgeReachPoint.badgeData?.type)")
        updateActiveReachPoints(badgeReachPoint.reachPointId, badgeReachPoint)
    }

    /// 处理多端消费
    func onHide(badgeView: UIView, badgeReachPoint: BadgeReachPoint) {
        Self.log.info("[MineBadge] onHideRP - id: \(badgeReachPoint.reachPointId), type: \(badgeReachPoint.badgeData?.type)")
        updateActiveReachPoints(badgeReachPoint.reachPointId, nil)
    }
}

extension Array {
    func filterDuplicates<E: Equatable>(_ filter: (Element) -> E) -> [Element] {
        var result = [Element]()
        for value in self {
            let key = filter(value)
            if !result.map({ filter($0) }).contains(key) {
                result.append(value)
            }
        }
        return result
    }
}
