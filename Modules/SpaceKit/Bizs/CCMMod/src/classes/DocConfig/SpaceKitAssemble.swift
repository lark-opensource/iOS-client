//
//  SpaceKitAssemble.swift
//  LarkSpaceKit
//
//  Created by maxiao on 2019/4/8.
//

import LarkContainer
import Swinject
import EENavigator
import LKCommonsLogging
import LarkFoundation
import SpaceInterface
import SpaceKit
import LarkCustomerService
import LarkAccountInterface
import LarkOpenFeed

#if MessengerMod
import LarkMessengerInterface
#endif

import LarkUIKit
import LarkNavigator
import LarkNavigation
import AppContainer
import AnimatedTabBar
import LarkAppLinkSDK
import LarkAppConfig
import BootManager
import SKCommon
import SKComment
import SKFoundation
import SKSpace
import SKDrive
import SKBrowser
import SKInfra
import SKUIKit
import SKResource
import UniverseDesignColor
import LarkTab
import LarkSceneManager
import LarkRustClient
import LarkAssembler
import LarkSplitViewController
import SKBitable
import LarkModel
import LarkOPInterface
import LarkOpenSetting
import LarkSettingUI

#if !canImport(LarkSearch) && canImport(LarkQuickLaunchInterface)
import LarkQuickLaunchInterface
#endif

// LarkAssembly拆分 https://bytedance.feishu.cn/docx/doxcn2C8YYPr0CJZnGNRJflQX1c
public final class SpaceKitAssemble: LarkAssemblyInterface {
    static let log = Logger.log(SpaceKitAssemble.self, category: "SpaceKitAssemble")

    public init() {}

//    static public func registNonAssembleTask() {
//        //拆出非assemble任务
//        ConsumerRegistry.registerConsumer(DocsConsumer(resolver: BootLoader.container))
//    }

