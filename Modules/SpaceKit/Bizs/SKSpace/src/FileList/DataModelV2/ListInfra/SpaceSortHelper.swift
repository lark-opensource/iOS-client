//
//  SpaceSortHelper.swift
//  SKSpace
//
//  Created by Weston Wu on 2021/6/24.
//

import Foundation
import SKCommon
import SKFoundation
import SKResource

extension SpaceSortHelper {

    public enum SortType: String, Codable, Equatable, CaseIterable {
        case updateTime
        case createTime
        case owner
        case title
        case lastOpenTime
        case lastModifiedTime
        case allTime
        case sharedTime
        case latestCreated
        case addedManualOfflineTime
        case addFavoriteTime

        var serverParamValue: String {
            switch self {
            case .updateTime:
                return "0"
            case .createTime:
                return "3"
            case .owner:
                return "4"
            case .title:
                return "5"
            case .lastOpenTime:
                return "6"
            case .lastModifiedTime:
                return "7"
            case .allTime:
                return "8"
            case .sharedTime:
                return "9"
            case .latestCreated:
                // 等价于 createTime
                return "3"
            case .addedManualOfflineTime:
                return "10"
            case .addFavoriteTime:
                spaceAssertionFailure("addFavoriteTime should not be used when query list from server")
                return "-1"
            }
        }

        public var reportName: String { // sort_action 参数的取值
            switch self {
            case .createTime:
                return "Created_time"
            case .owner:
                return "Owner"
            case .title:
                return "Name"
            case .updateTime:
                return "Modified_time"
            case .lastOpenTime:
                return "Latest_open_time" // 建议
            case .lastModifiedTime:
                return "Latest_modified_time" // 建议
            case .allTime:
                return "All_time" // 建议
            case .sharedTime:
                return "Shared_time"
            case .latestCreated:
                return "Letest_created" // 建议
            case .addedManualOfflineTime:
                return "default" // 产品定的
            case .addFavoriteTime:
                return "star_time"
            }
        }

        var legacyType: SortItem.SortType {
            switch self {
            case .updateTime:
                return .updateTime
            case .createTime:
                return .createTime
            case .owner:
                return .owner
            case .title:
                return .title
            case .lastOpenTime:
                return .latestOpenTime
            case .lastModifiedTime:
                return .latestModifiedTime
            case .allTime:
                return .allTime
            case .sharedTime:
                return .shareTime
            case .latestCreated:
                return .letestCreated
            case .addedManualOfflineTime:
                return .latestAddManuOffline
            case .addFavoriteTime:
                return .addFavoriteTime
            }
        }

        var displayName: String {
            switch self {
            case .createTime:
                return BundleI18n.SKResource.Doc_List_SortByCreationTime
            case .owner:
                return BundleI18n.SKResource.Doc_List_SortByOwner
            case .title:
                return BundleI18n.SKResource.Doc_List_SortByTitle
            case .updateTime:
                return BundleI18n.SKResource.Doc_List_SortByUpdateTime
            case .lastOpenTime:
                return BundleI18n.SKResource.LarkCCM_NewCM_ViewedTime_Option
            case .lastModifiedTime:
                return BundleI18n.SKResource.Doc_List_SortByUpdateTime
            case .allTime:
                return BundleI18n.SKResource.Doc_List_Filter_All  // 没有定义，就用已有的
            case .sharedTime:
                return BundleI18n.SKResource.LarkCCM_NewCM_SharedTime_Menu
            case .latestCreated:
                return BundleI18n.SKResource.Doc_List_SortByCreationTime
            case .addedManualOfflineTime:
                return BundleI18n.SKResource.LarkCCM_NewCM_SavedTime_Option
            case .addFavoriteTime:
                return BundleI18n.SKResource.LarkCCM_NewCM_StarredTime_Menu
            }
        }
    }

    public struct SortOption: Codable, Equatable {
        let type: SortType
        private(set) var descending: Bool
        let allowAscending: Bool

        var sortParams: [String: Any] {
            [
                "rank": type.serverParamValue,
                "asc": !descending
            ]
        }

