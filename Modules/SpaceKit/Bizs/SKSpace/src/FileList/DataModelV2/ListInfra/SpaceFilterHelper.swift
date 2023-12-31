//
//  SpaceFilterHelper.swift
//  SKSpace
//
//  Created by Weston Wu on 2021/6/30.
//

import Foundation
import SKCommon
import SKFoundation
import SKResource
import LarkCache
import SpaceInterface

// 为单测抽离依赖
protocol SpaceListConfigCache {
    func set(data: Data, for key: String)
    func data(by key: String) -> Data?
}

extension LarkCache.Cache: SpaceListConfigCache {
    func set(data: Data, for key: String) {
        set(object: data, forKey: key)
    }
    func data(by key: String) -> Data? {
        object(forKey: key)
    }
}

extension SpaceFilterHelper {

    enum FilterOption: String, Codable, Equatable, CaseIterable {
        case all
        case doc
        case sheet
        case bitable
        case slides
        case mindnote
        case file
        case wiki
        case folder

        var reportName: String {
            switch self {
            case .all:
                return "all"
            case .file:
                return "file"
            case .doc:
                return "doc"
            case .sheet:
                return "sheet"
            case .bitable:
                return "bitable"
            case .slides:
                return "slides"
            case .mindnote:
                return "mindnote"
            case .wiki:
                return "wiki"
            case .folder:
                return "folder"
            }
        }

        var reportNameV2: String {
            switch self {
            case .all:
                return "all"
            case .file:
                return "drive"
            case .doc:
                return "docs"
            case .sheet:
                return "sheets"
            case .bitable:
                return "bitable"
            case .slides:
                return "slides"
            case .mindnote:
                return "mindnotes"
            case .wiki:
                return "wiki"
            case .folder:
                return "folder"
            }
        }

        // obj_type 字段取值，以及本地过滤时包含的 types
        var objTypes: [DocsType]? {
            switch self {
            case .all:
                return nil
            case .doc:
                return [.doc, .docX]
            case .sheet:
                return [.sheet]
            case .bitable:
                return [.bitable]
            case .slides:
                return [.slides]
            case .mindnote:
                return [.mindnote]
            case .file:
                return [.file]
            case .wiki:
                return [.wiki]
            case .folder:
                return [.folder]
            }
        }

        var filterParams: [String: Any] {
            [:]
        }

        var filterQuery: String? {
            guard let objTypes = objTypes else { return nil }
            return objTypes.map { "obj_type=\($0.rawValue)" }.joined(separator: "&")
        }

        var optionEnabled: Bool {
            switch self {
            case .all:
                return true
            case .doc:
                return DocsType.doc.enabledByFeatureGating
            case .sheet:
                return DocsType.sheet.enabledByFeatureGating
            case .bitable:
                return DocsType.bitable.enabledByFeatureGating
            case .slides:
                return DocsType.slides.enabledByFeatureGating
            case .mindnote:
                return DocsType.mindnote.enabledByFeatureGating
            case .file:
                return DocsType.file.enabledByFeatureGating
            case .wiki:
                return DocsType.wiki.enabledByFeatureGating
            case .folder:
                return DocsType.folder.enabledByFeatureGating
            }
        }

        var legacyType: FilterItem.FilterType {
            switch self {
            case .all:
                return .all
            case .doc:
                return .doc
            case .sheet:
                return .sheet
            case .bitable:
                return .bitable
            case .slides:
                return .slides
            case .mindnote:
                return .mindnote
            case .file:
                return .file
            case .wiki:
                return .wiki
            case .folder:
                return .folder
            }
        }

        public var displayName: String {
            switch self {
            case .all:
                return BundleI18n.SKResource.Doc_List_Filter_All
            case .file:
                return BundleI18n.SKResource.LarkCCM_Docs_LocalFile_Menu_Mob
            case .doc:
                return  BundleI18n.SKResource.Doc_Facade_Document
            case .sheet:
                return  BundleI18n.SKResource.Doc_Facade_CreateSheet
            case .bitable:
                return  BundleI18n.SKResource.Doc_List_Filter_Bitable
            case .slides:
                return  BundleI18n.SKResource.LarkCCM_Slides_ProductName
            case .mindnote:
                return  BundleI18n.SKResource.Doc_Facade_MindNote
            case .wiki:
                return BundleI18n.SKResource.Doc_Facade_Wiki
            case .folder:
                return BundleI18n.SKResource.Doc_Facade_Folder
            }
        }
    }
}

