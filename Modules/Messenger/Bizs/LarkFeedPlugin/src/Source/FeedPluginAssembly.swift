//
//  FeedPluginAssembly.swift
//  LarkFeedPlugin
//
//  Created by 袁平 on 2020/6/21.
//

import Foundation
import Swinject
import LarkSDKInterface
import LarkAccountInterface
import LarkMessengerInterface
import LarkOpenFeed
import LarkFeatureGating
import BootManager
import LarkAssembler
import EENavigator
import RustPB
import LarkFeed
import LarkFeedBase
import LarkFeedEvent
import LarkFeedBanner
import LarkOpenChat
import LarkOpenSetting
import LarkUIKit
import ByteWebImage
import LarkMessageCore

public final class FeedPluginAssembly: LarkAssemblyInterface {
    public init() {}

    public func getSubAssemblies() -> [LarkAssemblyInterface]? {
        FeedAssembly()
        FeedEventAssembly()
        FeedBannerAssembly()
    }

    // MARK: - 注入启动任务
    public func registLaunch(container: Container) {
        NewBootManager.register(FeedPluginBizRegistTask.self)
    }

    public func registContainer(container: Container) {
        let user = container.inObjectScope(Feed.userScope)
        let userGraph = container.inObjectScope(Feed.userGraph)

        container.register(FeedPluginBizRegistService.self) { (_) -> FeedPluginBizRegistService in
            return FeedPluginBizRegistService()
        }

        // 由于各个类型dependency都只是作一次中转，所以可将dependency注册为user级别使用
        // chat feed card dependency
        user.register(ChatFeedCardDependency.self) { r -> ChatFeedCardDependency in
            return try ChatFeedCardDependencyImpl(resolver: r)
        }

        // thread feed card dependency
        user.register(ThreadFeedCardDependency.self) { r -> ThreadFeedCardDependency in
            return try ThreadFeedCardDependencyImpl(resolver: r)
        }

        // subscription feed card dependency
        user.register(SubscriberFeedCardDependency.self) { r -> SubscriberFeedCardDependency in
            return try SubscriberFeedCardDependencyImpl(resolver: r)
        }

        user.register(FeedGuideConfigService.self) { r -> FeedGuideConfigService in
            let filterDataStore = try r.resolve(assert: FilterDataStore.self)
            let feedGuideDependency = try r.resolve(assert: FeedGuideDependency.self)
            return try FeedGuideConfigServiceImpl(filterDataStore: filterDataStore,
                                                  feedGuideDependency: feedGuideDependency)
        }

        user.register(FeedGuideDependency.self) { r -> FeedGuideDependency in
            return try FeedGuideDependencyImpl(resolver: r)
        }
    }

    // MARK: - 注册Routers
    public func registRouter(container: Container) {
        Navigator.shared.registerRoute.type(AddItemInToLabelPickerBody.self)
        .factory(AddItemInToLabelPickerHandler.init(resolver:))
    }

    @_silgen_name("Lark.OpenChat.Messenger.Label")
    static public func assembleChatSetting() {
        ChatSettingModule.register(ChatSettingLabelSubModule.self)
    }

    @_silgen_name("Lark.OpenSetting.FeedPluginAssembly")
    public static func pageFactoryRegister() {
        PageFactory.shared.register(page: .efficiency, moduleKey: ModulePair.Efficiency.feedSetting.moduleKey, provider: { userResolver in
            GeneralBlockModule(
                userResolver: userResolver,
                title: BundleI18n.LarkMine.Lark_Core_ChatFilter,
                footerStr: BundleI18n.LarkMine.Lark_NewSettings_MessageFilterDesc,
                onClickBlock: { (userResolver, from) in
                    let body = FeedFilterSettingBody(source: .fromMine, showMuteFilterSetting: true)
                    userResolver.navigator.present(body: body,
                                                   wrap: LkNavigationController.self,
                                                   from: from,
                                                   prepare: { $0.modalPresentationStyle = .formSheet },
                                                   animated: true)
                })
        })

        PageFactory.shared.register(page: .notification, moduleKey: ModulePair.Notification.indisturbEntry.moduleKey, provider: { userResolver in
            GeneralBlockModule(
                userResolver: userResolver,
                title: BundleI18n.LarkMine.Lark_NewSettings_MutedChatsNewMessageNotification,
                onClickBlock: { (userResolver, from) in
                    let body = FeedBadgeStyleSettingBody()
                    userResolver.navigator.push(body: body, from: from)
                })
        })

        PageFactory.shared.register(page: .efficiency, moduleKey: ModulePair.Efficiency.feedActionSetting.moduleKey, provider: { userResolver in
            if Feed.Feature(userResolver).feedActionSettingEnable {
                return GeneralBlockModule(
                    userResolver: userResolver,
                    title: BundleI18n.LarkMine.Lark_ChatSwipeActions_Mobile_Title,
                    onClickBlock: { (userResolver, from) in
                        let body = FeedSwipeActionSettingBody()
                        userResolver.navigator.present(body: body,
                                                       wrap: LkNavigationController.self,
                                                       from: from,
                                                       prepare: { $0.modalPresentationStyle = .formSheet },
                                                       animated: true)
                    })
            } else {
                return nil
            }
        })
    }

    // 支持向feed注入监听
    @_silgen_name("Lark.Feed.Listener.Guide")
    static public func registerGuideListener() {
        FeedListenerProviderRegistery.register(provider: { resolver -> FeedListenerItem in
            return FeedGuideLifeListener(resolver: resolver)
        })
    }

    @_silgen_name("Lark.Feed.Listener.Image.Preload")
    static public func registerImagePreloadListener() {
        FeedListenerProviderRegistery.register(provider: { _ in FeedImagePreloadListener() })
    }

    @_silgen_name("Lark.Feed.Listener.Chat.Preload")
    static public func registerChatPreloadListener() {
        FeedListenerProviderRegistery.register(provider: { _ in FeedChatPreLoadListener() })
    }
}
