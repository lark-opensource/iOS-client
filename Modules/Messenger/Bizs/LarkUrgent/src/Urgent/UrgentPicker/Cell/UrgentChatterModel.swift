//
//  UrgentChatterModel.swift
//  LarkUrgent
//
//  Created by 李勇 on 2019/6/7.
//

import Foundation
import LarkTag
import LarkModel
import LarkCore
import LarkBizTag
import ServerPB

/// 接入SelectedCollectionView
/// SelectedCollectionView使用的是SelectedCollectionItem
extension UrgentChatterModel: SelectedCollectionItem {
    var id: String { return self.chatter.id }
    var avatarKey: String { return self.chatter.avatarKey }
    var medalKey: String { chatter.medalKey }
    var isChatter: Bool { return true }
}

enum UrgentChatterAuthDenyReason: Equatable {
    case pass
    case reason(ServerPB_Misc_DeniedReason)
}

struct UrgentChatterModel {
    var itemName: String
    var itemTags: [TagDataItem]?
    var itemCellClass: AnyClass
    var chatter: Chatter
    var isRead: Bool
    var unSupportChatterType: UnSupportChatterType
    let authDenyReason: UrgentChatterAuthDenyReason

    init(chatter: Chatter,
         itemName: String,
         itemTags: [TagDataItem]?,
         isRead: Bool = false,
         unSupportChatterType: UnSupportChatterType = .none,
         itemCellClass: AnyClass,
         authDenyReason: UrgentChatterAuthDenyReason) {
        self.chatter = chatter
        self.itemName = itemName
        self.isRead = isRead
        self.unSupportChatterType = unSupportChatterType
        self.itemTags = itemTags
        self.itemCellClass = itemCellClass
        self.authDenyReason = authDenyReason
    }

    var hitDenyReason: ServerPB_Misc_DeniedReason? {
        switch self.authDenyReason {
        case .reason(let reason):
            if reason == .sameTenantDeny ||
                reason == .externalCoordinateCtl ||
                reason == .targetExternalCoordinateCtl ||
                reason == .noFriendship ||
                reason == .beBlocked {
                return reason
            }
        case .pass:
            return nil
        }
        return nil
    }
}

struct UrgentExtraInfo {
    var isRead: Bool = false
    var unSupportChatterType: UnSupportChatterType = .none
    var authDenyReason: UrgentChatterAuthDenyReason = .pass
}
