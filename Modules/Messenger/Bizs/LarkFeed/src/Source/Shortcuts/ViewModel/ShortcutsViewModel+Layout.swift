//
//  ShortcutsViewModel+Layout.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/7/3.
//

// MARK: layout
import UIKit
import Foundation
extension ShortcutsViewModel {

    // 根据当前机型计算单行最大个数
    var itemMaxNumber: Int {
        if containerWidth <= 0 {
            return 0
        }
        let itemsContentWidth: CGFloat = containerWidth - ShortcutLayout.edgeInset.left - ShortcutLayout.edgeInset.right
        let itemsMaxNum: Int = 1 + Int(floorf(Float((itemsContentWidth - ShortcutLayout.itemWidth) / (ShortcutLayout.itemWidth + ShortcutLayout.minItemSpace))))
        let itemMaxNumber = max(itemsMaxNum, 0)
        return itemMaxNumber
    }

    var maxHeight: CGFloat {
        if dataSource.isEmpty {
            return 0
        }

        // Prevent the devisor being 0.
        var line = 0
        var remainder = 0
        if itemMaxNumber > 0 {
            line = dataSource.count / itemMaxNumber
            remainder = dataSource.count % itemMaxNumber
        }

        if line == 1 && remainder == 0 {
            return ShortcutLayout.singleLineHeight
        }

        return floor(CGFloat(line + 1) * ShortcutLayout.itemHeight + ShortcutLayout.edgeInset.top + ShortcutLayout.edgeInset.bottom)
    }

    var minHeight: CGFloat {
        dataSource.isEmpty ? 0 : ShortcutLayout.singleLineHeight
    }
}
