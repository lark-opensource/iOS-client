//
//  main.swift
//  LarkAccountDemo
//
//  Created by Supeng on 2021/1/15.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import BootManager
import BootManagerDependency
import AppContainer
import Swinject
import RxSwift
import RxCocoa
import WebBrowser
import LarkWebViewContainer
import LarkUIKit
import SpaceInterface
import LarkRustClient
import LarkAccountInterface
import AnimatedTabBar
import LarkMail
import LarkSDKInterface
import EENavigator
import LarkTab
import LarkEditorJS
import ECOProbe
import LKTracing
import LarkLocalizations
import RunloopTools
import LarkNavigation
import LarkAssembler
import LarkEMM
import LarkSecurityComplianceInfra
import SKDrive

#if CalendarMod
import CalendarMod
#endif


#if LARKCONTACT
import LarkMessengerInterface
import LarkContact
import LarkFeedInterface
public struct ContactAssemblyDefaultConfig: ContactAssemblyConfig {
    public init() {}
}
#endif

class LarkMainAssembly: FlowBootTask, Identifiable {
    static var identify = "LarkMainAssembly"

    override var runOnlyOnce: Bool { return true }

    override func execute(_ context: BootContext) {

        /// OPTrace 全局初始化
        let config = OPTraceConfig(prefix: LKTracing.identifier) { (parent) -> String in
            return LKTracing.newSpan(traceId: parent)
        }
        OPTraceService.default().setup(config)

        // commonJS 准备
        DispatchQueue.global().async {
            CommonJSUtil.unzipIfNeeded()
        }

        // 语言load
        LanguageManager.supportLanguages =
            (Bundle.main.infoDictionary!["SUPPORTED_LANGUAGES"] as! [String]).map { Lang(rawValue: $0) }

        // load assemblies
        var assemblies: [LarkAssemblyInterface] = [
            BaseAssembly(),
            MailAssemble(), // MailAssemble 还没有适配 LarkAssembler，需额外加入，适配后可去掉
        ]
#if LARKCONTACT
        assemblies.append(ContactAssembly(config: ContactAssemblyDefaultConfig()))
#endif

#if CalendarMod
        let calendarAssemble: LarkAssemblyInterface?  = LarkCalendarAssembly() as? LarkAssemblyInterface
        if let assemble = calendarAssemble {
            assemblies.append(contentsOf: [assemble])
        }
#endif
       
        _ = Assembler(assemblies: assemblies, container: BootLoader.container)
        BootLoader.assemblyLoaded = true


        // fake feed
        TabRegistry.register(.feed) { _ in FakeTab() }
        Navigator.shared.registerRoute(plainPattern: Tab.feed.urlString) { (_, res) in
            let con = FakeViewController()
            con.resolver = BootLoader.container
            res.end(resource: con)
        }

        registerService(container: BootLoader.container)
        // setup log
        LarkLogger.setup()
        // fg
        //    LarkFeatureGating.NDEBUG = true

        // enable runloop dispatcher
        RunloopDispatcher.enable = true

//        RunloopDispatcher.shared.addTask(priority: .required, scope: .user, identify: "afterFirstRender") {
//            NewBootManager.shared.trigger(with: .afterFirstRender, contextID: context.contextID)
//        }
        #if INJECTION
        Bundle(path: "/Applications/InjectionIII.app/Contents/Resources/iOSInjection.bundle")?.load()
        #endif
    }
}