    private func getRegistPush(pushCenter: PushNotificationCenter) -> [Command: RustPushHandlerFactory] {
        let factories: [Command: RustPushHandlerFactory] = [
            .pushDynamicNetStatus: {
                DynamicNetStatusPushHandler(pushCenter: pushCenter)
            },
            .pushCipherChangedEvent: {
                PushCipherChangedEventHandler()
            }
        ]
        return factories
    }
// MARK: - LarkAssemblyInterface
    public func registContainer(container: Swinject.Container) {
        let resolver = container
        let userContainer = container.inObjectScope(CCMUserScope.userScope)
        let userTransientContainer = container.inObjectScope(CCMUserScope.userTransient)
        
        userContainer.register(FormsChooseContactProtocol.self) { _ in
            FormsChooseContactImpl()
        }

        userContainer.register(UserScopedObject.self) { _ in
            return UserScopedObject()
        }
        
        userContainer.register(CCMFeatureGatingService.self) {
            return CCMFeatureGatingImpl(resolver: $0)
        }
        
        userContainer.register(EditorManager.self) {
            return EditorManager(userResolver: $0)
        }
        
//        container.register(DocsConsumer.self) { _ in
//            return DocsConsumer(resolver: resolver)
//        }.inObjectScope(.container)

        container.register(DocsDependency.self) { (_) -> DocsDependency in
            return DocsDependencyImpl(resolver: resolver)
        }.inObjectScope(.container)

        container.register(DocsFactoryDependency.self) { (_) -> DocsFactoryDependency in
            return DocsFactoryDependencyImpl(resolver: resolver)
        }.inObjectScope(.container)

        container.register(DocSDKAPI.self) { (_) in
            let docsViewControllerFactory = resolver.resolve(DocsViewControllerFactory.self)!
            return DocSDKAPIImpl(docSDK: docsViewControllerFactory.docs)
        }.inObjectScope(.container)

        container.register(DocsViewControllerFactory.self) { (r) in
            let docsViewControllerFactory = DocsViewControllerFactory(
                dependency: r.resolve(DocsFactoryDependency.self)!,
                resolver: resolver
            )
            docsViewControllerFactory.initDocsSDK()

            let pushCenter = r.pushCenter
            docsViewControllerFactory.setPushCenter(pushCenter)
            return docsViewControllerFactory
        }.inObjectScope(.container)

        container.register(DocCommonUploadProtocol.self) { _ in
            return DocCommonUploader()
        }.inObjectScope(.container)

        container.register(DocCommonDownloadProtocol.self) { _ in
            return DocCommonDownloader()
        }.inObjectScope(.container)

        container.register(FollowAPIFactory.self) { (_) in
            let docsViewControllerFactory = resolver.resolve(DocsViewControllerFactory.self)!
            return DocsVCFollowFactory(docsSDK: docsViewControllerFactory.docs)
        }
        container.register(QuotaAlertService.self) { _ in
            return QuotaAlertPresentor.shared
        }

        container.register(DocsUserCacheServiceProtocol.self) { _ in
            return DocsUserCacheService()
        }.inObjectScope(.container)

        //这里不要再改动，后续DocsContaioner 内部fg去掉后，这里也可以同步去掉
        container.register(DriveSDK.self) { r in
            let factory = r.resolve(DocsViewControllerFactory.self)!
            return factory.driveSDK
        }.inObjectScope(.container)

        #if MessengerMod
        container.register(AskOwnerDependency.self) { _ in
            return AskOwnerDependencyImpl()
        }.inObjectScope(.container)

        container.register(DocPermissionDependency.self) { resolver in
            return DocPermissionDependencyImpl(resolver: resolver)
        }.inObjectScope(.container)
        #endif

        container.register(DocPermissionProtocol.self) { _ in
            return DocPermissionProtocolImpl()
        }.inObjectScope(.container)

        container.register(DocShareViewControllerDependency.self) { _ in
            return DocShareViewControllerDependencyImpl()
        }.inObjectScope(.container)
        
        container.register(DocCommentModuleSDK.self) { _, paramsBody in
            return DocCommentModuleSDKImpl(paramsBody: paramsBody)
        }.inObjectScope(.transient) // transient保证每次resolve出来都是不同的实例

        DocsContainer.shared.register(CollaboratorSearchAPI.self) { _ in
            return CollaboratorSearchAPIImpl(resolver: resolver)
        }.inObjectScope(.user)

        DocsContainer.shared.register(DocSearchAPI.self) { _ in
            return DocSearchAPIImpl(resolver: resolver)
        }.inObjectScope(.user)

        container.register(DocsTemplateCreateProtocol.self) { _ in
            return DocsTemplateCreateImpl()
        }.inObjectScope(.container)
        
        container.register(SpaceDownloadCacheProtocol.self) { _ in
            return DocDownloadCacheService.shared
        }
        
        userContainer.register(SKEditorDocsViewCreateInterface.self) {
            return SKEditorDocsViewCreateInterfaceImp(userResolver: $0)
        }
        
        container.register(CommentResourceInterface.self) { _ in
            return CommentResourceInterfaceImp()
        }.inObjectScope(.container)
        
        container.register(CCMAIService.self) { r in
            return CCMAIServiceImpl(resolver: r)
        }.inObjectScope(.user)
        
        container.register(CCMTranslateService.self) { r in
            return CCMTranslateImpl(resolver: r)
        }.inObjectScope(.user)
        
        container.inObjectScope(.user).register(CCMAILaunchBarService.self) { r in
            return CCMAILaunchBarServiceImpl(resolver: r)
        }

        container.register(DriveMoreActionProtocol.self, factory: { (_) -> DriveMoreActionProtocol in
            return DriveFileExportCapacity.shared
        })

        userContainer.register(WorkspaceSearchFactory.self) { userResolver in
            return CCMSearchFactory(userResolver: userResolver)
        }
        
        userContainer.register(BitableSearchFactoryProtocol.self) { userResolver in
            return BitableSearchFactory(userResolver: userResolver)
        }
        
        userContainer.register(BitableVCFactoryProtocol.self) { userResolver in
            return BitableVCFactoryImpl(userResolver: userResolver)
        }
        
        userContainer.register(DocsPickerFactory.self) { userResolver in
            return CCMSearchFactory(userResolver: userResolver)
        }

        userContainer.register(NetConfig.self, factory: {
            return NetConfig(userResolver: $0)
        })
        
        userContainer.register(SKCommon.User.self, factory: { (userResolver) -> SKCommon.User in
            let service = try userResolver.resolve(assert: PassportUserService.self)
            let tenantID = service.user.tenant.tenantID
            let session = service.user.sessionKey
            let isGuest = service.user.isGuestUser
            let instance = SKCommon.User(userResolver: userResolver)
            DocsLogger.info("create SKCommon.User instance in userScope \(ObjectIdentifier(instance))")
            instance.reloadUser(basicInfo: BasicUserInfo(userResolver.userID, tenantID, session, isGuest))
            instance.refreshUserProfileIfNeed()
            return instance
        })

        container.register(DocComponentSDK.self) { _ in
            return DocComponentSDKImpl.shared
        }.inObjectScope(.container)
        
        container.register(TemplateAPI.self) { _ in
            return TemplateAPIImpl.shared
        }.inObjectScope(.container)
                
        DocsContainer.shared.register(CCMTranslateAPI.self) { _ in
            return CCMSelectTranslateImpl.shared
        }.inObjectScope(.container)
        let graphContainer = container.inObjectScope(CCMUserScope.userGraph)
        // doc feed card dependency
        #if MessengerMod
        graphContainer.register(DocFeedCardDependency.self) { r -> DocFeedCardDependency in
            return try DocFeedCardDependencyImpl(resolver: r)
        }
        #endif
        
        // TODO: howie，现回退SKDataMananger用户态改造
//        userContainer.register(SKDataManager.self, factory: {
//            let instance = SKDataManager(userResolver: $0)
//            DocsLogger.info("create SKDataManager instance in userScope \(ObjectIdentifier(instance))")
//            return instance
//        })
        
//        userContainer.register(DataCenter.self, factory: { _ in
//            let instance = DataCenter()
//            DocsLogger.info("create DataCenter instance in userScope \(ObjectIdentifier(instance))")
//            return instance
//        })
        container.inObjectScope(.user).register(DocHtmlCacheFetchManager.self) { r in
            return DocHtmlCacheFetchManager(userResolver: r)
        }
        
        //用户容器注册，需要获取 UserResolver
        userContainer.register(BTLynxContainerEnvService.self) { resolver ->
            BTLynxContainerEnvService in
            return BTLynxContainerEnvironment(resolver: resolver)
        }.inObjectScope(.user)

        userContainer.register(CCMMagicShareDowngradeService.self) {
            MSDowngradeServiceImpl(userResolver: $0)
        }
        
        userTransientContainer.register(DocPluginForWebProtocol.self) { userResolver in
            return DocPluginForWebImp(userResolver)
        }
        
        #if !canImport(LarkSearch) && canImport(LarkQuickLaunchInterface)
        userContainer.register(OpenNavigationProtocol.self) { _ in
            OpenNavigationImpl()
        }
        #endif
    }

