//
//  KeyboardFontSubModule.swift
//  LarkBaseKeyboard
//
//  Created by liluobin on 2023/4/7.
//

import UIKit
import LarkOpenKeyboard
import LarkKeyboardView
import EditTextView
import LKCommonsLogging
import LarkOpenIM
import RxSwift
import RxCocoa

/// 每个module缺个使用介绍
class UITextViewDelegateWarpper: NSObject, UITextViewDelegate {

    static let logger = Logger.log(UITextViewDelegateWarpper.self, category: "Module.Inputs")

    var textViewDidChangeSelectionCallBack: (()->Void)?
    var textViewDidChangeCallBack: (()->Void)?

    init(textViewDidChangeSelectionCallBack: (()->Void)?,
         textViewDidChangeCallBack: (()->Void)?) {
        self.textViewDidChangeSelectionCallBack = textViewDidChangeSelectionCallBack
        self.textViewDidChangeCallBack = textViewDidChangeCallBack
    }

    func textViewDidChangeSelection(_ textView: UITextView) {
        self.textViewDidChangeSelectionCallBack?()
    }

    func textViewDidChange(_ textView: UITextView) {
        self.textViewDidChangeCallBack?()
    }
}

open class KeyboardPanelFontSubModule<C:KeyboardContext, M:KeyboardMetaModel>: BaseKeyboardPanelDefaultSubModule<C, M>, KeyboardPanelFontManagerDelegate {

    public var fontToolBar: FontToolBar? { return mgr?.fontToolBar }

    public var inputManager: PostInputManager? { return mgr?.inputManager }

    /// 默认是nomal 没有特殊情况可以不实现
    public var getFontBarSpaceStyle: (() -> FontToolBar.ButtonSpace)?

    public var mgr: KeyboardPanelFontManager?

    public var disposeBag = DisposeBag()

    open override var panelItemKey: KeyboardItemKey {
        return .font
    }

    /// 是否需要自动观测文字的改变，defalut is ture
    /// 如果不需要的话 就需要手动将文字改变的情况传入
    open var autoObserverTextChange: Bool {
        return true
    }

    /// 需要子类复写
    open var itemsTintColor: UIColor? {
        assertionFailure("need override")
        return nil
    }

    lazy var delegateWarpper: UITextViewDelegateWarpper = {
        return UITextViewDelegateWarpper { [weak self] in
            guard let self = self else { return }
            self.textViewDidChangeSelection(self.context.inputTextView)
        } textViewDidChangeCallBack: { [weak self] in
            guard let self = self else { return }
            self.textViewDidChange(self.context.inputTextView)
        }
    }()

    private var hasSetDelegate = false

    open func fontItemClick() {
    }

    open func attributeTypeFor(_ type: FontActionType, selected: Bool) {
    }

    open func willShowFontActionBarWithTypes(_ types: [FontActionType], style: FontBarStyle, text: NSAttributedString?) {
    }

    open override func didCreatePanelItem() -> InputKeyboardItem? {
        if !hasSetDelegate {
            self.context.inputTextView.delegate = self.delegateWarpper
            self.hasSetDelegate = true
        }
        let config = KeyboardFontPanelItemConfig(getFontBarSpaceStyle: self.getFontBarSpaceStyle,
                                                 itemsTintColor: self.itemsTintColor,
                                                 inputTextView: self.context.inputTextView,
                                                 keyboardPanel: self.context.keyboardPanel,
                                                 delegate: self)
        self.mgr = KeyboardPanelFontManager(config: config)
        // textViewDidChange 方法不能cover所有文字的改变，有些情况下需要rx 才可以监听到
        self.observerTextChange()
        return mgr?.didCreatePanelItem()
    }

    open func observerTextChange() {
        guard autoObserverTextChange else { return }
        self.disposeBag = DisposeBag()
        self.context.inputTextView.rx.value.asDriver().drive(onNext: { [weak self] (_) in
            guard let self = self else { return }
            self.mgr?.textViewDidChange(self.context.inputTextView)
            self.onTextViewLengthChange(self.context.inputTextView.attributedText.length)
        }).disposed(by: self.disposeBag)
    }

    open override func keyboardPanelDidLayoutIcon() {
        self.mgr?.keyboardPanelDidLayoutIcon()
    }

    open func textViewDidChange(_ textView: UITextView) {
        self.mgr?.textViewDidChange(textView)
    }

    open func textViewDidChangeSelection(_ textView: UITextView) {
        self.mgr?.textViewDidChangeSelection(textView)
    }

    /// 输入框粘贴文字时候调用，一般在FontInputHandler回调里面处理
    public func onChangeSelectionFromPaste() {
        self.mgr?.onChangeSelectionFromPaste()
    }

    /// 输入框的文字改变时候触发
    public func onTextViewLengthChange(_ length: Int) {
        self.mgr?.onTextViewLengthChange(length)
    }

    /// 更新BISU的布局  宽松 Or 紧凑
    public func updateFontBarSpaceStyle(_ space: FontToolBar.ButtonSpace) {
        self.mgr?.updateFontBarSpaceStyle(space)
    }

    /// 隐藏fontBar
    public func hideFontActionBar() {
        self.mgr?.hideFontActionBar()
    }

    /// 根据当前的FontToolBarStatusItem的配置，暂时fontBar
    /// style: FontBarStyle? = nil 隐藏fontBar
    /// style == .static 弹出fontBar
    /// style == .dy 不做操作
    public func updateWithUIWithFontBarStatusItem(_ status: FontToolBarStatusItem) {
        self.mgr?.updateWithUIWithFontBarStatusItem(status)
    }

    ///
    public func updateInputTextViewStyle() {
        self.mgr?.updateInputTextViewStyle()
    }

    /// 如果fontBar存在的话 更新一下展示的状态
    public func updateActionBarStatus(_ status: FontToolBarStatusItem) {
        self.mgr?.updateActionBarStatus(status)
    }

    /// 获取当前FontBar的按钮选中状态
    public func getFontBarStatusItem() -> FontToolBarStatusItem? {
        self.mgr?.getFontBarStatusItem()
    }
}
