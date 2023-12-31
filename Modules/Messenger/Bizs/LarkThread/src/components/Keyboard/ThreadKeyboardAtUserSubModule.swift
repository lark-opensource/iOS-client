//
//  ThreadKeyboardAtUserSubModule.swift
//  LarkThread
//
//  Created by liluobin on 2023/4/11.
//

import UIKit
import LarkOpenKeyboard
import LarkChatOpenKeyboard
import LarkBaseKeyboard
import LarkFeatureGating
import LarkIMMention
import LarkMessengerInterface
import EENavigator
import LarkUIKit
import LarkCore
import LarkMessageCore
import LarkKeyboardView
import LarkContainer

public class MessageThreadKeyboardAtUserSubModule: ThreadKeyboardAtUserSubModule {
    override func supportAtUser() -> Bool {
        return true
    }
}

public class ThreadKeyboardAtUserSubModule: KeyboardPanelAtUserSubModule<KeyboardContext, IMKeyboardMetaModel>, ThreadKeyboardViewPageItemProtocol {
    @ScopedInjectedLazy var theadInputAtManager: TheadInputAtManager?

    open override func didCreatePanelItem() -> InputKeyboardItem? {
        LarkMessageCoreTracker.trackClickKeyboardInputItem(.at)
        return super.didCreatePanelItem()
    }

    public override func itemIconColor() -> UIColor? {
        return ThreadKeyboardPageItem.iconColor
    }

    open override func showAtPicker(cancel: (() -> Void)?, complete: (([InputKeyboardAtItem]) -> Void)?) {
        guard let chat = self.metaModel?.chat, let theadInputAtManager else {
            return
        }
        if !supportAtUser() {
            return
        }
        /// 这里cancel 不需要处理 不做特殊处理
        theadInputAtManager.inputTextViewInputAt(fromVC: context.displayVC,
                                                 chat: chat,
                                                 cancel: nil,
                                                 complete: complete)
        IMTracker.Chat.Main.Click.AtMention(chat,
                                            isFullScreen: false,
                                            nil,
                                            threadId: self.threadPageItem?.thread.id)

    }

    func supportAtUser() -> Bool {
        guard let chat = self.metaModel?.chat else {
            return false
        }
        return chat.type != .p2P
    }
}