    public func registRouter(container: Swinject.Container) {
        let resolver = container

        Navigator.shared.registerRoute_(plainPattern: Tab.doc.urlString, priority: .high) {
            return TabDocsViewControllerHandler(resolver: resolver)
        }

        Navigator.shared.registerRoute_(type: CreateDocBody.self) {
            return CreateDocHandler(resolver: resolver)
        }

        #if MessengerMod
        Navigator.shared.registerRoute_(type: AskOwnerBody.self) {
            return AskOwnerViewControllerHandler()
        }
        #endif

        Navigator.shared.registerRoute_(type: EmbedDocAuthControllerBody.self) {
            return EmbedDocAuthControllerHandler()
        }

        Navigator.shared.registerRoute_(type: DocShareViewControllerBody.self) {
            return DocShareViewControllerHandler()
        }

        Navigator.shared.registerRoute_(type: DriveLocalFileControllerBody.self) {
            return DriveLocalFilePreviewControllerHandler(resolver: resolver)
        }
        Navigator.shared.registerRoute_(
            match: { (url) -> Bool in
                let passportService = try? resolver.resolve(assert: PassportService.self)
                let isLogin = passportService?.foregroundUser != nil
                if !isLogin {
                    return false
                }
                let docSDKAPI = resolver.resolve(DocSDKAPI.self)!
                return docSDKAPI.canOpen(url: url.absoluteString)
            },
            tester: { req in
                req.context["_canOpenInDocs"] = true
                if URLValidator.isDocsURL(req.url) {
                    req.context["_canCloseBrowser"] = true
                }
                return true
            }
        ) {
            return DocsViewControllerHandler(resolver: resolver)
        }

        Navigator.shared.registerRoute_(type: LarkSearchChatPickerBody.self) {
            return LarkSearchChatPickerHandler(resolver: resolver)
        }

        Navigator.shared.registerRoute_(type: LarkSearchContactPickerBody.self) {
            return LarkSearchContactPickerHandler(resolver: resolver)
        }

        // 处理: lark://client/doc 处理本地通知
        Navigator.shared.registerRoute_(type: DocPushBody.self, cacheHandler: true) { () -> TypedRouterHandler<DocPushBody> in
            return DocPushBodyHandler(resolver: resolver)
        }

        Navigator.shared.registerRoute_(type: SendDocBody.self) { () -> TypedRouterHandler<SendDocBody> in
            return SendDocRouterHandler(resolver: resolver)
        }

        // 注册 Wiki Tab
        Navigator.shared.registerRoute_(plainPattern: Tab.wiki.urlString, priority: .high) {
            return TabWikiViewControllerHandler(resolver: resolver)
        }
        // 注册 Base Tab
        Navigator.shared.registerRoute_(plainPattern: Tab.base.urlString, priority: .high) {
            return TabBaseViewControllerHandler(resolver: resolver)
        }
        // 处理展示任务执行者
        Navigator.shared.registerRoute_(type: LarkShowTaskAssigneeBody.self) {
            return LarkShowTaskAssigneeHandler(resolver: resolver)
        }
        // 处理搜索任务执行者
        Navigator.shared.registerRoute_(type: LarkSearchAssigneePickerBody.self) {
            return LarkSearchAssigneePickerHandler(resolver: resolver)
        }
        // 处理任务创建页
        Navigator.shared.registerRoute_(type: LarkShowCreateTaskBody.self) {
            return LarkShowCreateTaskHandler(resolver: resolver)
        }

        Navigator.shared.registerRoute.type(CCMUserSettingsBody.self)
            .factory(CCMUserSettingsBodyHandler.init(resolver:))
    }

