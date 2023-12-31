//
//  MockAssembly.swift
//  LarkFeed-Unit-Tests
//
//  Created by 白镜吾 on 2023/9/5.
//

import Foundation
import LarkContainer
import LarkOpenFeed
import LarkSDKInterface
import RustPB
import LarkModel
import LarkFeedBase
import RunloopTools
@testable import LarkFeed

class MockAssembly {
    static var mockContainer: Container = {
        return generateContainer()
    }()

    static func generateContainer() -> Container {
        let container = Container()
        container.canCallResolve = false
        setUpTask()
        let user = container.inObjectScope(.user)

        FeedCardModuleManager.register(moduleType: MockChatFeedCardModule.self)

        user.register(PushNotificationCenter.self) { resolver in
            let scope = ScopedPushNotificationCenter()
            scope.userID = resolver.userID
            return scope
        }

        // 替换掉 FeedAPI，手动实现 Feeds 相关操作
        user.register(FeedAPI.self) { _ in
            return MockFeedAPI()
        }

        // MARK: FeedMuteConfigService
        user.register(FeedMuteConfigService.self) { _ in
            return MockFeedMuteConfig()
        }

        // MARK: FeedContext
        user.register(FeedContext.self) { r -> FeedContext  in
            return FeedContext(userResolver: r)
        }

        // MARK: FeedContextService
        user.register(FeedContextService.self) { r -> FeedContextService in
            let context = try r.resolve(assert: FeedContext.self)
            return context
        }

        // MARK: FeedCTAConfigService
        user.register(FeedCTAConfigService.self) { (r) -> FeedCTAConfigService in
            return FeedCTAConfig(userResolver: r)
        }

        // MARK: FeedCardContext
        user.register(FeedCardContext.self) { r -> FeedCardContext in
            let context = try r.resolve(assert: FeedContextService.self)
            let ctaConfigService = try r.resolve(assert: FeedCTAConfigService.self)
            return FeedCardContext(resolver: r, feedContextService: context, ctaConfigService: ctaConfigService)
        }

        // MARK: FilterDataStore
        user.register(FilterDataStore.self) { r -> FilterDataStore in
            let feedAPI = try r.resolve(assert: FeedAPI.self)
            let feedMuteConfigService = try r.resolve(assert: FeedMuteConfigService.self)
            let pushCenter = try r.userPushCenter
            let pushFeedFilterSettings = pushCenter.observable(for: LarkFeed.FiltersModel.self)
            let pushFeedPreview = pushCenter.observable(for: LarkFeed.PushFeedPreview.self)
            let dependency = try FilterDataDependencyImpl(userResolver: r,
                                                          feedAPI: feedAPI,
                                                          feedMuteConfigService: feedMuteConfigService,
                                                          pushFeedFilterSettings: pushFeedFilterSettings,
                                                          pushFeedPreview: pushFeedPreview)
            return FilterDataStore(dependency: dependency)
        }

        // MARK: BatchMuteFeedCardsService
        user.register(BatchMuteFeedCardsService.self) { (r) -> BatchMuteFeedCardsService in
            let pushCenter = try r.userPushCenter
            let pushMuteFeedCards = pushCenter.observable(for: PushMuteFeedCards.self)
            let context = try r.resolve(assert: FeedContextService.self)

            return BatchMuteFeedCardsServiceImpl(pushMuteFeedCards: pushMuteFeedCards, context: context)
        }

        // MARK: BatchClearBagdeService
        user.register(BatchClearBagdeService.self) { (r) -> BatchClearBagdeService in
            let pushCenter = try r.userPushCenter
            let pushBatchClearFeedBadges = pushCenter.observable(for: PushBatchClearFeedBadge.self)
            let context = try r.resolve(assert: FeedContextService.self)

            return BatchClearBagdeServiceImpl(pushBatchClearFeedBadges: pushBatchClearFeedBadges, context: context)
        }

        // MARK: FilterActionHandler
        user.register(FilterActionHandler.self) { (r) -> FilterActionHandler in
            let feedAPI = try r.resolve(assert: FeedAPI.self)
            let filterDataStore = try r.resolve(assert: FilterDataStore.self)
            let batchClearBadgeService = try r.resolve(assert: BatchClearBagdeService.self)
            let batchMuteFeedCardsService = try r.resolve(assert: BatchMuteFeedCardsService.self)
            let feedContextService = try r.resolve(assert: FeedContextService.self)
            let muteActionSetting = FeedSetting(r).getFeedMuteActionSetting()
            let clearBadgeActionSetting = FeedSetting(r).gettGroupClearBadgeSetting()
            let atAllSetting = FeedAtAllSetting.get(userResolver: r)
            let displayRuleSetting = FeedSetting(r).getGroupDisplayRuleSetting()
            return try FilterActionHandler(userResolver: r,
                                           feedContextService: feedContextService,
                                           filterDataStore: filterDataStore,
                                           feedAPI: feedAPI,
                                           batchMuteFeedCardsService: batchMuteFeedCardsService,
                                           batchClearBadgeService: batchClearBadgeService,
                                           muteActionSetting: muteActionSetting,
                                           clearBadgeActionSetting: clearBadgeActionSetting,
                                           atAllSetting: atAllSetting,
                                           displayRuleSetting: displayRuleSetting)
        }

        // MARK: Feed3BarStyleService
        user.register(Feed3BarStyleService.self) { _ -> Feed3BarStyleService in
            return Feed3BarStyleServiceImpl()
        }

        // MARK: FeedCardModuleManager
        user.register(FeedCardModuleManager.self) { r -> FeedCardModuleManager in
            let context = try r.resolve(assert: FeedCardContext.self)
            return FeedCardModuleManager(feedCardContext: context)
        }

        // MARK: BaseFeedsViewModelDependency
        user.register(BaseFeedsViewModelDependency.self) { r -> BaseFeedsViewModelDependency in
            return try MockBaseFeedsViewModelDependency(resolver: r)
        }

        // MARK: FeedListViewModelDependency
        user.register(FeedListViewModelDependency.self) { r -> FeedListViewModelDependency in
            let filterDataStore = try r.resolve(assert: FilterDataStore.self)
            let feedAPI = try r.resolve(assert: FeedAPI.self)
            let styleService = try r.resolve(assert: Feed3BarStyleService.self)
            return MockFeedListViewModelDependency(
                filterDataStore: filterDataStore,
                feedAPI: feedAPI,
                styleService: styleService)
        }

        // MARK: ChatterManagerProtocol
        user.register(ChatterManagerProtocol.self) { r in
            let userPushCenter = try r.userPushCenter
            let pushChatter = userPushCenter.observable(for: PushChatters.self).map { $0.chatters }
            return MockChatterManager(pushChatters: pushChatter, userResolver: r)
        }

        // MARK: FeedDependency
        user.register(FeedDependency.self) { r -> FeedDependency in
            return MockFeedDependency(userResolver: r)
        }

        // MARK: FeedGuideDependency
        user.register(FeedGuideDependency.self) { r -> FeedGuideDependency in
            return MockFeedGuideDependency(userResolver: r)
        }

        // MARK: FeedThreeBarService
        user.register(FeedThreeBarService.self) { r -> FeedThreeBarService in
            let styleService = try r.resolve(assert: Feed3BarStyleService.self)
            return FeedThreeBarServiceImpl(feed3BarStyleService: styleService)
        }

        /// 注入Feed Setting Store
        user.register(FeedSettingStore.self) { r -> FeedSettingStore in
            let feedAPI = try r.resolve(assert: FeedAPI.self)
            let pushCenter = try r.userPushCenter
            let pushActionSetting = pushCenter.observable(for: LarkFeed.FeedActionSettingData.self)
            return FeedSettingStore(feedAPI: feedAPI, pushActionSetting: pushActionSetting)
        }

        container.canCallResolve = true
        return container
    }

    static func setUpTask() {
        RunloopDispatcher.enable = true
    }
}

private class MockChatFeedCardModule: FeedCardBaseModule {
    // [必须实现]表明自己的业务类型
    override var type: FeedPreviewType {
        return .chat
    }

    // [必须实现] 关联业务的实体数据。feed框架内部使用，或者是使用feed框架的业务使用
    override func bizData(feedPreview: FeedPreview) -> FeedPreviewBizData {
        let entityId: String
        if feedPreview.preview.chatData.chatType == .p2P {
            entityId = feedPreview.preview.chatData.chatterID
        } else {
            entityId = feedPreview.id
        }
        var shortcutChannel = Basic_V1_Channel()
        shortcutChannel.id = feedPreview.id
        shortcutChannel.type = .chat
        let data = FeedPreviewBizData(entityId: entityId, shortcutChannel: shortcutChannel)
        return data
    }
}
