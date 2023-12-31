//
//  ProfileFieldTextListCell.swift
//  LarkProfile
//
//  Created by 姚启灏 on 2021/7/7.
//

import Foundation
import UIKit

public final class ProfileFieldTextListItem: ProfileFieldItem {
    public var type: ProfileFieldType

    public var fieldKey: String

    public var title: String

    public var textList: [String]

    public var expandItemDir: [Int: ExpandStatus] = [:] // 记录单个item是否展开
    public var expandAll: Bool = false

    public var enableLongPress: Bool = false

    public init(type: ProfileFieldType = .textList,
                fieldKey: String = "",
                title: String = "",
                textList: [String] = []) {
        self.type = type
        self.fieldKey = fieldKey
        self.title = title
        self.textList = textList
    }
}

public final class ProfileFieldTextListCell: ProfileFieldCell {
    private var textListView: ProfileExpandableView?

    public override class func canHandle(item: ProfileFieldItem) -> Bool {
        guard let cellItem = item as? ProfileFieldTextListItem else {
            return false
        }
        return cellItem.type == .textList
    }

    override func commonInit() {
        super.commonInit()

        guard let cellItem = item as? ProfileFieldTextListItem else {
            return
        }

        var expandItems: [ExpandableItem] = []
        for (index, text) in cellItem.textList.enumerated() {
            let item = ExpandableItem(
                content: text,
                contentColor: Cons.contentColor,
                expandStatus: cellItem.expandItemDir[index] ?? .folded)
            expandItems.append(item)
        }

        var preferredMaxLayoutWidth: CGFloat = -1
        if let tableView = context.tableView {
            preferredMaxLayoutWidth = tableView.bounds.width - Cons.hMargin * 2 - Cons.titleWidth
        }
        let textListView = ProfileExpandableView(
            items: expandItems,
            font: Cons.contentFont,
            expandAll: cellItem.expandAll,
            alignment: isVerticalLayout ? .left : .right,
            preferredMaxLayoutWidth: preferredMaxLayoutWidth,
            expandAllCallback: { [weak self] in
                cellItem.expandAll.toggle()
                self?.context.tableView?.reloadData()
        })
        self.textListView = textListView

        self.stackView.addArrangedSubview(textListView)
    }
}