    public func registURLInterceptor(container: Swinject.Container) {
        // Doc 本地通知
        (DocPushBody.pattern, { (url: URL, from: NavigatorFrom) in
            Navigator.shared.showDetailOrPush(url: url, tab: .feed, from: from)
        })

        // Space 推送
        (SKNoticePushRouterBody.pattern, { (url: URL, from: NavigatorFrom) in
            Navigator.shared.present(url, from: from)
        })
    }

    public func registLaunch(container: Swinject.Container) {
        NewBootManager.register(SetupDocsHandleLoginTask.self)
        NewBootManager.register(LoadDocsTask.self)
        NewBootManager.register(SetupDocsTask.self)
    }

    public func registLauncherDelegate(container: Swinject.Container) {
        (LauncherDelegateFactory {
            container.whenLauncherDelegate {
                DocsLaunchDelegate(resolver: container)
            }
        }, LauncherDelegateRegisteryPriority.middle)
    }

    public func registPassportDelegate(container: Container) {
        (PassportDelegateFactory {
            container.whenPassportDelegate {
                DocsPassportDelegate(resolver: container)
            }
        }, PassportDelegatePriority.middle)
    }

    public func registPushHandler(container: Swinject.Container) {
        getRegistPush(pushCenter: container.pushCenter)
    }

