//
//  OpenPlatformAssembly.swift
//  LarkOpenPlatform
//
//  Created by yinyuan on 2019/9/17.
//

import AppContainer
import EENavigator
import LKCommonsLogging
import LarkAppLinkSDK
import LarkFeatureGating
import LarkRustClient
import Swinject
import BootManager
import LarkMessageBase
import ByteViewInterface
import EEAtomic
import WebBrowser
import LarkMessageBase
import LarkOPInterface
import LarkForward
import LarkAccountInterface
import EEMicroAppSDK
import LarkUIKit
import LarkMessengerInterface
import RunloopTools
import LarkMicroApp
import TTMicroApp
import LarkCache
import LarkAssembler
import LarkContainer
import LarkOpenChat
#if MeegoMod
import LarkMeegoInterface
#endif
import LarkModel
import LarkChat
#if NativeApp
import NativeAppPublicKit
#endif
import EcosystemWeb
import LarkFlag
import LarkMessageCard
import OPPlugin
import UniverseDesignToast
import ECOInfra
import LarkOpenPluginManager
import RenderRouterInterface
import UniversalCard
import UniversalCardInterface
import UniversalCardBase

public final class OpenPlatformAssembly: LarkAssemblyInterface {

    private static let logger = Logger.oplog(OpenPlatformAssembly.self, category: "OpenPlatformAssembly")

    public init() { }

    ///不同的 silgen_name 注册不同的业务场景，请勿随意注册，参考 https://bytedance.feishu.cn/docx/doxcnL9FGB9yqj6mHjoyYhnnf1e ，有问题可咨询对应业务同事，或者 yangjing.sniper@bytedance.com
    @_silgen_name("Lark.LarkMessageBase_MessageSummerize_regist.OpenPlatformAssembly")
    static public func messageCardMessageSummerizeRegister() {
        MetaModelSummerizeRegistry.regist(CardModelSummerizeFactory.self)
    }

    @_silgen_name("Lark.ChatCellFactory.OpenPlatformAssembly")
    static public func messageCardChatCellFactoryRegister() {
        MessageEngineSubFactoryRegistery.register(DynamicContentFactory.self)
        ChatPinMessageEngineSubFactoryRegistery.register(DynamicContentFactory.self)
        ChatMessageSubFactoryRegistery.register(DynamicContentFactory.self)
        MergeForwardMessageSubFactoryRegistery.register(DynamicContentFactory.self)
        MessageDetailMessageSubFactoryRegistery.register(MessageDetailDynamicContentFactory.self)
        ThreadChatSubFactoryRegistery.register(DynamicContentFactory.self)
        ThreadDetailSubFactoryRegistery.register(DynamicContentFactory.self)
        ReplyInThreadSubFactoryRegistery.register(DynamicContentFactory.self)
        ReplyInThreadForwardDetailSubFactoryRegistery.register(DynamicContentFactory.self)
        PinMessageSubFactoryRegistery.register(DynamicContentFactory.self)

        MessageEngineSubFactoryRegistery.register(MessageCardThreadFactory.self)
        ChatPinMessageEngineSubFactoryRegistery.register(MessageCardThreadFactory.self)
        ChatMessageSubFactoryRegistery.register(MessageCardFactory.self)
        MergeForwardMessageSubFactoryRegistery.register(MessageCardFactory.self)
        MessageDetailMessageSubFactoryRegistery.register(MessageCardFactory.self)
        ThreadChatSubFactoryRegistery.register(MessageCardFactory.self)
        ThreadDetailSubFactoryRegistery.register(MessageCardFactory.self)
        ReplyInThreadSubFactoryRegistery.register(MessageCardFactory.self)
        ReplyInThreadForwardDetailSubFactoryRegistery.register(MessageCardFactory.self)
        PinMessageSubFactoryRegistery.register(MessageCardFactory.self)
        
        EngineComponentRegistry.register(factory: RenderRouterCardFactory.self)
    }

    @_silgen_name("Lark.LarkFlag_LarkFlagAssembly_regist.OpenPlatformAssembly")
    static public func messageCardFlagCellFactoryRegister() {
        FlagListMessageSubFactoryRegistery.register(DynamicContentFactory.self)
        FlagMessageDetailSubFactoryRegistery.register(DynamicContentFactory.self)
        
        FlagListMessageSubFactoryRegistery.register(MessageCardFactory.self)
        FlagMessageDetailSubFactoryRegistery.register(MessageCardFactory.self)
    }

