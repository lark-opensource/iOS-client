//
//  KeyboardPanelFontManager.swift
//  LarkBaseKeyboard
//
//  Created by liluobin on 2023/4/14.
//

import UIKit
import LarkKeyboardView
import EditTextView

public class KeyboardFontPanelItemConfig {

    /// 默认是nomal 没有特殊情况可以不实现
    public var getFontBarSpaceStyle: (() -> FontToolBar.ButtonSpace)?

    let itemsTintColor: UIColor?

    var inputTextView: LarkEditTextView

    var keyboardPanel: KeyboardPanel

    weak var delegate: KeyboardPanelFontManagerDelegate?

    public init(getFontBarSpaceStyle: (() -> FontToolBar.ButtonSpace)? = nil,
         itemsTintColor: UIColor?,
         inputTextView: LarkEditTextView,
         keyboardPanel: KeyboardPanel,
         delegate: KeyboardPanelFontManagerDelegate? = nil) {
        self.getFontBarSpaceStyle = getFontBarSpaceStyle
        self.itemsTintColor = itemsTintColor
        self.inputTextView = inputTextView
        self.keyboardPanel = keyboardPanel
        self.delegate = delegate
    }
}

public protocol KeyboardPanelFontManagerDelegate: AnyObject {
    func attributeTypeFor(_ type: FontActionType, selected: Bool)
    func fontItemClick()
    func willShowFontActionBarWithTypes(_ types: [FontActionType], style: FontBarStyle, text: NSAttributedString?)
}

public class KeyboardPanelFontManager {

    let config: KeyboardFontPanelItemConfig

    public lazy var inputManager: PostInputManager = {
        let mgr = PostInputManager(inputTextView: self.inputTextView)
        mgr.addParagraphStyle()
        return mgr
    }()

    /// 当光标修改的时候，是否需要隐藏bar
    private var isNeedDissmissFontbar = true
    private var changeSelectionFromPaste = false
    private var canDynamicHiddenFontBar: Bool { fontToolBar?.style == FontBarStyle.dynamic }
    private var isShowFontToolBar: Bool { fontToolBar != nil }
    private var textLength: Int = 0
    private var hasSetDelegate = false
    private lazy var fontBarItemTypes: [LarkBaseKeyboard.FontActionType] = [.bold, .strikethrough, .italic, .underline]

    public var fontToolBar: FontToolBar?

    private var inputTextView: LarkEditTextView { self.config.inputTextView }

    private var keyboardPanel: KeyboardPanel { self.config.keyboardPanel }

    public init(config: KeyboardFontPanelItemConfig) {
        self.config = config
    }

    func didCreatePanelItem() -> InputKeyboardItem? {
        return LarkKeyboard.buildFont(iconColor: config.itemsTintColor) { [weak self] in
            let itemTypes: [FontActionType] = [.goback, .bold, .strikethrough, .italic, .underline]
            self?.showFontActionBarWithTypes(itemTypes, style: .static)
            self?.config.delegate?.fontItemClick()
            return false
        }
    }

    /// 输入框粘贴文字时候调用，一般在FontinputHandler回调里面处理
    func onChangeSelectionFromPaste() {
        self.changeSelectionFromPaste = true
    }

    /// 输入框的文字改变时候触发
    func onTextViewLengthChange(_ length: Int) {
        self.textLength = length
    }

    public func updateFontBarSpaceStyle(_ space: FontToolBar.ButtonSpace) {
        self.fontToolBar?.buttonSpace =  space
    }

