//
//  ThreadKeyboardFontSubModule.swift
//  LarkThread
//
//  Created by liluobin on 2023/4/11.
//

import UIKit
import LarkOpenKeyboard
import LarkChatOpenKeyboard
import LarkBaseKeyboard
import LarkCore
import LarkMessageBase
import LarkKeyboardView

open class ThreadKeyboardFontSubModule: KeyboardPanelFontSubModule<KeyboardContext, IMKeyboardMetaModel>, ThreadKeyboardViewPageItemProtocol {

    public override var itemsTintColor: UIColor? { return ThreadKeyboardPageItem.iconColor }

    private var needTrackInputFontStyle = false

    public override var autoObserverTextChange: Bool {
        return false
    }

    open override func didCreatePanelItem() -> InputKeyboardItem? {
        getFontBarSpaceStyle = { [weak self] in
            guard let keyboardStatusManager = self?.threadPageItem?.keyboardStatusManager else {
                return .normal
            }
            return keyboardStatusManager.currentKeyboardJob.isFontBarCompactLayout ? .compact : .normal
        }
        return super.didCreatePanelItem()
    }
    open override func textViewDidChange(_ textView: UITextView) {
        super.textViewDidChange(textView)
        if needTrackInputFontStyle, let chat = self.metaModel?.chat {
            needTrackInputFontStyle = false
            IMTracker.Chat.Main.Click.TextEdit(chat,
                                               isFullScreen: false,
                                               isUserClick: true,
                                               nil,
                                               item: inputManager?.getInputViewFontStatus())
        }
    }

    open override func willShowFontActionBarWithTypes(_ types: [FontActionType], style: FontBarStyle, text: NSAttributedString?) {
        if let chat = self.metaModel?.chat {
            PublicTracker.FontBar.View(chat,
                                       isFullScreen: false,
                                       isUserClick: style == .static)
        }
    }

    open override func attributeTypeFor(_ type: FontActionType, selected: Bool) {
        super.attributeTypeFor(type, selected: selected)
        if context.inputTextView.selectedRange.length == 0 {
            self.needTrackInputFontStyle = selected
        }
        if selected, let chat = self.metaModel?.chat, let thread = self.threadPageItem?.thread {
            PublicTracker.FontBar.Click(chat,
                                        isFullScreen: false,
                                        type: type,
                                        thread.id)
            /// 用户选中文字的时候上报
            if fontToolBar?.style == .dynamic {
                IMTracker.Chat.Main.Click.TextEdit(chat,
                                                   isFullScreen: false,
                                                   isUserClick: false,
                                                   nil,
                                                   type: type)
            }
        }

    }
}
