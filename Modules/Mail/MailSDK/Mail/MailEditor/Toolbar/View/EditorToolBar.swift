//
//  EditorToolBar.swift
//  DocsSDK
//
//  Created by 边俊林 on 2019/1/9.
//

import UIKit
import LarkUIKit

protocol EditorToolBarDelegate: AnyObject {
    func EditorToolBar(_ toolBar: EditorToolBar, changeInputView inputView: UIView?)
    func EditorToolBarShouldEndEditing(_ toolBar: EditorToolBar, editMode: EditorToolBar.EditMode, byUser: Bool)
//    func EditorToolBarRequestMailInfo(_ toolBar: EditorToolBar) -> MailInfo?
    func EditorToolBarRequestInvokeScript(_ toolBar: EditorToolBar, script: String)
}

/// 编辑器工具条
class EditorToolBar: UIView {
    weak var delegate: EditorToolBarDelegate?
    // MARK: 📕External Interface
    /// 工具条正常情况下的固有高度
    static var inherentHeight: CGFloat = Const.inherentHeight
    /// 其他Panel使用键盘高度作为自身高度
    var useKeyboardHeight: Bool = true
    /// 设置Panel最小高度，仅当useKeyboardHeight开启时可用
    var minimumPanelHeight: CGFloat = 180
    /// 预估键盘高度，用于当无法获取键盘高度且需要一个大致高度时
    var estimateKeyboardHeight: CGFloat = 260
    /// 开启Taptic Engine反馈
    var useTapticEngine: Bool = true
    /// 当前工具条编辑模式
    private(set) var mode: EditMode = .normal

    var willRestoreByKeyBoard: Bool = false

    // MARK: 📘Data
    private weak var currentPanel: EditorSubToolBarPanel?
    private weak var currentMain: EditorMainToolBarPanel?
    private weak var currentTitleView: UIView?

    private var keyboardHeight: CGFloat = 0
    private var isJustInit: Bool = true
    private var restoreTag: String?
    private var restoreKeyboardHeight: CGFloat?

    // MARK: 📙UI Widget
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 更新键盘的高度，应在每次系统键盘高度更新时设置(不包括Panel类型item的菜单)
    func setKeyboardHeight(_ height: CGFloat) {
        keyboardHeight = height
    }
}

extension EditorToolBar {
    // MARK: 📓Internal Supporting Method
    private func layoutPanel(_ panel: UIView) -> UIView {
        let panelView = panel
        var targetHeight = keyboardHeight
        if targetHeight == 0 { targetHeight = estimateKeyboardHeight }
        targetHeight = max(targetHeight, minimumPanelHeight + Display.bottomSafeAreaHeight)

        let heightConstraints = panelView.constraints.filter { ($0.firstItem === panelView) && ($0.firstAttribute == NSLayoutConstraint.Attribute.height) }
        if  !heightConstraints.isEmpty {
            let constraint = heightConstraints[0]
            constraint.constant = targetHeight
            panelView.layoutIfNeeded()
        }
        panelView.frame = CGRect(origin: .zero, size: CGSize(width: frame.width, height: targetHeight))
        return panelView
    }

    /* ↓↓↓ Compatible with Docs && Sheet ↓↓↓ */
    @inline(__always)
    private func changeInputView(_ panel: UIView?) {
    }

    @inline(__always)
    private func doEndEditing(byUser: Bool? = nil) {
        delegate?.EditorToolBarShouldEndEditing(self, editMode: mode, byUser: byUser ?? false)
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if self.isHidden { return nil }
        return nil
    }
}

extension EditorToolBar {
    enum EditMode {
        /// 标准工具条
        case normal
    }

    struct Const {
        static let itemWidth: CGFloat = 44
        static let imageWidth: CGFloat = 24
        static let itemPadding: CGFloat = 8
        static let horPadding: CGFloat = 7
        static let staticHorPadding: CGFloat = 6
        static let separateWidth: CGFloat = 1
        static let separateVerPadding: CGFloat = 10
        static let inherentHeight: CGFloat = 44
        static let sheetInputViewHeight: CGFloat = 44
        static let iconCellId: String = "iconCellId"
    }
}

extension EditorToolBar {
    func setTitleView(_ titleView: UIView) { }

    func removeTitleView() { }
}

extension EditorToolBar: MailSubToolBarDelegate {
}
