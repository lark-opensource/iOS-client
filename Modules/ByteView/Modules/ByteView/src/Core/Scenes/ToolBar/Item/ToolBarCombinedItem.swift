//
//  ToolBarCombinedItem.swift
//  ByteView
//
//  Created by wulv on 2023/10/24.
//

import Foundation

class ToolBarCombinedItem: ToolBarItem {

    var subItems: [ToolBarItem] = [] {
        didSet {
            oldValue.forEach { $0.removeListener(self) }
            subItems.forEach { $0.addListener(self) }
        }
    }

    override var desiredPadLocation: ToolBarItemPadLocation {
        subItems.contains(where: { $0.desiredPadLocation == .inCombined }) ? .center : .none
    }
    override var showTitle: Bool { false }
    override var isSelected: Bool { false }

    /// 由子 item 的 notifyListeners 触发
    func subItemDidChange(_ subItem: ToolBarItem) {
        // 通知上层复合型按钮自身有变化
        notifyListeners()
        notifySizeListeners()
    }
}

extension ToolBarCombinedItem: ToolBarItemDelegate {
    func toolbarItemDidChange(_ item: ToolBarItem) {
        guard let changed = subItems.first(where: { $0.itemType == item.itemType }) else { return }
        subItemDidChange(changed)
    }
}
