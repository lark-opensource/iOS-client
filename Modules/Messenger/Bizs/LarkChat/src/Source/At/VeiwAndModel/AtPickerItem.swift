//
//  AtPickerItem.swift
//  LarkChat
//
//  Created by Kongkaikai on 2019/11/4.
//

import Foundation
import LarkCore
import LarkTag
import LarkModel
import LarkListItem
import LarkSetting
import LarkBizTag

struct AtPickerItem: ChatChatterItem {
    var itemId: String { return chatter.id }
    var itemAvatarKey: String { return chatter.avatarKey }
    var itemMedalKey: String = ""
    private(set) var itemName: String
    var itemPinyinOfName: String? { return chatter.namePinyin }
    var itemDescription: Chatter.Description? {
        return chatter.description_p
    }
    var descInlineProvider: DescriptionInlineProvider?
    var descUIConfig: StatusLabel.UIConfig?
    var itemDepartment: String?
    private(set) var itemTags: [TagDataItem]?
    var itemCellClass: AnyClass
    var isBottomLineHidden: Bool = false
    var isSelectedable: Bool = true
    var itemUserInfo: Any?
    var itemTimeZoneId: String?

    var isOuter: Bool

    var trackExtension: AtPickerItemTrackExtension

    var chatter: Chatter
    var needDisplayDepartment: Bool?
    var supportShowDepartment: Bool?

    init(
        chatter: Chatter,
        itemName: String,
        itemTags: [TagDataItem]?,
        itemCellClass: AnyClass,
        itemDepartment: String? = nil,
        isOuter: Bool,
        trackExtension: AtPickerItemTrackExtension
    ) {
        self.chatter = chatter
        self.itemName = itemName
        self.itemTags = itemTags
        self.itemCellClass = itemCellClass
        self.itemUserInfo = chatter
        self.itemDepartment = itemDepartment
        self.isOuter = isOuter
        self.trackExtension = trackExtension
    }
}

extension AtPickerItem: SelectedCollectionItem {
    public var id: String { return itemId }
    public var avatarKey: String { return itemAvatarKey }
    public var medalKey: String { self.chatter.medalKey }
    public var isChatter: Bool { return true }
}
