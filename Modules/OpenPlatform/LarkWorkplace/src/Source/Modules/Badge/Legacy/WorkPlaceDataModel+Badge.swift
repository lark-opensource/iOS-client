//
//  WorkPlaceDataModel+Badge.swift
//  LarkWorkplace
//
//  Created by lilun.ios on 2020/12/21.
//

import Foundation
import LarkWorkplaceModel

private let _queue = DispatchQueue(label: "com.workplace.badgeDecode")

extension WorkPlaceDataModel {
    func extractBadgeInfo(complete: @escaping ((WorkPlaceBadgeInfo) -> Void)) {
        Self.logger.info("extractBadgeInfo start")
        // swiftlint:disable closure_body_length
        _queue.async {
            var result = WorkPlaceBadgeInfo()
            var map: [String: WorkPlaceBadge.BadgeSingleKey] = [:]
            for group in self.groups where group.shouldDisplayBadge() {
                let isMainTag = group.category.tag.isMainTag ?? false
                for unit in group.itemUnits {
                    let item = unit.item
                    // 记录badge信息
                    if let badgeItemList = item.badgeInfo?.value,
                       let appID = item.appId,
                       let appAbility = item.mobileDefaultAbility,
                       let displayAbility = AppBadgeItemInfo.convertDisplayAbility(appAbility),
                       item.itemType == .normalApplication {
                        let badge = AppBadgeItemInfo(
                            appID: appID,
                            badgeList: badgeItemList.filter({ $0.clientType == .mobile }),
                            workplaceDisplayAbility: displayAbility
                        )
                        if isMainTag {
                            // 我的常用，icon才计数
                            if unit.type == .icon {
                                // 以merge的方式进行更新
                                result.updateBadge(appID: appID, badge: badge, type: .merge)
                            }
                        } else {
                            // 非我的常用，直接计数
                            // 以merge的方式进行更新
                            result.updateBadge(appID: appID, badge: badge, type: .merge)
                        }
                    }
                    // 额外记录工作台应用信息
                    if let badgeKey = item.badgeKey() {
                        map[badgeKey.key()] = badgeKey
                    }
                }
            }
            result.workplaceAppMap = map
            DispatchQueue.main.async { complete(result) }
        }
        // swiftlint:enable closure_body_length
    }
}
