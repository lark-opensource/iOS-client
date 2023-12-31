//
//  FiltersModel.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/12/31.
//

import Foundation
import RustPB
import LarkOpenFeed
import LarkContainer

public final class FiltersModel {
    static let maxNumber = 999_999
    static let filterSettingTitle = "···"

    let enable: Bool // 是否展示用户分组栏
    let usedFilters: [FilterItemModel] // 用户分组，pb里不包括 ALL
    let allFilters: [FilterItemModel] // 全部分组信息，pb里不包括 ALL
    let commonlyUsedFilters: [FilterItemModel] // 常用分组，pb里不包括 ALL
    let showMute: Bool
    let hasShowMute: Bool
    let hasShowAtAllInAtFilter: Bool
    let showAtAllInAtFilter: Bool
    let msgDisplaySettingMap: [Feed_V1_FeedFilter.TypeEnum: FeedMsgDisplayFilterItem]
    let feedRuleMd5: String
    let version: Int64

    // tea埋点以及日志打印
    public static func tabName(_ type: Feed_V1_FeedFilter.TypeEnum) -> String {
        return FeedGroupData.name(groupType: type)
    }

    static let mainRuleMap: [FeedMsgDisplayItemType: Feed_V1_DisplayFeedRule.DisplayFeedMainRule] = [
        .showAll: .alwaysDisplay,
        .showNew: .displayWhenNewMsg,
        .showNone: .neverDisplay
    ]

    static let msgRuleMap: [FeedMsgDisplayItemType: Feed_V1_DisplayFeedRule.DisplayFeedMsgType] = [
        .showAllNew: .all,
        .showAtMeMentions: .atMe,
        .showAtAllMentions: .atAll,
        .showStarredContacts: .starContacts
    ]

    static let mainRuleOptMap: [FeedMsgDisplayItemType: Feed_V1_DisplayFeedRule.DisplayFeedMainRule] = [
        .showAll: .alwaysDisplay,
        .showNew: .displayWhenSpecificMsg,
        .showAllNew: .displayWhenAnyNewMsg,
        .showNone: .neverDisplay
    ]

    static let msgRuleOptMap: [FeedMsgDisplayItemType: Feed_V1_DisplayFeedRule.DisplayFeedMsgType] = [
        .showAtMeMentions: .atMe,
        .showAtAllMentions: .atAll,
        .showStarredContacts: .starContacts
    ]

    static func transform(userResolver: UserResolver, _ getFilterPB: Feed_V1_GetFeedFilterSettingsResponse) -> FiltersModel {
        let enable = getFilterPB.filterEnable
        let showMute = getFilterPB.showMute || Feed.Feature(userResolver).groupSettingEnable
        let actionMap = getFilterPB.commonlyUsedFilterAction
        let usedFilters = getVaildUsedFilters(getFilterPB.usedFilters, showMute, actionMap)
        let commonlyUsedFilters = getVaildUsedFilters(getFilterPB.commonlyUsedFilters, showMute, actionMap)
        let allFilters = getFilterPB.allFilters.compactMap { filterPb -> FilterItemModel? in
            if filterPb.filterType == .unknown {
                return nil
            }

            guard let name = FeedFilterTabSourceFactory.source(for: filterPb.filterType)?.titleProvider() else {
                return nil
            }
            if !showMute, filterPb.filterType == .mute {
                return nil
            }
            let action = actionMap[Int32(filterPb.filterType.rawValue)]
            return FilterItemModel.transform(filterPb, name: name, action: action)
        }

        let msgDisplaySettingMap = transformFeedRule(userResolver: userResolver, getFilterPB.filterDisplayFeedRule)

        return FiltersModel(enable: enable,
                            usedFilters: usedFilters,
                            allFilters: allFilters,
                            commonlyUsedFilters: commonlyUsedFilters,
                            showMute: showMute,
                            hasShowMute: getFilterPB.hasShowMute,
                            hasShowAtAllInAtFilter: getFilterPB.hasShowAtAllInAtFilter,
                            showAtAllInAtFilter: getFilterPB.showAtAllInAtFilter,
                            msgDisplaySettingMap: msgDisplaySettingMap,
                            feedRuleMd5: getFilterPB.filterDisplayFeedRuleMd5,
                            version: getFilterPB.version)
    }

