//
//  Favorite+BadgeInfo.swift
//  LarkWorkplace
//
//  Created by Meng on 2022/11/09.
//

import LarkWorkplaceModel

/// 常用组件 badge 解析逻辑。
extension CommonAndRecommendComponent: BadgeInfoConvertable {
    /// 把 CommonAndRecommendComponent 转换为相应的全量 badge 信息。
    ///
    /// 常用中的 Block 目前是被过滤掉的，仅使用 icon & application 类型的数据。
    /// Block 标准形态支持 badge 跟随业务后续统一支持。
    func buildBadgeNodes() -> [String: WPBadge] {
        var allNodes: [NodeComponent] = []
        subModuleList.forEach { (subModule) in
            if let nodes = nodeComponentsMap[subModule] {
                allNodes.append(contentsOf: nodes)
            }
        }
        return allNodes                                                   // [NodeComponent]
            .compactMap({ $0 as? CommonIconComponent })                         // [CommonIconComponent]
            .filter({ $0.appScene != nil && $0.appScene != .systemAdd })
            .compactMap(convertCommonComponentToBadgeNodes)                     // [[appId: WPBadge]]
            .reduce(into: [String: WPBadge](), { container, nodes in       // [appId: WPBadge]
                container.merge(nodes, uniquingKeysWith: { (pre, _) in pre })
            })
    }

    /// 解析具体的 icon 类型内的 badge 信息
    private func convertCommonComponentToBadgeNodes(
        _ component: CommonIconComponent
    ) -> [String: WPBadge] {
        guard let item = component.itemModel?.item,
              let defaultBadgeAbility = item.badgeAbility(),
              // badge目前只支持应用形态，若需支持其他形态，需要在下面放开对应限制
              item.itemType == .normalApplication,
              let badgeInfo = item.badgeInfo?.value else {
            return [:]
        }

        let badgeNodes = badgeInfo.filter({ $0.clientType == .mobile && $0.appAbility == defaultBadgeAbility })
        return badgeNodes.reduce(into: [String: WPBadge](), { $0[$1.appId] = $1 })
    }
}