struct SpaceFilterHelper {

    let listIdentifier: String
    private let cacheKey: String
    private(set) var selectedIndex: Int
    var selectedOption: FilterOption {
        guard selectedIndex < options.count else {
            spaceAssertionFailure("filter option index out of range")
            return .all
        }
        return options[selectedIndex]
    }
    let options: [FilterOption]
    let defaultOption: FilterOption

    // 表示 selectedOption 与默认值相比是否发生变化
    var changed: Bool {
        selectedOption != options.first
    }

    private let configCache: SpaceListConfigCache

    private init(listIdentifier: String, options: [FilterOption]) {
        self.init(listIdentifier: listIdentifier, options: options, configCache: CacheService.configCache)
    }

    // options 不能为空，第一个 option 是默认选项
    init(listIdentifier: String, options: [FilterOption], configCache: SpaceListConfigCache) {
        assert(!options.isEmpty, "options cannot be empty")
        self.listIdentifier = listIdentifier
        cacheKey = "space.filter." + listIdentifier
        selectedIndex = 0
        self.options = options
        defaultOption = options.first ?? .all
        self.configCache = configCache
    }

    // 从 configCache 恢复曾经保存的选项，区分 user 和 listIdentifier
    mutating func restore() {
        guard let data = configCache.data(by: cacheKey) else {
            DocsLogger.info("space.filter.helper --- restore filter option failed, data not found", extraInfo: ["list-id": listIdentifier])
            return
        }
        do {
            let option = try JSONDecoder().decode(FilterOption.self, from: data)
            guard let optionIndex = options.firstIndex(of: option) else {
                DocsLogger.error("space.filter.helper --- saved option not found in options", extraInfo: ["list-id": listIdentifier, "option": option, "options": options])
                return
            }
            selectedIndex = optionIndex
            DocsLogger.info("space.filter.helper --- filter option restored", extraInfo: ["list-id": listIdentifier, "option": option])
        } catch {
            DocsLogger.error("space.filter.helper --- decode filter option failed", extraInfo: ["list-id": listIdentifier], error: error)
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
                DocsLogger.error("space.filter.helper --- encode sort option failed", extraInfo: ["list-id": listID], error: error)
            }
        }
    }

    mutating func update(filterIndex: Int) {
        guard filterIndex < options.count else {
            DocsLogger.error("space.filter.helper --- invalid filterIndex", extraInfo: ["filterIndex": filterIndex, "optionsCount": options.count])
            selectedIndex = 0
            return
        }
        selectedIndex = filterIndex
    }

    mutating func update(selectedOption: FilterOption) {
        guard let index = options.firstIndex(of: selectedOption) else {
            DocsLogger.error("space.filter.helper --- new selected option type not in options!", extraInfo: ["list-id": listIdentifier, "option": selectedOption, "options": options])
            return
        }
        self.selectedIndex = index
    }
}

// UI
extension SpaceFilterHelper {

    var legacyItemsForFilterPanel: [FilterItem] {
        let index = selectedIndex
        var items = options.map { FilterItem(isSelected: false, filterType: $0.legacyType) }
        var selectedItem = items[index]
        selectedItem.isSelected = true
        items[index] = selectedItem
        return items
    }

    var defaultLegacyItemsForFilterPanel: [FilterItem] {
        var items = options.map { FilterItem(isSelected: false, filterType: $0.legacyType) }
        var defaultItem = items[0]
        defaultItem.isSelected = true
        items[0] = defaultItem
        return items
    }
}

private extension SpaceFilterHelper.FilterOption {

    static var recentOptions: [Self] {
        if UserScopeNoChangeFG.ZYP.recentListNewFilterEnable {
            return [.all, .doc, .sheet, .slides, .bitable, .mindnote, .file]
        } else {
            return [.all, .doc, .sheet, .slides, .bitable, .mindnote, .file, .wiki]
        }
    }
    // 和最近列表相同
    static var favoritesOptions: [Self] { recentOptions }
    
