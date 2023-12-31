//
//  RankViewModel.swift
//  RankDemo2
//
//  Created by bytedance on 2020/11/27.
//

import Foundation
import LarkTab

public protocol AbstractRankItem {
    var tab: Tab { get }
    var uniqueID: String { get }
}

public extension AbstractRankItem {
    func isCustomIcon() -> Bool {
        return tab.remoteQuickIcon != nil && tab.appType != .native
    }
}

/// 单个app的数据结构
public struct RankItem: AbstractRankItem {
    public let tab: Tab
    public let stateConfig: ItemStateConfig
    public let name: String
    public let primaryOnly: Bool
    public let unmovable: Bool
    public let uniqueID: String
    // 是否支持删除,支持删除的会显示删除按钮
    public let canDelete: Bool

    public init(
        tab: Tab,
        stateConfig: ItemStateConfig,
        name: String,
        primaryOnly: Bool,
        unmovable: Bool,
        uniqueID: String,
        canDelete: Bool = false
    ) {
        self.tab = tab
        self.stateConfig = stateConfig
        self.name = name
        self.primaryOnly = primaryOnly
        self.unmovable = unmovable
        self.uniqueID = uniqueID
        self.canDelete = canDelete
    }
}

extension Int {
    static let mainItemSection = 0
    static let quickItemSection = 1
}

final class RankViewModel {
    private let headerTitles = [
        BundleI18n.AnimatedTabBar.Lark_Legacy_BottomNavigation,
        BundleI18n.AnimatedTabBar.Lark_Legacy_NavigationMore
    ]
    // 原始数据备份，用于对比是否有变更
    public let mainItemsBackup: [RankItem]
    public let quickItemsBackup: [RankItem]

    public var mainItems: [RankItem]
    public var quickItems: [RankItem]
    let minTabCount: Int
    let maxTabCount: Int
    var tips: String?

    init(mainItems: [RankItem],
         quickItems: [RankItem],
         minTabCount: Int,
         maxTabCount: Int) {
        self.mainItemsBackup = mainItems
        self.quickItemsBackup = quickItems
        self.mainItems = mainItems
        self.quickItems = quickItems
        self.minTabCount = minTabCount
        self.maxTabCount = maxTabCount
    }

    func allItems(at section: Int) -> [RankItem] {
        assert(Thread.isMainThread, "ui data accessible only on main thread")
        switch section {
        case .mainItemSection: return mainItems
        case .quickItemSection: return quickItems
        default: return []
        }
    }

    func append(_ item: RankItem, at section: Int) {
        assert(Thread.isMainThread, "ui data accessible only on main thread")
        switch section {
        case .mainItemSection: mainItems.append(item)
        case .quickItemSection: quickItems.append(item)
        default: break
        }
    }

    func remove(at indexPath: IndexPath) {
        assert(Thread.isMainThread, "ui data accessible only on main thread")
        switch indexPath.section {
        case .mainItemSection:
            guard indexPath.row < mainItems.count else { return }
            mainItems.remove(at: indexPath.row)
        case .quickItemSection:
            guard indexPath.row < quickItems.count else { return }
            quickItems.remove(at: indexPath.row)
        default: break
        }
    }

    func headerTitle(at section: Int) -> String? {
        guard section < headerTitles.count else { return nil }
        return headerTitles[section]
    }

    func itemsCount(at section: Int) -> Int {
        assert(Thread.isMainThread, "ui data accessible only on main thread")
        switch section {
        case .mainItemSection: return mainItems.count
        case .quickItemSection: return quickItems.count
        default: return 0
        }
    }

    func itemInfo(in section: Int, at row: Int) -> RankItem? {
        assert(Thread.isMainThread, "ui data accessible only on main thread")
        switch section {
        case .mainItemSection:
            guard row < mainItems.count else { return nil }
            return mainItems[row]
        case .quickItemSection:
            guard row < quickItems.count else { return nil }
            return quickItems[row]
        default: return nil
        }
    }

    func canEdit(in section: Int, at row: Int) -> Bool {
        guard let info = itemInfo(in: section, at: row) else { return false }
        return !info.unmovable
    }

    func canMove(from source: IndexPath, to destination: IndexPath) -> IndexPath {
        // 更多 -> 主导航，且主导航已满
        if source.section == .quickItemSection, destination.section == .mainItemSection, mainItems.count >= maxTabCount {
            // 需要在canMove时记录tips，在松手时Toast
            tips = BundleI18n.AnimatedTabBar.Lark_Legacy_BottomNavigationItemMaxReachedToast(maxTabCount)
            return source
        }
        // 主导航 -> 更多，且主导航无法再移除
        if source.section == .mainItemSection, destination.section == .quickItemSection, mainItems.count <= minTabCount {
            if minTabCount == 1 {
                tips = BundleI18n.AnimatedTabBar.Lark_Legacy_NavigationCantEmptyToast
            } else {
                tips = BundleI18n.AnimatedTabBar.Lark_Legacy_BottomNavigationItemMinimumToast(minTabCount)
            }
            return source
        }
        // 主导航 -> 更多，且不可移出主导航时：不能拖到「更多」里
        if let info = itemInfo(in: source.section, at: source.row), info.primaryOnly,
           source.section == .mainItemSection, destination.section == .quickItemSection {
            return source
        }
        // 置顶cell不能作为目的地
        if let info = itemInfo(in: destination.section, at: destination.row) {
            return info.unmovable ? source : destination
        }
        return destination
    }

    func move(from source: IndexPath, to destination: IndexPath) {
        assert(Thread.isMainThread, "ui data accessible only on main thread")
        switch (source.section, destination.section) {
        case (.mainItemSection, .mainItemSection):
            guard source.row < mainItems.count, destination.row <= mainItems.count else { return }
            let item = mainItems.remove(at: source.row)
            mainItems.insert(item, at: destination.row)
        case (.mainItemSection, .quickItemSection):
            guard source.row < mainItems.count, destination.row <= quickItems.count else { return }
            let item = mainItems.remove(at: source.row)
            quickItems.insert(item, at: destination.row)
        case (.quickItemSection, .quickItemSection):
            guard source.row < quickItems.count, destination.row <= quickItems.count else { return }
            let item = quickItems.remove(at: source.row)
            quickItems.insert(item, at: destination.row)
        case (.quickItemSection, .mainItemSection):
            guard source.row < quickItems.count, destination.row <= mainItems.count else { return }
            let item = quickItems.remove(at: source.row)
            mainItems.insert(item, at: destination.row)
        default: break
        }
    }

    // rank前后数据是否变更
    func changed() -> Bool {
        return !mainItems.map { $0.tab }.elementsEqual(mainItemsBackup.map { $0.tab })
            || !quickItems.map { $0.tab }.elementsEqual(quickItemsBackup.map { $0.tab })
    }
}
