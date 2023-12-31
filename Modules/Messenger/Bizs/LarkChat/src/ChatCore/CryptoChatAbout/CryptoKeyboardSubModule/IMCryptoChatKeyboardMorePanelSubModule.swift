//
//  IMCryptoChatKeyboardMorePanelSubModule.swift
//  LarkChat
//
//  Created by liluobin on 2023/4/10.
//

import UIKit
import LarkOpenKeyboard
import LarkChatOpenKeyboard
import LarkBaseKeyboard
import RxSwift
import RxCocoa
import LarkOpenChat
import LarkMessengerInterface
import LarkKeyboardView
import LarkContainer
import LarkMessageCore
import LarkCore

public class IMCryptoChatKeyboardMorePanelSubModule: KeyboardPanelMoreSubModule<KeyboardContext, IMKeyboardMetaModel>,
                                                     ChatKeyboardViewPageItemProtocol {

    @ScopedInjectedLazy private var secretChatService: SecretChatService?

    /// 设置后清空原有的item
    var itemDriver: Driver<[ChatKeyboardMoreItem]>? {
        didSet {
            self.item = nil
        }
    }

    public override func didCreatePanelItem() -> InputKeyboardItem? {
        if let itemDriver = self.itemDriver, let secretChatService {
            self.config = KeyboardPanelMoreConfig(itemsTintColor: secretChatService.keyboardItemsTintColor,
                                                   itemDriver: itemDriver.map({ items in
                return items.map { item in
                    BaseKeyboardMoreItem(text: item.text,
                                         icon: item.icon,
                                         selectIcon: item.selectIcon,
                                         badgeText: item.badgeText,
                                         showDotBadge: item.showDotBadge,
                                         isDynamic: item.isDynamic,
                                         customViewBlock: item.customViewBlock,
                                         tapped: item.tapped)
                }
            }))
        }
       return super.didCreatePanelItem()
    }

    public override func buildMoreSelected() {
        guard let chat = self.metaModel?.chat else { return }
        LarkMessageCoreTracker.trackClickKeyboardInputItem(KeyboardItemKey.more)
        ChatTrack.trackChatKeyBoardMoreClick(chat: chat)
        IMTracker.Chat.Main.Click.InputPlus(chat, chatPageItem?.chatFromWhere)
        IMTracker.Chat.InputPlus.View(chat)
    }
}
