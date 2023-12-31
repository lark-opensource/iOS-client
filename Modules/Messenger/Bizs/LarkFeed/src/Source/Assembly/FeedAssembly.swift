//
//  FeedAssembly.swift
//  LarkFeed
//
//  Created by bytedance on 2020/6/3.
//

import Foundation
import Swinject
import LarkAccountInterface
import LarkSDKInterface
import LarkMessengerInterface
import RustPB
import LarkModel
import LarkAppConfig
import LarkNavigator
import EENavigator
import AnimatedTabBar
import LarkRustClient
import LarkNavigation
import LarkUIKit
import BootManager
import LarkTab
import LarkDebugExtensionPoint
import LarkAssembler
import RxSwift
import RxCocoa
import LarkOpenFeed
import LarkContainer
import LarkFeedBase

public final class FeedAssembly: LarkAssemblyInterface {
    public init() {}

    // MARK: - 注入启动任务
    public func registLaunch(container: Container) {
        NewBootManager.register(LoadFeedTask.self)
        NewBootManager.register(FeedBizRegistTask.self)
    }

    public func registPassportDelegate(container: Container) {
           (PassportDelegateFactory {
               let enableUserScope = container.resolve(PassportService.self)?.enableUserScope ?? false
               if enableUserScope {
                   return FeedPassportDelegate()
               } else {
                   return DummyPassportDelegate()
               }
           }, PassportDelegatePriority.high)
       }

       public func registLauncherDelegate(container: Container) {
           (LauncherDelegateFactory {
               let enableUserScope = container.resolve(PassportService.self)?.enableUserScope ?? false
               if enableUserScope {
                   return DummyLauncherDelegate()
               } else {
                   return FeedLauncherDelegate()
               }
           }, LauncherDelegateRegisteryPriority.high)
       }