    static func transform(userResolver: UserResolver, _ pushFilterPB: Feed_V1_PushFeedFilterSettings) -> FiltersModel {
        let enable = pushFilterPB.filterEnable
        let showMute = pushFilterPB.showMute || Feed.Feature(userResolver).groupSettingEnable
        let actionMap = pushFilterPB.commonlyUsedFilterAction
        let usedFilters = getVaildUsedFilters(pushFilterPB.usedFilterInfos, showMute, actionMap)
        let commonlyUsedFilters = getVaildUsedFilters(pushFilterPB.commonlyUsedFilters, showMute, actionMap)
        let msgDisplaySettingMap = transformFeedRule(userResolver: userResolver, pushFilterPB.filterDisplayFeedRule)

        return FiltersModel(enable: enable,
                            usedFilters: usedFilters,
                            allFilters: [],
                            commonlyUsedFilters: commonlyUsedFilters,
                            showMute: showMute,
                            hasShowMute: pushFilterPB.hasShowMute,
                            hasShowAtAllInAtFilter: pushFilterPB.hasShowAtAllInAtFilter,
                            showAtAllInAtFilter: pushFilterPB.showAtAllInAtFilter,
                            msgDisplaySettingMap: msgDisplaySettingMap,
                            feedRuleMd5: pushFilterPB.filterDisplayFeedRuleMd5,
                            version: pushFilterPB.version)
    }

    static func getVaildUsedFilters(_ usedFilters: [Feed_V1_FeedFilter],
                                    _ showMute: Bool,
                                    _ actionMap: [Int32: Feed_V1_FilterRealAction]) -> [FilterItemModel] {
        var tempFilters = usedFilters.compactMap { filterPb -> FilterItemModel? in
            if filterPb.filterType == .unknown {
                return nil
            }

            guard let name = FeedFilterTabSourceFactory.source(for: filterPb.filterType)?.titleProvider() else {
                return nil
            }
            // TODO: 需要rust优化
            if !showMute, filterPb.filterType == .mute {
                return nil
            }
            let action = actionMap[Int32(filterPb.filterType.rawValue)]
            return FilterItemModel.transform(filterPb, name: name, action: action)
        }
        tempFilters = insertFirstTabIfNeed(tempFilters, showMute, actionMap)
        return tempFilters
    }

    static func getVaildUsedFilters(_ usedFilters: [Feed_V1_FeedFilterInfo],
                                    _ showMute: Bool,
                                    _ actionMap: [Int32: Feed_V1_FilterRealAction]) -> [FilterItemModel] {
        var tempFilters = usedFilters.compactMap { filterPb -> FilterItemModel? in
            if filterPb.type.filterType == .unknown {
                return nil
            }

            guard let name = FeedFilterTabSourceFactory.source(for: filterPb.type.filterType)?.titleProvider() else {
                return nil
            }
            // TODO: 需要rust优化
            if !showMute, filterPb.type.filterType == .mute {
                return nil
            }
            let action = actionMap[Int32(filterPb.type.filterType.rawValue)]
            return FilterItemModel.transform(filterPb, name: name, action: action)
        }

        tempFilters = insertFirstTabIfNeed(tempFilters, showMute, actionMap)
        return tempFilters
    }

    static func insertFirstTabIfNeed(_ usedFilters: [FilterItemModel],
                                     _ showMute: Bool,
                                     _ actionMap: [Int32: Feed_V1_FilterRealAction]) -> [FilterItemModel] {
        var tempFilters = usedFilters
        var needInsertFirstTab = false
        if !tempFilters.isEmpty, let firstType = tempFilters.first?.type, !AllFeedListViewModel.getFirstTabs().contains(firstType) {
            needInsertFirstTab = true
        } else  if tempFilters.isEmpty {
            needInsertFirstTab = true
        }

        if needInsertFirstTab {
            let firstTab = AllFeedListViewModel.getFirstTab(showMute: showMute)
            if let name = FeedFilterTabSourceFactory.source(for: firstTab)?.titleProvider() {
                let action = actionMap[Int32(firstTab.rawValue)]
                let allItemModel = FilterItemModel(type: firstTab, name: name, action: action)
                tempFilters.insert(allItemModel, at: 0)
            }
        }
        return tempFilters
    }