        var legacyItem: SortItem {
            var item = SortItem(isSelected: false, isUp: !descending, sortType: type.legacyType)
            item.needShowUpArrow = allowAscending
            return item
        }

        mutating func update(descending: Bool) {
            if !descending, !allowAscending {
                DocsLogger.error("update sortOption descending when not allow to change")
                return
            }
            self.descending = descending
        }
    }
}

public struct SpaceSortHelper {

    let listIdentifier: String
    private let cacheKey: String
    private(set) var selectedOption: SortOption
    var selectedIndex: Int {
        let index = options.firstIndex { option in
            option.type == selectedOption.type
        }
        return index ?? 0
    }
    let options: [SortOption]

    // 表示 selectedOption 与默认值相比是否发生变化
    var changed: Bool {
        selectedOption != defaultOption
    }

    let defaultOption: SortOption
    private let configCache: SpaceListConfigCache

    /// options 不能为空，defaultOption 为 nil 时，默认读第一个 option
    init(listIdentifier: String, options: [SortOption], defaultOption: SortOption? = nil, configCache: SpaceListConfigCache) {
        assert(!options.isEmpty, "options cannot be empty")
        if let defaultOption = defaultOption {
            assert(options.contains(where: { option in
                return option.type == defaultOption.type
                && option.allowAscending == defaultOption.allowAscending
            }))
        }
        self.listIdentifier = listIdentifier
        cacheKey = "space.sort." + listIdentifier
        selectedOption = defaultOption ?? options.first ?? SortOption(type: .allTime, descending: true, allowAscending: false)
        self.defaultOption = selectedOption
        self.options = options
        self.configCache = configCache
    }

    private init(listIdentifier: String, options: [SortOption], defaultOption: SortOption? = nil) {
        self.init(listIdentifier: listIdentifier, options: options, defaultOption: defaultOption, configCache: CacheService.configCache)
    }

    // 从 configCache 恢复曾经保存的选项，区分 user 和 listIdentifier
    mutating func restore() {
        guard let data = configCache.data(by: cacheKey) else {
            DocsLogger.info("space.sort.helper --- restore sort option failed, data not found", extraInfo: ["list-id": listIdentifier])
            return
        }
        do {
            let option = try JSONDecoder().decode(SortOption.self, from: data)
            let isValidOption = options.contains { next in
                option.type == next.type && option.allowAscending == next.allowAscending
            }
            if !isValidOption, !self.options.isEmpty {
                selectedOption = self.defaultOption
            } else {
                selectedOption = option
            }
            DocsLogger.info("space.sort.helper --- sort option restored", extraInfo: ["list-id": listIdentifier, "option": option])
        } catch {
            DocsLogger.error("space.sort.helper --- decode sort option failed", extraInfo: ["list-id": listIdentifier], error: error)
        }
    }

    // 向 configCache 写入当前选择的选项，区分 user 和 listIdentifier
    func store() {
        let currentOption = selectedOption
        let key = cacheKey
        let listID = listIdentifier
        let cache = configCache
        DispatchQueue.global().async {
            do {
                let data = try JSONEncoder().encode(currentOption)
                cache.set(data: data, for: key)
            } catch {
                DocsLogger.error("space.sort.helper --- encode sort option failed", extraInfo: ["list-id": listID], error: error)
            }
        }
    }

    mutating func update(sortIndex: Int, descending: Bool) {
        let index: Int
        if sortIndex < options.count {
            index = sortIndex
        } else {
            DocsLogger.error("space.sort.helper --- invalid sortIndex", extraInfo: ["sortIndex": sortIndex, "optionsCount": options.count])
            index = 0
        }
        var sortOption = options[index]
        sortOption.update(descending: descending)
        selectedOption = sortOption
    }

    mutating func update(selectedOption: SortOption) {
        guard options.contains(where: { $0.type == selectedOption.type }) else {
            DocsLogger.error("space.sort.helper --- new selected option type not in options!", extraInfo: ["list-id": listIdentifier, "option": selectedOption, "all-options": options])
            return
        }
        self.selectedOption = selectedOption
    }
}

// UI
extension SpaceSortHelper {

