//
//  SpaceListModifier.swift
//  SKSpace
//
//  Created by Weston Wu on 2021/7/2.
//

import Foundation
import SKCommon
import SKFoundation
import SpaceInterface

protocol SpaceListModifier {
    typealias FilterOption = SpaceFilterHelper.FilterOption
    typealias SortOption = SpaceSortHelper.SortOption
    func handle(entries: [SpaceEntry]) -> [SpaceEntry]
}

private extension SpaceListModifier.SortOption {

    var entrySorter: (SpaceEntry, SpaceEntry) -> Bool {
        switch type {
        case .updateTime:
            return { ($0.editTime ?? 0) > ($1.editTime ?? 0) }
        case .createTime:
            return { ($0.createTime ?? 0) > ($1.createTime ?? 0) }
        case .owner:
            return { ($0.owner ?? "") > ($1.owner ?? "") }
        case .title:
            return { $0.name > $1.name }
        case .lastOpenTime:
            return { ($0.openTime ?? 0) > ($1.openTime ?? 0) }
        case .lastModifiedTime:
            return { ($0.myEditTime ?? 0) > ($1.myEditTime ?? 0) }
        case .allTime:
            return { ($0.activityTime ?? 0) > ($1.activityTime ?? 0) }
        case .sharedTime:
            return { ($0.shareTime ?? 0) > ($1.shareTime ?? 0) }
        case .latestCreated:
            return { ($0.createTime ?? 0) > ($1.createTime ?? 0) }
        case .addedManualOfflineTime:
            return { ($0.addManuOfflineTime ?? 0) > ($1.addManuOfflineTime ?? 0) }
        case .addFavoriteTime:
            return { ($0.favoriteTime ?? 0) > ($1.favoriteTime ?? 0) }
        }
    }
}

private extension SpaceListModifier.FilterOption {
    // 已和后端对齐，后续做成配置下发
    // 参考文档: https://bytedance.feishu.cn/docs/pv34vPnYryXIjMGEyP2jBe
    static let imageTypes = ["jpg", "jpeg", "png", "bmp", "tif", "tiff", "svg", "raw", "gif", "ico", "webp", "heic"]

    var entryFilter: (SpaceEntry) -> Bool {
        switch self {
        case .all:
            return { _ in true }
        case .doc,
             .sheet,
             .bitable,
             .slides,
             .mindnote,
             .wiki,
             .folder,
             .file:
            guard let validTypes = objTypes else {
                assertionFailure()
                return { _ in true }
            }
            if UserScopeNoChangeFG.ZYP.recentListNewFilterEnable {
                return { validTypes.contains($0.realType) }
            } else {
                return { validTypes.contains($0.docsType) }
            }
        }
    }
}

struct SpaceListSortModifier: SpaceListModifier {
    let sortOption: SortOption

    func handle(entries: [SpaceEntry]) -> [SpaceEntry] {
        let sortedEntries: [SpaceEntry]
        if sortOption.descending {
            sortedEntries = entries.sorted(by: sortOption.entrySorter)
        } else {
            let sorter = sortOption.entrySorter
            sortedEntries = entries.sorted { !sorter($0, $1) }
        }
        return sortedEntries
    }
}

struct SpaceListFilterModifier: SpaceListModifier {
    let filterOption: FilterOption

    func handle(entries: [SpaceEntry]) -> [SpaceEntry] {
        entries.filter(filterOption.entryFilter)
    }
}

// 筛选掉精简模式下不显示的文档
struct SpaceLeanModeModifier: SpaceListModifier {
    func handle(entries: [SpaceEntry]) -> [SpaceEntry] {
        let timeLimit = SimpleModeManager.timeLimit
        return entries.filter { entry in
            // 隐藏文件夹
            if entry.type == .folder { return false }
            // 隐藏没打开过的文件
            guard let openTime = entry.openTime else { return false }
            // 隐藏特定时间前打开的文件
            if openTime <= timeLimit { return false }
            return true
        }
    }
}

// 最近列表的特定排序选项需要过滤掉部分文件
struct SpaceRecentListModifier: SpaceListModifier {
    let sortOption: SortOption

    init(sortOption: SortOption) {
        self.sortOption = sortOption
    }

    // 最近列表的特定排序选项需要过滤掉部分文件
    func handle(entries: [SpaceEntry]) -> [SpaceEntry] {
        switch sortOption.type {
        case .lastModifiedTime:
            return entries.filter {
                guard let myEditTime = $0.myEditTime, myEditTime > 0 else { return false }
                return true
            }
        case .latestCreated:
            guard let userID = User.current.info?.userID else { return entries }
            return entries.filter { $0.ownerID == userID }
        default:
            return entries
        }
    }
}

// 组合一系列 modifier
struct SpaceListComplexModifier: SpaceListModifier {
    let subModifiers: [SpaceListModifier]

    init(subModifiers: [SpaceListModifier]) {
        self.subModifiers = subModifiers
    }

    func handle(entries: [SpaceEntry]) -> [SpaceEntry] {
        return subModifiers.reduce(entries) { entries, subModifier in
            subModifier.handle(entries: entries)
        }
    }
}

extension SpaceListComplexModifier: ExpressibleByArrayLiteral {

    init(arrayLiteral subModifiers: SpaceListModifier...) {
        self.subModifiers = subModifiers
    }
}