    init(enable: Bool,
         usedFilters: [FilterItemModel],
         allFilters: [FilterItemModel],
         commonlyUsedFilters: [FilterItemModel],
         showMute: Bool,
         hasShowMute: Bool,
         hasShowAtAllInAtFilter: Bool,
         showAtAllInAtFilter: Bool,
         msgDisplaySettingMap: [Feed_V1_FeedFilter.TypeEnum: FeedMsgDisplayFilterItem],
         feedRuleMd5: String,
         version: Int64) {
        self.enable = enable
        self.usedFilters = usedFilters
        self.allFilters = allFilters
        self.commonlyUsedFilters = commonlyUsedFilters
        self.showMute = showMute
        self.hasShowMute = hasShowMute
        self.hasShowAtAllInAtFilter = hasShowAtAllInAtFilter
        self.showAtAllInAtFilter = showAtAllInAtFilter
        self.msgDisplaySettingMap = msgDisplaySettingMap
        self.feedRuleMd5 = feedRuleMd5
        self.version = version
    }
}

// MARK: - DisplayRule ModelTransform
extension FiltersModel {
    // 数据模型Map转换: sdk -> client
    static func transformFeedRule(userResolver: UserResolver, _ feedRule: [Int32: Feed_V1_DisplayFeedRule]) -> [Feed_V1_FeedFilter.TypeEnum: FeedMsgDisplayFilterItem] {
        let msgDisplaySettingArray = feedRule.compactMap { (key: Int32, value: Feed_V1_DisplayFeedRule) -> FeedMsgDisplayFilterItem? in
            guard let filterType = Feed_V1_FeedFilter.TypeEnum(rawValue: Int(key)) else { return nil }
            let selectedTypes = transformToSelectedTypes(userResolver: userResolver, value)
            if selectedTypes.isEmpty { return nil }
            return FeedMsgDisplayFilterModel(userResolver: userResolver, selectedTypes: selectedTypes, filterType: filterType)
        }

        var msgDisplaySettingMap: [Feed_V1_FeedFilter.TypeEnum: FeedMsgDisplayFilterItem] = [:]
        for item in msgDisplaySettingArray {
            msgDisplaySettingMap[item.filterType] = item
        }
        return msgDisplaySettingMap
    }

    // UI数据模型转换: sdk -> client ui
    // 异常情况: 若 feedRule 为 .unknown 或废弃字段，返回空数组
    static func transformToSelectedTypes(userResolver: UserResolver, _ feedRule: Feed_V1_DisplayFeedRule) -> [FeedMsgDisplayItemType] {
        if Feed.Feature(userResolver).groupSettingOptEnable {
            return transformToSelectedTypesByOpt(feedRule)
        } else {
            return transformToSelectedTypesByDefault(feedRule)
        }
    }

    // default
    private static func transformToSelectedTypesByDefault(_ feedRule: Feed_V1_DisplayFeedRule) -> [FeedMsgDisplayItemType] {
        let mainRuleMap = FiltersModel.mainRuleMap
        guard let mainType = mainRuleMap.filter({ $0.value == feedRule.mainRule }).keys.first else {
            return []
        }
        if mainType == .showAll || mainType == .showNone { return [mainType] }
        if mainType == .showNew {
            var types = [mainType]
            if feedRule.msgTypes.contains(.all) {
                types.append(.showAllNew)
            }
            if feedRule.msgTypes.contains(.atMe) {
                types.append(.showAtMeMentions)
            }
            if feedRule.msgTypes.contains(.atAll) {
                types.append(.showAtAllMentions)
            }
            if feedRule.msgTypes.contains(.starContacts) {
                types.append(.showStarredContacts)
            }
            return types
        }
        return []
    }

    // opt
    private static func transformToSelectedTypesByOpt(_ feedRule: Feed_V1_DisplayFeedRule) -> [FeedMsgDisplayItemType] {
        let mainRuleMap = FiltersModel.mainRuleOptMap
        guard let mainType = mainRuleMap.filter({ $0.value == feedRule.mainRule }).keys.first else {
            return []
        }
        if mainType == .showAll || mainType == .showNone || mainType == .showAllNew { return [mainType] }
        if mainType == .showNew {
            var types = [mainType]
            if feedRule.msgTypes.contains(.atMe) {
                types.append(.showAtMeMentions)
            }
            if feedRule.msgTypes.contains(.atAll) {
                types.append(.showAtAllMentions)
            }
            if feedRule.msgTypes.contains(.starContacts) {
                types.append(.showStarredContacts)
            }
            return types
        }
        return []
    }

