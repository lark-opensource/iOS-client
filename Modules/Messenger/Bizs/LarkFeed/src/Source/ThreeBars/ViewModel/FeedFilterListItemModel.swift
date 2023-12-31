//
//  FeedFilterListItemModel.swift
//  LarkFeed
//
//  Created by liuxianyu on 2022/8/29.
//

import UIKit
import Foundation
import RustPB

struct FeedFilterListItemModel: FeedFilterListItemInterface {
    let selectState: Bool
    let filterType: Feed_V1_FeedFilter.TypeEnum
    let unread: Int
    let unreadContent: String
    let title: String
    let avatarInfo: (avatarId: String, avatarKey: String)?
    let avatarImage: UIImage?
    let subTabId: String?

    static func transformFilterModel(_ filterModel: FilterItemModel, _ selectedType: Feed_V1_FeedFilter.TypeEnum) -> FeedFilterListItemModel {
        var selectState: Bool = false
        if selectedType != .unknown {
            selectState = filterModel.type == selectedType
        }

        let remindUnreadCount = filterModel.unread
        let unreadContent = makeUnreadContent(remindUnreadCount)
        return FeedFilterListItemModel(selectState: selectState,
                                       filterType: filterModel.type,
                                       unread: remindUnreadCount,
                                       unreadContent: unreadContent,
                                       title: filterModel.name,
                                       avatarInfo: nil,
                                       avatarImage: nil,
                                       subTabId: nil)
    }

    static func transformTeamModel(_ teamModel: FeedTeamItemViewModel, _ selectedTeamId: String?) -> FeedFilterListItemModel {
        var selectState: Bool = false
        if let teamId = selectedTeamId, !teamId.isEmpty {
            selectState = String(teamModel.teamItem.id) == teamId
        }

        let remindUnreadCount = teamModel.remindUnreadCount ?? 0
        let unreadContent = makeUnreadContent(remindUnreadCount)
        return FeedFilterListItemModel(selectState: selectState,
                                       filterType: .team,
                                       unread: remindUnreadCount,
                                       unreadContent: unreadContent,
                                       title: teamModel.teamEntity.name,
                                       avatarInfo: (String(teamModel.teamEntity.id), teamModel.teamEntity.avatarKey),
                                       avatarImage: nil,
                                       subTabId: String(teamModel.teamItem.id))
    }

    static func transformLabelModel(_ labelModel: LabelViewModel, _ selectedLabelId: String?) -> FeedFilterListItemModel {
        var selectState: Bool = false
        if let labelId = selectedLabelId, !labelId.isEmpty {
            selectState = String(labelModel.item.id) == labelId
        }
        let remindUnreadCount = Int(labelModel.meta.extraData.remindUnreadCount)
        let unreadContent = makeUnreadContent(remindUnreadCount)
        return FeedFilterListItemModel(selectState: selectState,
                                       filterType: .tag,
                                       unread: remindUnreadCount,
                                       unreadContent: unreadContent,
                                       title: labelModel.meta.feedGroup.name,
                                       avatarInfo: nil,
                                       avatarImage: Resources.labelCustomOutlined,
                                       subTabId: String(labelModel.item.id))
    }

    static func makeUnreadContent(_ unread: Int) -> String {
        var countStr = ""
        if unread > 0 {
            if unread <= FiltersModel.maxNumber {
                countStr = " \(unread)"
            } else if unread == FiltersModel.maxNumber + 1 {
                countStr = " 1M"
            } else {
                countStr = " 1M+"
            }
        }
        return countStr
    }
}
