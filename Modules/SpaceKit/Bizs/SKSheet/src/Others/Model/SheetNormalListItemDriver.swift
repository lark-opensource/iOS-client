//
//  NormalListItemDriver.swift
//  SpaceKit
//
//  Created by Webster on 2019/9/29.
//

import Foundation
import SKCommon
import SKUIKit

enum SheetFilterExpandType: String {
    case single
    case text
    case range
}

class SheetNormalListItemDriver: SheetSpecialFilterDriver {
    private var listItem: SheetFilterInfo.NormalListItem
    private var filterType: SheetFilterType
    private var referWidth = SKDisplay.activeWindowBounds.width
    var identifier: String {
        return listItem.identifier
    }

    var title: String {
        return listItem.title ?? ""
    }

    var hitValue: String? {
        return listItem.colorValue
    }

    var expandType: SheetSpecialFilterView.ExpandType {
        if isNoneItem {
            return .nothing
        } else if filterType == .byColor {
            return .colors
        } else if let type = SheetFilterExpandType(rawValue: listItem.type ?? "") {
            switch type {
            case .single, .text:
                return .text
            case .range:
                return .textRange
            }
        }
        return .nothing
    }

    var isExpand: Bool {
        get { return listItem.select }
        set { listItem.select = newValue }
    }

    var valueList: [String] {
        if filterType == .byColor {
            return listItem.colors ?? [String]()
        } else {
            return listItem.conditionValue ?? [String]()
        }
    }

    // 不展开时每个 item 的高度
    var normalHeight: CGFloat {
        return 48
    }

    var expandHeight: CGFloat {
        guard !isNoneItem else { return normalHeight }
        switch filterType {
        case .byColor:
            let colorWellMargin: CGFloat = SheetSpecialFilterView.sectionPadding
            let itemsCount = CGFloat(listItem.colors?.count ?? 1)
            let itemLength: CGFloat = SheetSpecialFilterView.colorItemWidth + 6
            let itemSpacing: CGFloat
            let numberOfItemsPerLine: CGFloat
            if SKDisplay.pad {
                itemSpacing = SheetSpecialFilterView.colorItemSpacingForPad
                let remainder = (referWidth - 2 * colorWellMargin - itemLength).truncatingRemainder(dividingBy: itemSpacing + itemLength)
                numberOfItemsPerLine = 1 + floor((referWidth - 2 * colorWellMargin - itemLength - remainder) / (itemSpacing + itemLength))
            } else {
                numberOfItemsPerLine = CGFloat(SheetSpecialFilterView.numberOfColorItemsPerLineForPhone)
                itemSpacing = (referWidth - 2 * colorWellMargin - numberOfItemsPerLine * itemLength) / (numberOfItemsPerLine - 1)
            }
            let numberOfLines: CGFloat = ceil(itemsCount / numberOfItemsPerLine)
            return normalHeight + numberOfLines * itemLength + (numberOfLines - 1) * itemSpacing + colorWellMargin
        default:
            return normalHeight + 40 + SheetSpecialFilterView.sectionPadding // 40 是输入框的高度
        }
    }

    init(item: SheetFilterInfo.NormalListItem, type: SheetFilterType, referWidth: CGFloat) {
        self.listItem = item
        self.filterType = type
        self.referWidth = referWidth
    }

    var isNoneItem: Bool {
        return SheetFilterInfo.JSIdentifier.noneIdentitiers.contains(listItem.identifier)
    }
}
