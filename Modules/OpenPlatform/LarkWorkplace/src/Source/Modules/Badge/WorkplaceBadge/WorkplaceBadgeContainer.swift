//
//  WorkplaceBadgeContainer.swift
//  LarkWorkplace
//
//  Created by Meng on 2022/5/30.
//

import Foundation
import ThreadSafeDataStructure
import SwiftyJSON
import LKCommonsLogging
import LarkWorkplaceModel

/// 模版化 Badge 容器，用于存储和维护 Badge 状态。
final class WorkplaceBadgeContainer {

    static let logger = Logger.log(WorkplaceBadgeContainer.self)

    /// 全量 badge 信息
    private(set) var badges: SafeDictionary<String, WPBadge> = [:] + .readWriteLock

    init() {}

    /// 计算当前工作台应当显示到主 Tab 的 badge 数量。
    ///
    /// 需要按照 displayAbility
    var tabBadgeNumber: Int {
        return badges.values                                                           // [WPBadge]
            .filter({ $0.countAble() })                                                // [WPBadge] all countAble
            .reduce(0, { $0 + Int($1.badgeNum) })                                      // badgeNumber
    }

    /// 计算某个 appId（应用）+ appAbility（形态）下的 badge 数量。
    func badgeNumber(for appId: String, appAbility: WPBadge.AppType) -> Int {
        guard let badgeNode = badges[appId], badgeNode.countAble() else { return 0 }  // WPBadge && countAble
        return Int(badgeNode.badgeNum)
    }

    /// 重新全量 reload badge 信息。
    ///
    /// - Parameter loadData: 当前 Badge 初始化数据，nil 会清理所有 badge 缓存
    func reload(with loadData: BadgeLoadType.LoadData?) {
        Self.logger.info("start reload badges", additionalData: loadData?.wp.logInfo ?? [:])

        // 1. clear all badge cache
        badges.removeAll()

        guard let loadData = loadData else { return }

        // 2. update badges
        switch loadData {
        case .template(let templateData):
            reloadTemplate(with: templateData)
        case .web(let webData):
            reloadWeb(with: webData)
        }

        Self.logger.info("did reload badges", additionalData: [
            "type": loadData.description,
            "badges": "\(badges)"
        ])
    }

    /// 模版化 Badge 数据刷新。
    ///
    /// 现在的接口返回数据全部无脑成了 JSON，然后字段解析的地方满天飞，没有标准的数据层model。
    /// 目前使用的是 GroupComponent 来解析，后面从数据层慢慢重构吧。
    ///
    /// 目前只支持「我的常用」和「非标 Block」badge 显示与聚合，不包含常用中的标准 Block。
    ///
    /// - Parameter templateData: 模版化初始数据
    private func reloadTemplate(with templateData: BadgeLoadType.LoadData.TemplateData) {
        let newBadges = templateData
            .components
            .compactMap({ $0 as? BadgeInfoConvertable })                            // [BadgeInfoConvertable]
            .map({ $0.buildBadgeNodes() })                                          // [[appId: WPBadge]]
            .reduce(into: [String: WPBadge](), { container, badgeNodes in
                container.merge(badgeNodes, uniquingKeysWith: { (pre, _) in pre })  // 按照顺序优先使用，component 顺序靠前越优先使用
            })
        badges = newBadges + .readWriteLock
    }

    /// Web 工作台 Badge 数据刷新
    /// - Parameter webData: web 工作台初始化数据
    private func reloadWeb(with webData: BadgeLoadType.LoadData.WebData) {
        let badgeNodes = webData.badgeNodes                                     // [OpenAppBadgeNode]
            .map({ $0.toAppBadgeNode() })                                       // [WPBadge]
            .filter({ $0.clientType == .mobile && $0.appAbility == .web })
            .reduce(into: [String: WPBadge](), { $0[$1.appId] = $1 })   // [appId: WPBadge]
        badges = badgeNodes + .readWriteLock
    }

    /// 更新 badge 信息。
    ///
    /// 更新内容来源于 push，不在本次 reload 内的 badgeNodes 不会被 merge 进来。
    /// - Parameter newInfo: 新的 badge 信息
    func updateBadge(with newNodes: [WPBadge]) {
        Self.logger.info("start update badge", additionalData: [
            "newNodes": "\(newNodes.map({ $0.wp.logInfo }))"
        ])

        let keys = badges.keys
        let updateNewNodes = newNodes.filter({ keys.contains($0.appId) })

        for newNode in updateNewNodes {
            guard let oldNode = badges[newNode.appId] else { continue }
            if newNode.key() == oldNode.key() && newNode.version > oldNode.version {
                badges[newNode.appId] = newNode
            }
        }

        Self.logger.info("did update badgeInfo", additionalData: ["badges": "\(badges)"])
    }
}

/// 将既有数据结构转换为 badgeInfo 字典。
///
/// 目前用于 CommonAndRecommendComponent 和 BlockLayoutComponent 结构转换
protocol BadgeInfoConvertable {
    func buildBadgeNodes() -> [String: WPBadge]
}
