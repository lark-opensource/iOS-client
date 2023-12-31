//
//  OpenAppEngine.swift
//  LarkOpenPlatform
//
//  Created by yinyuan on 2020/12/28.
//

import Foundation
import Swinject
import OPGadget
import OPSDK
import LarkAccountInterface
import RxSwift
import LKCommonsLogging
import LarkFoundation
import LarkLocalizations
import RustPB
import LarkAppConfig
import EEMicroAppSDK
import OPBlock
import LarkReleaseConfig
import ECOProbe
import LarkSetting
import LarkFeatureGating
import LarkWebViewContainer
import WebKit
import LarkEnv
import OPFoundation
import LarkContainer

private typealias OpenDomainSettings = InitSettingKey

private let logger = Logger.oplog(OpenAppEngine.self, category: "OpenAppEngine")

public protocol EMAProtcolAppendProxy {
    init(resolver: Resolver)
}

// 开放应用引擎
public final class OpenAppEngine {

    // OP Lark 胶水层实现类型
    public typealias LarkOpenProtocolType = EMAProtocol & EMAProtcolAppendProxy

    public static var shared = OpenAppEngine()

    private var resolver: Resolver?

    private let disposeBag = DisposeBag()

    private var currentAccountIdentifier: String?

    /// 外部必须注入的宿主能力
    private var larkOpenProtocolType: LarkOpenProtocolType.Type?

    private var larkOpenDelegate: LarkOpenProtocolType?

    // 拆分活体相关依赖能力，使得登陆前能使用其能力
    private var larkLiveFaceDelegate: EMALiveFaceProtocol?

    /// 早于登录执行的初始化工作（避免执行耗时操作，否则可能会影响启动速度）
    public func assembleSetup(resolver: Resolver, larkOpenProtocolType: LarkOpenProtocolType.Type, larkLiveFaceDelegate: EMALiveFaceProtocol?) {

        self.resolver = resolver

        self.larkOpenProtocolType = larkOpenProtocolType

        self.larkLiveFaceDelegate = larkLiveFaceDelegate

        EERoute.shared().liveFaceDelegate = larkLiveFaceDelegate

        LauncherDelegateRegistery.register(factory: LauncherDelegateFactory {
            OpenPlatformLauncherDelegate()
        }, priority: .middle)
    }

    private init() { // code from ziyichen 这里只是加一个private避免外边乱init
        // 和包管理进行磋商，要求在init加这个通知监听
        lgSetup()
        OPApplicationService.notify = {
            OpenAppEngine.shared.notifyLoginIfNeeded()
        }
    }

    /// 需要在应用能力被调用时，保证 login 已经执行。例如：
    /// 1. 小程序启动前
    /// 2. 主导航小程序加载前
    @objc public func notifyLoginIfNeeded() { // code from yinyuan.0 只是加了个 @objc
        if let resolver = resolver {
            let userResolver = OPUserScope.userResolver()
            // 未登录则尝试登录
            login(resolver: userResolver)
        }
    }