    @_silgen_name("Lark.LarkForward_LarkForwardMessageAssembly_regist.OpenPlatformAssembly")
    static public func messageCardProviderRegister() {
        ForwardAlertFactory.register(type: SendMessageCardForwardAlertProvider.self)
    }

    @_silgen_name("Lark.OpenChat.LarkOpenPlatform")
    static public func openChatRegister() {
        // 注册消息菜单操作 - 会话界面
        ChatMessageActionModule.register(MessageCardCopyActionSubModule.self)
        // 注册消息菜单操作 - 回复详情页
        MessageDetailMessageActionModule.register(MessageCardCopyActionSubModule.self)
        // 注册消息菜单操作 - 话题群
        ThreadMessageActionModule.register(MessageCardCopyActionSubModule.self)
        // 注册消息菜单操作 - 话题详情页
        ThreadDetailMessageActionModule.register(MessageCardCopyActionSubModule.self)
        // 注册消息菜单操作 - 话题回复(Reply In Thread)
        ReplyThreadMessageActionModule.register(MessageCardCopyActionSubModule.self)
        // 注册消息菜单操作 - 私有话题转发
        PrivateThreadMessageActionModule.register(MessageCardCopyActionSubModule.self)
        // 注册消息菜单操作 - 合并转发详情页
        MergeForwardMessageActionModule.register(MessageCardCopyActionSubModule.self)
    }

    /// 注册新版菜单的插件
    /// - Parameter resolver: SwiftLint的Resolver
    public func assembleMenuPlugin(resolver: UserResolver) {
        // 注册关于插件
        let appAboutContext = MenuPluginContext(
            plugin: AppAboutMenuPlugin.self
        )
        MenuPluginPool.registerPlugin(pluginContext: appAboutContext)

        // 注册常用应用插件
        let appCommonAppContext = MenuPluginContext(
            plugin: AppCommonAppMenuPlugin.self,
            parameters: [AppCommonAppMenuPlugin.providerContextResloveKey: resolver]
        )
        MenuPluginPool.registerPlugin(pluginContext: appCommonAppContext)

        // 注册小程序机器人应用插件
        let appBotContext = MenuPluginContext(
            plugin: AppBotMenuPlugin.self,
            parameters: [AppBotMenuPlugin.providerContextResloveKey: resolver]
        )
        MenuPluginPool.registerPlugin(pluginContext: appBotContext)

        // 注册"添加到更多"功能插件
        let launcherMoreContext = MenuPluginContext(
            plugin: LauncherMoreMenuPlugin.self,
            parameters: [LauncherMoreMenuPlugin.providerContextResloveKey: resolver]
        )
        MenuPluginPool.registerPlugin(pluginContext: launcherMoreContext)
        
        // 注册小程序添加到桌面应用插件
        let appShortCutContext = MenuPluginContext(
            plugin: AppShortCutMenuPlugin.self,
            parameters: [AppShortCutMenuPlugin.providerContextResloveKey: resolver]
        )
        MenuPluginPool.registerPlugin(pluginContext: appShortCutContext)

        // 注册小程序反馈应用插件
        let appFeebackContext = MenuPluginContext(
            plugin: AppFeedbackMenuPlugin.self
        )
        MenuPluginPool.registerPlugin(pluginContext: appFeebackContext)

        // 注册小程序分享应用插件
        let appShareContext = MenuPluginContext(
            plugin: AppShareMenuPlugin.self
        )
        MenuPluginPool.registerPlugin(pluginContext: appShareContext)
    }

