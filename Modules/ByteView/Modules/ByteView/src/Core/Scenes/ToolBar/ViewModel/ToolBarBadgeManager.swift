//
//  ToolBarBadgeManager.swift
//  ByteView
//
//  Created by YizhuoChen on 2023/6/5.
//

import Foundation
import ByteViewCommon

protocol ToolBarBadgeManagerDelegate: AnyObject {
    func toolBarBadgeDidChange(on itemType: ToolBarItemType)
}

/// ToolBar 红点逻辑管理者。由于 toolbar 上红点种类多，不同场景各自设置红点容易出现覆盖或误删除，
/// 因此所有红点设置都应该以请求的方式向该类发送，由该类决定当前最终显示哪个红点
class ToolBarBadgeManager {
    private static let logger = Logger.ui
    private let listeners = Listeners<ToolBarBadgeManagerDelegate>()

    @RwAtomic
    private var badges: [ToolBarItemType: [ToolBarBadgeType]] = [:]

    func addListener(_ listener: ToolBarBadgeManagerDelegate) {
        listeners.addListener(listener)
    }

    /// 请求显示某种类型的红点
    func requestBadge(_ badgeType: ToolBarBadgeType, from itemType: ToolBarItemType) {
        Self.logger.info("Request badgeType \(badgeType.description) from item \(itemType.rawValue)")
        switch badgeType {
        case .none:
            badges[itemType] = nil
        default:
            if var currentTypes = badges[itemType], !currentTypes.isEmpty {
                if let index = currentTypes.firstIndex(where: { $0.isSameType(with: badgeType) }) {
                    currentTypes[index] = badgeType
                } else {
                    currentTypes.append(badgeType)
                }
                badges[itemType] = currentTypes
            } else {
                badges[itemType] = [badgeType]
            }
        }
        DispatchQueue.main.async {
            self.listeners.forEach { $0.toolBarBadgeDidChange(on: itemType) }
        }
    }

    /// 请求不再展示某种红点
    func requestRemovingBadge(_ badgeType: ToolBarBadgeType, from itemType: ToolBarItemType) {
        Self.logger.info("Request removing badgeType \(badgeType.description) from item \(itemType.rawValue)")
        badges[itemType]?.removeAll(where: { $0.isSameType(with: badgeType) })
        Util.runInMainThread {
            self.listeners.forEach { $0.toolBarBadgeDidChange(on: itemType) }
        }
    }

    /// 当前某个特定类型的 item 上应该展示的红点类型
    func currentBadge(for itemType: ToolBarItemType) -> ToolBarBadgeType {
        return badges[itemType]?.sorted { $0.priority > $1.priority }.first ?? .none
    }

    /// 汇总所有 badges 里的红点类型，得出当前应该展示哪一种。适用于 more 上的红点展示
    func hasMoreBadge(with filterBlock: (ToolBarItemType, ToolBarBadgeType) -> Bool) -> Bool {
        self.badges
            .map { item, badges in (item, badges.max(by: { $0.priority > $1.priority }) ?? .none) }
            .first { (item, badge) in
                if case .text = badge {
                    return false
                } else {
                    return filterBlock(item, badge) && badge != .none
                }
            } != nil
    }
}