    // 提供给 sort 选择器使用的数据，在所有可选项的基础上，将当前选项的升降序结果进行替换，返回 UI 可以直接展示的数据
    var optionsForSortPanel: [SortOption] {
        let currentOption = selectedOption
        var allOptions = options
        guard let index = allOptions.firstIndex(where: { $0.type == currentOption.type }) else {
            DocsLogger.error("space.sort.helper --- current option type not in available options!", extraInfo: ["list-id": listIdentifier, "option": currentOption, "all-options": allOptions])
            assertionFailure("space.sort.helper --- current option type not in available options!")
            return allOptions
        }
        allOptions[index] = currentOption
        return allOptions
    }

    var legacyItemsForSortPanel: [SortItem] {
        let currentOption = selectedOption
        let allOptions = options
        guard let index = allOptions.firstIndex(where: { $0.type == currentOption.type }) else {
            DocsLogger.error("space.sort.helper --- current option type not in available options!", extraInfo: ["list-id": listIdentifier, "option": currentOption, "all-options": allOptions])
            assertionFailure("space.sort.helper --- current option type not in available options!")
            var items = allOptions.map(\.legacyItem)
            var defaultItem = items[0]
            defaultItem.isSelected = true
            items[0] = defaultItem
            return items
        }
        var items = allOptions.map(\.legacyItem)
        var selectedItem = items[index]
        selectedItem.isSelected = true
        selectedItem.isUp = !currentOption.descending
        items[index] = selectedItem
        return items
    }

    var defaultLegacyItemsForSortPanel: [SortItem] {
        var items = options.map(\.legacyItem)
        let defaultIndex = options.firstIndex { $0.type == defaultOption.type } ?? 0
        var defaultItem = items[defaultIndex]
        defaultItem.isSelected = true
        defaultItem.isUp = !defaultOption.descending
        items[defaultIndex] = defaultItem
        return items
    }
}

extension SpaceSortHelper {
    static var recent: SpaceSortHelper {
        SpaceSortHelper(listIdentifier: "RecentList",
                        options: [
                            SortOption(type: .lastModifiedTime, descending: true, allowAscending: false),
                            SortOption(type: .latestCreated, descending: true, allowAscending: false),
                            SortOption(type: .lastOpenTime, descending: true, allowAscending: false)
                        ],
                        defaultOption: SortOption(type: .lastOpenTime, descending: true, allowAscending: false))
    }
    
    static var bitableRecent: SpaceSortHelper {
        SpaceSortHelper(listIdentifier: "BitableRecentList",
                        options: [
                            SortOption(type: .lastOpenTime, descending: true, allowAscending: false)
                        ])
    }

    static var spaceTabRecent: SpaceSortHelper {
        SpaceSortHelper(listIdentifier: "SpaceTabRecentList",
                        options: [
                            SortOption(type: .lastOpenTime, descending: true, allowAscending: false)
                        ])
    }

    static var offLine: SpaceSortHelper {
        SpaceSortHelper(listIdentifier: "MOFilesService",
                        options: [
                            SortOption(type: .updateTime, descending: true, allowAscending: false),
                            SortOption(type: .latestCreated, descending: true, allowAscending: false),
                            SortOption(type: .addedManualOfflineTime, descending: true, allowAscending: false)
                        ])
    }

    static var myFolder: SpaceSortHelper {
        SpaceSortHelper(listIdentifier: "MyFolderList",
                        options: [
                            SortOption(type: .title, descending: true, allowAscending: true),
                            SortOption(type: .updateTime, descending: true, allowAscending: true),
                            SortOption(type: .createTime, descending: true, allowAscending: true)
                        ],
                        defaultOption: SortOption(type: .title, descending: false, allowAscending: true))
    }

    static var shareFolder: SpaceSortHelper {
        SpaceSortHelper(listIdentifier: "ShareFolderList",
                        options: [
                            SortOption(type: .title, descending: true, allowAscending: true),
                            SortOption(type: .updateTime, descending: true, allowAscending: true),
                            SortOption(type: .createTime, descending: true, allowAscending: true)
                        ],
                        defaultOption: SortOption(type: .title, descending: false, allowAscending: true))
    }
    