    // UI数据模型转换: client ui -> sdk
    // 异常情况: 若 type 未匹配，则返回 nil，目的是请求 sdk 接口时不做数据更新
    static func transformToFeedRule(userResolver: UserResolver, _ item: FeedMsgDisplayFilterItem) -> Feed_V1_DisplayFeedRule? {
        if Feed.Feature(userResolver).groupSettingOptEnable {
            return transformToFeedRuleByOpt(item)
        } else {
            return transformToFeedRuleByDefault(item)
        }
    }

    private static func transformToFeedRuleByDefault(_ item: FeedMsgDisplayFilterItem) -> Feed_V1_DisplayFeedRule? {
        var feedRule = Feed_V1_DisplayFeedRule()
        let selectedTypes = item.selectedTypes
        let mainRuleMap = FiltersModel.mainRuleMap
        let msgRuleMap = FiltersModel.msgRuleMap

        for type in mainRuleMap.keys {
            if selectedTypes.contains(type), let mainRule = mainRuleMap[type] {
                feedRule.mainRule = mainRule
                break
            }
        }

        if feedRule.mainRule == .unknownMainRule { return nil }
        guard feedRule.mainRule == .displayWhenNewMsg else {
            return feedRule
        }

        var msgRules: [Feed_V1_DisplayFeedRule.DisplayFeedMsgType] = []
        for type in msgRuleMap.keys {
            if selectedTypes.contains(type), let msgRule = msgRuleMap[type] {
                msgRules.append(msgRule)
            }
        }
        feedRule.msgTypes = msgRules
        return feedRule
    }

    private static func transformToFeedRuleByOpt(_ item: FeedMsgDisplayFilterItem) -> Feed_V1_DisplayFeedRule? {
        var feedRule = Feed_V1_DisplayFeedRule()
        let selectedTypes = item.selectedTypes
        let mainRuleMap = FiltersModel.mainRuleOptMap
        let msgRuleMap = FiltersModel.msgRuleOptMap

        for type in mainRuleMap.keys {
            if selectedTypes.contains(type), let mainRule = mainRuleMap[type] {
                feedRule.mainRule = mainRule
                break
            }
        }

        if feedRule.mainRule == .unknownMainRule {
            return nil
        }
        guard feedRule.mainRule == .displayWhenSpecificMsg else {
            return feedRule
        }

        var msgRules: [Feed_V1_DisplayFeedRule.DisplayFeedMsgType] = []
        for type in msgRuleMap.keys {
            if selectedTypes.contains(type),
               let msgRule = msgRuleMap[type] {
                msgRules.append(msgRule)
            }
        }
        feedRule.msgTypes = msgRules
        return feedRule
    }
}

final class FilterItemModel {
    let type: Feed_V1_FeedFilter.TypeEnum
    let unread: Int
    let unreadText: String
    let name: String
    let title: String
    var action: Feed_V1_FilterRealAction?

    static func transform(_ filterPb: Feed_V1_FeedFilter, name: String, action: Feed_V1_FilterRealAction?) -> FilterItemModel {
        return FilterItemModel(type: filterPb.filterType, name: name, action: action)
    }

    static func transform(_ filterInfoPb: Feed_V1_FeedFilterInfo, name: String, action: Feed_V1_FilterRealAction?) -> FilterItemModel {
        return FilterItemModel(type: filterInfoPb.type.filterType,
                               name: name,
                               unread: Int(filterInfoPb.unreadCount),
                               action: action)
    }

    init(type: Feed_V1_FeedFilter.TypeEnum,
         name: String,
         unread: Int = 0,
         action: Feed_V1_FilterRealAction? = nil) {
        self.type = type
        self.unread = unread
        self.name = name
        var countStr = ""
        if !(type == .inbox || type == .message || type == .done) && unread - 1 > -1 {
            if unread <= FiltersModel.maxNumber {
                countStr = "\(unread)"
            } else if unread == FiltersModel.maxNumber + 1 {
                countStr = "1M"
            } else {
                countStr = "1M+"
            }
        }
        self.unreadText = countStr

        if !countStr.isEmpty {
            self.title = name + " " + countStr
        } else {
            self.title = name
        }
        self.action = action
    }

    func updateUnread(_ count: Int) -> FilterItemModel {
        return FilterItemModel(type: self.type, name: self.name, unread: count, action: self.action)
    }

    public var description: String {
        return "\(self.type), \(self.unread)"
    }
}
