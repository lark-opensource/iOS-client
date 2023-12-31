//
//  HashTagDetailDescriptionLayout.swift
//  Moment
//
//  Created by liluobin on 2021/7/19.
//

import Foundation
import UIKit

final class HashTagDescriptionItem {
    let title: String
    let font: UIFont
    var frame: CGRect = .zero
    var isHidden = false
    init(title: String, font: UIFont = UIFont.systemFont(ofSize: 12, weight: .bold)) {
        self.title = title
        self.font = font
    }
}

final class HashTagDetailDescriptionLayout {
    enum Style: Equatable {
        case oneLine
        case twoLine(oneItemOnFristLine: Bool)
        case threeLine
    }
    let separationItemWidth: CGFloat = 19
    let itemCount: Int = 3

    var style: Style = .oneLine
    var avatarViewSize: CGSize = .zero

    var firstItemLeftSpace: CGFloat {
        return avatarViewSize.width == 0 ? 0 : 6
    }

    var maxWidth: CGFloat {
        return UIScreen.main.bounds.size.width - 16 * 2
    }
    func calculateForItems(_ items: [HashTagDescriptionItem]) {
        if items.count != itemCount {
            return
        }
        defer {
            updateItemsFrame(items)
        }
        var contentWidth = avatarViewSize.width + firstItemLeftSpace
        items.forEach { (item) in
            item.frame.size.width = item.title.isEmpty ? 0 : min(MomentsDataConverter.widthForString(item.title, font: item.font), maxWidth)
            item.frame.size.height = avatarViewSize.height
            contentWidth += item.frame.width
            if item.frame.size.width != 0 {
                contentWidth += CGFloat(items.count - 1) * separationItemWidth
            }
        }
        /// 减去多加的一次
        contentWidth -= separationItemWidth
        /// 3个可以放在一行
        guard contentWidth > maxWidth else {
            style = .oneLine
            return
        }
        /// 如果最后一个item为空
        if items[2].frame.width == 0 {
            style = .twoLine(oneItemOnFristLine: true)
            return
        }

        contentWidth -= (items[2].frame.width + separationItemWidth)
        /// 2个可以放在第一行
        guard contentWidth > maxWidth else {
            style = .twoLine(oneItemOnFristLine: false)
            return
        }

        contentWidth -= (items[1].frame.width + separationItemWidth)
        if contentWidth > maxWidth {
            items.first?.frame.size.width = maxWidth - avatarViewSize.width - firstItemLeftSpace
        }
        if items[1].frame.width + items[2].frame.width + separationItemWidth > maxWidth {
            style = .threeLine
        } else {
            style = .twoLine(oneItemOnFristLine: true)
        }
    }

    func updateItemsFrame(_ items: [HashTagDescriptionItem]) {
        switch style {
        case .oneLine:
            for (idx, item) in items.enumerated() {
                if idx == 0 {
                    item.frame.origin.x = avatarViewSize.width + firstItemLeftSpace
                } else {
                    item.frame.origin.x = items[idx - 1].frame.maxX + separationItemWidth
                }
                item.frame.origin.y = 0
            }
        case .twoLine(let oneItemOnFristLine):
            if oneItemOnFristLine {
                for (idx, item) in items.enumerated() {
                    if idx == 0 {
                        item.frame.origin.x = avatarViewSize.width + firstItemLeftSpace
                        item.frame.origin.y = 0
                    } else {
                        item.frame.origin.y = items[0].frame.maxY + 8
                        item.frame.origin.x = idx == 1 ? 0 : items[idx - 1].frame.maxX + separationItemWidth
                    }
                }
            } else {
                for (idx, item) in items.enumerated() {
                    if idx == 2 {
                        item.frame.origin.y = items[idx - 1].frame.maxY + 8
                        item.frame.origin.x = 0
                    } else {
                        item.frame.origin.y = 0
                        item.frame.origin.x = idx == 0 ? avatarViewSize.width + firstItemLeftSpace : items[idx - 1].frame.maxX + separationItemWidth
                    }
                }
            }
        case .threeLine:
            for (idx, item) in items.enumerated() {
                if idx == 0 {
                    item.frame.origin.x = avatarViewSize.width + firstItemLeftSpace
                    item.frame.origin.y = 0
                } else {
                    item.frame.origin.x = 0
                    item.frame.origin.y = items[idx - 1].frame.maxY + 8
                }
            }
            return
        }
    }

    func insertSeparationItemFor(items: [HashTagDescriptionItem]) -> [HashTagDescriptionItem] {
        guard items.count == itemCount else {
            return []
        }
        var newItems = items
        let separationItems: [HashTagDescriptionItem] = [HashTagDescriptionItem(title: "·",
                                                                                font: UIFont.systemFont(ofSize: 18, weight: .bold)),
                                                         HashTagDescriptionItem(title: "·",
                                                                                font: UIFont.systemFont(ofSize: 18, weight: .bold))]
        separationItems.forEach { $0.isHidden = true }

        switch style {
        case .oneLine:
            for idx in 0..<(items.count - 1) {
                let separationItem = separationItems[idx]
                separationItem.frame = CGRect(x: items[idx].frame.maxX, y: 0, width: separationItemWidth, height: avatarViewSize.height)
                separationItem.isHidden = false
            }
        case .threeLine:
            break
        case .twoLine(let oneItemOnFristLine):
            let relatedItem: HashTagDescriptionItem
            let separationItem = separationItems.last
            separationItem?.isHidden = false
            if oneItemOnFristLine {
                relatedItem = items[1]
            } else {
                relatedItem = items[0]
            }
            separationItem?.frame = CGRect(x: relatedItem.frame.maxX, y: relatedItem.frame.minY, width: separationItemWidth, height: avatarViewSize.height)
        }

        if items[itemCount - 1].frame.width == 0 {
            separationItems.last?.isHidden = true
        }
        newItems.insert(separationItems[0], at: 1)
        newItems.insert(separationItems[1], at: 3)
        return newItems
    }
}
