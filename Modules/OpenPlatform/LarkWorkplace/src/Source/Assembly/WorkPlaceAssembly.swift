//
//  WorkPlaceAssembly.swift
//  Action
//
//  Created by yinyuan on 2018/7/26.
//

import EENavigator
import LarkRustClient
import LarkUIKit
import Swinject
import UIKit
import LKCommonsLogging
import LarkTab
import LarkSceneManager
import OPSDK
import EEMicroAppSDK
import RoundedHUD
import WebBrowser
import LarkAppLinkSDK
import LarkAssembler
import BootManager
import LarkAccountInterface
import LarkGuide
import LarkNavigation
import Blockit
import LarkSetting
import LarkOpenWorkplace

public final class LarkWorkplaceAssembly: LarkAssemblyInterface {

    public init() {}

    // 注册路由
    public func registRouter(container: Container) {
        // 工作台 Tab 入口容器
        Navigator.shared.registerRoute.plain(Tab.appCenter.urlString)
            .priority(.high)
            .factory(WorkplaceHomeControllerHandler.init(resolver:))

        // 原生工作台
        Navigator.shared.registerRoute.type(WorkplaceNativeBody.self)
            .factory(WorkplaceNativeControllerHandler.init(resolver:))

        // 模版工作台
        Navigator.shared.registerRoute.type(WorkplaceTemplateBody.self)
            .factory(WorkplaceTemplateControllerHandler.init(resolver:))

        // Web工作台
        Navigator.shared.registerRoute.type(WorkplaceWebBody.self)
            .factory(WorkplaceWebControllerHandler.init(resolver:))

        // 工作台预览
        Navigator.shared.registerRoute.type(WorkplacePreviewBody.self)
            .factory(WorkplacePreviewControllerHandler.init(resolver:))

        // 工作台 AppLink 跳转能力
        Navigator.shared.registerRoute.type(WPHomeRootBody.self)
            .factory(WPHomeRootVCHandler.init(resolver:))

        // 应用搜索页面
        Navigator.shared.registerRoute.type(AppSearchBody.self)
            .factory(AppSearchControllerHandler.init(resolver:))

        // 应用 Badge 设置页
        Navigator.shared.registerRoute.type(AppBadgeSettingBody.self)
            .factory(AppBadgeSettingControllerHandler.init(resolver:))

        // 原生工作台设置页
        Navigator.shared.registerRoute.type(WorkplaceSettingBody.self)
            .factory(WorkplaceSettingControllerHandler.init(resolver:))

        // 常用设置页
        Navigator.shared.registerRoute.type(FavoriteSettingBody.self)
            .factory(FavoriteSettingControllerHandler.init(resolver:))

        // 工作台 Block 小组件预览
        Navigator.shared.registerRoute.type(BlockPreviewBody.self)
            .factory(BlockPreviewControllerHandler.init(resolver:))

        // Block 官方示例首页
        Navigator.shared.registerRoute.type(BlockDemoBody.self)
            .factory(BlockDemoControllerHandler.init(resolver:))

        // Block 官方示例列表页
        Navigator.shared.registerRoute.type(BlockDemoListBody.self)
            .factory(BlockDemoListControllerHandler.init(resolver:))

        // Block 官方示例详情页
        Navigator.shared.registerRoute.type(BlockDemoDetailBody.self)
            .factory(BlockDemoDetailControllerHandler.init(resolver:))

        // 运营弹窗
        Navigator.shared.registerRoute.type(OperationDialogBody.self)
            .factory(OperationDialogControllerHandler.init(resolver:))
    }

    // 注册 Tab
    public func registTabRegistry(container: Container) {
        (Tab.appCenter, { _ in WorkplaceTab() }) as (Tab, TabEntryProvider)
    }

    // 注册消息推送
    public func registRustPushHandlerInUserSpace(container: Container) {
        (Command.pushOpAppCenterUpdateV2, WorkplacePushHandler.init(resolver:))
        (Command.gadgetCommonPush, GadgetCommonPushHandler.init(resolver:))
        (Command.pushOpenAppBadgeNodes, WorkplaceBadgePushHandler.init(resolver:))
    }