    public func registLarkAppLink(container: Container){
        LarkAppLinkSDK.registerHandler(path: "/client/chat/open", handler: {(applink: AppLink) in
            let resolver = container.getCurrentUserResolver(compatibleMode: OPUserScope.compatibleModeEnabled)
            if let client = try? resolver.resolve(assert: OpenPlatformHttpClient.self) {
                OpenChatLinkHandler().handle(appLink: applink,
                                             httpClient: client,
                                             resolver: resolver)
            }
        })
        
        LarkAppLinkSDK.registerHandler(path: "/client/op/open", handler: {(_ applink: AppLink) in
            // 用于外部开放业务回调/唤起 Lark
        })

        LarkAppLinkSDK.registerHandler(path: "/client/workplace/unsupport", handler: {(_ applink: AppLink) in
            // 用于外部开放业务回调/唤起 Lark
            let resolver = container.getCurrentUserResolver(compatibleMode: OPUserScope.compatibleModeEnabled)
            AppNotSupportHandler().handle(appLink: applink, resolver: resolver)
        })
        LarkAppLinkSDK.registerHandler(path: "/client/message_action_list/open", handler: {(_ applink: AppLink) in
            // 用于外部开放业务回调/唤起 Lark
            let resolver = container.getCurrentUserResolver(compatibleMode: OPUserScope.compatibleModeEnabled)
            MessageActionHandler().handle(appLink: applink, resolver: resolver)
        })

        // Bot applink
        LarkAppLinkSDK.registerHandler(path: "/client/bot/open") { applink in
            let resolver = container.getCurrentUserResolver(compatibleMode: OPUserScope.compatibleModeEnabled)
            BotAppLinkHandler().handle(applink: applink, resolver: resolver)
        }

        // AppShare link
        LarkAppLinkSDK.registerHandler(path: "/client/app_share/open") { applink in
            let resolver = container.getCurrentUserResolver(compatibleMode: OPUserScope.compatibleModeEnabled)
            AppShareLinkHandler().handle(applink: applink, resolver: resolver)
        }
        /// H5应用，提前注册
//        let resolver = container.getCurrentUserResolver(compatibleMode: OPUserScope.compatibleModeEnabled)
        H5Applink.registerApplinkForH5App(container: container)
        
        #if NativeApp
        // NativeApp link
        LarkAppLinkSDK.registerHandler(path: "/client/native_app/open") { applink in
            let resolver = container.getCurrentUserResolver(compatibleMode: OPUserScope.compatibleModeEnabled)
            NativeAppOpenLinkHandler().handle(applink: applink, resolver: resolver)
        }
        #endif
        
        #if !LARK_NO_DEBUG
        LarkAppLinkSDK.registerHandler(path: "/client/op_api_debug/set_jssdk") { applink in
            let query = applink.url.queryParameters
            
            let window = UIApplication.shared.delegate?.window?.map { $0 }
            let toastParentView = window ?? UIView()
            guard var url = query["url"], let type = query["type"], ["gadget", "block"].contains(type.lowercased()) else {
                UDToast().showFailure(with: "无效jssdk调试Applink", on: toastParentView)
                return
            }
            
            url = url.trimmingCharacters(in: .whitespaces)
            
            UserDefaults.standard.set(true, forKey: "kEEMicroAppDebugSwitch")
            EERoute.shared().updateDebug()
            
            UDToast().showSuccess(with: "jssdk替换成功~", on: toastParentView)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                if (type == "gadget") {
                    EERoute.shared().setJSSDKUrlString(url)
                } else if (type == "block") {
                    EERoute.shared().setBlockJSSDKUrlString(url)
                    exit(0)
                }
            }
        }
        #endif
    }


    public func registContainer(container:Container){
        let resolver = container
        let user = container.inObjectScope(OPUserScope.userScope)
        let userGraph = container.inObjectScope(OPUserScope.userGraph)
        
        user.register(OpenPlatformService.self) { (r) -> OpenPlatformService in
            return try OpenPlatform(resolver: r)
        }
        
        user.register(LarkOpenAPIService.self) { (r) -> LarkOpenAPIService in
            return try LarkOpenAPIServiceImpl(resolver: r)
        }
        
        user.register(OpenPlatformAliver.self) { (r) -> OpenPlatformAliver in
            return OpenPlatformAliver(resolver: r)
        }
        
        user.register(OpenPlatformHttpClient.self) { (r) -> OpenPlatformHttpClient in
            return OpenPlatformHttpClient(resolver: r)
        }
        
        user.register(ECOSettingsFetchingService.self) { (r) -> ECOSettingsFetchingService in
            return ECOSettingsFetchingServiceImp(resolver: r)
        }
        userGraph.register(ECOConfigService.self) { r in
            let configManager = try r.resolve(assert: EMAConfigManager.self)
            return configManager
        }
        
        user.register(EMAConfigManager.self) { _ in
            return EMAConfigManager()
        }

        container.register(CardContextDependency.self) { _ -> CardContextDependency in
            return CardContextDependencyImpl(resolver: resolver)
        }

        user.register(CardClientMessagePublishService.self) { r in
            return CardClientMessageServiceImpl(resolver: r)
        }

        user.register(CardClientMessageService.self) { (r) in
            if let service = try r.resolve(assert:CardClientMessagePublishService.self) as? CardClientMessageServiceImpl {
                return service
            } else {
                assertionFailure("CardClientMessageService register fail: can't get CardClientMessagePublishService")
                return CardClientMessageServiceImpl(resolver: r)
            }
        }

        user.register(OPAppAuditService.self) { (r) -> OPAppAuditService in
            let userService = try r.resolve(assert: PassportUserService.self)
            return OPAppAuditServiceImpl(currentUserID: userService.user.userID)
        }

        user.register(OPClockInEnv.self) { _ in
            return OPClockInEnvIMP()
        }
        
        user.register(OPBadgeAPI.self) { (r) -> OPBadgeAPI in
            let rustService = try r.resolve(assert: RustService.self)
            return RustOpenAppBadgeAPI(rustService: rustService)
        }
        
        #if NativeApp
        user.register(NativeAppManagerInternalProtocol.self) { (r) -> NativeAppManagerInternalProtocol in
            return NativeAppManager(resolver: r)
        }
        #endif

        user.register(AppDetailInternalDependency.self) { (r) -> AppDetailInternalDependency in
            return try AppDetailInternalDependency(resolver: r)
        }

        user.register(MessageCardMigrateControl.self) { (r) -> MessageCardMigrateControl in
            return MessageCardMigrateControl(resolver: r)
        }

        user.register(MessageCardPinAlertContentViewProtocol.self) { (r) -> MessageCardPinAlertContentView in
            return MessageCardPinAlertContentView(userResolver: r)
        }
        
        container.register(DriveDownloadServiceProtocol.self) { _ in
            return WebDriveDownloadService(resolver: resolver)
        }.inObjectScope(.transient)
        
        container.register(PanelBrowserServiceProtocol.self) { _ in
            return PanelBrowserService(resolver: resolver) as! PanelBrowserServiceProtocol
        }.inObjectScope(.container)
        
        #if CCMMod
        container.register(OpenPluginDriveUploadProxy.self) { resolver -> OpenPluginDriveUploadProxy in
            return OpenPlatformDriveSDKProvider(resolver: resolver)
        }.inObjectScope(.container)
        container.register(OpenPluginDriveDownloadProxy.self) { resolver -> OpenPluginDriveDownloadProxy in
            return OpenPlatformDriveSDKProvider(resolver: resolver)
        }.inObjectScope(.container)
        container.register(OpenPluginDrivePreviewProxy.self) { resolver -> OpenPluginDrivePreviewProxy in
            return OpenPlatformDriveSDKProvider(resolver: resolver)
        }.inObjectScope(.container)
        #endif

        user.register(PrefetchRequestV2Proxy.self) { resolver -> PrefetchRequestV2Proxy in
            return try OpenPluginPrefetchRequestProvider(resolver: resolver)
        }
        
        user.register(OpenPlatformOuterService.self) { (r) -> OpenPlatformOuterService in
            return OpenPlatformOuterServiceImpl(resolver: r)
        }
        
        container.register(LarkOpenPlatformMyAIService.self) { _ in
            return LarkOpenplatformMyAIServiceIMP(resolver: resolver)
        }.inObjectScope(.container)
        
        // 特定KA诉求登录前调用人脸API, 因此在此处注册EMALiveFaceProtocol服务
        // 兜底FG期间, 保留EERoute.shared().liveFaceDelegate的挂载.
        // FG: openplatform.architecture.eeroute.decoupling
        container.register(EMALiveFaceProtocol.self) { _ -> EMALiveFaceProtocol in
            EMALiveFaceProtocolImpl()
        }.inObjectScope(.container)
        
        container.register(EMAProtocol.self) { resolver -> EMAProtocol in
            EMAProtocolImpl(resolver: resolver)
        }.inObjectScope(.container)
        
        container.register(EMADebuggerSharedService.self) { _ -> EMADebuggerSharedService in
            EMADebuggerManager.sharedInstance()
        }.inObjectScope(.container)
        
        container.register(OPQRCodeAnalysisProxy.self) { resolver -> OPQRCodeAnalysisProxy in
            return OPQRCodeAnalysisProxyProvider(resolver: resolver)
        }.inObjectScope(.container)
        
        container.register(OpenPluginMediaProxy.self) { _ in
            return OpenPlatformMediaProvider()
        }.inObjectScope(.container)

        container.register(OPAPIWebAppExtensionContainer.self) { _ in
            OPAPIWebAppExtensionContainerImpl()
        }.inObjectScope(.container)
        
        container.register(OpenPluginSearchPoiProxy.self) { _ in
            OpenPluginSearchPoiProvider()
        }.inObjectScope(.container)
        
        user.register(UniversalCardEnvironmentServiceProtocol.self){ (r) -> UniversalCardEnvironmentServiceProtocol in
            return try UniversalCardEnvironmentService(resolver: r)
        }
        
        user.register(UniversalCardContextManagerProtocol.self) { _ in
            UniversalCardContextManager()
        }

        user.register(UniversalCardModuleDependencyProtocol.self){ (r) -> UniversalCardModuleDependencyProtocol in
            return try UniversalCardModuleDependency(resolver: r)
        }


    }

    public func registLaunch(container:Container){
        NewBootManager.register(OpenPlatformBeforeLoginTask.self)
        NewBootManager.register(SetupOPInterfaceTask.self)
        NewBootManager.register(SetupOpenPlatformTask.self)
    }

    public func registRouter(container: Container) {
        let resolver = container

        Navigator.shared.registerRoute.type(OPShareBody.self).factory(cache: true, OPShareHandler.init(resolver:))
        Navigator.shared.registerRoute.type(ChatGroupBotBody.self).factory(ChatGroupBotHandler.init(resolver:))
        Navigator.shared.registerRoute.type(OPOpenShareAppBody.self).factory(cache: true, OPOpenShareAppBodyHandler.init(resolver:))
        Navigator.shared.registerRoute.plain(AppDetailPatternHandler.pattern).factory(AppDetailPatternHandler.init(resolver:))
        Navigator.shared.registerRoute.type(AppDetailBody.self).factory(AppDetailHandler.init(resolver:))
        Navigator.shared.registerRoute.type(AppSettingBody.self).factory(AppSettingHandler.init(resolver:))
        Navigator.shared.registerRoute.type(ApplyForUseBody.self).factory(ApplyForUseHandler.init(resolver:))

        Navigator.shared.registerRoute.type(SendMessageCardForwardAlertBody.self).factory(SendMessageCardForwardAlertHandler.init(resolver:))

    }
    
    public func registLauncherDelegate(container: Container) {
        (LauncherDelegateFactory {
            OpenPlatformLauncherDelegate()
        }, LauncherDelegateRegisteryPriority.high)
    }
    
    @_silgen_name("Lark.LarkCache_CleanTaskRegistry_regist.LarkOpenPlatform")
    public static func registerCleanTask() {
        CleanTaskRegistry.register(cleanTask: FileSystemLogCleanTask())
        // 注册小程序包和meta清理Task
        CleanTaskRegistry.register(cleanTask: OPGadgetCacheCleanTask())
    }

    public func registServerPushHandlerInUserSpace(container: Container) {
        (ServerCommand.pushAttendanceRefreshConfig, OPClockInPushHandler.init(resolver:))
        (ServerCommand.pushAttendanceTopSpeedClockIn, OPClockInPushHandler.init(resolver:))
    }
    
    public func registRustPushHandlerInUserSpace(container: Container) {
        (Command.gadgetCommonPush, MsgActionPlusMenuCommonPushHandler.init(resolver:))
    }
}

