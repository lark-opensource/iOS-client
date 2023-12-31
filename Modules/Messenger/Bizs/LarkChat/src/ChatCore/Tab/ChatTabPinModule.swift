//
//  ChatTabPinModule.swift
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
import UniverseDesignIcon
import LarkBadge
import UniverseDesignColor
import LarkFeatureGating

final public class ChatTabPinModule: ChatTabSubModule {
    override public var type: ChatTabType {
        return .pin
    }

    override public class func canInitialize(context: ChatTabContext) -> Bool {
        return true
    }

    override public func jumpTab(model: ChatJumpTabModel) {
        let body = PinListBody(chatId: model.chat.id)
        navigator.push(body: body, from: model.targetVC)
    }

    override public func getTabManageItem(_ metaModel: ChatTabMetaModel) -> ChatTabManageItem? {
        guard let content = metaModel.content else { return nil }
        return ChatTabManageItem(
          name: self.getTabTitle(metaModel),
          tabId: content.id,
          canBeDeleted: false,
          canEdit: false,
          canBeSorted: true,
          imageResource: self.getImageResource(metaModel),
          count: self.context.store.getValue(for: ChatTabPinService.pinCountKey),
          badgePath: self.getBadgePath(metaModel)
        )
    }

    override public func getTabTitle(_ metaModel: ChatTabMetaModel) -> String {
        return BundleI18n.LarkChat.Lark_IM_Tabs_PinNew_TabTitle
    }

    override public func getImageResource(_ metaModel: ChatTabMetaModel) -> ChatTabImageResource {
        let pinColor: UIColor = UDColor.T400 & UDColor.T500
        return .image(UDIcon.getIconByKey(.pinFilled,
                                          iconColor: pinColor,
                                          size: CGSize(width: 20, height: 20)))
    }

    override public func getBadgePath(_ metaModel: ChatTabMetaModel) -> Path? {
        guard enableBadge else { return nil }
        return try? self.context.resolver.resolve(assert: ChatOpenService.self).chatPath.chat_more.raw("pin")
    }

    override public func getClickParams(_ metaModel: ChatTabMetaModel) -> [AnyHashable: Any]? {
        let showBadge: Bool = self.context.store.getValue(for: ChatTabPinService.pinBadgeShowKey) ?? false
        let pinCount: Int = self.context.store.getValue(for: ChatTabPinService.pinCountKey) ?? 0
        return ["tab_type": "pin_tab",
                "is_oapi_tab": "false",
                "is_enabled_red_dot": showBadge ? "true" : "false",
                "item_nums": "\(pinCount)"]
    }

    private lazy var enableBadge: Bool = {
        return userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "im.chat.tabs.pin.badge"))
    }()
}