    public func registContainer(container: Container) {
        let user = container.inObjectScope(WorkplaceScope.userScope)
        let userGraph = container.inObjectScope(WorkplaceScope.userGraph)

        user.register(WPInternalDependency.self) { r in
            let newGuideService = try r.resolve(assert: NewGuideService.self)
            let guideService = try r.resolve(assert: GuideService.self)
            let navigationService = try r.resolve(assert: NavigationService.self)
            return WPInternalDependency(
                newGuideService: newGuideService,
                guideService: guideService,
                navigationService: navigationService
            )
        }

        user.register(WPDependency.self) { r in
            let workplaceDependency = try r.resolve(assert: WorkPlaceDependency.self)
            let internalDependency = try r.resolve(assert: WPInternalDependency.self)
            return WPDependency(dependency: workplaceDependency, internalDependency: internalDependency)
        }

        userGraph.register(WorkplaceContext.self) { (r, trace: OPTrace) in
            let configService = try r.resolve(assert: WPConfigService.self)
            return WorkplaceContext(
                userResolver: r,
                userPushCenter: try r.userPushCenter,
                trace: trace,
                configService: configService
            )
        }

        user.register(WPConfigService.self) { r in
            let fgService = try r.resolve(assert: FeatureGatingService.self)
            let settingService = try r.resolve(assert: SettingService.self)
            return WPConfigServiceImpl(fgService: fgService, settingService: settingService)
        }

        user.register(WorkplaceOpenAPI.self) { r in
            let dataManager = try r.resolve(assert: AppCenterDataManager.self)
            let pushCenter = try r.userPushCenter
            return WorkplaceOpenAPIImpl(pushCenter: pushCenter, dataManager: dataManager)
        }

        user.register(WPTraceService.self) { r in
            return WPTraceServiceImpl()
        }

        user.register(WorkplacePrefetchService.self) { r in
            let root = try r.resolve(assert: WPRootDataMgr.self)
            let badgeServiceContainer = try r.resolve(assert: WPBadgeServiceContainer.self)
            let blockDataService = try r.resolve(assert: WPBlockDataService.self)
            let normalWorkplace = try r.resolve(assert: AppCenterDataManager.self)
            let badgeAPI = try r.resolve(assert: BadgeAPI.self)
            let configService = try r.resolve(assert: WPConfigService.self)

            let isPreview: Bool = false
            let previewToken: String? = nil
            let template = try r.resolve(
                assert: TemplateDataManager.self, arguments: isPreview, previewToken
            )
            let rootTrace = try r.resolve(assert: WPTraceService.self).root
            let context = try r.resolve(assert: WorkplaceContext.self, argument: rootTrace)
            return WorkplacePrefetchServiceImpl(
                root: root,
                template: template,
                badgeServiceContainer: badgeServiceContainer,
                blockDataService: blockDataService,
                normalWorkplace: normalWorkplace,
                badgeAPI: badgeAPI,
                context: context
            )
        }

        user.register(WPRootDataMgr.self) { r in
            let traceService = try r.resolve(assert: WPTraceService.self)
            let context = try r.resolve(assert: WorkplaceContext.self, argument: traceService.root)
            let networkService = try r.resolve(assert: WPNetworkService.self)
            return WPRootDataMgr(
                context: context,
                networkService: networkService
            )
        }

        userGraph.register(TemplateDataManager.self) { (r, isPreview: Bool, previewToken: String?) in
            let traceService = try r.resolve(assert: WPTraceService.self)
            let workplaceBadgeService = try r.resolve(assert: WorkplaceBadgeService.self)
            let configService = try r.resolve(assert: WPConfigService.self)
            let userService = try r.resolve(assert: PassportUserService.self)
            let networkService = try r.resolve(assert: WPNetworkService.self)
            return TemplateDataManager(
                userResolver: r,
                userId: r.userID,
                tenantId: userService.userTenant.tenantID,
                isPreview: isPreview,
                previewToken: previewToken,
                traceService: traceService,
                workplaceBadgeService: workplaceBadgeService,
                configService: configService,
                networkService: networkService
            )
        }

        user.register(WPBadgeServiceContainer.self) { r in
            let config = try r.resolve(assert: BadgeConfig.self)
            let appCenterBadgeService = try r.resolve(assert: AppCenterBadgeService.self)
            let workplaceBadgeService = try r.resolve(assert: WorkplaceBadgeService.self)
            let configService = try r.resolve(assert: WPConfigService.self)
            // 由于不同的预加载策略，WPBadgeServiceContainer 与 WorkplacePrefetchService 有循环依赖
            // 预加载 FG 全量后应该可以解掉
            let prefetchServiceProvider = {
                try? r.resolve(assert: WorkplacePrefetchService.self)
            }
            return WPBadgeServiceContainer(
                config: config,
                appCenterBadgeService: appCenterBadgeService,
                workplaceBadgeService: workplaceBadgeService,
                configService: configService,
                prefetchServiceProvider: prefetchServiceProvider
            )
        }

        user.register(BadgeConfig.self) { r in
            let configService = try r.resolve(assert: WPConfigService.self)
            return BadgeConfig(configService: configService)
        }

        user.register(AppCenterBadgeService.self) { r in
            let rustService = try r.resolve(assert: RustService.self)
            let dataManager = try r.resolve(assert: AppCenterDataManager.self)
            let pushCenter = try r.userPushCenter
            return AppCenterBadgeServiceImpl(
                rustService: rustService, dataManager: dataManager, pushCenter: pushCenter
            )
        }

        user.register(WorkplaceBadgeService.self) { r in
            let traceService = try r.resolve(assert: WPTraceService.self)
            let rustService = try r.resolve(assert: RustService.self)
            let pushCenter = try r.userPushCenter
            let configService = try r.resolve(assert: WPConfigService.self)
            return WorkplaceBadgeServiceImpl(
                traceService: traceService,
                rustService: rustService,
                pushCenter: pushCenter,
                configService: configService
            )
        }

        user.register(BadgeAPI.self) { r in
            let rustService = try r.resolve(assert: RustService.self)
            return RustBadgeAPI(rustService: rustService)
        }

        user.register(WPBlockDataService.self) { r in
            let traceService = try r.resolve(assert: WPTraceService.self)
            let blockService = try r.resolve(assert: BlockitService.self)
            let networkService = try r.resolve(assert: WPNetworkService.self)
            return WPBlockDataServiceImpl(
                traceService: traceService,
                blockService: blockService,
                networkService: networkService
            )
        }

        user.register(AppCenterDataManager.self) { r in
            let traceService = try r.resolve(assert: WPTraceService.self)
            let rustService = try r.resolve(assert: RustService.self)
            let dependency = try r.resolve(assert: WPDependency.self)
            let networkService = try r.resolve(assert: WPNetworkService.self)
            let homeDataService = try r.resolve(assert: WPNormalHomeDataService.self)
            let configService = try r.resolve(assert: WPConfigService.self)
            let userService = try r.resolve(assert: PassportUserService.self)
            // 原来的 AppCenterDataManager 是单例，解偶为依赖注入后，与 AppCenterBadgeService 形成了循环依赖
            let appCenterBadgeServiceProvider = {
                try? r.resolve(assert: AppCenterBadgeService.self)
            }
            return AppCenterDataManager(
                userId: r.userID,
                traceService: traceService,
                dependency: dependency,
                networkService: networkService,
                rustService: rustService,
                homeDataService: homeDataService,
                configService: configService,
                appCenterBadgeServiceProvider: appCenterBadgeServiceProvider,
                userService: userService
            )
        }

        user.register(WPHomePageDisplayStateService.self) { r in
            let navigationService = try r.resolve(assert: NavigationService.self)
            return WPHomePageDisplayStateServiceImpl(navigationService: navigationService)
        }

        user.register(AppBadgeListenerService.self) { r in
            let pushCenter = try r.userPushCenter
            let configService = try r.resolve(assert: WPConfigService.self)
            return AppBadgeListenerServiceImpl(pushCenter: pushCenter, configService: configService)
        }

        user.register(WPNormalHomeDataService.self) { r in
            return WPNormalHomeDataServiceImpl()
        }

        userGraph.register(WPAppSearchModel.self) { r in
            let dataManager = try r.resolve(assert: AppCenterDataManager.self)
            let configService = try r.resolve(assert: WPConfigService.self)
            return WPAppSearchModel(dataManager: dataManager, configService: configService)
        }

        userGraph.register(AppBadgeSettingViewModel.self) { r in
            let dataManager = try r.resolve(assert: AppCenterDataManager.self)
            return AppBadgeSettingViewModel(dataManager: dataManager)
        }

        userGraph.register(WorkplaceOpenService.self) { r in
            let dataManager = try r.resolve(assert: AppCenterDataManager.self)
            let navigator = r.navigator
            let dependency = try r.resolve(assert: WPDependency.self)
            let userService = try r.resolve(assert: PassportUserService.self)
            return WorkplaceOpenServiceImpl(
                userId: r.userID,
                tenantId: userService.userTenant.tenantID,
                dataManager: dataManager,
                navigator: navigator,
                dependency: dependency
            )
        }

        userGraph.register(WidgetDataCacheProtocol.self) { r in
            let configService = try r.resolve(assert: WPConfigService.self)
            return WidgetDataCache(userID: r.userID, configService: configService)
        }

        userGraph.register(WidgetDataManage.self) { r in
            let pushCenter = try r.userPushCenter
            let traceService = try r.resolve(assert: WPTraceService.self)
            let gadgetCache = try r.resolve(assert: WidgetDataCacheProtocol.self)
            let networkService = try r.resolve(assert: WPNetworkService.self)
            return WidgetDataManage(
                pushCenter: pushCenter,
                traceService: traceService,
                gadgetCache: gadgetCache,
                networkService: networkService
            )
        }

        user.register(WPNetworkService.self) { r in
            let service = try r.resolve(assert: ECONetworkService.self)
            return WPNetworkServiceImpl(userResolver: r, service: service)
        }

        userGraph.register(OperationDialogMgr.self) { r in
            let userService = try r.resolve(assert: PassportUserService.self)
            let traceService = try r.resolve(assert: WPTraceService.self)
            let configService = try r.resolve(assert: WPConfigService.self)
            let networkService = try r.resolve(assert: WPNetworkService.self)
            return OperationDialogMgr(
                userService: userService,
                traceService: traceService,
                configService: configService,
                networkService: networkService
            )
        }
    }