private func registerService(container: Container) {
    let resolver = container
    let user = container.inObjectScope(.user)
    // 侧边栏VC

    SideBarVCRegistry.registerSideBarVC { (_,_) -> UIViewController? in
        MineViewController.init(resolver: resolver)
    }

    container.register(DocCommonUploadProtocol.self) { r in
        let uploader = DocCommonUploader()
        return uploader
    }.inObjectScope(.container)
    
//    container.register(SDKRustService.self) { (r) -> SDKRustService in
//        return SDKClient(client: r.resolve(RustService.self)!)
//    }
//    container.register(ConfigurationAPI.self) { (r) -> ConfigurationAPI in
//        let rustClient = r.resolve(SDKRustService.self)!
//        let deviceId = r.resolve(DeviceService.self)!.deviceId
//        return RustConfigurationAPI(client: rustClient, onScheduler: scheduler, deviceId: deviceId)
//    }.inObjectScope(.user)

//    container.register(StickerService.self) { r in
//        return StickerServiceImpl()
//    }.inObjectScope(.user)
//    container.register(UserCacheService.self) { r -> UserCacheService in
//        return UserCacheServiceImpl()
//    }.inObjectScope(.container)
    
//    container.register(ChatterAPI.self) { (r) -> ChatterAPI in
//        let rustClient = r.resolve(SDKRustService.self)!
//        return RustChatterAPI(client: rustClient, onScheduler: scheduler)
//    }.inObjectScope(.user)
    
//    container.register(ResourceAPI.self) { (r) -> ResourceAPI in
//        let rustClient = r.resolve(SDKRustService.self)!
//        return RustResourceAPI(client: rustClient, onScheduler: scheduler)
//    }.inObjectScope(.user)
    
//    container.register(ChatterManagerProtocol.self) { _ in
//        let pushChatter = resolver.pushCenter.observable(for: PushChatters.self).map { $0.chatters }
//        return ChatterManager(pushChatters: pushChatter)
//    }.inObjectScope(.container)
    
//    container.register(UserAppConfig.self) { (r) -> UserAppConfig in
//        let config: UserAppConfig = BaseUserAppConfig(
//            configAPI: r.resolve(ConfigurationAPI.self)!,
//            pushWebSocketStatusOb: r.pushCenter.observable(for: PushWebSocketStatus.self),
//            pushAppConfigOb: r.pushCenter.observable(for: PushAppConfig.self)
//        )
//        return config
//    }.inObjectScope(.user)

    container.register(LarkWebViewProtocol.self) { r in
        return OpenPlatformAPIHandlerImp(container)
    }.inObjectScope(.user)

    let dependency = OpenPlatformAPIHandlerImp(container)
    container.register(WebBrowserDependencyProtocol.self) { _ in
        dependency
    }.inObjectScope(.user)
    container.register(LarkWebViewProtocol.self) { _ in
        dependency
    }.inObjectScope(.user)
    
//    container.register(PasteboardService.self) { _ in
//        return PasteboardServiceImp()
//    }.inObjectScope(.user)
    
    user.register(Settings.self) { r in
        return SettingsImp.settings(resolver: r)
    }

#if LARKCONTACT
    container.register(FeedContext.self) { _ -> FeedContext in
                return FeedContext()
            }.inObjectScope(.user)

    container.register(FeedContextService.self) { _ -> FeedContextService in
        let context = container.resolve(FeedContext.self)!
        return context
    }
#endif

//    let dependency = LarkImageServiceDependencyImpl(
//                    currentAccountID: { container.resolve(AccountService.self)?.currentAccountInfo.userID },
//                    stickerServiceProvider: { container.resolve(StickerService.self)! },
//                    avatarConfigProvider: { container.resolve(UserGeneralSettings.self)!.avatarConfig },
//                    configAPIProvider: { container.resolve(ConfigurationAPI.self)! },
//                    rustService: { container.resolve(RustService.self)! },
//                    progressServiceProvider: { resolver.resolve(ProgressService.self)! }
//                )
//    LarkImageService.shared.registerDependency(dependency)
}

struct FakeTab: TabRepresentable {
  var tab: Tab { Tab.feed }
}

class FakeViewController: UIViewController, TabRootViewController, LarkNaviBarDataSource, LarkNaviBarDelegate {
    var tab: Tab { Tab.feed }
    var controller: UIViewController { self }
    var titleText: BehaviorRelay<String> { BehaviorRelay(value: "Fake View Controller") }
    var isNaviBarEnabled: Bool { true }
    var isDrawerEnabled: Bool { true }
    var resolver: Container?
    let disposeBag = DisposeBag()


    override func viewDidLoad() {
        super.viewDidLoad()

        DemoEventBus.shared.router
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] router in
                guard let self = self else { return }
                switch router {
                case .namecard:
#if LARKCONTACT
                    let body = NameCardListBody()
                    Navigator.shared.present(
                        body: body,
                        wrap: LkNavigationController.self,
                        from: self,
                        prepare: { $0.modalPresentationStyle = .overCurrentContext }
                    )
#endif
                    break
                }
            })
            .disposed(by: disposeBag)
  }
}


NewBootManager.shared.dependency = BootManagerDependency()
NewBootManager.register(LarkMainAssembly.self)
BootLoader.shared.start(delegate: AppContainer.AppDelegate.self, config: .default)
