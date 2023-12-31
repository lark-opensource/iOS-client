//
//  ChatTabDocModule.swift
//  LarkChat
//
//  Created by Zigeng on 2022/5/6.
//

import UIKit
import Foundation
import LarkContainer
import Swinject
import LarkUIKit
import LarkAccountInterface
import LarkSDKInterface
import LarkSearchCore
import LarkMessengerInterface
import LarkFeatureGating
import LarkOpenChat
import LKCommonsLogging
import LKCommonsTracker
import Homeric
import EENavigator
import LarkModel
import UniverseDesignIcon

public final class ChatTabDocSpaceModule: ChatTabSubModule {
    public override var type: ChatTabType {
        return .docSpace
    }

    public override class func canInitialize(context: ChatTabContext) -> Bool {
        /// 总是应该被初始化
        return true
    }

    public override func jumpTab(model: ChatJumpTabModel) {
        guard let searchDocVC = try? ChatTabSearchDocViewController(
            userResolver: userResolver,
            chatId: model.chat.id,
            router: DefaultChatTabSearchDocRouter(userResolver: userResolver, jumpToTab: { [weak self] (tabContent, tagetVC) in
                guard let openTabService = try? self?.context.resolver.resolve(assert: ChatOpenTabService.self) else { return }
                openTabService.jumpToTab(tabContent, targetVC: tagetVC)
            })
        ) else { return }
        navigator.push(searchDocVC, from: model.targetVC)
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
        return BundleI18n.LarkChat.Lark_IM_Tabs_Docs_Title
    }

    public override func getImageResource(_ metaModel: ChatTabMetaModel) -> ChatTabImageResource {
        return .image(UDIcon.getIconByKey(.tabDriveColorful, size: CGSize(width: 20, height: 20)))
    }

    public override func getClickParams(_ metaModel: ChatTabMetaModel) -> [AnyHashable: Any]? {
       return ["tab_type": "doc_tab", "is_oapi_tab": "false"]
    }

    public override func getFirstScreenParams(_ metaModels: [ChatTabMetaModel]) -> [AnyHashable: Any] {
        return ["is_doc_list_tab_included": metaModels.isEmpty ? "false" : "true"]
    }
}