    // MARK: - 注入依赖
    public func registContainer(container: Container) {
        let user = container.inObjectScope(Feed.userScope)
        let userGraph = container.inObjectScope(Feed.userGraph)
        container.register(FeedBizRegisterService.self) { (_) -> FeedBizRegisterService in
            return FeedBizRegisterService()
        }

        /// 注入 Badge Style Config
        user.register(FeedBadgeConfigService.self) { (r) -> FeedBadgeConfigService in
            let pushCenter = try r.userPushCenter
            let configAPI = try r.resolve(assert: ConfigurationAPI.self)
            let pushUserSetting = pushCenter.observable(for: RustPB.Settings_V1_PushUserSetting.self)
            let style = FeedKVStorage(userId: r.userID).getFeedBadgeStyle()
            return FeedBadgeConfig(style: style,
                                   configAPI: configAPI,
                                   pushUserSetting: pushUserSetting)
        }

        /// 注入【全部】type 的 vm
        user.register(AllFeedListViewModel.self) { (r) -> AllFeedListViewModel in
            let pushCenter = try r.userPushCenter
            let feedListViewModelDependency = try r.resolve(assert: FeedListViewModelDependency.self)
            let baseFeedsViewModelDependency = try r.resolve(assert: BaseFeedsViewModelDependency.self)
            let tabMuteBadgeObservable = try r.resolve(assert: FeedBadgeConfigService.self).tabMuteBadgeObservable
            let feedContext = try r.resolve(assert: FeedContext.self)
            feedContext.listeners = FeedListenerProviderRegistery.providers.map({ $0(r) })
            let allFeedsDependency = AllFeedsDependencyImpl(
                tabMuteBadgeObservable: tabMuteBadgeObservable,
                feedMuteConfigService: try r.resolve(assert: FeedMuteConfigService.self),
                feedAPI: try r.resolve(assert: FeedAPI.self),
                feedGuideDependency: try r.resolve(assert: FeedGuideDependency.self)
            )
            return AllFeedListViewModel(allFeedsDependency: allFeedsDependency,
                                        dependency: feedListViewModelDependency,
                                        baseDependency: baseFeedsViewModelDependency,
                                        feedContext: feedContext)
        }

        /// 注入 Feed 侧边栏 vm
        user.register(FeedFilterListViewModel.self) { (r) -> FeedFilterListViewModel in
            let filterDataStore = try r.resolve(assert: FilterDataStore.self)
            let fixedViewModel = try r.resolve(assert: FilterFixedViewModel.self)
            let context = try r.resolve(assert: FeedContextService.self)
            let selectionHandler = try r.resolve(assert: FeedFilterSelectionAbility.self)
            let styleService = try r.resolve(assert: Feed3BarStyleService.self)
            let dependency = FeedFilterListDependencyImpl(resolver: r,
                                                          filterDataStore: filterDataStore,
                                                          fixedViewModel: fixedViewModel,
                                                          context: context,
                                                          selectionHandler: selectionHandler,
                                                          styleService: styleService
            )
            return FeedFilterListViewModel(dependency: dependency)
        }

        /// 注入团队 vm
        user.register(FeedTeamViewModel.self) { (r) -> FeedTeamViewModel in
            let pushCenter = try r.userPushCenter

            let context = try r.resolve(assert: FeedContextService.self)
            let pushItems = pushCenter.observable(for: Im_V1_PushItems.self)
            let pushTeams = pushCenter.observable(for: Im_V1_PushTeams.self)
            let pushItemExpired = pushCenter.observable(for: Im_V1_PushItemExpired.self)
            let pushFeedPreview = pushCenter.observable(for: LarkFeed.PushFeedPreview.self)
            let pushTeamItemChats = pushCenter.observable(for: LarkFeed.PushTeamItemChats.self)
            let badgeStyleObservable = try r.resolve(assert: FeedBadgeConfigService.self).badgeStyleObservable
            let pushWebSocketStatus = pushCenter.observable(for: PushWebSocketStatus.self)
            let batchClearBadgeService = try r.resolve(assert: BatchClearBagdeService.self)
            let batchMuteFeedCardsService = try r.resolve(assert: BatchMuteFeedCardsService.self)
            let feedGuideDependency = try r.resolve(assert: FeedGuideDependency.self)
            let filterDataStore = try r.resolve(assert: FilterDataStore.self)

            let dependency = try FeedTeamDependencyImpl(
                resolver: r,
                pushItems: pushItems,
                pushTeams: pushTeams,
                pushItemExpired: pushItemExpired,
                pushFeedPreview: pushFeedPreview,
                pushTeamItemChats: pushTeamItemChats,
                badgeStyleObservable: badgeStyleObservable,
                pushWebSocketStatus: pushWebSocketStatus,
                batchClearBadgeService: batchClearBadgeService,
                batchMuteFeedCardsService: batchMuteFeedCardsService,
                feedGuideDependency: feedGuideDependency,
                context: context,
                filterDataStore: filterDataStore)
            return FeedTeamViewModel(dependency: dependency,
                                     context: context)
        }

        /// 注入标签 vm
        user.register(LabelMainListViewModel.self) { (r) -> LabelMainListViewModel in
            let pushCenter = try r.userPushCenter
            let context = try r.resolve(assert: FeedContextService.self)
            let pushLabels = pushCenter.observable(for: PushLabel.self)
            let pushFeedPreview = pushCenter.observable(for: LarkFeed.PushFeedPreview.self)
            let badgeStyleObservable = try r.resolve(assert: FeedBadgeConfigService.self).badgeStyleObservable
            let batchClearBadge = try r.resolve(assert: BatchClearBagdeService.self)
            let batchMuteFeedCardsService = try r.resolve(assert: BatchMuteFeedCardsService.self)
            let feedGuideDependency = try r.resolve(assert: FeedGuideDependency.self)
            let dependency = try LabelDependencyImpl(
                resolver: r,
                pushLabels: pushLabels,
                pushFeedPreview: pushFeedPreview,
                badgeStyleObservable: badgeStyleObservable,
                batchClearBadgeService: batchClearBadge,
                batchMuteFeedCardsService: batchMuteFeedCardsService,
                feedGuideDependency: feedGuideDependency,
                context: context)
            let labelContext = LabelMainListContext()
            let vm = LabelMainListViewModel(dependency: dependency,
                                            context: context,
                                            labelContext: labelContext)
            return vm
        }

        /// 注入固定分组栏 vm
        user.register(FilterFixedViewModel.self) { (r) -> FilterFixedViewModel in
            let dataStore = try r.resolve(assert: FilterDataStore.self)
            let filterActionHandler = try r.resolve(assert: FilterActionHandler.self)
            let feedAPI = try r.resolve(assert: FeedAPI.self)
            let context = try r.resolve(assert: FeedContextService.self)
            let selectionHandler = try r.resolve(assert: FeedFilterSelectionAbility.self)
            let pushCenter = try r.userPushCenter
            let pushFeedFixedFilterSettings = pushCenter.observable(for: LarkFeed.FeedThreeColumnSettingModel.self)
            let pushDynamicNetStatus = pushCenter.observable(for: PushDynamicNetStatus.self)
            let dependency = try FilterFixedDependencyImpl(userResolver: r,
                                                           dataStore: dataStore,
                                                           filterActionHandler: filterActionHandler,
                                                           feedAPI: feedAPI,
                                                           context: context,
                                                           selectionHandler: selectionHandler,
                                                           pushFeedFixedFilterSettings: pushFeedFixedFilterSettings,
                                                           pushDynamicNetStatus: pushDynamicNetStatus)
            return FilterFixedViewModel(dependency: dependency)
        }

        /// 注入分组数据处理器
        user.register(FilterDataStore.self) { (r) -> FilterDataStore in
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

        /// 注入Feed Setting Store
        user.register(FeedSettingStore.self) { r -> FeedSettingStore in
            let feedAPI = try r.resolve(assert: FeedAPI.self)
            let pushCenter = try r.userPushCenter
            let pushActionSetting = pushCenter.observable(for: LarkFeed.FeedActionSettingData.self)
            return FeedSettingStore(feedAPI: feedAPI, pushActionSetting: pushActionSetting)
        }

        /// 注入分组事件处理器
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
        /// FeedNavigationBarViewModel
        user.register(FeedNavigationBarViewModel.self) { r -> FeedNavigationBarViewModel in
            let pushCenter = try r.userPushCenter
            let pushDynamicNetStatus = pushCenter.observable(for: PushDynamicNetStatus.self)
            let pushLoadFeedCardsStatus = pushCenter.observable(for: Feed_V1_PushLoadFeedCardsStatus.self)
            let chatterManager = try r.resolve(assert: ChatterManagerProtocol.self)
            let styleService = try r.resolve(assert: Feed3BarStyleService.self)
            let context = try r.resolve(assert: FeedContextService.self)
            return FeedNavigationBarViewModel(chatterId: r.userID,
                                              pushDynamicNetStatus: pushDynamicNetStatus,
                                              pushLoadFeedCardsStatus: pushLoadFeedCardsStatus,
                                              chatterManager: chatterManager,
                                              styleService: styleService,
                                              context: context)
        }

        /// ShortcutsViewModel
        user.register(ShortcutsViewModel.self) { (r) -> ShortcutsViewModel in
            let pushCenter = try r.userPushCenter
            let pushShortcuts = pushCenter.observable(for: LarkFeed.PushShortcuts.self)
            let pushFeedPreview = pushCenter.observable(for: LarkFeed.PushFeedPreview.self)
            let badgeStyleObservable = try r.resolve(assert: FeedBadgeConfigService.self).badgeStyleObservable
            let dependency = try ShortCutViewModelDependencyImpl(resolver: r,
                                                             pushShortcuts: pushShortcuts,
                                                             pushFeedPreview: pushFeedPreview,
                                                             badgeStyleObservable: badgeStyleObservable)
            return ShortcutsViewModel(dependency: dependency)
        }

        user.register(ShortcutsCollectionView.self) { (r) -> ShortcutsCollectionView in
            let vm = try r.resolve(assert: ShortcutsViewModel.self)
            return ShortcutsCollectionView(viewModel: vm)
        }

        user.register(BaseFeedsViewModelDependency.self) { r in
            let badgeStyleObservable = try r.resolve(assert: FeedBadgeConfigService.self).badgeStyleObservable
            let is24HourTime = try r.resolve(assert: UserGeneralSettings.self).is24HourTime
            return try BaseFeedsViewModelDependencyImp(
                resolver: r,
                badgeStyleObservable: badgeStyleObservable,
                is24HourTime: is24HourTime)
        }

        user.register(FeedListViewModelDependency.self) { (r) -> FeedListViewModelDependency in
            return FeedListViewModelDependencyImpl(
                filterDataStore: try r.resolve(assert: FilterDataStore.self),
                feedAPI: try r.resolve(assert: FeedAPI.self),
                rustClient: try r.resolve(assert: RustService.self),
                styleService: try r.resolve(assert: Feed3BarStyleService.self))
        }

        user.register(FeedSyncDispatchServiceDependency.self) { r -> FeedSyncDispatchServiceDependency in
            let pushCenter = try r.userPushCenter
            let pushDynamicNetStatus = pushCenter.observable(for: PushDynamicNetStatus.self)
            let pushLoadFeedCardsStatus = pushCenter.observable(for: Feed_V1_PushLoadFeedCardsStatus.self)
            return try FeedSyncDispatchServiceDependencyImp(resolver: r,
                                                        pushDynamicNetStatus: pushDynamicNetStatus,
                                                        pushLoadFeedCardsStatus: pushLoadFeedCardsStatus)
        }

        user.register(FeedServiceForDocDependency.self) { (r) -> FeedServiceForDocDependency in
            let shortcutsVMProvider = { try? r.resolve(assert: ShortcutsViewModel.self) }
            return FeedServiceForDocDependencyImpl(shortcutsViewModelProvider: shortcutsVMProvider)
        }

        user.register(BatchClearBagdeService.self) { (r) -> BatchClearBagdeService in
            let pushCenter = try r.userPushCenter
            let pushBatchClearFeedBadges = pushCenter.observable(for: PushBatchClearFeedBadge.self)
            let context = try r.resolve(assert: FeedContextService.self)

            return try BatchClearBagdeServiceImpl(pushBatchClearFeedBadges: pushBatchClearFeedBadges, context: context)
        }

        user.register(BatchMuteFeedCardsService.self) { (r) -> BatchMuteFeedCardsService in
            let pushCenter = try r.userPushCenter
            let pushMuteFeedCards = pushCenter.observable(for: PushMuteFeedCards.self)
            let context = try r.resolve(assert: FeedContextService.self)

            return try BatchMuteFeedCardsServiceImpl(pushMuteFeedCards: pushMuteFeedCards, context: context)
        }

        user.register(FeedContext.self) { (r) -> FeedContext in
            return FeedContext(userResolver: r)
        }

        userGraph.register(FeedContextService.self) { r -> FeedContextService in
            let context = try r.resolve(assert: FeedContext.self)
            return context
        }

        user.register(FeedLayoutConfig.self) { _ -> FeedLayoutConfig in
            return FeedLayoutConfig()
        }

        userGraph.register(FeedLayoutService.self) { r -> FeedLayoutService in
            return try r.resolve(assert: FeedLayoutConfig.self)
        }

        user.register(FeedPreloaderService.self) { (r) -> FeedPreloaderServiceImpl in
            return FeedPreloaderServiceImpl(resolver: r)
        }

        userGraph.register(FeedSyncDispatchService.self) { (r) -> FeedSyncDispatchService in
            let dependency = try r.resolve(assert: FeedSyncDispatchServiceDependency.self)
            return FeedSyncDispatchServiceImp(dependency: dependency)
        }

        userGraph.register(FeedListPageSwitchService.self) { (r) -> FeedListPageSwitchService in
            let context = try r.resolve(assert: FeedContextService.self)
            let filterListViewModel = try r.resolve(assert: FeedFilterListViewModel.self)
            return FeedListPageSwitchServiceImp(context: context, filterListViewModel: filterListViewModel)
        }

        userGraph.register(FeedThreeColumnsGuideService.self) { (r) -> FeedThreeColumnsGuideService in
            let context = try r.resolve(assert: FeedContextService.self)
            return FeedThreeColumnsGuideServiceImp(context: context)
        }

        userGraph.register(FeedSyncDispatchServiceForDoc.self) { (r) -> FeedSyncDispatchServiceForDoc in
            let feedServiceForDocDependency = try r.resolve(assert: FeedServiceForDocDependency.self)
            return FeedServiceForDocImpl(feedServiceForDocDependency)
        }

        user.register(FeedMuteConfigService.self) { r -> FeedMuteConfigService in
            return FeedMuteConfig(userResolver: r)
        }

        user.register(FeedSelectionService.self) { _ -> FeedSelectionService in
            return FeedSelectionServiceImp()
        }

        user.register(Feed3BarStyleService.self) { _ -> Feed3BarStyleService in
            return Feed3BarStyleServiceImpl()
        }

        user.register(FeedThreeBarService.self) { (r) -> FeedThreeBarService in
            let styleService = try r.resolve(assert: Feed3BarStyleService.self)
            return FeedThreeBarServiceImpl(feed3BarStyleService: styleService)
        }

        user.register(FeedFilterSelectionService.self) { _ -> FeedFilterSelectionService in
            return FeedFilterSelectionServiceImpl()
        }

        user.register(FeedFilterSelectionAbility.self) { (r) -> FeedFilterSelectionAbility in
            let selectionService = try r.resolve(assert: FeedFilterSelectionService.self)
            return FeedFilterSelectionHandler(selectionService: selectionService)
        }

        user.register(MainTabbarControllerDependency.self) { (r) -> MainTabbarControllerDependency in
            let chatterManager = try r.resolve(assert: ChatterManagerProtocol.self)
            let context = try r.resolve(assert: FeedContextService.self)
            return MainTabbarControllerDependencyImpl(resolver: r, chatterManager: chatterManager, context: context)
        }

        user.register(FeedCTAConfigService.self) { (r) -> FeedCTAConfigService in
            return FeedCTAConfig(userResolver: r)
        }

        // feed card context
        user.register(FeedCardContext.self) { (r) -> FeedCardContext in
            let context = try r.resolve(assert: FeedContextService.self)
            let ctaConfigService = try r.resolve(assert: FeedCTAConfigService.self)
            return FeedCardContext(resolver: r, feedContextService: context, ctaConfigService: ctaConfigService)
        }

        // feed card module 管理器
        user.register(FeedCardModuleManager.self) { (r) -> FeedCardModuleManager in
            let context = try r.resolve(assert: FeedCardContext.self)
            return FeedCardModuleManager(feedCardContext: context)
        }

        // feed action 门面类
        userGraph.register(FeedActionService.self) { r -> FeedActionService in
            let context = try r.resolve(assert: FeedCardContext.self)
            return FeedActionServiceImp(context: context)
        }
    }

    public func registTabRegistry(container: Container) {
        (Tab.feed, { (_: [URLQueryItem]?) -> TabRepresentable in
            return FeedTab()
        })
    }

    // MARK: - 注册 Routers
    public func registRouter(container: Container) {
        Navigator.shared.registerRoute.plain(Tab.feed.urlString)
        .priority(.high)
        .factory(FeedRouterHandler.init(resolver:))

        Navigator.shared.registerRoute.type(FeedFilterSettingBody.self)
        .factory(FeedFilterSettingHandler.init(resolver:))

        Navigator.shared.registerRoute.type(FeedSwipeActionSettingBody.self)
        .factory(FeedSwipeActionSettingHandler.init(resolver:))

        Navigator.shared.registerRoute.type(FeedBadgeStyleSettingBody.self)
        .factory(FeedBadgeStyleSettingHandler.init(resolver:))

        Navigator.shared.registerRoute.type(ChatBoxBody.self)
        .factory(BoxFeedsRequestHandler.init(resolver:))

        Navigator.shared.registerRoute.type(HiddenTeamChatListBody.self)
        .factory(HiddenChatListHandler.init(resolver:))

        Navigator.shared.registerRoute.type(FeedPageBody.self)
        .handle { _, _, res in res.end(resource: EmptyResource()) }

        Navigator.shared.registerRoute.type(SettingLabelBody.self)
        .factory(SettingLabelHandler.init(resolver:))

        Navigator.shared.registerRoute.type(SettingLabelListBody.self)
        .factory(SettingLabelListHandler.init(resolver:))

        Navigator.shared.registerRoute.type(FeedFilterBody.self)
        .factory(FeedFilterHandler.init(resolver:))

        Navigator.shared.registerRoute.type(AddItemInToLabelBody.self)
        .factory(AddItemInToLabelBodyHandler.init(resolver:))

        Navigator.shared.registerRoute.type(FeedMsgDisplaySettingBody.self)
        .factory(FeedMsgDisplaySettingHandler.init(resolver: ))

        Navigator.shared.registerRoute.type(FeedMsgDisplayMoreSettingBody.self)
        .factory(FeedMsgDisplayMoreSettingHandler.init(resolver: ))

        Navigator.shared.registerMiddleware
        .factory(FeedSelectionHandler.init(resolver:))

        Navigator.shared.registerRoute.type(BindItemInToTeamBody.self)
        .factory(BindItemInToTeamHandler.init(resolver:))
    }

    public func registDebugItem(container: Container) {
        ({
            FeedDebugItem()
        }, SectionType.debugTool)
    }

    public func registRustPushHandlerInUserSpace(container: Container) {
        (Command.pushShortcuts, PushShortcutsHandler.init(resolver:))
        (Command.pushReconnection, PushReconnectionHandler.init(resolver:))
        (Command.pushFeedEntityPreviews, PushFeedEntityPreviewsHandler.init(resolver:))
        (Command.pushLoadFeedCardsStatus, PushLoadFeedCardsStatusHandler.init(resolver:))
        (Command.pushFeedFilterSettings, PushFeedFilterSettingsHandler.init(resolver:))
        (Command.pushItems, PushItemsHandler.init(resolver:))
        (Command.pushTeams, PushTeamsHandler.init(resolver:))
        (Command.pushItemExpired, PushItemExpiredHandler.init(resolver:))
        (Command.pushTeamMembers, PushTeamMembersHandler.init(resolver:))
        (Command.pushTeamItemChats, PushTeamItemChatsHandler.init(resolver:))
        (Command.pushFeedGroup, PushLabelHandler.init(resolver:))
        (Command.pushThreeColumnsSetting, PushFeedFixedFilterSettingsHandler.init(resolver:))
        (Command.pushBatchClearFeedBadge, PushClearFeedBadgeHandler.init(resolver:))
        (Command.pushBatchMuteFeedCards, PushBatchMuteFeedCardsHandler.init(resolver:))
        (Command.pushFeedActionSetting, PushFeedActionSettingHandler.init(resolver:))
    }
}

import LarkSetting
/// 用于FG控制UserResolver的迁移, 控制Resolver类型.
/// 使用UserResolver后可能抛错，需要控制对应的兼容问题
public enum Feed {
    public static var userScopeCompatibleMode: Bool { !Feed.Feature.userScopeFG }
    /// 替换.user, FG控制是否开启兼容模式。兼容模式和.user一致
    public static let userScope = UserLifeScope { userScopeCompatibleMode }
    /// 替换.graph, FG控制是否开启兼容模式。
    public static let userGraph = UserGraphScope { userScopeCompatibleMode }
}
