//
//  IMComposeKeyboardFontPanelSubModule.swift
//  LarkMessageCore
//
//  Created by liluobin on 2023/4/22.
//

import UIKit
import LarkBaseKeyboard
import LarkOpenKeyboard
import LarkChatOpenKeyboard
import LarkKeyboardView
import LarkCore
import LarkMessageBase

class IMComposeKeyboardFontPanelSubModule: KeyboardPanelFontSubModule<IMComposeKeyboardContext, IMKeyboardMetaModel>, ComposeKeyboardViewPageItemProtocol {

    override var itemsTintColor: UIColor? {
        return ComposeKeyboardPageItem.iconColor
    }

    private var needTrackInputFontStyle = false

    public override func didCreatePanelItem() -> InputKeyboardItem? {
        getFontBarSpaceStyle = { [weak self] in
            guard let keyboardStatusManager = self?.context.keyboardStatusManager else {
                return .normal
            }
            return keyboardStatusManager.currentKeyboardJob.isFontBarCompactLayout ? .compact : .normal
        }
        return super.didCreatePanelItem()
    }

    override func textViewDidChange(_ textView: UITextView) {
        super.textViewDidChange(textView)
        if self.needTrackInputFontStyle, let chat = self.metaModel?.chat {
            self.needTrackInputFontStyle = false
            IMTracker.Chat.Main.Click.TextEdit(chat,
                                               isFullScreen: true,
                                               isUserClick: true,
                                               pageItem?.chatFromWhere,
                                               item: inputManager?.getInputViewFontStatus())
        }
    }

    override func fontItemClick() {
        let chat = self.metaModel?.chat
        let replyMessageId = self.context.keyboardStatusManager.getRelatedDispalyMessage()?.id
        IMTracker.Chat.Main.Click.Toolbar(chat,
                                          isFullScreen: true,
                                          replyMessageId,
                                          self.pageItem?.chatFromWhere)
    }

    override func attributeTypeFor(_ type: FontActionType, selected: Bool) {
        super.attributeTypeFor(type, selected: selected)
        guard type != .goback else { return }
        if context.inputTextView.selectedRange.length == 0 {
            self.needTrackInputFontStyle = selected
        }

        guard let chat = self.metaModel?.chat else { return }
        if selected, let bar = self.fontToolBar {
            let threadId = self.getThreadIdForChat(chat,
                                                   keyboardStatusManager: self.context.keyboardStatusManager)
            PublicTracker.FontBar.Click(chat, isFullScreen: true, type: type, threadId)
            /// 用户选中文字的时候上报
            if bar.style == .dynamic {
                IMTracker.Chat.Main.Click.TextEdit(chat,
                                                   isFullScreen: true,
                                                   isUserClick: false,
                                                   pageItem?.chatFromWhere,
                                                   type: type)
            }
        }
    }
}