    public func registLarkAppLink(container: Swinject.Container) {
        LarkAppLinkSDK.registerHandler(path: "/client/docs/open", handler: { (applink: AppLink) in
            /*
            guard let from = applink.context?.from() else { return }
            if let urlString = applink.url.queryParameters["url"],
               let url = URL(string: urlString) {
                Navigator.shared.push(url, from: from)
            }
             */
            // 增加一些日志，不修改逻辑，遇到问题后不至于没日志降低效能陷入被动
            // 其实在每个 else 分支都可以加一个 toast 说明错误原因，不然用户视角就是点了 link 啥反应都没
            guard let context = applink.context else {
                DocsLogger.error("applink.context is nil")
                return
            }
            guard let from = context.from() else {
                DocsLogger.error("context.from() is nil")
                return
            }
            // queryParameters这个方法有待讨论，从严格的技术角度，query其实是个数组，这里不修改需求无关逻辑，但是日后是否需要显示的修改成取数组里第一个？
            guard let urlString = applink.url.queryParameters["url"] else {
                DocsLogger.error("applink.url.queryParameters.url query is nil")
                return
            }
            guard let url = URL(string: urlString) else {
                // urlString 和 lijuyou 确认过，error 级别的 log 底层会过滤
                DocsLogger.error("urlString new URL is nil, urlString is \(urlString)")
                return
            }
            
            let animated = context["animatedValueFromRouter"] as? Bool ?? true
            // 严格意义上这里应该判断一下 URL 是否是 CCM 业务域内的，否则可能会被当作跳板打开其他业务，这里还有个安全风险，相当于通过 docs/open 把所有飞书的内部路由对飞书外部开放了，毕竟 applink 是开放的嘛
            //  兼容 iPad 场景 showDetail 的场景
            if Display.pad, let fromVC = from.fromViewController, fromVC is DefaultDetailVC {
                DocsLogger.info("fromVC is DefaultDetailVC, should not push, should showDetailOrPush")
                Navigator.shared.showDetailOrPush(url, wrap: LkNavigationController.self, from: fromVC, animated: animated)
            } else {
                Navigator.shared.push(url, from: from, animated: animated)
            }
        })
        LarkAppLinkSDK.registerHandler(path: "/client/docs/template", handler: { applink in
            guard let from = applink.context?.from(), let fromVC = from.fromViewController else { return }
            let docsTabFrom = WindowTopMostFrom(vc: fromVC)
            var queryDict = applink.url.queryParameters

            if let enterSource = queryDict["enterSource"], enterSource == "bitable_ws_landing_banner" {
                queryDict["objType"] = String(DocsType.bitable.rawValue)
                queryDict["from"] = "bitable_ws_landing_banner"
            } else if let enterSource = queryDict["enterSource"], enterSource.hasPrefix("base_hp_") {
                queryDict["objType"] = String(DocsType.bitable.rawValue)
            } else {
                Navigator.shared.switchTab(Tab.doc.url, from: from)
            }

            let body = TemplateCenterBody(queryDict: queryDict)
            Navigator.shared.presentOrPush(body: body,
                                           wrap: LkNavigationController.self,
                                           from: docsTabFrom,
                                           prepareForPresent: { (vc) in
                vc.modalPresentationStyle = .formSheet
            })
        })

#if MessengerMod
        LarkAppLinkSDK.registerHandler(path: "/client/docs/ask_owner", handler: { applink in
            guard let from = applink.context?.from(), let fromVC = from.fromViewController else { return }
            let queryDict = applink.url.queryParameters
            let tempBody = AskOwnerControllerBody(queryDict: queryDict, fromVc: fromVC)
            let body = AskOwnerBody(collaboratorID: tempBody.collaboratorID,
                                    ownerName: tempBody.ownerName,
                                    ownerID: tempBody.ownerID,
                                    docsType: tempBody.docsType,
                                    objToken: tempBody.objToken,
                                    imageKey: tempBody.imageKey,
                                    title: tempBody.title,
                                    detail: tempBody.detail,
                                    isExternal: tempBody.isExternal,
                                    isCrossTenanet: tempBody.isCrossTenanet,
                                    needPopover: tempBody.needPopover,
                                    roleType: tempBody.roleType)
            Navigator.shared.present(body: body, from: from, animated: false)
        })

#endif

        LarkAppLinkSDK.registerHandler(path: "/client/docs/embed", handler: { applink in
            guard let from = applink.context?.from(), let fromVC = from.fromViewController else { return }
            let queryDict = applink.url.queryParameters
            let body = EmbedDocAuthControllerBody(queryDict: queryDict, fromVc: fromVC)
//            let docsTabFrom = WindowTopMostFrom(vc: fromVC)
//            Navigator.shared.push(body: body, from: docsTabFrom)

            let vc = EmbedDocAuthViewController(body: body)
            Navigator.shared.docs.showDetailOrPush(vc, from: fromVC)
        })

        LarkAppLinkSDK.registerHandler(path: "/client/docs/open_doc_template", handler: { applink in
            guard let from = applink.context?.from(), let fromVC = from.fromViewController else { return }
            var queryDict = applink.url.queryParameters
            let body = TemplatePreviewBody(parameters: queryDict, fromVC: fromVC)
            Navigator.shared.presentOrPush(body: body,
                                           wrap: LkNavigationController.self,
                                           from: fromVC,
                                           prepareForPresent: { (vc) in
                vc.modalPresentationStyle = .formSheet
            })
        })

        LarkAppLinkSDK.registerHandler(path: "/client/docs/permission/secret/setting", handler: { applink in
            guard let from = applink.context?.from(), let fromVC = from.fromViewController else { return }
            let queryDict = applink.url.queryParameters
            let body = AdjustSettingsBody(parameters: queryDict)
            Navigator.shared.presentOrPush(body: body,
                                           wrap: LkNavigationController.self,
                                           from: fromVC,
                                           prepareForPresent: { (vc) in
                vc.modalPresentationStyle = .formSheet
            })
        })

        LarkAppLinkSDK.registerHandler(path: "/client/docs/share_recommend") { applink in
            guard UserScopeNoChangeFG.WWJ.imShareLeaderEnable else { return }
            guard let from = applink.context?.from(), let fromVC = from.fromViewController else { return }
            let body = CCMShareLeaderGuideBody()
            Navigator.shared.present(body: body, from: fromVC)
        }

        // 参考 LarkMessageCoreAssembly
        // 目前没有机制、时机支持UDColor，沟通后确认可放到registLarkAppLink
        UDColor.registerUDBizColor(UDCCMBizColor())
    }