struct CardContextDependencyImpl: CardContextDependency {
    @SafeLazy
    private var opService: OpenPlatformService
    @SafeLazy
    private var meetingService: MeetingService
    #if MeegoMod
    @SafeLazy
    private var meegoService: LarkMeegoService
    #endif

    init(resolver: Resolver) {
        self._opService = SafeLazy { resolver.resolve(OpenPlatformService.self)! }
        self._meetingService = SafeLazy { resolver.resolve(MeetingService.self)! }
        #if MeegoMod
        self._meegoService = SafeLazy { resolver.resolve(LarkMeegoService.self)! }
        #endif
    }

    // MARK: CardContextDependency
    func urlWithTriggerCode(_ sourceUrl: String, _ cardMsgID: String, _ callback: @escaping (String) -> Void) {
        return self.opService.urlWithTriggerCode(sourceUrl, cardMsgID, callback)
    }

    func isRinging() -> Bool {
        return meetingService.currentMeeting?.state == .ringing
    }

    func hasCurrentModule() -> Bool {
        return meetingService.currentMeeting?.isActive == true
    }

    func inRingingCannotJoinMeetingText() -> String {
        return meetingService.resources.inRingingCannotJoinMeeting
    }

    func isInCallText() -> String {
        return meetingService.resources.isInCallText
    }

    func videoDenied() -> Bool {
        return meetingService.isCameraDenied
    }

    func showCameraAlert() {
        meetingService.showCameraAlert()
    }

    func audioDenied() -> Bool {
        return meetingService.isMicrophoneDenied
    }

    func showMicrophoneAlert() {
        meetingService.showMicrophoneAlert()
    }
    
    func setupMeegoEnv(message: LarkModel.Message) {
        #if MeegoMod
        meegoService.handleMeegoCardExposed(message: message)
        #endif
    }
}
