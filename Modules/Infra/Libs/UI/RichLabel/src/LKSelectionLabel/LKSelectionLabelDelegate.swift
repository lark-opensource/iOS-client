//
//  LKSelectionLabelDelegate.swift
//  LarkUIKit
//
//  Created by qihongye on 2018/12/26.
//

import UIKit
import Foundation
public protocol LKSelectionLabelDelegate: AnyObject {
    func selectionDragModeUpdate(_ inDragMode: Bool)
    func selectionRangeDidUpdate(_ range: NSRange)
    func selectionRangeDidSelected(
        _ range: NSRange,
        didSelectedAttrString: NSAttributedString,
        didSelectedRenderAttributedString: NSAttributedString
    )

    /// 用户自定义 SelectionLabel 复制操作文案
    /// 如果返回 nil，则直接使用属性字符串 string 属性作为默认复制文案
    func selectionRangeText(
        _ range: NSRange,
        didSelectedAttrString: NSAttributedString,
        didSelectedRenderAttributedString: NSAttributedString
    ) -> String?

    /// 是否需要响应复制快捷键, 返回 true 则会把 selectedText 设置到设置到剪贴板中
    func selectionRangeHandleCopy(selectedText: String) -> Bool

    /// selection label 开始 drag interaction 手势 回调
    func selectionLabelBeginDragInteraction(label: LKSelectionLabel)

    /// selection label 通过鼠标拖选进入 SelectionMode 回调
    func selectionLabelWillEnterSelectionModeByPointerDrag(label: LKSelectionLabel)
}

extension LKSelectionLabelDelegate {
    public func selectionDragModeUpdate(_ inDragMode: Bool) {
    }

    public func selectionRangeDidUpdate(_ range: NSRange) {
    }

    public func selectionRangeDidSelected(
        _ range: NSRange,
        didSelectedAttrString: NSAttributedString,
        didSelectedRenderAttributedString: NSAttributedString) {
    }

    public func selectionRangeText(
        _ range: NSRange,
        didSelectedAttrString: NSAttributedString,
        didSelectedRenderAttributedString: NSAttributedString
    ) -> String? {
        return nil
    }

    public func selectionRangeHandleCopy(selectedText: String) -> Bool {
        return true
    }

    public func selectionLabelBeginDragInteraction(label: LKSelectionLabel) {
    }

    public func selectionLabelWillEnterSelectionModeByPointerDrag(label: LKSelectionLabel) {
    }
}