    /// 账户登录，需要早于应用启动执行
    public func login(resolver: UserResolver) {

        guard let userService = try? resolver.resolve(assert: PassportUserService.self) else {
            logger.error("OpenAppEngine login failed: PassportUserService impl is nil!")
            return
        }
        // 获取当前账户
        let currentUser = userService.user
        let tenantId = currentUser.tenant.tenantID
        let userID = currentUser.userID
        let accountToken = OPAccountTokenHelper.accountToken(userID: userID, tenantID: tenantId)
        let userSession = currentUser.sessionKey ?? ""

        let accountIdentifier = tenantId + "_" + userID + "_" + accountToken + "_" + userSession.md5() // ⚠️ 需要脱敏，不允许出现敏感信息

        if currentAccountIdentifier == accountIdentifier {
            // 相同的账户，避免重复登录
            logger.info("OpenAppEngine logined")
            return
        } else if currentAccountIdentifier != nil {
            // 更换账号，先清理
            logout()
        }
        currentAccountIdentifier = accountIdentifier

        // 在MG项目中，删除了海外类型
        var envType: OPEnvType = .online
        let env = EnvManager.env
        switch env.type {
        case .release:
            envType = .online
        case .staging:
            envType = .staging
        case .preRelease:
            envType = .preRelease
        @unknown default:
            envType = .online
        }

        if let larkOpenProtocolType = larkOpenProtocolType {

            logger.info("OpenAppEngine login accountIdentifier:\(accountIdentifier)")
            // 切换租户后，先清理所有小程序进程

            var larkOpenDelegate: LarkOpenProtocolType?
            let fg = EMARouteProvider.FG.value
            if fg {
                // EMAProtocol实现服务初始化
                let emaProtocol = resolver.resolve(EMAProtocol.self)
                emaProtocol?.regist()
                // 拎出原先在EERoute.login里处理emaProtocol的部分
                BDPSettingsManager.shared().addSettings(EERoute.shared().preloadABTestDic(with: emaProtocol))
                if let interpreters = emaProtocol?.registerWorkerInterpreters() {
                    OpenJSWorkerInterpreterManager.shared.register(configs: interpreters)
                } else {
                    assertionFailure("emaProtocol should be found")
                }
            } else {
            larkOpenDelegate = larkOpenProtocolType.init(resolver: resolver)
            larkOpenDelegate?.regist()
            self.larkOpenDelegate = larkOpenDelegate    // 需要持有一下，不然会立即释放
            }

            let gadgetDomainConfig = MicroAppDomainConfig(settings: resolver.resolve(AppConfiguration.self)?.settings ?? [:])
            EERoute.shared().login(withDelegate: larkOpenDelegate,
                                   accoutToken: accountToken,
                                   userID: userID,
                                   userSession: userSession,
                                   envType: envType,
                                   domainConfig: gadgetDomainConfig,
                                   channel: ReleaseConfig.releaseChannel,
                                   tenantID: tenantId)
        } else {
            assertionFailure("larkOpenProtocolType must be setted")
        }

        let appAccountConfig = OPAppAccountConfig(userSession: userSession, accountToken: accountToken, userID: userID, tenantID: tenantId)
        // TODO: language 从哪来？做什么用
        let envEnvironment = OPAppEnvironment(envType: envType, larkVersion: Utils.appVersion, language: LanguageManager.currentLanguage.localeIdentifier)

        let settings = resolver.resolve(AppConfiguration.self)?.settings ?? [:]
        let domainSettings = resolver.resolve(AppConfiguration.self)?.domainSettings ?? [:]

        let domainConfig = OPAppDomainConfig(
            openDomain: settings[OpenDomainSettings.open]?.first ?? "",
            configDomain: settings[OpenDomainSettings.mpConfig]?.first ?? "",
            pstatpDomain: settings[OpenDomainSettings.ttCdn]?.first ?? "",
            vodDomain: settings[OpenDomainSettings.vod]?.first ?? "",
            snssdkDomain: settings[OpenDomainSettings.mpTt]?.first ?? "",
            referDomain: settings[OpenDomainSettings.mpRefer]?.first ?? "",
            appLinkDomain: settings[OpenDomainSettings.mpApplink]?.first ?? "",
            openAppInterface: settings[OpenDomainSettings.openAppInterface]?.first ?? "",
            webViewSafeDomain: domainSettings[DomainKey.mpWebViewComponent]?.first ?? ""
        )
        OPApplicationService.setupGlobalConfig(
            accountConfig: appAccountConfig,
            envConfig: envEnvironment,
            domainConfig: domainConfig,
            resolver: resolver
        )
        OPApplicationService.current.registerContainerService(
            for: .gadget,
            service: OPGadgetContainerService()
        )
        var apis: [BlockAdaptedAPIName] = [
            .login,
            .getUserInfo,
            .getSystemInfo,
            .getSystemInfoSync,
            .openSchema,
            .enterProfile,
            .chooseChat,
            .chooseContact,
            .chooseImage,
            .showToast,
            .hideToast,
            .showModal,
            .docsPicker,
            .createRequestTask,
            .operateRequestTask,
            .createSocketTask,
            .operateSocketTask,
            .setStorage,
            .setStorageSync,
            .getStorage,
            .getStorageSync,
            .removeStorage,
            .removeStorageSync,
            .getStorageInfo,
            .getStorageInfoSync,
            .clearStorage,
            .clearStorageSync,
            .monitorReport,
            .setContainerConfig,
            .showBlockErrorPage,
            .hideBlockErrorPage,
            .getEnvVariable,
            .getKAInfo,
            .onServerBadgePush,
            .offServerBadgePush,
            .openLingoProfile,
            .request,
            .getUserCustomAttr,
            .invokeCustomAPI,
            .getLocation,
            .startLocationUpdate,
            .stopLocationUpdate,
            .getNetworkType,
            .getConnectedWifi,
        ]

        if supportSaveLog() {
            apis.append(.saveLog)
        }

        OPApplicationService.current
            .pluginManager(for: .block) // 仅注入到 Block 类型应用中
            .registerPlugin(plugin: OPBlockAPIAdapterPlugin(apis: apis))
        OPApplicationService.current.registerContainerService(
            for: .block,
            service: OPBlockContainerService()
        )
        //注册预安装的 Provider injector对象
        if BDPPreloadHelper.preHandleEnable() {
            EMAPreloadHelper.injectMetaProvidersIntoPrelaodHandler()
        }
    }

    private func supportSaveLog() -> Bool {
        LarkFeatureGating.shared.getFeatureBoolValue(for: "openplatform.block.api_save_log", defaultValue: false)
    }
    /// 退出登录
    fileprivate func logout() {
        logger.info("OpenAppEngine logout currentAccountIdentifier: \(currentAccountIdentifier ?? "nil")")
        // 退出小程序登录
        EERoute.shared().clearTaskCache()
        EERoute.shared().logout()

        currentAccountIdentifier = nil

    }

    //  和包管理负责人丰平讨论，避免模块耦合，通过通知的方法完成
    public func lgSetup() {
        NotificationCenter.default.addObserver(self, selector: #selector(notifyLoginIfNeeded), name: NSNotification.Name(rawValue: "OpenAppEngine.shared.notifyLoginIfNeeded"), object: nil)
    }
}

private class OpenPlatformLauncherDelegate: LauncherDelegate {
    public var name = "OpenPlatform"

    public func afterLoginSucceded(_ context: LauncherContext) {
        logger.info("OpenPlatform.afterLoginSucceded. \(String(describing: context.currentUserID)) \(context.isFastLogin)")
        //  离线包需求要求在WKWebView init埋个点，考虑到要做FG，复用此处的afterLoginSucceded时机
        if FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "wkwebview.init.and.load.monitor")) {
            logger.info("lkwm_setupLKWMonitorCatefory")
            WKWebView.lkwm_setupLKWMonitorCatefory()
        }
    }

    public func afterLogout(context: LauncherContext, conf: LogoutConf) {
        // 退出登录
        logger.info("OpenPlatform.afterLogout. \(String(describing: context.currentUserID))")
        OpenAppEngine.shared.logout()
    }

    public func beforeSwitchAccout() {
        logger.info("OpenPlatform.beforeSwitchAccout")
    }

    public func afterSwitchAccout(error: Error?) -> Observable<Void> {
        // 切换账户
        logger.info("OpenPlatform.afterSwitchAccout. \(String(describing: error))")
        return .just(())
    }
}
