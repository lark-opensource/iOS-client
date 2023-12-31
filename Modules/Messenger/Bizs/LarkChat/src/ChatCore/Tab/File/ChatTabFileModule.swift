//
//  ChatTabFileModule.swift
//  LarkChat
//
//  Created by zhaojiachen on 2022/4/22.
//

import UIKit
import Foundation
import LarkOpenChat
import LarkModel
import EENavigator
import UniverseDesignIcon
import LarkSetting

public final class ChatTabFileModule: ChatTabSubModule {
    public override var type: ChatTabType {
        return .file
    }

    public override class func canInitialize(context: ChatTabContext) -> Bool {
        true // "im.chat.tab.file" 已经全量
    }

    public override func jumpTab(model: ChatJumpTabModel) {
        if let searchFileVC = try? ChatTabSearchFileViewController(
            userResolver: userResolver, chatId: model.chat.id,
            router: DefaultChatTabSearchFileRouter(userResolver: userResolver)
        ) {
            navigator.push(searchFileVC, from: model.targetVC)
        }
    }

    public override func getTabManageItem(_ metaModel: ChatTabMetaModel) -> ChatTabManageItem? {
        guard let content = metaModel.content else { return nil }
        return ChatTabManageItem(
            name: self.getTabTitle(metaModel),
            tabId: content.id,
            canBeDeleted: false,
            canEdit: false,
            canBeSorted: true,
            imageResource: self.getImageResource(metaModel)
        )
    }

    public override func getTabTitle(_ metaModel: ChatTabMetaModel) -> String {
        return BundleI18n.LarkChat.Lark_Legacy_FileLabel
    }

    public override func getImageResource(_ metaModel: ChatTabMetaModel) -> ChatTabImageResource {
        return .image(UDIcon.getIconByKey(.fileFolderColorful, size: CGSize(width: 20, height: 20)))
    }

    public override func getClickParams(_ metaModel: ChatTabMetaModel) -> [AnyHashable: Any]? {
        return ["tab_type": "file_tab", "is_oapi_tab": "false"]
    }
}
