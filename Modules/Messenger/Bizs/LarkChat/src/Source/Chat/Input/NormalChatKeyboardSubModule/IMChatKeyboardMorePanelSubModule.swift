//
//  IMChatKeyboardMorePanelSubModule.swift
//  LarkChat
//
//  Created by liluobin on 2023/4/9.
//

import UIKit
import LarkChatOpenKeyboard
import LarkOpenKeyboard
import LarkBaseKeyboard
import LarkMessageCore
import LarkKeyboardView
import LarkCore
import LarkOpenChat
import RxSwift
import RxCocoa
import LarkChatKeyboardInterface

public class IMChatKeyboardMorePanelSubModule: KeyboardPanelMoreSubModule<KeyboardContext, IMKeyboardMetaModel>,
                                               ChatKeyboardViewPageItemProtocol {
    /// 支持设置黑名单
    var blackList: [ChatKeyboardMoreItemType] {
        return self.itemConfig?.uiConfig?.blacklist ?? []
    }

    /// 设置后清空原有的item
    var itemDriver: Driver<[ChatKeyboardMoreItem]>? {
        didSet {
            self.item = nil
        }
    }

    private var itemConfig: ChatMoreKeyboardItemConfig? {
        return try? context.userResolver.resolve(assert: ChatOpenKeyboardItemConfigService.self).getChatKeyboardItemFor(self.panelItemKey)
    }

    public override func didCreatePanelItem() -> InputKeyboardItem? {
        if let itemDriver = self.itemDriver {
            let blackListArr = self.blackList
            self.config = KeyboardPanelMoreConfig(itemsTintColor: UIColor.ud.iconN2,
                                                  itemDriver: itemDriver.map({ items in
                return items.compactMap { item in
                    if !blackListArr.contains(where: { $0 == item.type }) {
                        return BaseKeyboardMoreItem(text: item.text,
                                                    icon: item.icon,
                                                    selectIcon: item.selectIcon,
                                                    badgeText: item.badgeText,
                                                    showDotBadge: item.showDotBadge,
                                                    isDynamic: item.isDynamic,
                                                    customViewBlock: item.customViewBlock,
                                                    tapped: item.tapped)

                    }
                    return nil
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
