//
//  ChatTabChatAnnouncementModule.swift
//  LarkChat
//
//  Created by zhaojiachen on 2022/4/6.
//

import UIKit
import Foundation
import LarkOpenChat
import LarkModel
import LarkContainer
import EENavigator
import LKCommonsLogging
import LarkMessengerInterface
import RxSwift
import RxCocoa
import LarkSDKInterface
import UniverseDesignIcon
import UniverseDesignToast
import LKCommonsTracker
import Homeric
import LarkCore

final public class ChatTabChatAnnouncementModule: ChatTabSubModule {
    static private let logger = Logger.log(ChatTabDocAPIModule.self, category: "Lark.MessengerAssembly")
    private let disposeBag = DisposeBag()
    @ScopedInjectedLazy private var docSDKAPI: ChatDocDependency?

    override public var type: ChatTabType {
        return .chatAnnouncement
    }

    override public class func canInitialize(context: ChatTabContext) -> Bool {
        return true
    }

    override public func jumpTab(model: ChatJumpTabModel) {
        let body = ChatAnnouncementBody(chatId: model.chat.id)
        // 用于文档打开的时候传入标识，走push方法打开不走标签方式打开
        let context: [String: Any] = ["showTemporary": false]
        navigator.push(body: body, context: context, from: model.targetVC)
    }

    override public func getTabTitle(_ metaModel: ChatTabMetaModel) -> String {
        return BundleI18n.LarkChat.Lark_Groups_Announcement
    }

    override public func getImageResource(_ metaModel: ChatTabMetaModel) -> ChatTabImageResource {
        return .image(UDIcon.getIconByKey(.announceFilled, iconColor: UIColor.ud.colorfulOrange, size: CGSize(width: 20, height: 20)))
    }

    override public func getTabManageItem(_ metaModel: ChatTabMetaModel) -> ChatTabManageItem? {
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

    override public func getChatAddTabEntry(_ addTabContext: ChatTabContextModel) -> ChatAddTabEntry? {
        if addTabContext.chat.type == .p2P { return nil }
        return ChatAddTabEntry(
            title: BundleI18n.LarkChat.Lark_IM_AddGroupAnnouncement_Button,
            type: self.type,
            icon: UDIcon.getIconByKey(.newboardsOutlined, iconColor: UIColor.ud.iconN2, size: CGSize(width: 20, height: 20))
        )
    }

    override public func beginAddTab(metaModel: ChatAddTabMetaModel) {
        guard let openTabService = try? self.context.resolver.resolve(assert: ChatOpenTabService.self) else { return }
        let targetVC = metaModel.targetVC
        let chat = metaModel.chat
        let extraInfo = metaModel.extraInfo
        let chatId = chat.id
        if chat.isFrozen {
            UDToast.showTips(with: BundleI18n.LarkChat.Lark_IM_CantCompleteActionBecauseGrpDisbanded_Toast, on: targetVC.view)
            return
        }
        openTabService.addTab(
            type: .chatAnnouncement,
            name: "",
            jsonPayload: nil,
            success: { [weak targetVC, userResolver] content in
                guard let targetVC = targetVC else { return }
                let body = ChatAnnouncementBody(chatId: chatId)
                userResolver.navigator.push(body: body, from: targetVC)

                guard let extraInfo = extraInfo else { return }
                var trackParams: [AnyHashable: Any] = ["click": "announcement_tab_add",
                                                       "target": "im_chat_announcement_page_view",
                                                       "tab_id": content.id]
                extraInfo.params.forEach {
                    trackParams[$0.key] = $0.value
                }
                Tracker.post(TeaEvent(extraInfo.event,
                                      params: trackParams,
                                      bizSceneModels: [IMTracker.Transform.chat(chat)]))
            },
            failure: { (error, _) in
                Self.logger.error("add chatAnnouncement tab failed", error: error)
            }
        )
    }

    override public func getClickParams(_ metaModel: ChatTabMetaModel) -> [AnyHashable: Any]? {
        var params: [AnyHashable: Any] = ["tab_type": "announcement_tab", "is_oapi_tab": "false"]
        if let url = URL(string: metaModel.chat.announcement.docURL) {
            params["file_id"] = self.docSDKAPI?.isSupportURLType(url: url).2
        }
        return params
    }
}
