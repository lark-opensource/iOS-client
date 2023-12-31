//
//  LarkMeegoAssembly.swift
//  LarkMeego
//
//  Created by shizhengyu on 2021/8/26.
//

import Foundation
import Swinject
import AppContainer
import BootManager
import EENavigator
import LarkAccountInterface
import LarkRustClient
import LarkMeegoInterface
import LarkDebugExtensionPoint
import LarkAssembler
import LarkAppLinkSDK
import LarkMeegoNetClient
import LarkMeegoPush
import LarkFoundation
import LarkEnv
import LarkReleaseConfig
import LarkLocalizations
import LarkSetting
import LarkMeegoNetClient
import LarkContainer
import LarkUIKit
import LarkMeegoLogger
import LarkMeegoStrategy
import LarkMeegoProjectBiz
import LarkMeegoWorkItemBiz
import LarkMeegoViewBiz

public enum Meego {
    public static var userScopeCompatibleMode: Bool {
        return !FeatureGating.get(by: FeatureGating.enableUserContainer, userResolver: nil)
    }
    // 用于替换 .user, FG 控制是否开启兼容模式。兼容模式下和 .user 表现一致
    public static let userScope = UserLifeScope { userScopeCompatibleMode }
    // 用于替换 .userGraph, FG 控制是否开启兼容模式。兼容模式下和 .userGraph 表现一致
    public static let userGraphScope = UserGraphScope { userScopeCompatibleMode }
}

private enum ApplinkAgreement {
    static let pattern = "/client/project"
    static let originUrlQueryKey = "origin_url"
}

public class LarkMeegoAssembly: LarkAssemblyInterface {
    public init() {}

    public func registContainer(container: Container) {
        let user = container.inObjectScope(Meego.userScope)

        user.register(MeegoNetClient.self) { r in
            let meegoNetClientHelper = try LarkMeegoNetClientHelper(userResolver: r)
            var larkMeegoNetClient = LarkMeegoNetClient(
                meegoNetClientHelper.getMeegoBaseURL(),
                config: meegoNetClientHelper.createNetConfig()
            )
            return larkMeegoNetClient
        }

        user.register(LarkMeegoService.self) { r in
            return try LarkMeegoServiceImpl(userResolver: r)
        }

        user.register(WorkItemBizDependency.self) { r in
            return try WorkItemBizDependencyImpl(userResolver: r)
        }

        user.register(ViewBizDependency.self) { r in
            return try ViewBizDependencyImpl(userResolver: r)
        }
    }

    public func registLaunch(container: Container) {
        NewBootManager.register(LarkMeegoBootTask.self)
    }

    public func registLauncherDelegate(container: Container) {
        (LauncherDelegateFactory {
            let enableUserScope = container.resolve(PassportService.self)?.enableUserScope ?? false
            return enableUserScope ? DummyLauncherDelegate() : LarkMeegoLaunchDelegate()
        }, LauncherDelegateRegisteryPriority.middle)
    }

    public func registPassportDelegate(container: Container) {
        (PassportDelegateFactory {
            let enableUserScope = container.resolve(PassportService.self)?.enableUserScope ?? false
            return enableUserScope ? LarkMeegoPassportDelegate() : DummyPassportDelegate()
        }, PassportDelegatePriority.middle)
    }

    public func registServerPushHandlerInUserSpace(container: Container) {
        (ServerCommand.pushMeego, LarkMeegoPushHandler.init(resolver:))
    }

    #if ALPHA
    public func registDebugItem(container: Container) {
        ({ LarkMeegoDebugItem() }, SectionType.debugTool)
    }
    #endif

    public func registLarkAppLink(container: Container) {
        MeegoLogger.info("register an applink for \(ApplinkAgreement.pattern)", customPrefix: "{applink}")

        LarkAppLinkSDK.registerHandler(path: ApplinkAgreement.pattern) { applink in
            MeegoLogger.info("receive an applink from url: \(applink.url.absoluteString)", customPrefix: "{applink}")
            guard FeatureGating.get(by: FeatureGating.enableMeegoApplink, userResolver: nil) else { return }

            if let originUrlString = applink.url.queryParameters[ApplinkAgreement.originUrlQueryKey]?.removingPercentEncoding,
               let originUrl = URL(string: originUrlString),
               let rootVc = Navigator.shared.mainSceneTopMost as? UIViewController {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, qos: .background) {
                    if rootVc.navigationController != nil {
                        Navigator.shared.push(originUrl, context: ["from": "applink"], from: rootVc)
                    } else {
                        let style: UIModalPresentationStyle = Display.pad ? .formSheet : .fullScreen
                        Navigator.shared.present(
                            originUrl,
                            context: ["from": "applink"],
                            wrap: LkNavigationController.self,
                            from: rootVc,
                            prepare: { (vc) in
                                vc.modalPresentationStyle = style
                            },
                            animated: true
                        )
                    }
                }
            }
        }
    }

    public func getSubAssemblies() -> [LarkAssembler.LarkAssemblyInterface]? {
        StrategyAssembly()
        ProjectBizAssembly()
    }
}
