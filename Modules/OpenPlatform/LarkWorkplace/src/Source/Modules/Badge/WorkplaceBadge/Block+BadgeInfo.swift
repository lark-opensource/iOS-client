//
//  Favorite+BadgeInfo.swift
//  LarkWorkplace
//
//  Created by Meng on 2022/11/09.
//

import Foundation
import LarkWorkplaceModel

/// 非标 Block badge 解析逻辑
extension BlockLayoutComponent: BadgeInfoConvertable {
    func buildBadgeNodes() -> [String: WPBadge] {
        guard let node = self.nodeComponents.first as? BlockComponent,
              let badgeNodes = node.blockModel?.item.badgeInfo?.value else {
            return [:]
        }

        let mobileBadgeNodes = badgeNodes.filter({ $0.clientType == .mobile })  // 过滤 mobile

        // 根据 badgeNodes 的 clientId(appId) 进行映射。
        // 对于一个 Block 来说，也有可能返回多个应用的 badge（比如官方组件 - 应用列表）
        // 同时服务端已经处理了 displayAbility 的计算，一个 appId 理论上只有一个 Node
        return mobileBadgeNodes.reduce(into: [String: WPBadge](), { container, node in // [appId: WPBadge]
            container[node.appId] = node
        })
    }
}
