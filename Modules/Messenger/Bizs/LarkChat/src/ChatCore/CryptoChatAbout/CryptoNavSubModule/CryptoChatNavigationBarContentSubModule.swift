//
//  CryptoChatNavigationBarContentSubModule.swift
//  LarkMessageCore
//
//  Created by liluobin on 2022/11/16.
//
import Foundation
import LarkUIKit
import LarkOpenChat
import RxSwift
import LarkCore
import LarkModel
import LarkSDKInterface
import LarkFeatureGating
import LarkMessageCore

public final class CryptoChatNavigationBarContentSubModule: ChatNavgationBarBaseContentSubModule {
    /// 密聊场景跳转到群设置
    public override func titleClicked() {
        ChatRouterAblility.routeToProfileOrSetting(chat: self.factory.chat, context: self.context)
    }

    public override func createContentView(metaModel: ChatNavigationBarMetaModel) {
        if self._contentView != nil {
            return
        }
        self.factory.updateChat(metaModel.chat)
        var inlineService: MessageTextToInlineService?
        var itemsOfTop: [ChatNavigationItemType] = [.nameItem, .countItem, .focusItem, .tagsItem, .rightArrowItem]
        var itemsOfbottom: [ChatNavigationItemType] = [.statusItem]
        if metaModel.chat.type == .p2P, let v = try? resolver.resolve(assert: MessageTextToInlineService.self) {
            inlineService = v
            itemsOfTop = [.nameItem, .tagsItem, .rightArrowItem]
            itemsOfbottom = []
        }

        let config = NavigationBarTitleViewConfig(showExtraFields: false,
                                                  canTap: true,
                                                  itemsOfTop: itemsOfTop,
                                                  itemsOfbottom: itemsOfbottom,
                                                  darkStyle: !Display.pad,
                                                  barStyle: self.context.navigationBarDisplayStyle(),
                                                  tagsGenerator: CryptoChatNavigationBarTagsGenerator(forceShowAllStaffTag: false,
                                                                                                      isDarkStyle: !Display.pad,
                                                                                                      userResolver: self.context.userResolver),
                                                  inlineService: inlineService,
                                                  chatterAPI: try? self.context.resolver.resolve(assert: ChatterAPI.self),
                                                  fixedTitle: metaModel.chat.type == .p2P ? BundleI18n.LarkChat.Lark_IM_SecureChatUser_Title : nil)
        self._contentView = self.factory.createTitleView(config: config,
                                                         delegate: self)
    }
}
