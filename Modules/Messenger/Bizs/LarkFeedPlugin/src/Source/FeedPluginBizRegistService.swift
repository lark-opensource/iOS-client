//
//  FeedPluginBizRegistService.swift
//  LarkFeedPlugin
//
//  Created by aslan on 2022/2/14.
//

import Foundation
import LarkFeed
import Swinject
import LarkOpenFeed
import LarkContainer
import LarkModel
import RustPB
import LarkFeedBase

public final class FeedPluginBizRegistService {

    init() {}

    public func regist(container: Container) {
        assembleFeedCell()
    }

    private func assembleFeedCell() {
        // 注入module
        FeedCardModuleManager.register(moduleType: ChatFeedCardModule.self)
        FeedCardModuleManager.register(moduleType: ThreadFeedCardModule.self)
        FeedCardModuleManager.register(moduleType: BoxFeedCardModule.self)
        FeedCardModuleManager.register(moduleType: SubscriberFeedCardModule.self)
        FeedCardModuleManager.register(moduleType: OpenAppFeedCardModule.self)

        // 注入component
        FeedCardComponentFactoryRegister.register(factory: { _ in
            FeedCardAvatarFactory()
        })
        FeedCardComponentFactoryRegister.register(factory: { _ in
            FeedCardNavigationFactory()
        })
        FeedCardComponentFactoryRegister.register(factory: { _ in
            FeedCardTitleFactory()
        })
        FeedCardComponentFactoryRegister.register(factory: { _ in
            FeedCardCustomStatusFactory()
        })
        FeedCardComponentFactoryRegister.register(factory: { _ in
            FeedCardSpecialFocusFactory()
        })
        FeedCardComponentFactoryRegister.register(factory: { _ in
            FeedCardTimeFactory()
        })
        FeedCardComponentFactoryRegister.register(factory: { _ in
            FeedCardFlagFactory()
        })
        FeedCardComponentFactoryRegister.register(factory: { _ in
            FeedCardStatusFactory()
        })
        FeedCardComponentFactoryRegister.register(factory: { _ in
            FeedCardSubtitleFactory()
        })
        FeedCardComponentFactoryRegister.register(factory: { _ in
            ChatFeedCardMsgStatusFactory()
        })
        FeedCardComponentFactoryRegister.register(factory: { context in
            FeedCardReactionFactory(context: context)
        })
        FeedCardComponentFactoryRegister.register(factory: { _ in
            FeedCardDigestFactory()
        })
        FeedCardComponentFactoryRegister.register(factory: { _ in
            FeedCardTagFactory()
        })
        FeedCardComponentFactoryRegister.register(factory: { _ in
            FeedCardMentionFactory()
        })
        FeedCardComponentFactoryRegister.register(factory: { _ in
            FeedCardMuteFactory()
        })
        FeedCardComponentFactoryRegister.register(factory: { context in
            FeedCardCTAFactory(context: context)
        })

        // FeedAction 工厂类注入
        FeedActionFactoryManager.register(factory: { FeedActionFlagFactory() })
        FeedActionFactoryManager.register(factory: { FeedActionJoinTeamFactory() })
        FeedActionFactoryManager.register(factory: { FeedActionTeamHideFactory() })

        // BizFeedAction 工厂类注入
        FeedActionFactoryManager.register(factory: { ChatFeedActionMuteFactory() })
        FeedActionFactoryManager.register(factory: { ChatFeedActionJumpFactory() })
        FeedActionFactoryManager.register(factory: { ChatFeedActionBlockMsgFactory() })
        FeedActionFactoryManager.register(factory: { SubscriptionFeedActionMuteFactory() })
        FeedActionFactoryManager.register(factory: { SubscriptionFeedActionJumpFactory() })
        FeedActionFactoryManager.register(factory: { ThreadFeedActionMuteFactory() })
        FeedActionFactoryManager.register(factory: { ThreadFeedActionJumpFactory() })
        FeedActionFactoryManager.register(factory: { BoxFeedActionJumpFactory() })
        FeedActionFactoryManager.register(factory: { OpenAppFeedActionJumpFactory() })
    }
}
