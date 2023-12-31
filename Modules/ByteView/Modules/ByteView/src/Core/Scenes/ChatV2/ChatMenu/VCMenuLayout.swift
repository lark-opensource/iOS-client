//
//  VCMenuLayout.swift
//  ByteView
//
//  Created by chenyizhuo on 2022/2/8.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import RichLabel
import UIKit
import ByteViewUI

protocol VCMenuLayoutDelegate: AnyObject {
    func layoutMenu(on parent: VCMenuViewController, menuSize: CGSize) -> CGPoint
}

class ChatMessageSelectionMenuLayout: VCMenuLayoutDelegate {
    let cell: UITableViewCell
    let targetLabel: LKSelectionLabel

    init(cell: UITableViewCell, targetLabel: LKSelectionLabel) {
        self.cell = cell
        self.targetLabel = targetLabel
    }

    func layoutMenu(on parent: VCMenuViewController, menuSize: CGSize) -> CGPoint {
        var x: CGFloat = 0
        // 起始游标及结束游标在 menuView 中的位置
        let startC = targetLabel.convert(targetLabel.startCursor.rect, to: parent.view)
        let endC = targetLabel.convert(targetLabel.endCursor.rect, to: parent.view)

        if targetLabel.inSelectionMode && startC.minY == endC.minY {
            // 如果在选中态，且游标位于同一行，则按当前选中范围居中布局
            x = startC.minX + (endC.maxX - startC.minX) / 2 - menuSize.width / 2
        } else {
            // 非选中态（即首次选中，默认全选），或者选中范围跨行，则按整个 label 居中显示
            let frameInParent = targetLabel.convert(targetLabel.bounds, to: parent.view)
            x = frameInParent.midX - menuSize.width / 2
        }

        var y: CGFloat = 0

        let chatCellInset: CGFloat = 8
        let menuOffset: CGFloat = 4
        let isRegular = Display.pad && VCScene.rootTraitCollection?.horizontalSizeClass == .regular
        let editBottom = isRegular ? 0 : VCScene.safeAreaInsets.bottom
        let bottomMargin = ChatMessageEditView.Layout.MinHeight + editBottom
        let selectionFrame: CGRect

        if !targetLabel.inSelectionMode {
            // 未选中状态，默认全选，直接以整个 label 为基准来布局
            selectionFrame = parent.view.convert(targetLabel.frame, from: targetLabel.superview).inset(by: UIEdgeInsets(top: -chatCellInset, left: 0, bottom: -chatCellInset, right: 0))
        } else {
            selectionFrame = CGRect(x: targetLabel.frame.minX, y: startC.minY - chatCellInset, width: targetLabel.frame.width, height: endC.maxY - startC.minY + 2 * chatCellInset)
        }

        if selectionFrame.minY - menuSize.height - menuOffset > 0 {
            // 1. 判断上方是否有足够的空间
            y = selectionFrame.minY - menuSize.height - menuOffset
        } else if selectionFrame.maxY + menuSize.height + menuOffset <= parent.view.bounds.maxY - bottomMargin {
            // 2. 其次判断能否展示在下方
            y = selectionFrame.maxY + menuOffset
        } else {
            // 3. 上方下方都不能完全展示，展示在中间
            let top = max(0, selectionFrame.minY)
            let bottom = min(parent.view.bounds.maxY - bottomMargin, selectionFrame.maxY)
            y = (top + bottom - menuSize.height) / 2
        }

        return CGPoint(x: x, y: y)
    }
}
