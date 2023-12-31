//
//  MiniProgramHandler.swift
//  LarkMicroApp
//
//  Created by yinyuan on 2019/9/2.
//

import Foundation
import RoundedHUD
import EEMicroAppSDK
import EENavigator
import LarkAppLinkSDK
import LarkFeatureSwitch
import LarkNavigator
import AnimatedTabBar
import LarkUIKit
import LarkNavigation
import LKCommonsLogging
import LarkFeatureGating
import RustPB
import LarkTab
import OPSDK
import OPGadget
import LarkSceneManager
import LarkNavigation
import LarkSetting
import TTMicroApp
import LarkContainer
import Swinject

public final class MiniProgramHandler {
    public init() {}

    private static let logger = Logger.log(MiniProgramHandler.self, category: "EEMicroApp")

    public func handle(appLink: AppLink, container: Container?) {
        
        // 解析 appLink 参数
        var queryParameters: [String: String] = [:]
        if let components = URLComponents(url: appLink.url, resolvingAgainstBaseURL: false),
            let queryItems = components.queryItems {
            for queryItem in queryItems {
                queryParameters[queryItem.name] = queryItem.value
            }
        }

        let sslocalModel = SSLocalModel()
        sslocalModel.type = .open
        guard let appId = queryParameters["appId"] else {
            return
        }
        
        // 判断是否被一方容器拦截
        if let microAppDependency = try? container?.resolve(assert: MicroAppDependency.self),
           let from = appLink.context?.from(),
           microAppDependency.openAppLinkWithWebApp(url: appLink.url, from: from) != nil {
            Self.logger.info("[webapp] redirect applink or sslocal succeed, with web app preview")
            return
        }
        
        sslocalModel.app_id = appId
        if let path = queryParameters["path_ios"] ?? queryParameters["path"] {
            sslocalModel.start_page = path
        }
        if let launchQuery = queryParameters[kBdpLaunchQueryKey] {
            sslocalModel.bdp_launch_query = launchQuery
        }
        if let requestAbility = queryParameters[kBdpLaunchRequestAbilityKey] {
            sslocalModel.required_launch_ability = requestAbility
        }
        if let leastVersion = queryParameters[kBdpLeastVersion] {
            sslocalModel.updateLeastVersionIfExisted(queryParameters)
        }
        if let needRelaunch = queryParameters[kBdpRelaunch] {
            sslocalModel.relaunch = needRelaunch
        }
        if let relaunchPath = queryParameters[kBdpRelaunchPath] {
            sslocalModel.relaunchPath = relaunchPath
        }
        
        // 限制端外调用半屏链接
        if !Display.pad && appLink.from != .app {
            // 半屏参数解析
            if let XScreenMode = queryParameters[kBdpXScreenMode] {
                sslocalModel.xScreenMode = XScreenMode
            }
            
            if let XScreenStyle = queryParameters[kBdpXScreenStyle] {
                sslocalModel.xScreenStyle = XScreenStyle
            }
            
            if let XScreenChatID = queryParameters[kBdpXScreenChatID] {
                sslocalModel.chatID = XScreenChatID
            }
        }
        
        if let versionType = queryParameters[kVersionType] {
            sslocalModel.versionType = OPAppVersionTypeFromString(versionType);
        }
        if let versionId = queryParameters[kVersionId] {
            sslocalModel.versionId = versionId
        }
        if let isDev = queryParameters[kIsDev] {
            sslocalModel.isdev = Int(isDev) ?? 0
        }
        if let token = queryParameters[kToken] {
            sslocalModel.token = token
        }

        guard let url = sslocalModel.generateURL() else {
            return
        }

        var from: FromScene
        if let fromShortCut = queryParameters["fromShortCut"] {
            from = FromScene.desktop_shortcut
        } else if let _ = queryParameters["from_im_open_biz"] {
            from = FromScene.im_open_biz
        } else {
            from = FromScene.build(context: appLink.context)
        }
        OPMonitor("applink_handler_success").setAppLink(appLink).flush()
        
        var channel: StartChannel = .applink
        if appLink.url.path.contains("/client/app_share/open") {
            channel = .sharelink
        }
        
        let showInTemporary = appLink.context?[kOpenInTemporay] as? Bool
        let launcherFrom = appLink.context?[kLauncherFrom] as? String ?? ""
        let extraParams = MiniProgramExtraParam(showInTemporary: showInTemporary,launcherFrom: launcherFrom)
        
        MiniProgramHandler.logger.info("gadget applink context launcher from \(launcherFrom)")
        
        MiniProgramHandler.openMiniProgram(url: url,
                                           from: from,
                                           context: appLink.context,
                                           navigatorFrom: appLink.context?.from(),
                                           appLink: appLink,channel:channel,
                                           extra:extraParams)
    }