    public func registLaunch(container: Container) {
        NewBootManager.register(WorkplaceBeforeLoginTask.self)
        NewBootManager.register(WorkplaceStartUpTask.self)
    }

    public func registLarkAppLink(container: Container) {
        // 工作台门户: /client/workplace/open
        LarkAppLinkSDK.registerHandler(
            path: WorkplaceHomeAppLinkHandler.pattern,
            handler: WorkplaceHomeAppLinkHandler.handle(applink:)
        )

        // 工作台预览: /client/workplace/preview
        LarkAppLinkSDK.registerHandler(
            path: WorkplacePreviewAppLinkHandler.pattern,
            handler: WorkplacePreviewAppLinkHandler.handle(applink:)
        )

        // Block 真机预览: /client/block/open
        LarkAppLinkSDK.registerHandler(
            path: BlockPreviewAppLinkHandler.pattern,
            handler: BlockPreviewAppLinkHandler.handle(applink:)
        )

        // Block 官方示例: /client/block/workplace/open
        LarkAppLinkSDK.registerHandler(
            path: BlockDemoAppLinkHandler.pattern,
            handler: BlockDemoAppLinkHandler.handle(applink:)
        )

        // 应用可见性申请: /client/app_apply_visibility/open
        LarkAppLinkSDK.registerHandler(
            path: AppApplyAppLinkHandler.pattern,
            handler: AppApplyAppLinkHandler.handle(applink:)
        )
    }

    public func registLarkScene(container: Container) {
        if #available(iOS 13.4, *), WorkPlaceScene.supportMutilScene() {
            SceneManager.shared.register(config: WorkplaceWebSceneConfig.self)
        }
    }
}
