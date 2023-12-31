//
//  AppCategoryDataModel.swift
//  LarkWorkplace
//
//  Created by  bytedance on 2020/6/19.
//

import Foundation
import SwiftyJSON
import LKCommonsLogging
import LarkWorkplaceModel

extension WPCategoryAppItem {
    static func build(with rankItem: RankItem) -> WPCategoryAppItem {
        return WPCategoryAppItem(
            itemId: rankItem.itemId,
            name: rankItem.name,
            desc: rankItem.desc,
            iconKey: rankItem.iconKey,
            appStoreDetailPageURL: nil,
            appStoreRedirectURL: nil,
            itemAbility: nil,
            isSharedByOtherOrganization: rankItem.isSharedByOtherOrganization,
            sharedSourceTenantInfo: rankItem.sharedSourceTenantInfo
        )
    }
}

extension WPSearchCategoryApp {
    func isEmpty() -> Bool {
        return (availableItems?.isEmpty ?? true) && (unavailableItems?.isEmpty ?? true)
    }

    func description() -> String {
        return "availableItems: \(availableItems?.count), unavailableItems: \(unavailableItems?.count)"
    }

    func hasMoreApps() -> Bool {
        return hasMore ?? false
    }
}