    public func registTabRegistry(container: Swinject.Container) {
        (Tab.doc, { (urls: [URLQueryItem]?) -> TabRepresentable in
            DocsTab()
        })
        (Tab.wiki, { (urls: [URLQueryItem]?) -> TabRepresentable in
            WikiTab()
        })
        (Tab.base, { (urls: [URLQueryItem]?) -> TabRepresentable in
            BaseTab()
        })
    }

    @available(iOS 13.0, *)
    public func registLarkScene(container: Swinject.Container) {
        SceneManager.shared.register(config: DocsSceneConfig.self)
    }

    @_silgen_name("Lark.Feed.FloatMenu.CCM")
    static public func feedFloatMenuRegister() {
        FeedFloatMenuModule.register(CCMCreateDocsMenuSubModule.self)
    }
    
    @_silgen_name("Lark.Feed.Listener.Doc.Preload")
    static public func registerFeedDocPreloadListener() {
        FeedListenerProviderRegistery.register(provider: { _ in FeedDocPreLoadListener() })
    }
    #if MessengerMod
    @_silgen_name("Lark.Feed.FeedCard.Doc")
    static public func registOpenFeed() {
        FeedCardModuleManager.register(moduleType: DocFeedCardModule.self)
        FeedActionFactoryManager.register(factory: { DocFeedActionMuteFactory() })
        FeedActionFactoryManager.register(factory: { DocFeedActionJumpFactory() })
    }
    #endif
    
