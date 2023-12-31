//
//  ChatChatterDatas.swift
//  LarkChat
//
//  Created by kongkaikai on 2019/2/24.
//

import Foundation
import LarkModel
import LarkTag
import LarkListItem
import LarkBizTag

public protocol ChatChatterItem {
    typealias DescriptionInlineResult = (_ sourceID: String,
                                         _ attriubuteText: NSMutableAttributedString,
                                         _ urlRangeMap: [NSRange: URL],
                                         _ textUrlRangeMap: [NSRange: String]) -> Void
    typealias DescriptionInlineProvider = (@escaping DescriptionInlineResult) -> Void

    var itemId: String { get }
    var itemAvatarKey: String { get }
    var itemMedalKey: String { get set }
    var isShowMedal: Bool { get }
    var itemName: String { get }
    var itemPinyinOfName: String? { get }
    var itemDescription: Chatter.Description? { get }
    var descInlineProvider: DescriptionInlineProvider? { get }
    var descUIConfig: StatusLabel.UIConfig? { get }
    var itemDepartment: String? { get set }
    var itemTags: [TagDataItem]? { get }
    var itemCellClass: AnyClass { get set }
    var isBottomLineHidden: Bool { get set }
    var isSelectedable: Bool { get set }
    var itemUserInfo: Any? { get set }
    var itemTimeZoneId: String? { get set }
    // 是否需要展示部门信息
    var needDisplayDepartment: Bool? { get set }
    // 是否支持展示部门信息
    var supportShowDepartment: Bool? { get set }
}

extension ChatChatterItem {
    public var isShowMedal: Bool { false }
}

public struct ChatChatterDefaultItem: ChatChatterItem {
    public var needDisplayDepartment: Bool?

    public var supportShowDepartment: Bool?

    private var _itemId: String

    public var itemId: String { return _itemId }

    public var itemAvatarKey: String { return "" }

    public var itemMedalKey: String = ""

    public var itemName: String { return "" }

    public var itemPinyinOfName: String? { return nil }

    public var itemDescription: LarkModel.Chatter.Description? { return nil }

    public var descInlineProvider: DescriptionInlineProvider? { return nil }

    public var descUIConfig: StatusLabel.UIConfig? { return nil }

    public var itemDepartment: String?

    public var itemTags: [LarkBizTag.TagDataItem]? { return nil }

    public var itemCellClass: AnyClass = ChatChatterCell.self

    public var isBottomLineHidden: Bool = false

    public var isSelectedable: Bool = false

    public var itemUserInfo: Any?

    public var itemTimeZoneId: String?

    public init(itemId: String) { self._itemId = itemId }
}

public struct ChatChatterWapper: ChatChatterItem {

    public var itemId: String { return chatter.id }
    public var itemAvatarKey: String { return chatter.avatarKey }
    public var itemName: String
    public var itemMedalKey: String
    public var isShowMedal: Bool { true }
    public var itemPinyinOfName: String? { return chatter.namePinyin }
    public var itemDescription: Chatter.Description? { return chatter.description_p }
    public var descInlineProvider: DescriptionInlineProvider?
    public var descUIConfig: StatusLabel.UIConfig?
    public var itemDepartment: String?
    public var itemTags: [TagDataItem]?
    public var itemCellClass: AnyClass
    public var isBottomLineHidden: Bool = false
    public var isSelectedable: Bool = true
    public var itemUserInfo: Any?
    public var itemTimeZoneId: String?

    public var chatter: Chatter
    public var needDisplayDepartment: Bool?
    public var supportShowDepartment: Bool?

    public init(
        chatter: Chatter,
        itemName: String,
        itemMedalKey: String = "",
        itemTags: [TagDataItem]?,
        itemCellClass: AnyClass,
        itemDepartment: String? = nil,
        itemTimeZoneId: String? = nil,
        descInlineProvider: DescriptionInlineProvider? = nil,
        descUIConfig: StatusLabel.UIConfig? = nil) {
        self.chatter = chatter
        self.itemName = itemName
        self.itemMedalKey = itemMedalKey
        self.itemTags = itemTags
        self.itemCellClass = itemCellClass
        self.itemUserInfo = chatter
        self.itemDepartment = itemDepartment
        self.itemTimeZoneId = itemTimeZoneId
        self.descInlineProvider = descInlineProvider
        self.descUIConfig = descUIConfig
    }
}

public protocol ChatChatterSection {
    var title: String? { get }
    var indexKey: String { get }
    var items: [ChatChatterItem] { get set }
    var sectionHeaderClass: AnyClass { get }
    var showHeader: Bool { get }
}

public struct ChatChatterSectionData: ChatChatterSection {
    public private(set) var title: String?
    public private(set) var indexKey: String
    public var items: [ChatChatterItem]
    public var sectionHeaderClass: AnyClass
    public var showHeader: Bool

    public init(title: String?, indexKey: String? = nil, items: [ChatChatterItem], showHeader: Bool = true, sectionHeaderClass: AnyClass) {
        self.title = title
        self.indexKey = indexKey ?? title ?? ""
        self.items = items
        self.showHeader = showHeader
        self.sectionHeaderClass = sectionHeaderClass
    }
}

extension ChatChatterWapper: SelectedCollectionItem {
    public var id: String { return itemId }
    public var avatarKey: String { return itemAvatarKey }
    public var medalKey: String { self.chatter.medalKey }
    public var isChatter: Bool { return true }
}

public extension Array where Element == ChatChatterSection {

    // 由于分页且分组，所以数据需要merge而不是直接追加
    mutating func merge(_ others: [ChatChatterSection]) {
        let keys = Set(self.map { $0.indexKey }).intersection(others.map { $0.indexKey })
        if keys.isEmpty {
            self += others
        } else {
            var temp = others
            for key in keys {
                if let oldIndex = self.firstIndex(where: { $0.indexKey == key }),
                    let newIndex = temp.firstIndex(where: { $0.indexKey == key }) {
                    self[oldIndex].items += others[newIndex].items
                    temp.remove(at: newIndex)
                }
            }
            self += temp
        }
    }

    mutating func updateDepartmentName(_ newDepartmentName: String, _ chatterId: String) {
        // 寻找并且替换旧部门信息,本方法仅更新已在数据源中的数据的部门信息
        let datas = self.map { (section) -> ChatChatterSection in
            var newSection = section
            let items = section.items.map { (item) -> ChatChatterItem in
                var newItem = item
                // 定位到需要更新的item，若部门信息新老值不相同
                if newItem.itemId == chatterId && newDepartmentName != newItem.itemDepartment {
                    // 更新部门信息
                    newItem.itemDepartment = newDepartmentName
                    return newItem
                }
                return item
            }
            newSection.items = items
            return newSection
        }
        self = datas
    }
}

public extension Chatter {
    var eduTags: [Tag] {
        var eduTag: [Tag] = []
        var tagInfos = self.chatExtra?.tagInfos.tags ?? []
        //如果有班主任
        if tagInfos.contains(where: { (info) -> Bool in
            return info.tagType == .classTeacher
        }) {
            //过滤掉所有任课老师标签
            tagInfos = tagInfos.filter({ (info) -> Bool in
                return info.tagType != .disciplineTeacher
            })
        }
        for tag in tagInfos {
            if tag.tagType == .classTeacher { //班主任
                eduTag.append(Tag(title: tag.description_p, style: .blue, type: .customTitleTag))
            } else if tag.tagType == .disciplineTeacher { //任课老师
                eduTag.append(Tag(title: tag.description_p, style: .turquoise, type: .customTitleTag))
            }
        }
        return eduTag
    }
}