    public func hideFontActionBar() {
        /// 如果没有fontBar直接return
        if self.fontToolBar == nil { return }
        // 更新约束来展示动画
        self.fontToolBar?.snp.updateConstraints { make in
            make.top.equalTo(self.keyboardPanel.buttonWrapper.snp.bottom)
        }
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.keyboardPanel.buttonWrapper.layoutIfNeeded()
            self?.fontToolBar?.alpha = 0
        } completion: { [weak self] _ in
            guard let self = self else { return }
            self.fontToolBar?.removeFromSuperview()
            self.fontToolBar = nil
        }
    }

    public func updateWithUIWithFontBarStatusItem(_ status: FontToolBarStatusItem) {
        inputManager.updateDefaultTypingAttributesWithStatus(status)
        if status.style == .static {
            updateKeyboardViewFontBarWithStatus(status)
        } else if status.style == nil {
            hideFontActionBar()
        }
    }

    public func updateInputTextViewStyle () {
        updateTextViewFontStyle(inputTextView)
    }

    public func getFontBarStatusItem() -> FontToolBarStatusItem? {
        return self.fontToolBar?.getCurrentStatusItem()
    }

    func showFontActionBarWithTypes(_ types: [FontActionType],
                                    style: FontBarStyle,
                                    text: NSAttributedString? = nil) {
        self.config.delegate?.willShowFontActionBarWithTypes(types, style: style, text: text)
        /// 用户拖动光标，不停改变选中区域, 会触发这里
        if fontToolBar != nil {
            updateFontBarWith(text: text)
            return
        }
        if !self.inputTextView.isFirstResponder {
            self.inputTextView.becomeFirstResponder()
        }
        let height = keyboardPanel.panelTopBarHeight
        let buttonSpace: FontToolBar.ButtonSpace = self.config.getFontBarSpaceStyle?() ?? .normal
        let bar = FontToolBar(itemTypes: types, style: style, height: height, buttonSpace: buttonSpace) { [weak self] (btn) in
            self?.attributeTypeFor(btn.type, selected: btn.isSelected)
        }
        bar.backgroundColor = UIColor.ud.bgBodyOverlay
        keyboardPanel.buttonWrapper.addSubview(bar)
        layoutFontBarNeedAnimation(bar: bar, needLayout: true)

        // fontbar出现动画： buttonWrapper 按钮渐隐, fontbar出现
        UIView.animate(withDuration: 0.3) { [weak self] in
            // 改变非发送按钮的alpha值
            self?.keyboardPanel.buttons.forEach({ button in
                if button.key != KeyboardItemKey.send.rawValue {
                    button.alpha = 0
                }
            })
            self?.keyboardPanel.buttonWrapper.layoutIfNeeded()
        } completion: { [weak self] _ in
            // 重置非发送按钮的alpha值
            self?.keyboardPanel.buttons.forEach({ button in
                if button.key != KeyboardItemKey.send.rawValue {
                    button.alpha = 1
                }
            })
        }
        self.fontToolBar = bar
        /// 选中文字触发 dynamic 需要取公共的样式
        /// 点击触发`static` 直接从defaultTypingAttributes获取
        if style == .dynamic {
            updateFontBarWith(text: text)
        } else {
            updateActionBarStatus(inputManager.getInputViewFontStatus())
        }
    }

    func updateFontBarWith(text: NSAttributedString? = nil) {
        guard let bar = fontToolBar else {
            return
        }
        if let text = text {
            bar.updateBarStatusWithAttributeStr(text)
        } else {
            let attr: NSAttributedString
            if inputTextView.selectedRange.location == 0 {
                attr = NSAttributedString(string: "")
            } else {
                let location = inputTextView.selectedRange.location - 1
                attr = inputTextView.attributedText.attributedSubstring(from: NSRange(location: location, length: 1))
            }
            bar.updateBarStatusWithAttributeStr(attr)
        }
    }

    open func attributeTypeFor(_ type: FontActionType, selected: Bool) {
        switch type {
        case .goback:
            hideFontActionBar()
        case .bold, .italic, .strikethrough, .underline:
            if inputTextView.selectedRange.length > 0 {
                let exceptRanges = PostInputManager.unsupportSelectedRangesForTextView(inputTextView)
                if PostInputManager.updateSelectedRangeIfNeedWithExceptRanges(exceptRanges, textView: inputTextView) {
                    return
                }
                let attr: NSAttributedString
                if selected {
                    attr = inputManager.addAtttibuteForRange(inputTextView.selectedRange, type: type)
                } else {
                    attr = inputManager.removeAttributeForRange(inputTextView.selectedRange, type: type)
                }
                let offset = inputTextView.contentOffset
                let selectedRange = inputTextView.selectedRange
                /// 给某段文字添加属性后，重新赋值 导致光标丢失。此时不需要移除fontbar
                isNeedDissmissFontbar = false
                inputTextView.attributedText = attr
                isNeedDissmissFontbar = true
                inputTextView.selectedRange = selectedRange
                inputTextView.setContentOffset(offset, animated: false)
            } else {
                inputManager.updateDefaultTypingAttributesWithType(type, apply: selected)
            }
        }
        self.config.delegate?.attributeTypeFor(type, selected: selected)
    }

    func updateActionBarStatus(_ status: FontToolBarStatusItem) {
        fontToolBar?.updateStatus(status)
    }

    func layoutFontBarNeedAnimation(bar: FontToolBar, needLayout: Bool) {
        // 初始化约束并立即布局
        bar.snp.remakeConstraints { make in
            make.left.equalToSuperview()
            make.bottom.equalToSuperview()
            make.top.equalTo(self.keyboardPanel.buttonWrapper.snp.bottom)
            make.right.equalToSuperview()
        }
        let height = keyboardPanel.panelTopBarHeight
        if needLayout {
            self.keyboardPanel.buttonWrapper.layoutIfNeeded()
        }
        bar.snp.updateConstraints { make in
            make.top.equalTo(self.keyboardPanel.buttonWrapper.snp.bottom).offset(-height)
        }
    }

    func updateTextViewFontStyle(_ textView: UITextView) {
        /// 更新Fontbar
        /// 之前默认 textView.selectedRange >= 0. 但是有上报attributedSubstring越界的问题，但是之前已经做了右边越界的处理，所以越界只能是左边
        /// 左边越界的话 location只能是负数，所以这里做个兼容处理，防止负数的时候出现crash
        let selectedRangeLocation = textView.selectedRange.location
        if  selectedRangeLocation <= 0 {
            updateFontBarAndDefaultTypingAttributesWidth(text: NSAttributedString(string: ""))
            if textView.selectedRange.location < 0 {
                UITextViewDelegateWarpper.logger.error("textView.selectedRange abnormal \(textView.selectedRange)")
                assertionFailure("textView.selectedRangey abnormal")
            }
        } else {
            let range = NSRange(location: textView.selectedRange.location - 1, length: 1)
            let attr: NSAttributedString
            if range.location + range.length <= textView.attributedText.length {
                attr = textView.attributedText.attributedSubstring(from: range)
            } else {
                assertionFailure("error to intercept current range")
                attr = NSAttributedString(string: "")
            }
            updateFontBarAndDefaultTypingAttributesWidth(text: attr)
        }
    }

    func updateFontBarAndDefaultTypingAttributesWidth(text: NSAttributedString) {
        let item = inputManager.updateDefaultTypingAttributesWidth(text: text)
        updateActionBarStatus(item)
    }

    func textViewDidChangeSelection(_ textView: UITextView) {
        /// 不输入 区域选中光标
        if textView.attributedText.length == textLength, textView.selectedRange.length > 0 {
            let subRange = textView.selectedRange
            /// 这里做个越界防护
            if subRange.location + subRange.length <= textView.attributedText.length {
                let subAttr = textView.attributedText.attributedSubstring(from: textView.selectedRange)
                showFontActionBarWithTypes(fontBarItemTypes, style: .dynamic, text: subAttr)
            }
            return
        }
        // 当取消选中内容时，需要隐藏fontbar
        if textView.selectedRange.length == 0, isShowFontToolBar, canDynamicHiddenFontBar, isNeedDissmissFontbar {
            hideFontActionBar()
        }

        if changeSelectionFromPaste, textView.selectedRange.length == 0 {
            changeSelectionFromPaste = false
            updateTextViewFontStyle(textView)
            return
        }
        /// 当用户删除或者仅移动光标
        guard textView.selectedRange.length == 0, textView.attributedText.length <= textLength else {
            return
        }
        updateTextViewFontStyle(textView)
    }

    public func textViewDidChange(_ textView: UITextView) {
        textLength = textView.attributedText.length
    }

    public func keyboardPanelDidLayoutIcon() {
        if let fontToolBar = fontToolBar {
            keyboardPanel.buttonWrapper.bringSubviewToFront(fontToolBar)
            if !self.keyboardPanel.panelTopBarRightContainer.subviews.isEmpty {
                layoutFontBarNeedAnimation(bar: fontToolBar, needLayout: false)
            }
        }
    }

    func updateKeyboardViewFontBarWithStatus(_ status: FontToolBarStatusItem) {
        if fontToolBar == nil {
            showFontActionBarWithTypes([.goback, .bold, .italic, .strikethrough, .underline], style: .static)
        }
        updateActionBarStatus(status)
    }
}