    #if !canImport(LarkSearch) && canImport(LarkQuickLaunchInterface)
    private final class OpenNavigationImpl: OpenNavigationProtocol {
        func notifyNavigationAppInfos(appInfos: [OpenNavigationAppInfo]) {}
    }
    #endif

    @_silgen_name("Lark.OpenSetting.CCMSettingAssembly")
    public static func pageFactoryRegister() {
        PageFactory.shared.register(page: .main, moduleKey: ModulePair.Main.ccmEntry.moduleKey) { userResolver in
            guard UserScopeNoChangeFG.WWJ.ccmSettingVisable else { return nil }
            return GeneralBlockModule(userResolver: userResolver,
                                      title: SKResource.BundleI18n.SKResource.LarkCCM_IM_SharingSuggestions_Docs_Title_Mob) { userResolver, fromVC in
                userResolver.navigator.push(body: CCMUserSettingsBody(), from: fromVC)
            }
        }
    }
}

/// CCM 文档页面
@available(iOS 13.0, *)
class DocsSceneConfig: SceneConfig {

    static var key: String { "Docs" }

    static func icon() -> UIImage { BundleResources.CCMMod.Docs.icon_doc_colorful }

    static func createRootVC(scene: UIScene, session: UISceneSession, options: UIScene.ConnectionOptions,
                             sceneInfo: Scene, localContext: AnyObject?) -> UIViewController? {
        var userInfo = sceneInfo.userInfo as [String: Any]
        // 去掉 token 再传给 factory，否则会被明文加到 UA 里
        userInfo[Scene.docs.kCCMSceneInfoTokenKey] = nil
        userInfo["showTemporary"] = false
        
        let docsUrl = sceneInfo.id
        let docSDKAPI = Injected<DocSDKAPI>().wrappedValue
        guard docSDKAPI.canOpen(url: docsUrl) else { return nil }
        let dependency = Injected<DocsDependency>().wrappedValue
        let docsViewControllerFactory = Injected<DocsViewControllerFactory>().wrappedValue
        if let vc = docsViewControllerFactory.create(dependency: dependency, url: URL(string: docsUrl), infos: userInfo) {
            return LkNavigationController(rootViewController: vc)
        } else {
            assertionFailure("cannot get vc")
            return nil
        }
    }

    static func contextualIcon(on imageView: UIImageView, with sceneInfo: Scene) {
        guard let icon = Scene.docs.contextualIcon(for: sceneInfo) else { return }
        imageView.contentMode = .scaleAspectFit
        imageView.image = icon
    }
}

public class FormsChooseContactImpl: FormsChooseContactProtocol {
    
    public func chooseContact(
        vc: UIViewController,
        featureConfig: LarkModel.PickerFeatureConfig,
        searchConfig: LarkModel.PickerSearchConfig,
        contactConfig: LarkModel.PickerContactViewConfig,
        dele: LarkModel.SearchPickerDelegate
    ) {
#if MessengerMod
        var body = ContactSearchPickerBody()
        
        body.featureConfig = featureConfig
        body.searchConfig = searchConfig
        body.contactConfig = contactConfig
        body.delegate = dele
        
        Navigator
            .shared
            .present(
                body: body,
                from: vc
            )
#endif
    }
    
}