    static var shareFolderV2: SpaceSortHelper {
        SpaceSortHelper(listIdentifier: "ShareFolderList",
                        options: [
                            SortOption(type: .title, descending: true, allowAscending: true),
                            SortOption(type: .updateTime, descending: true, allowAscending: true),
                            SortOption(type: .createTime, descending: true, allowAscending: true),
                            SortOption(type: .sharedTime, descending: true, allowAscending: true)
                        ],
                        defaultOption: SortOption(type: .title, descending: false, allowAscending: true))
    }

    static var hiddenFolder: SpaceSortHelper {
        SpaceSortHelper(listIdentifier: "HiddenFolderList",
                        options: [
                            SortOption(type: .title, descending: true, allowAscending: true),
                            SortOption(type: .updateTime, descending: true, allowAscending: true),
                            SortOption(type: .createTime, descending: true, allowAscending: true),
                            SortOption(type: .sharedTime, descending: true, allowAscending: true)
                        ],
                        defaultOption: SortOption(type: .title, descending: false, allowAscending: true))
    }

    static func subFolder(token: String) -> SpaceSortHelper {
        let options = [
            SortOption(type: .title, descending: true, allowAscending: true),
            SortOption(type: .updateTime, descending: true, allowAscending: true),
            SortOption(type: .createTime, descending: true, allowAscending: true),
        ]
        return SpaceSortHelper(listIdentifier: token.encryptToken, // 会打到 log 里
                        options: options,
                        defaultOption: SortOption(type: .title, descending: false, allowAscending: true))
    }

    static var sharedFile: SpaceSortHelper {
        var options = [
            SortOption(type: .updateTime, descending: true, allowAscending: true),
            SortOption(type: .createTime, descending: true, allowAscending: true),
            SortOption(type: .sharedTime, descending: true, allowAscending: true)
        ]
        if UserScopeNoChangeFG.MJ.disableShareEditTimeSort {
            options.removeAll { $0.type == .updateTime }
        }
        return SpaceSortHelper(listIdentifier: "SharedFile",
                               options: options,
                               defaultOption: SortOption(type: .sharedTime, descending: true, allowAscending: true))
    }

    static var personalFileV1: SpaceSortHelper {
        SpaceSortHelper(listIdentifier: "PersonalFileV1",
                        options: [
                            SortOption(type: .updateTime, descending: true, allowAscending: true),
                            SortOption(type: .createTime, descending: true, allowAscending: true)
                        ])
    }

    static var personalFileV2: SpaceSortHelper {
        SpaceSortHelper(listIdentifier: "PersonalFileV2",
                        options: [
                            SortOption(type: .title, descending: true, allowAscending: true),
                            SortOption(type: .updateTime, descending: true, allowAscending: true),
                            SortOption(type: .createTime, descending: true, allowAscending: true)
                        ],
                        defaultOption: SortOption(type: .title, descending: false, allowAscending: true))
    }

    static var personalFolderV2: SpaceSortHelper {
        SpaceSortHelper(listIdentifier: "PersonalFolderV2",
                        options: [
                            SortOption(type: .title, descending: true, allowAscending: true),
                            SortOption(type: .updateTime, descending: true, allowAscending: true),
                            SortOption(type: .createTime, descending: true, allowAscending: true)
                        ],
                        defaultOption: SortOption(type: .title, descending: false, allowAscending: true))
    }

    static var unorganizedFile: SpaceSortHelper {
        SpaceSortHelper(listIdentifier: "unorganizedFile",
                        options: [
                            SortOption(type: .title, descending: true, allowAscending: true),
                            SortOption(type: .updateTime, descending: true, allowAscending: true),
                            SortOption(type: .createTime, descending: true, allowAscending: true)
                        ],
                        defaultOption: SortOption(type: .createTime, descending: true, allowAscending: true))
    }

    static func subordinateRecent(id: String) -> SpaceSortHelper {
        let options = [
            SortOption(type: .lastModifiedTime, descending: true, allowAscending: true)
        ]
        return SpaceSortHelper(listIdentifier: id.encryptToken, // 会打到 log 里
                        options: options,
                               defaultOption: SortOption(type: .lastModifiedTime, descending: false, allowAscending: true))
    }
}
