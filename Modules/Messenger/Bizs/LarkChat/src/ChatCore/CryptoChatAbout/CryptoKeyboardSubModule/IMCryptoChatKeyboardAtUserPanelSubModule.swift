//
//  IMCryptoChatKeyboardAtUserPanelSubModule.swift
//  LarkChat
//
//  Created by liluobin on 2023/4/6.
//

import UIKit
import LarkBaseKeyboard
import LarkOpenKeyboard
import LarkChatOpenKeyboard
import LarkMessengerInterface
import LarkContainer
import EENavigator
import LarkUIKit
import LarkCore
import RustPB
import LarkMessageCore

open class IMChatBaseKeyboardAtUserPanelSubModule: KeyboardPanelAtUserSubModule<KeyboardContext,
                                              IMKeyboardMetaModel>, ChatKeyboardViewPageItemProtocol {
}

public class IMCryptoChatKeyboardAtUserPanelSubModule: IMChatBaseKeyboardAtUserPanelSubModule {

    @ScopedInjectedLazy private var secretChatService: SecretChatService?

    var chatFromWhere: ChatFromWhere? {
        chatPageItem?.chatFromWhere
    }

    public override func itemIconColor() -> UIColor? {
        return secretChatService?.keyboardItemsTintColor
    }

    public override func showAtPicker(cancel: (() -> Void)?, complete: (([InputKeyboardAtItem]) -> Void)?) {
        guard let chat = self.metaModel?.chat else { return }
        var body = AtPickerBody(chatID: chat.id)
        body.cancel = cancel
        if let callback = complete {
            body.completion = { items in
                callback(items.map { .chatter(.init(id: $0.id, name: $0.name, actualName: $0.actualName, isOuter: $0.isOuter)) })
            }
        }
        navigator.present(
            body: body,
            wrap: LkNavigationController.self,
            from: context.displayVC,
            prepare: { $0.modalPresentationStyle = LarkCoreUtils.autoAdaptStyle() }
        )
        IMTracker.Chat.Main.Click.AtMention(chat,
                                            isFullScreen: false,
                                            chatFromWhere?.rawValue)
    }

    public override func didSelectedItem() {
        LarkMessageCoreTracker.trackClickKeyboardInputItem(.at)
    }

    public override func insertUrl(urlString: String) {
        assertionFailure("crypto error entrance, current not support")
    }

    public override func insertUrl(title: String, url: URL, type: Basic_V1_Doc.TypeEnum) {
        assertionFailure("crypto error entrance, current not support")
    }
}