    public static func openMiniProgram(url: URL, from: FromScene, context: [String: Any]? = nil, navigatorFrom: NavigatorFrom?, appLink: AppLink? = nil,channel: StartChannel? = .undefined,extra: MiniProgramExtraParam? = nil) {
        if OPGadgetDegradeConfig.clientEnable, let appLink = appLink {
            let sslocal = SSLocalModel(url: url)
            // 如果满足降级策略, 这边则不继续执行小程序路由逻辑
            if let degradeConfig = OPGadgetDegradeConfig.degradeConfig(for: sslocal.app_id),
               degradeConfig.degradeEnable(),
               let degradeURL = degradeConfig.link() {
                // 这边通过AppLinkService重定向
                logger.info("[GadgetDegrade] open url: \(degradeURL.absoluteString)")
                degradeConfig.degradeOpen(url: degradeURL, from: appLink.from, fromControler: appLink.fromControler) { res in
                    logger.info("[GadgetDegrade] open result: \(res)")
                }
                return
            }
        }
        setAppInfo(url: url, from: from, context: context)
        showAfterSwitchIfNeeded(url: url, scene: from, navigationFrom: navigatorFrom, channel: channel, applinkTraceId: appLink?.traceId, extra:extra)
    }

    public static func handelMiniProgramRequest(url: URL, req: EENavigator.Request, res: Response, channel: StartChannel? = .undefined) {
        if let dependency = try? req.getUserResolver().resolve(assert: MicroAppDependency.self),
           let newUrl = dependency.openAppLinkWithWebApp(url: url, from: nil) {
            if let resource = Navigator.shared.response(for: newUrl).resource {
                logger.info("[webapp] handelMiniProgramRequest,replace ok")
                res.end(resource: resource)
                return
            } else {
                logger.info("[webapp] handelMiniProgramRequest,replace fail")
            }
        }
        
        
        if OPGadgetDegradeConfig.clientEnable {
            let sslocal = SSLocalModel(url: url)
            // 如果满足降级策略, 这边则不继续执行小程序路由逻辑
            if let degradeConfig = OPGadgetDegradeConfig.degradeConfig(for: sslocal.app_id),
                degradeConfig.degradeEnable(),
                let degradeURL = degradeConfig.link() {
                logger.info("[GadgetDegrade] open url: \(degradeURL.absoluteString)")
                // 通过response自身携带方法进行重定向
                res.redirect(degradeURL)
                return
            }
        }
        
        if req.context[FromSceneKey.key] == nil,
            let bundleID = req.url.queryParameters["bundleID"],
            !bundleID.isEmpty,
            bundleID != Bundle.main.bundleIdentifier {
            req.context[FromSceneKey.key] = FromScene.app.rawValue
        }

        let from: FromScene = FromScene.build(context: req.context)
        let sceneCode = from.sceneCode()

        setAppInfo(url: url, from: from, context: req.context)

        // 从多任务管理器跳转到小程序，需要返回vc，由多任务管理器负责push操作
        let vc: UIViewController?
        if (req.context["manualPush"] as? Bool) == true {
            // 已不再支持的逻辑
            vc = EERoute.shared().getViewController(by: url, scene: sceneCode, window: req.context.from()?.fromViewController?.view.window)
        } else {
            guard let navigationFrom = req.context.from() else { return }
            
            let showInTemporary = req.context[kOpenInTemporay] as? Bool
            let launcherFrom = req.context[kLauncherFrom] as? String ?? ""
            let extraParams = MiniProgramExtraParam(showInTemporary: showInTemporary,launcherFrom: launcherFrom)
            showAfterSwitchIfNeeded(url: url, scene: from, navigationFrom: navigationFrom,channel: channel,extra: extraParams)
            vc = nil
        }

        res.end(resource: vc ?? EmptyResource())
    }

