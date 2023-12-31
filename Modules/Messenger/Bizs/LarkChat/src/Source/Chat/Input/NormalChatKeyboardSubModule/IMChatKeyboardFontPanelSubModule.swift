//
//  IMChatKeyboardFontPanelSubModule.swift
//  LarkChat
//
//  Created by liluobin on 2023/4/9.
//

import UIKit
import LarkBaseKeyboard
import LarkOpenKeyboard
import LarkChatOpenKeyboard
import LarkCore
import LarkMessageBase
import LarkKeyboardView

public class IMChatKeyboardFontPanelSubModule: KeyboardPanelFontSubModule<KeyboardContext, IMKeyboardMetaModel>,
                                               ChatKeyboardViewPageItemProtocol {

    public override var itemsTintColor: UIColor? { return UIColor.ud.iconN2 }

    private var needTrackInputFontStyle = false

    public override var autoObserverTextChange: Bool {
        return false
    }

    public override func fontItemClick() {
        IMTracker.Chat.Main.Click.Toolbar(self.metaModel?.chat,
                                          isFullScreen: false,
                                          nil, chatPageItem?.chatFromWhere)
    }

    public override func didCreatePanelItem() -> InputKeyboardItem? {
        getFontBarSpaceStyle = { [weak self] in
            guard let keyboardStatusManager = self?.chatPageItem?.keyboardStatusManager else {
                return .normal
            }
            return keyboardStatusManager.currentKeyboardJob.isFontBarCompactLayout ? .compact : .normal
        }
        return super.didCreatePanelItem()
    }

    public override func willShowFontActionBarWithTypes(_ types: [FontActionType],
                                                    style: FontBarStyle,
                                                    text: NSAttributedString? = nil) {
        super.willShowFontActionBarWithTypes(types, style: style, text: text)
        PublicTracker.FontBar.View(self.metaModel?.chat, isFullScreen: false, isUserClick: style == .static)
    }

    public override func textViewDidChange(_ textView: UITextView) {
        super.textViewDidChange(textView)
        if needTrackInputFontStyle, let chatModel = self.metaModel?.chat {
            needTrackInputFontStyle = false
            IMTracker.Chat.Main.Click.TextEdit(chatModel,
                                               isFullScreen: false,
                                               isUserClick: true,
                                               chatPageItem?.chatFromWhere,
                                               item: inputManager?.getInputViewFontStatus())
        }
    }

    public override func attributeTypeFor(_ type: FontActionType, selected: Bool) {
        super.attributeTypeFor(type, selected: selected)
        guard type != .goback else { return }
        if context.inputTextView.selectedRange.length == 0 {
            self.needTrackInputFontStyle = selected
        }
        guard let chat = self.metaModel?.chat else { return }
        if selected, let bar = self.fontToolBar {
            PublicTracker.FontBar.Click(chat, isFullScreen: false, type: type)
            /// 用户选中文字的时候上报
            if bar.style == .dynamic {
                IMTracker.Chat.Main.Click.TextEdit(chat,
                                                   isFullScreen: false,
                                                   isUserClick: false,
                                                   chatPageItem?.chatFromWhere,
                                                   type: type)
            }
        }
    }
}
