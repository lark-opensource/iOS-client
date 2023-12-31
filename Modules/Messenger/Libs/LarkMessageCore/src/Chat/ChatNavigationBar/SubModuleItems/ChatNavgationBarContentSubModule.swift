//
//  ChatNavgationBarContentSubModule.swift
//  LarkMessageCore
//
//  Created by liluobin on 2022/11/10.
//

import UIKit
import Foundation
import LarkUIKit
import LarkOpenChat
import RxSwift
import LarkCore
import LarkInteraction
import LarkFocus
import LarkModel
import LarkTag
import LKContentFix
import LarkMessengerInterface
import LarkSDKInterface
import EENavigator
import LarkSetting
import LarkContainer
import LarkBadge
import LarkFeatureGating

open class ChatNavgationBarBaseContentSubModule: BaseNavigationBarContentSubModule, NavigationBarTitleViewDelegate {
    open override class var name: String { return  "ChatNavgationBarBaseContentSubModule" }

    public lazy var factory: NavigationBarTitleViewFactory = {
        return NavigationBarTitleViewFactory(resolver: self.context.userResolver)
    }()

    public var _contentView: UIView?

    open override var contentView: UIView? {
        return _contentView
    }

    public func getCurrentWindow() -> UIWindow? {
        return self.context.chatVC().view.window
    }

    /// 各场景复写，自定义点击行为
    open func titleClicked() {}

    open override func modelDidChange(model: ChatNavigationBarMetaModel) {
        self.factory.updateChat(model.chat)
    }
}

class ChatNavgationBarContentSubModule: ChatNavgationBarBaseContentSubModule {
    @ScopedInjectedLazy private var fgService: FeatureGatingService?
    /// 产品&UI要求 只有手机上展示居左样式
     var showLeftStyle: Bool {
         return (try? self.userResolver.resolve(type: ChatNavigationBarConfigService.self).showLeftStyle) ?? false
     }

    /// Chat场景跳转到群设置
    override func titleClicked() {
        ChatRouterAblility.routeToProfileOrSetting(chat: self.factory.chat, context: self.context)
    }

    override func createContentView(metaModel: ChatNavigationBarMetaModel) {
        if self._contentView != nil {
            return
        }
        self.factory.updateChat(metaModel.chat)
        // 仅单聊时才显示个人签名
        var inlineService: MessageTextToInlineService?
        if metaModel.chat.type == .p2P, let v = try? self.context.userResolver.resolve(assert: MessageTextToInlineService.self) {
            inlineService = v
        }
        let style = ChatTitleViewStyle(alignmentStyle: showLeftStyle ? .left : .center,
                                       showTitleArrow: !showLeftStyle)
        let config = NavigationBarTitleViewConfig(showExtraFields: fgService?.staticFeatureGatingValue(with: "pc.show.user.admin.info") ?? false,
                                                  canTap: true,
                                                  itemsOfTop: nil,
                                                  itemsOfbottom: nil,
                                                  darkStyle: false,
                                                  barStyle: self.context.navigationBarDisplayStyle(),
                                                  tagsGenerator: DefaultChatNavigationBarTagsGenerator(forceShowAllStaffTag: false,
                                                                                                       isDarkStyle: false,
                                                                                                       userResolver: self.context.userResolver),
                                                  inlineService: inlineService,
                                                  chatterAPI: try? self.context.userResolver.resolve(assert: ChatterAPI.self),
                                                  style: style)
        self._contentView = self.factory.createTitleView(config: config,
                                                         delegate: self)
    }

    override func barStyleDidChange() {
        self.factory.updateBarStyle(self.context.navigationBarDisplayStyle())
    }
}

/// 封装Chat、Crypto场景跳转Profile、群设置逻辑，从ChatVC迁移到此，用于SubModule内部闭环跳转逻辑
public class ChatRouterAblility {
    public static func routeToProfileOrSetting(chat: Chat?, context: ChatNavgationBarContext) {
        guard let chat = chat else { return }

        let chatFromWhere = context.store.getValue(for: IMTracker.Chat.Main.ChatFromWhereKey) ?? ""
        IMTracker.Chat.Main.Click.NavigationTitle(chat, chatFromWhere)
        if context.userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "pc.show.user.admin.info")), chat.type == .p2P {
            ChatRouterAblility.routeToProfile(chat: chat, context: context)
            return
        }
        let isGroupOwner = ChatRouterAblility.isGroupOwner(chat: chat, context: context)
        LarkMessageCoreTracker.trackChatSetting(chat: chat, isGroupOwner: isGroupOwner, source: "title")
        LarkMessageCoreTracker.trackNewChatSetting(chat: chat, isGroupOwner: isGroupOwner, source: .chatTitle)
        ChatRouterAblility.routeToChatSetting(chat: chat, context: context, source: .chatTitle, action: .chatTitle)
    }

    private static func isGroupOwner(chat: Chat, context: ChatNavgationBarContext) -> Bool {
        return context.userResolver.userID == chat.ownerId
    }

    private static func routeToProfile(chat: Chat, context: ChatNavgationBarContext) {
        guard let targetVC = (try? context.userResolver.resolve(assert: ChatOpenService.self))?.chatVC() else { return }
        let body = PersonCardBody(chatterId: chat.chatterId, source: .chat)
        context.userResolver.navigator.presentOrPush(body: body,
                                                     wrap: LkNavigationController.self,
                                                     from: targetVC,
                                                     prepareForPresent: { vc in
            vc.modalPresentationStyle = .formSheet
        })
    }

    public static func routeToChatSetting(chat: Chat, context: ChatNavgationBarContext, source: EnterChatSettingSource, action: EnterChatSettingAction) {
        guard let targetVC = (try? context.userResolver.resolve(assert: ChatOpenService.self))?.chatVC() else { return }

        if !chat.announcement.docURL.isEmpty, let dependency = try? context.userResolver.resolve(type: NavigationBarSubModuleDependency.self) {
            dependency.preloadDocFeed(chat.announcement.docURL, from: chat.trackType + "_announcement")
        }
        let body = ChatInfoBody(chat: chat, action: action, type: .ignore)
        context.userResolver.navigator.push(body: body, from: targetVC)

        let isGroupOwner = ChatRouterAblility.isGroupOwner(chat: chat, context: context)
        LarkMessageCoreTracker.trackNewChatSetting(chat: chat, isGroupOwner: isGroupOwner, source: source)
        // path拼接逻辑同ChatViewModel.settingPath
        BadgeManager.clearBadge(context.chatRootPath.chat_more.raw(SidebarItemType.setting.rawValue))
    }
}