    static var bitableFavoritesOptions: [Self] {
        if UserScopeNoChangeFG.ZYP.recentListNewFilterEnable {
            return [.all, .bitable]
        } else {
            return [.all, .bitable, .wiki]
        }
    }
    
    static var offLineOptions: [Self] {
        var options: [Self] = [.all, .doc, .sheet, .file]
        /// wiki支持离线FG打开时，筛选面板中添加wiki过滤选项
        if !UserScopeNoChangeFG.ZYP.recentListNewFilterEnable {
            options.append(.wiki)
        }
        return options
    }
    // 没有 wiki
    static var personalFileOptionsV1: [Self] {
        return [.all, .doc, .sheet, .slides, .bitable, .mindnote, .file]
    }
    // 和我的空间v1相同
    static var sharedFileOptionsV1: [Self] { personalFileOptionsV1 }
    // 没有 wiki，多了 folder
    static var sharedFileOptionsV2: [Self] {
        return [.all, .doc, .sheet, .slides, .bitable, .mindnote, .file, .folder]
    }
    // 没有folder
    static var sharedFileOptionsV3: [Self] {
        [.all, .doc, .sheet, .slides, .bitable, .mindnote, .file]
    }
}

extension SpaceFilterHelper {
    static var recent: Self {
        // 过滤掉 FG 禁用的类型
        let availableOptions = FilterOption.recentOptions.filter(\.optionEnabled)
        return SpaceFilterHelper(listIdentifier: "RecentList", options: availableOptions)
    }

    static var spaceTabRecent: Self {
        return SpaceFilterHelper(listIdentifier: "SpaceTabRecentList", options: [.all])
    }

    static var favorites: Self {
        // 过滤掉 FG 禁用的类型
        let availableOptions = FilterOption.favoritesOptions.filter(\.optionEnabled)
        return SpaceFilterHelper(listIdentifier: "Favorites", options: availableOptions)
    }
    
    static var bitableFavorites: Self {
        let availableOptions = FilterOption.bitableFavoritesOptions.filter(\.optionEnabled)
        return SpaceFilterHelper(listIdentifier: "BitableFavorites", options: availableOptions)
    }
    
    static var offLine: Self {
        let availableOptions = FilterOption.offLineOptions.filter(\.optionEnabled)
        return SpaceFilterHelper(listIdentifier: "MOFilesService", options: availableOptions)
    }

    static var sharedFileV1: Self {
        let availableOptions = FilterOption.sharedFileOptionsV1.filter(\.optionEnabled)
        return SpaceFilterHelper(listIdentifier: "SharedFileV1", options: availableOptions)
    }

    static var sharedFileV2: Self {
        let availableOptions = FilterOption.sharedFileOptionsV2.filter(\.optionEnabled)
        return SpaceFilterHelper(listIdentifier: "SharedFileV2", options: availableOptions)
    }
    
    static var sharedFileV3: Self {
        let availableOptions = FilterOption.sharedFileOptionsV3.filter(\.optionEnabled)
        return SpaceFilterHelper(listIdentifier: "SharedFileV3", options: availableOptions)
    }

    static var personalFileV1: Self {
        let availableOptions = FilterOption.personalFileOptionsV1.filter(\.optionEnabled)
        return SpaceFilterHelper(listIdentifier: "PersonalFileV1", options: availableOptions)
    }
    // 个人空间V2不支持过滤
    static var personalFileV2: Self {
        return SpaceFilterHelper(listIdentifier: "PersonalFileV2", options: [.all])
    }

    // 个人空间V2不支持过滤
    static var personalFolderV2: Self {
        return SpaceFilterHelper(listIdentifier: "PersonalFolderV2", options: [.all])
    }

    // 未整理列表不支持过滤
    static var unorganizedFile: Self {
        return SpaceFilterHelper(listIdentifier: "unorganizedFile", options: [.all])
    }
    
    // bitable home页面
    static var bitable: Self {
        return SpaceFilterHelper(listIdentifier: "bitable", options: [.bitable])
    }

    static func subordinateRecent(id: String) -> Self {
        // 过滤掉 FG 禁用的类型
        let availableOptions = FilterOption.recentOptions.filter(\.optionEnabled)
        return SpaceFilterHelper(listIdentifier: id.encryptToken, options: availableOptions)
    }
}