    private static func setAppInfo(url: URL,
                                   from: FromScene,
                                   context: [String: Any]? = nil) {
        let sslocal = SSLocalModel(url: url)
        let appID: String? = sslocal.app_id
        if let appID = appID {
            let appInfo: MicroAppInfo = MicroAppInfoManager.shared.getAppInfo(appID: appID) ?? MicroAppInfo(appID: appID)
            appInfo.scene = from
            appInfo.sslocal = sslocal
            appInfo.feedAppID = nil // 每次启动先重置 feedAppID
            appInfo.feedSeqID = nil // 每次启动先重置 feedSeqID
            appInfo.feedType = nil  // 每次启动先重置 feedType
            if let context = context, let feedInfo = context["feedInfo"] as? [String: Any] {
                appInfo.feedAppID = feedInfo["appID"] as? String
                appInfo.feedSeqID = feedInfo["seqID"] as? String
                appInfo.feedType = feedInfo["type"] as? Basic_V1_FeedCard.EntityType
            }
            MicroAppInfoManager.shared.setAppInfo(appInfo)
        }
    }

    // 小程序打开适配iPad，同理可参见 Navigator+showAfterSwitchIfNeeded.swift，规则如下
    // iPad 先跳转tab，再showDetail
    // iphone，直接push
    private static func showAfterSwitchIfNeeded(url: URL,
                                                scene: FromScene,
                                                navigationFrom: NavigatorFrom?,
                                                channel: StartChannel? = .undefined,
                                                applinkTraceId: String? = "",
                                                extra: MiniProgramExtraParam? = nil) {
        // 通知需要保证登录（某些场景下默认的主动登录任务会延迟数秒才会执行，可能晚于用户操作）
        OpenAppEngine.shared.notifyLoginIfNeeded()
        
        let sceneCode = scene.sceneCode()
        let window = navigationFrom?.fromViewController?.view.window
        let sslocal = SSLocalModel(url: url)
        let uniqueId = sslocal.uniqueID()

        MiniProgramHandler.logger.error("MiniProgramHandler showAfterSwitch with new gadgetNavigator")
        EERoute.shared().openURL(byPushViewController: url, scene: sceneCode, window: window, channel: channel?.rawValue, applinkTraceId: applinkTraceId, extra: extra)
    }

    /// 多 scene 场景中, 需要在主 scene 打开小程序
    private static func checkoutToMainSceneIfNeeded(from: NavigatorFrom, callback: @escaping (NavigatorFrom) -> Void) {
        if Display.pad && SceneManager.shared.supportsMultipleScenes {
            SceneManager.shared.active(scene: .mainScene(), from: from.fromViewController) { (window, _) in
                if let window = window {
                    callback(window)
                }
            }
        } else {
            callback(from)
        }
    }
}

fileprivate extension FromScene {
    // iPad上，小程序打开小程序，采用push的方式；其他采用切换到应用中心Tab然后showDetail的方式
    var ipadMPOpenType: OpenType {
        switch self {
        case .micro_app, .mini_program:
            return .push
        default:
            return .showDetail
        }
    }
}
