//
//  KeyboardPanelAtUserSubModule.swift
//  LarkBaseKeyboard
//
//  Created by liluobin on 2023/4/6.
//

import LarkOpenKeyboard
import LarkKeyboardView
import LarkContainer
import LarkOpenIM
import RustPB

open class KeyboardPanelAtUserSubModule <C:KeyboardContext, M:KeyboardMetaModel>: BaseKeyboardPanelDefaultSubModule<C, M>, KeyboardPanelAtUserManagerDelegate {


    /// 按钮的颜色
    open func itemIconColor() -> UIColor? {
        assertionFailure("need to be override")
        return nil
    }

    open override var panelItemKey: KeyboardItemKey {
        return .at
    }

    /// 插入At或者URL之后给与回调
    /// isInsertAt是否是插入@
    public var afterInsertCallBack: ((_ insertType: KeyboardPanelAtUserItemConfig.InsertType) -> Void)? {
        didSet {
            self.mgr.config.afterInsertCallBack = afterInsertCallBack
        }
    }

    public lazy var mgr: KeyboardPanelAtUserManager = {
        let config = KeyboardPanelAtUserItemConfig(itemIconColor: self.itemIconColor(),
                                                   afterInsertCallBack: nil,
                                                   shouldInsert: { [weak self] id in
            guard let self = self else { return true }
            return self.shouldInsert(id: id)
        },
                                                   textView: context.inputTextView,
                                                   delegate: self)
        return KeyboardPanelAtUserManager(config: config)
    }()


    open override func didCreatePanelItem() -> InputKeyboardItem? {
        return mgr.createItem()
    }

    /// 插入@之后 是否弹起键盘 -》showAtPicker  complete: (([LarkBaseKeyboard.InputKeyboardAtItem]
    open func becomeFirstResponderAfterComplete() -> Bool {
        return false
    }

    /// 取消插入之后 是否弹起键盘 -》showAtPicker (cancel: (() -> Void)?,
    open func becomeFirstResponderhAfterCancel() -> Bool {
        return false
    }

    open func showAtPicker(cancel: (() -> Void)?, complete: (([LarkBaseKeyboard.InputKeyboardAtItem]) -> Void)?) {
        assertionFailure("need to be override")
    }

    /// 代理实际回调方法
    open func didSelectedItem() {
    }

    open func insert(userName: String, actualName: String, userId: String, isOuter: Bool) {
    }

    open func insertUrl(title: String, url: URL, type: RustPB.Basic_V1_Doc.TypeEnum) {
    }

    open func insertUrl(urlString: String) {
    }

    open func shouldInsert(id: String) -> Bool {
        return true
    }
}
