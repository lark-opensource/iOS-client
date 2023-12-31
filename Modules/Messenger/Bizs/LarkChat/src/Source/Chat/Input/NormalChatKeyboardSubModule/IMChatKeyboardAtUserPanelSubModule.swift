//
//  IMChatKeyboardAtUserPanelSubModule.swift
//  LarkChat
//
//  Created by liluobin on 2023/4/6.
//

import UIKit
import LarkBaseKeyboard
import LarkChatOpenKeyboard
import LarkOpenKeyboard
import LarkFeatureGating
import LarkMessengerInterface
import EENavigator
import LarkCore
import LarkUIKit
import LarkMessageCore
import LarkModel
import LarkAccountInterface
import RustPB
import LarkKeyboardView
import LarkChatKeyboardInterface

public class IMChatKeyboardAtUserPanelSubModule: IMChatBaseKeyboardAtUserPanelSubModule {

    public override func itemIconColor() -> UIColor? {
        return UIColor.ud.iconN2
    }

    private var itemConfig: ChatKeyboardAtItemConfig? {
        return try? context.userResolver.resolve(assert: ChatOpenKeyboardItemConfigService.self).getChatKeyboardItemFor(self.panelItemKey)
    }

    var chatFromWhere: ChatFromWhere? {
        return chatPageItem?.chatFromWhere
    }

    // 使用通用mention组件
    private lazy var mentionOptEnable: Bool = {
        userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "messenger.message.corporate_aite_clouddocuments"))
    }()

    lazy var processor = IMAtPickerProcessor()

    public override func showAtPicker(cancel: (() -> Void)?, complete: (([InputKeyboardAtItem]) -> Void)?) {
        guard let chat = self.metaModel?.chat else {
            return
        }
        itemConfig?.uiConfig?.tappedBlock?()
        let config = IMAtPickerProcessor.IMAtPickerConfig(chat: chat,
                                                          userResolver: userResolver,
                                                          supportAtMyAI: chatPageItem?.supportAtMyAI ?? false, fromVC: self.context.displayVC)
        processor.showAtPicker(config: config, cancel: cancel, complete: complete)
        IMTracker.Chat.Main.Click.AtMention(chat,
                                            isFullScreen: false,
                                            chatFromWhere?.rawValue)
    }

    public override func didSelectedItem() {
        LarkMessageCoreTracker.trackClickKeyboardInputItem(.at)
    }

    public override func shouldInsert(id: String) -> Bool {
        if id == (try? self.context.userResolver.resolve(type: MyAIService.self).defaultResource.mockID) {
            try? self.context.userResolver.resolve(type: IMMyAIInlineService.self).openMyAIInlineMode(source: .mention)
            return false
        }
        return true
    }
}

extension Chat {
    public func isEnableAtAll(me: String) -> Bool {
        return self.type != .p2P &&
        (self.atAllPermission == .allMembers || self.ownerId == me || self.isGroupAdmin)
    }
}
