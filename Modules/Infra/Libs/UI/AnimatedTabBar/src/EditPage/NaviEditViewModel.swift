//
//  NaviEditViewModel.swift
//  AnimatedTabBar
//
//  Created by phoenix on 2023/8/1.
//

import Foundation
import LarkTab

enum NaviEditItemType {
    // 快捷导航
    case quick
    // 主导航
    case main
}

final class NaviEditViewModel {
    // 原始数据备份，用于对比是否有变更
    public let mainItemsBackup: [AbstractTabBarItem]
    public let quickItemsBackup: [AbstractTabBarItem]

    public var mainItems: [AbstractTabBarItem]
    public var quickItems: [AbstractTabBarItem]
    let minTabCount: Int
    let maxTabCount: Int
    var tips: String?

    init(mainItems: [AbstractTabBarItem],
         quickItems: [AbstractTabBarItem],
         minTabCount: Int,
         maxTabCount: Int) {
        self.mainItemsBackup = mainItems
        self.quickItemsBackup = quickItems
        self.mainItems = mainItems
        self.quickItems = quickItems
        self.minTabCount = minTabCount
        self.maxTabCount = maxTabCount
    }

    func insert(in type: NaviEditItemType, at indexPath: IndexPath, _ item: AbstractTabBarItem) {
        assert(Thread.isMainThread, "ui data accessible only on main thread")
        switch type {
        case .quick: quickItems.insert(item, at: indexPath.item)
        case .main: mainItems.insert(item, at: indexPath.item)
        default: break
        }
    }

    func remove(in type: NaviEditItemType, at indexPath: IndexPath) {
        assert(Thread.isMainThread, "ui data accessible only on main thread")
        switch type {
        case .quick:
            guard indexPath.item < quickItems.count else { return }
            quickItems.remove(at: indexPath.item)
        case .main:
            guard indexPath.item < mainItems.count else { return }
            mainItems.remove(at: indexPath.item)
        default: break
        }
    }

    // rank前后数据是否变更
    func changed() -> Bool {
        return !mainItems.map { $0.tab }.elementsEqual(mainItemsBackup.map { $0.tab })
            || !quickItems.map { $0.tab }.elementsEqual(quickItemsBackup.map { $0.tab })
    }
}

